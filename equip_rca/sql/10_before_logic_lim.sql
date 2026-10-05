-- =====================================================================
-- 10_before_logic_lim.sql
-- The BEFORE tab of the validation sheet, rebuilt on LineItemMaster.
--
-- Companion to 09_production_lim.sql. Same table, same filters, same
-- revenue formula -- so the two tabs of the sheet are strictly
-- comparable and only the logic differs.
--
-- WHAT "BEFORE" MEANS HERE
--   Current production behaviour: a customer is put in a bucket on the
--   day they are acquired, and every dollar they ever spend stays in
--   that bucket for life.
--
--   No change 1 -- revenue is never re-allocated after acquisition.
--   No change 2 -- Faire retailers and their revenue are NOT added.
--   Change 3 IS applied -- the $0 founding-order rule. This is
--   deliberate. Production does not have that rule, but applying it to
--   both tabs keeps the July cohort comparable; otherwise the Before
--   tab would carry 936 phantom customers the After tab does not, and
--   every July diff would be measuring the rule rather than the logic.
--
-- Read-only. Single SELECT. Same five LineItemMaster gotchas as 09:
--   returns are rows in this table, no is_test / is_gift_card filter,
--   item_gross_sales = item_subtotal_price, channel not platform_name,
--   and `date` needs backticks.
-- =====================================================================
WITH params AS (
  SELECT DATE '2025-09-01' AS first_cohort,
         DATE '2026-07-01' AS last_cohort,
         10                AS max_month_index,
         -- Must match 09_production_lim.sql or the two tabs are not
         -- comparable. 0 reproduces the OrderLinesMaster build; set to
         -- -1 in BOTH files once the upstream shipping sign is fixed.
         0                 AS return_shipping_sign
),

raw_orders AS (
  SELECT raw_order_id, total_price
  FROM (
    SELECT CAST(id AS STRING)               AS raw_order_id,
           SAFE_CAST(total_price AS NUMERIC) AS total_price,
           cancelled_at,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY _daton_batch_runtime DESC) AS rn
    FROM `insightsprod.equipfoods_5642_prod_raw.Equip_SHOPIFYV2_3317_orders`
    WHERE created_at >= TIMESTAMP '2025-01-01'
  )
  WHERE rn = 1 AND cancelled_at IS NULL
),

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

return_level AS (
  SELECT CAST(customer_id AS STRING) AS customer_id,
         MIN(`date`) AS return_date,
         SUM(COALESCE(item_returns, 0))        AS return_value,
         SUM(COALESCE(item_shipping_price, 0)) AS return_shipping
  FROM `insightsprod.equipfoods_5642_prod_presentation.LineItemMaster`
  WHERE customer_id IS NOT NULL
    AND channel = 'Shopify'
    AND transaction_type = 'Return'
  GROUP BY 1, CAST(order_id AS STRING)
),

founding AS (
  SELECT customer_id, order_id, order_date AS acq_date, revenue_bucket AS founding_bucket
  FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS rn
    FROM order_level
  )
  WHERE rn = 1
),

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

cohort AS (
  SELECT a.customer_id, a.bucket, DATE_TRUNC(a.acq_date, MONTH) AS acq_month
  FROM acq a
  CROSS JOIN params p
  LEFT JOIN raw_orders t ON t.raw_order_id = a.order_id
  WHERE DATE_TRUNC(a.acq_date, MONTH) BETWEEN p.first_cohort AND p.last_cohort
    AND (a.founding_bucket IS NULL OR a.founding_bucket != 'TT New')
    AND IFNULL(t.total_price, 1) != 0
),

-- The whole of the Before logic: every event keeps the customer's
-- acquisition bucket. No allocation step at all.
events AS (
  SELECT c.acq_month, c.bucket, o.order_date AS ev_date, o.order_ltr AS ltr
  FROM order_level o
  JOIN cohort c USING (customer_id)
  UNION ALL
  SELECT c.acq_month, c.bucket, rl.return_date,
         -rl.return_value + (p.return_shipping_sign * rl.return_shipping)
  FROM return_level rl
  CROSS JOIN params p
  JOIN cohort c ON rl.customer_id = c.customer_id
),

facts AS (
  SELECT acq_month, bucket AS b,
         DATE_DIFF(DATE_TRUNC(ev_date, MONTH), acq_month, MONTH) AS m,
         SUM(ltr) AS v
  FROM events GROUP BY 1, 2, 3
  UNION ALL
  SELECT acq_month, 'All customers',
         DATE_DIFF(DATE_TRUNC(ev_date, MONTH), acq_month, MONTH),
         SUM(ltr)
  FROM events GROUP BY 1, 2, 3
),

sizes AS (
  SELECT acq_month, bucket AS b, COUNT(*) AS n FROM cohort GROUP BY 1, 2
  UNION ALL
  SELECT acq_month, 'All customers', COUNT(*) FROM cohort GROUP BY 1, 2
),

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
LEFT JOIN facts f
  ON f.acq_month = g.acq_month AND f.b = g.b AND f.m = g.m
ORDER BY g.b, acquisition_month, g.m;

-- =====================================================================
-- VALIDATION -- must reproduce the OrderLinesMaster Before tab.
--
--                      customers      M0        last month
--   2025-09  All          7,920      93.90      245.79  (M10)
--            OTP          4,767      92.50      203.64  (M10)
--            Sub          3,153      96.01      309.51  (M10)
--   2026-03  All         11,220      97.46      203.17  (M6)
--            OTP          6,643      95.00      166.73  (M6)
--            Sub          4,577     101.02      256.07  (M6)
--   2026-07  All         10,850     100.67      139.16  (M2)
--            OTP          6,413      98.05      121.16  (M2)
--            Sub          4,437     104.44      165.18  (M2)
--
-- Structural checks:
--   OTP + Subscription = All customers in every cell
--   customer counts are LOWER than 09_production_lim.sql in every
--   cohort from 2026-02 on -- that gap is the Faire retailers, which
--   this query does not add. Expect +17 Feb, +33 Mar, +25 Apr,
--   +37 May, +33 Jun, +46 Jul.
--   Cohorts before 2026-02 must match 09 exactly: Faire launched
--   2026-02-10, so there is nothing to add.
--
-- If a number is off by more than ~0.1%, check in this order:
--   1. Were Return rows included?
--   2. Is return_shipping_sign still 0, and the same as in 09?
--   3. Did an is_test / is_gift_card filter get added back in?
-- =====================================================================
