-- =====================================================================
-- 09_production_lim.sql
-- The production cohort LTR query, rebuilt on LineItemMaster.
--
-- This is the ONE query meant to survive the investigation. It produces
-- the "After" numbers: change 1 (attribution) + change 2 (Faire) +
-- change 3 ($0 founding orders). Everything else in sql/ is diagnostic
-- and stays on OrderLinesMaster as the record of how we got here.
--
-- Why LineItemMaster: it is the house convention, and it is simply
-- OrderLinesMaster and ReturnLinesMaster combined, so the numbers are
-- the same. We built the investigation on the two source tables because
-- we needed control over the returns step -- that was the step we got
-- wrong first time round.
--
-- Read-only. Single SELECT. No DDL, no temp tables.
--
-- ---------------------------------------------------------------------
-- DIFFERENCES FROM THE OrderLinesMaster BUILD -- read before running
-- ---------------------------------------------------------------------
-- 1. Returns live in this same table as transaction_type = 'Return'
--    rows, dated by their own return date. Do NOT filter to
--    transaction_type = 'Order' -- that silently drops every return and
--    puts the answer 1-4% high. That mistake is what sent the whole
--    investigation down a blind alley.
-- 2. No is_test / is_gift_card filter. LineItemMaster applies both
--    internally and does not expose the columns, so filtering here
--    errors. Their absence is correct, not an omission.
-- 3. Column names differ: item_gross_sales IS OrderLinesMaster's
--    item_subtotal_price, and item_discounts IS its item_discount.
--    Same values, different names.
-- 4. The channel column is 'channel', not 'platform_name'.
-- 5. The date column is `date` and must be backticked -- reserved word.
-- 6. Faire and the $0 rule both come from the RAW orders table, not from
--    LineItemMaster. Faire is excluded from the presentation layer
--    entirely, so no presentation model can supply it.
--
-- ---------------------------------------------------------------------
-- KNOWN UPSTREAM BUG -- see return_shipping_sign in params
-- ---------------------------------------------------------------------
-- On Return rows LineItemMaster carries item_shipping_price as a
-- POSITIVE refunded amount and the natural formula adds it, so refunded
-- shipping increases revenue. That is a sign error in the model, raised
-- with the DE team. It is about $61K across all Shopify.
-- The param below controls how this query treats it.
-- =====================================================================
WITH params AS (
  SELECT DATE '2025-09-01' AS first_cohort,
         DATE '2026-07-01' AS last_cohort,
         10                AS max_month_index,
         -- Shipping on a Return row:
         --    0  ignore it. DEFAULT. Reproduces the published
         --       OrderLinesMaster build exactly, so the validation
         --       targets at the bottom of this file apply.
         --   -1  subtract it. The correct treatment once the upstream
         --       bug is fixed. Expect March M4 to move by about
         --       -425 (OTP) and -1,046 (Subscription).
         --   +1  the model's current behaviour. Wrong. Never ship this.
         0                 AS return_shipping_sign
),

-- ---------------------------------------------------------------------
-- Raw Shopify orders: latest Daton version per order, cancellations
-- dropped. Needed for the $0 founding rule and for Faire.
-- ---------------------------------------------------------------------
raw_orders AS (
  SELECT raw_order_id, customer_id, created_at, source_name,
         total_price, subtotal_after_discount
  FROM (
    SELECT CAST(id AS STRING)                          AS raw_order_id,
           CAST(customer[SAFE_OFFSET(0)].id AS STRING) AS customer_id,
           created_at, cancelled_at, source_name,
           SAFE_CAST(total_price AS NUMERIC)    AS total_price,
           SAFE_CAST(subtotal_price AS NUMERIC) AS subtotal_after_discount,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY _daton_batch_runtime DESC) AS rn
    FROM `insightsprod.equipfoods_5642_prod_raw.Equip_SHOPIFYV2_3317_orders`
    WHERE created_at >= TIMESTAMP '2025-01-01'
  )
  WHERE rn = 1 AND cancelled_at IS NULL
),

-- ---------------------------------------------------------------------
-- Order grain. COALESCE every term: SUM(a - b) drops the whole row when
-- any term is NULL, which cost $146K of OTP revenue in an earlier run.
-- ---------------------------------------------------------------------
order_level AS (
  SELECT CAST(customer_id AS STRING) AS customer_id,
         CAST(order_id    AS STRING) AS order_id,
         MIN(`date`)         AS order_date,
         MAX(revenue_bucket) AS revenue_bucket,
         SUM(COALESCE(item_gross_sales, 0)    - COALESCE(item_discounts, 0)
           + COALESCE(item_shipping_price, 0) - COALESCE(item_shipping_tax, 0)) AS order_ltr
  FROM `insightsprod.equipfoods_5642_prod_presentation.LineItemMaster`
  WHERE customer_id IS NOT NULL
    AND channel = 'Shopify'
    AND transaction_type = 'Order'
  GROUP BY 1, 2
),

