-- =====================================================================
-- 05a_change1_four_rules.sql
-- Doc section 5.1 — "Post-acquisition attribution", the four-rule test
--
-- The single engine behind every number in this document. Emits all
-- four candidate attribution rules over all eleven cohorts so they can
-- be scored side by side:
--
--   A old              acquisition bucket for life          <- BEFORE tab
--   B de rule          re-allocate from M1 by subscription state
--   B de rule + faire  B plus Faire retailers and revenue   <- AFTER tab
--   C window + faire   Subscription only BETWEEN first and last
--                      subscription order (rejected)
--
-- Scoring against the client (mean 14.11% / 1.03% / 1.11% / 2.16%)
-- is done OUTSIDE this query -- the client's values live in their
-- workbook, not in BigQuery. This produces the "ours" side only.
--
-- A caution: rule C won an earlier round of this same test when it was
-- run on LineItemMaster. It lost once the baseline was corrected to
-- OrderLinesMaster. Score any new rule on all eleven cohorts, never on
-- March alone.
--
-- Read-only. Single SELECT. Expect 4 logics x 3 buckets x 11 cohorts
-- x month_index, roughly 700 rows.
-- =====================================================================
WITH params AS (
  SELECT DATE '2025-09-01' AS first_cohort,
         DATE '2026-07-01' AS last_cohort,
         10                AS max_month_index
),