-- Return grain, dated by the return's own date.
return_level AS (
  SELECT CAST(customer_id AS STRING) AS customer_id,
         CAST(order_id    AS STRING) AS order_id,
         MIN(`date`) AS return_date,
         SUM(COALESCE(item_returns, 0))        AS return_value,
         SUM(COALESCE(item_shipping_price, 0)) AS return_shipping
  FROM `insightsprod.equipfoods_5642_prod_presentation.LineItemMaster`
  WHERE customer_id IS NOT NULL
    AND channel = 'Shopify'
    AND transaction_type = 'Return'
  GROUP BY 1, 2
),

founding AS (
  SELECT customer_id, order_id, order_date AS acq_date, revenue_bucket AS founding_bucket
  FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS rn
    FROM order_level
  )
  WHERE rn = 1
),

-- Subscription if ANY order on the acquisition DATE is a subscription
-- type -- the client buckets by day, not by single order.
acq AS (
  SELECT f.customer_id, f.order_id, f.acq_date, f.founding_bucket,
         IF(LOGICAL_OR(ol.revenue_bucket IN ('NC Subs', 'Recurring Day Of', 'SKIO (Recurring)')),
            'Subscription', 'OTP') AS bucket
  FROM founding f
  JOIN order_level ol
    ON ol.customer_id = f.customer_id
   AND ol.order_date  = f.acq_date
  GROUP BY 1, 2, 3, 4
),

-- CHANGE 3 -- drop customers whose FOUNDING order cost nothing.
-- The 2026-07-09 giveaway created 936 acquisitions worth $3.57 each
-- against a July average of $93.96. Scoped to the founding order only:
-- applied globally it would drop legitimate $0 replacements. Uses
-- total_price, not total_line_items_price, which misses 2 of the 875
-- and all 66 shipping-only cases.
cohort_base AS (
  SELECT a.customer_id, a.bucket, DATE_TRUNC(a.acq_date, MONTH) AS acq_month
  FROM acq a
  CROSS JOIN params p
  LEFT JOIN raw_orders t ON t.raw_order_id = a.order_id
  WHERE DATE_TRUNC(a.acq_date, MONTH) BETWEEN p.first_cohort AND p.last_cohort
    AND (a.founding_bucket IS NULL OR a.founding_bucket != 'TT New')   -- TikTok
    AND IFNULL(t.total_price, 1) != 0
),

-- CHANGE 2 -- Faire wholesale.
-- Faire retailers must enter the DENOMINATOR as well as the numerator:
-- 87% of Faire revenue belongs to retailers with no presentation-layer
-- row at all, so adding revenue alone inflates LTR per customer.
-- Faire-only customers are dated by their first FAIRE order; dating
-- them by their first raw order back-dates 7 of them into pre-February
-- cohorts, and Faire launched 2026-02-10.
faire_first AS (
  SELECT customer_id,
         DATE_TRUNC(DATE(MIN(created_at), 'America/New_York'), MONTH) AS first_faire_month
  FROM raw_orders
  WHERE source_name = 'faire' AND customer_id IS NOT NULL
  GROUP BY customer_id
),

cohort_faire_new AS (
  SELECT f.customer_id, 'OTP' AS bucket, f.first_faire_month AS acq_month
  FROM faire_first f
  CROSS JOIN params p
  LEFT JOIN order_level o USING (customer_id)
  WHERE o.customer_id IS NULL
    AND f.first_faire_month BETWEEN p.first_cohort AND p.last_cohort
  GROUP BY 1, 2, 3
),

cohort_plus AS (
  SELECT * FROM cohort_base
  UNION ALL
  SELECT * FROM cohort_faire_new
),

faire_rev AS (
  SELECT cp.acq_month, cp.customer_id,
         DATE_DIFF(DATE_TRUNC(DATE(r.created_at, 'America/New_York'), MONTH),
                   cp.acq_month, MONTH) AS m,
         SUM(r.subtotal_after_discount) AS ltr
  FROM raw_orders r
  JOIN cohort_plus cp USING (customer_id)
  WHERE r.source_name = 'faire'
  GROUP BY 1, 2, 3
),

-- CHANGE 1 -- post-acquisition attribution.
-- M0 stays in the acquisition bucket. From M1 an order is Subscription
-- if the customer was acquired on Subscription, OR the order is a
-- subscription type, OR it falls on/after their first subscription
-- order. Note this is keyed on the order DATE, not the month index --
-- an earlier version switched the customer at the start of the month
-- containing their first subscription order, which over-assigned every
-- OTP order placed earlier in that same month.
cust_orders AS (
  SELECT o.customer_id, o.order_id, o.order_date, o.order_ltr, c.bucket, c.acq_month,
         MIN(IF(o.revenue_bucket IN ('NC Subs', 'Recurring Day Of', 'SKIO (Recurring)'),
                o.order_date, NULL)) OVER (PARTITION BY o.customer_id) AS first_sub_date
  FROM order_level o
  JOIN cohort_base c USING (customer_id)
),

order_alloc AS (
  SELECT customer_id, order_id, acq_month, bucket, order_date, order_ltr,
         IF(bucket = 'Subscription'
            OR (first_sub_date IS NOT NULL AND order_date >= first_sub_date),
            'Subscription', 'OTP') AS alloc
  FROM cust_orders
),

-- Orders, returns and Faire as one event stream.
-- A return follows the allocation of the order it reverses.
events AS (
  SELECT acq_month, bucket, order_date AS ev_date, order_ltr AS ltr, alloc
  FROM order_alloc

  UNION ALL

  SELECT c.acq_month, c.bucket, rl.return_date,
         -rl.return_value + (p.return_shipping_sign * rl.return_shipping),
         COALESCE(oa.alloc, c.bucket)
  FROM return_level rl
  CROSS JOIN params p
  JOIN cohort_base c ON rl.customer_id = c.customer_id
  LEFT JOIN order_alloc oa ON oa.order_id = rl.order_id

  UNION ALL

  -- Faire is always OTP: no Faire order is a subscription.
  SELECT fr.acq_month, 'OTP', DATE_ADD(fr.acq_month, INTERVAL fr.m MONTH),
         fr.ltr, 'OTP'
  FROM faire_rev fr
),

ev AS (
  SELECT acq_month, bucket, alloc, ltr,
         DATE_DIFF(DATE_TRUNC(ev_date, MONTH), acq_month, MONTH)     AS m,
         DATE_DIFF(DATE_TRUNC(ev_date, MONTH), acq_month, MONTH) = 0 AS is_m0
  FROM events
),

facts AS (
  SELECT acq_month, IF(is_m0, bucket, alloc) AS b, m, SUM(ltr) AS v
  FROM ev GROUP BY 1, 2, 3
),

facts2 AS (
  SELECT acq_month, b, m, SUM(v) AS v FROM facts GROUP BY 1, 2, 3
  UNION ALL
  SELECT acq_month, 'All customers', m, SUM(v) FROM facts GROUP BY 1, 2, 3
),

sizes AS (
  SELECT acq_month, bucket AS b, COUNT(*) AS n FROM cohort_plus GROUP BY 1, 2
  UNION ALL
  SELECT acq_month, 'All customers', COUNT(*) FROM cohort_plus GROUP BY 1, 2
),

-- Dense grid so a month with no events still carries the prior cumulative.
grid AS (
  SELECT s.acq_month, s.b, s.n, mm AS m
  FROM sizes s
  CROSS JOIN params p
  CROSS JOIN UNNEST(GENERATE_ARRAY(0, p.max_month_index)) AS mm
  WHERE DATE_ADD(s.acq_month, INTERVAL mm MONTH) < DATE_TRUNC(CURRENT_DATE(), MONTH)
)

SELECT FORMAT_DATE('%Y-%m', g.acq_month) AS acquisition_month,
       g.b                               AS bucket,
       g.m                               AS month_index,
       g.n                               AS cohort_customers,
       ROUND(SUM(COALESCE(f.v, 0)) OVER (
         PARTITION BY g.acq_month, g.b ORDER BY g.m), 0)       AS cum_revenue,
       ROUND(SUM(COALESCE(f.v, 0)) OVER (
         PARTITION BY g.acq_month, g.b ORDER BY g.m) / g.n, 2) AS cum_ltr_per_customer
FROM grid g
LEFT JOIN facts2 f
  ON f.acq_month = g.acq_month AND f.b = g.b AND f.m = g.m
ORDER BY g.b, acquisition_month, g.m;

-- =====================================================================
-- VALIDATION -- with return_shipping_sign = 0, this must reproduce the
-- OrderLinesMaster build. Check these before trusting any output.
--
-- March 2026 (LTR per customer):
--   OTP            6,676 customers    M0  97.08    M4 128.78
--   Subscription   4,577 customers    M0 101.02    M4 255.93
--   All customers 11,253 customers    M0  98.68    M4 180.50
--
-- Structural checks, true in every cell:
--   OTP + Subscription = All customers
--   customer counts identical to the OrderLinesMaster build
--   no cohort before 2026-02 gains a Faire customer
--
-- If a number is off by more than ~0.1%, check in this order:
--   1. Were Return rows included? (the usual cause)
--   2. Is return_shipping_sign still 0?
--   3. Did an is_test / is_gift_card filter get added back in?
-- =====================================================================