-- ---------------------------------------------------------------------
-- Raw Shopify orders. Latest Daton version per order id, cancellations
-- dropped. Two uses: the $0-founding-order rule, and Faire (which never
-- reaches OrderLinesMaster at all -- see doc section 5.2).
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
-- Order grain from the presentation layer.
-- LTR = gross - item discount + shipping - shipping tax, net of returns
-- further down. COALESCE on every term: SUM(a - b) drops the entire row
-- when any term is NULL.
-- ---------------------------------------------------------------------
order_level AS (
  SELECT CAST(customer_id AS STRING) AS customer_id,
         CAST(order_id    AS STRING) AS order_id,
         MIN(order_date)     AS order_date,
         MAX(revenue_bucket) AS revenue_bucket,
         SUM(COALESCE(item_subtotal_price, 0) - COALESCE(item_discount, 0)
           + COALESCE(item_shipping_price, 0) - COALESCE(item_shipping_tax, 0)) AS order_ltr
  FROM `insightsprod.equipfoods_5642_prod_presentation.OrderLinesMaster`
  WHERE customer_id IS NOT NULL
    AND IFNULL(is_test, FALSE)      = FALSE
    AND IFNULL(is_gift_card, FALSE) = FALSE
    AND platform_name = 'Shopify'
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

-- Subscription if ANY order on the acquisition DATE is a subscription type.
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

cohort_base AS (
  SELECT a.customer_id, a.bucket, DATE_TRUNC(a.acq_date, MONTH) AS acq_month
  FROM acq a
  CROSS JOIN params p
  LEFT JOIN raw_orders t ON t.raw_order_id = a.order_id
  WHERE DATE_TRUNC(a.acq_date, MONTH) BETWEEN p.first_cohort AND p.last_cohort
    AND (a.founding_bucket IS NULL OR a.founding_bucket != 'TT New')  -- TikTok
    AND IFNULL(t.total_price, 1) != 0                                 -- doc 5.3
),

-- ---------------------------------------------------------------------
-- CHANGE 2 — Faire (doc section 5.2).
-- Faire retailers must be added to the DENOMINATOR as well as the
-- numerator: 87% of Faire revenue belongs to retailers with no
-- OrderLinesMaster row at all, so revenue-only inflates LTR per customer.
-- Faire-only customers are dated by their first FAIRE order, not their
-- first raw order, or an excluded order type back-dates them into a
-- pre-February cohort (Faire launched 2026-02-10).
-- ---------------------------------------------------------------------
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

-- ---------------------------------------------------------------------
-- CHANGE 1 — post-acquisition attribution (doc section 5.1).
--   alloc_de : Subscription from the customer's FIRST subscription order
--              onward (and always, if acquired on Subscription).
--   alloc_c  : Subscription only BETWEEN first and last subscription
--              order. Rejected -- kept so the choice stays auditable.
-- ---------------------------------------------------------------------
cust_orders AS (
  SELECT o.customer_id, o.order_id, o.order_date, o.order_ltr, c.bucket, c.acq_month,
         MIN(IF(o.revenue_bucket IN ('NC Subs', 'Recurring Day Of', 'SKIO (Recurring)'),
                o.order_date, NULL)) OVER (PARTITION BY o.customer_id) AS first_sub_date,
         MAX(IF(o.revenue_bucket IN ('NC Subs', 'Recurring Day Of', 'SKIO (Recurring)'),
                o.order_date, NULL)) OVER (PARTITION BY o.customer_id) AS last_sub_date
  FROM order_level o
  JOIN cohort_base c USING (customer_id)
),

order_alloc AS (
  SELECT customer_id, order_id, acq_month, bucket, order_date, order_ltr,
         IF(bucket = 'Subscription'
            OR (first_sub_date IS NOT NULL AND order_date >= first_sub_date),
            'Subscription', 'OTP') AS alloc_de,
         IF(first_sub_date IS NOT NULL
            AND order_date BETWEEN first_sub_date AND last_sub_date,
            'Subscription', 'OTP') AS alloc_c
  FROM cust_orders
),

-- Returns follow the allocation of the order they reverse.
events AS (
  SELECT acq_month, bucket, order_date AS ev_date, order_ltr AS ltr, alloc_de, alloc_c
  FROM order_alloc
  UNION ALL
  SELECT c.acq_month, c.bucket, rl.return_date,
         -COALESCE(rl.item_subtotal_price, 0),
         COALESCE(oa.alloc_de, c.bucket),
         COALESCE(oa.alloc_c,  c.bucket)
  FROM `insightsprod.equipfoods_5642_prod_presentation.ReturnLinesMaster` rl
  JOIN cohort_base c ON CAST(rl.customer_id AS STRING) = c.customer_id
  LEFT JOIN order_alloc oa ON oa.order_id = CAST(rl.return_order_id AS STRING)
  WHERE IFNULL(rl.is_test, FALSE)      = FALSE
    AND IFNULL(rl.is_gift_card, FALSE) = FALSE
    AND rl.platform_name = 'Shopify'
),

ev AS (
  SELECT acq_month, bucket, alloc_de, alloc_c, ltr,
         DATE_DIFF(DATE_TRUNC(ev_date, MONTH), acq_month, MONTH)      AS m,
         DATE_DIFF(DATE_TRUNC(ev_date, MONTH), acq_month, MONTH) = 0  AS is_m0
  FROM events
),

-- M0 always stays in the acquisition bucket; only M1+ is re-allocated.
facts AS (
  SELECT acq_month, 'A old' AS logic, bucket AS b, m, SUM(ltr) AS v FROM ev GROUP BY 1,2,3,4
  UNION ALL SELECT acq_month, 'B de rule',         IF(is_m0, bucket, alloc_de), m, SUM(ltr) FROM ev GROUP BY 1,2,3,4
  UNION ALL SELECT acq_month, 'B de rule + faire', IF(is_m0, bucket, alloc_de), m, SUM(ltr) FROM ev GROUP BY 1,2,3,4
  UNION ALL SELECT acq_month, 'C window + faire',  IF(is_m0, bucket, alloc_c),  m, SUM(ltr) FROM ev GROUP BY 1,2,3,4
  UNION ALL SELECT acq_month, 'B de rule + faire', 'OTP', m, SUM(ltr) FROM faire_rev GROUP BY 1,2,3,4
  UNION ALL SELECT acq_month, 'C window + faire',  'OTP', m, SUM(ltr) FROM faire_rev GROUP BY 1,2,3,4
),

facts2 AS (
  SELECT acq_month, logic, b, m, SUM(v) AS v FROM facts GROUP BY 1,2,3,4
  UNION ALL
  SELECT acq_month, logic, 'All customers', m, SUM(v) FROM facts GROUP BY 1,2,4
),

-- Denominators. Only the "+ faire" logics use the enlarged base.
sizes AS (
  SELECT acq_month, 'A old' AS logic, bucket AS b, COUNT(*) AS n FROM cohort_base GROUP BY 1,2,3
  UNION ALL SELECT acq_month, 'A old',             'All customers', COUNT(*) FROM cohort_base GROUP BY 1,2
  UNION ALL SELECT acq_month, 'B de rule',         bucket,          COUNT(*) FROM cohort_base GROUP BY 1,2,3
  UNION ALL SELECT acq_month, 'B de rule',         'All customers', COUNT(*) FROM cohort_base GROUP BY 1,2
  UNION ALL SELECT acq_month, 'B de rule + faire', bucket,          COUNT(*) FROM cohort_plus GROUP BY 1,2,3
  UNION ALL SELECT acq_month, 'B de rule + faire', 'All customers', COUNT(*) FROM cohort_plus GROUP BY 1,2
  UNION ALL SELECT acq_month, 'C window + faire',  bucket,          COUNT(*) FROM cohort_plus GROUP BY 1,2,3
  UNION ALL SELECT acq_month, 'C window + faire',  'All customers', COUNT(*) FROM cohort_plus GROUP BY 1,2
),

-- Dense grid so a month with no events still carries the prior cumulative.
grid AS (
  SELECT s.acq_month, s.logic, s.b, s.n, mm AS m
  FROM sizes s
  CROSS JOIN params p
  CROSS JOIN UNNEST(GENERATE_ARRAY(0, p.max_month_index)) AS mm
  WHERE DATE_ADD(s.acq_month, INTERVAL mm MONTH) < DATE_TRUNC(CURRENT_DATE(), MONTH)
),

cells AS (
  SELECT g.acq_month, g.logic, g.b AS bucket, g.m AS month_index, g.n AS cohort_customers,
         SUM(COALESCE(f.v, 0)) OVER (
           PARTITION BY g.acq_month, g.logic, g.b ORDER BY g.m) AS cum_revenue
  FROM grid g
  LEFT JOIN facts2 f
    ON f.acq_month = g.acq_month AND f.logic = g.logic AND f.b = g.b AND f.m = g.m
)

SELECT FORMAT_DATE('%Y-%m', acq_month) AS acquisition_month,
       logic,
       bucket,
       month_index,
       cohort_customers,
       ROUND(cum_revenue, 0)                      AS cum_revenue,
       ROUND(cum_revenue / cohort_customers, 2)   AS cum_ltr_per_customer
FROM cells
ORDER BY logic, bucket, acquisition_month, month_index;
