-- =====================================================================
-- 02_before_logic.sql
-- Doc section 2 — "The Before logic: what the dashboard does today"
--
-- Reproduces the BEFORE tab of the validation sheet: a customer is put
-- in a bucket on the day they are acquired and every dollar they ever
-- spend is counted in that bucket for life.
--
-- Read-only. Single SELECT. No DDL, no temp tables.
-- Returns one row per (cohort, bucket, month_index).
-- Expected: 33 cohort/bucket pairs; March 2026 = 6,643 OTP + 4,577 Sub.
-- =====================================================================
WITH params AS (
  SELECT DATE '2025-09-01' AS first_cohort,
         DATE '2026-07-01' AS last_cohort,
         10                AS max_month_index
),

-- Raw Shopify orders, latest Daton version only, cancellations dropped.
-- Needed solely for the $0-founding-order rule (doc section 5.3), which
-- is applied to BOTH tabs so Before and After stay comparable.
raw_orders AS (
  SELECT raw_order_id, total_price
  FROM (
    SELECT CAST(id AS STRING) AS raw_order_id,
           SAFE_CAST(total_price AS NUMERIC) AS total_price,
           cancelled_at,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY _daton_batch_runtime DESC) AS rn
    FROM `insightsprod.equipfoods_5642_prod_raw.Equip_SHOPIFYV2_3317_orders`
    WHERE created_at >= TIMESTAMP '2025-01-01'
  )
  WHERE rn = 1 AND cancelled_at IS NULL
),

-- Order grain. LTR = gross - discount + shipping - shipping tax.
-- COALESCE on every term: SUM(a - b) silently drops the whole row when
-- any term is NULL, which cost $146k of OTP revenue in an earlier run.
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

-- Founding order = earliest by (order_date, order_id).
founding AS (
  SELECT customer_id, order_id, order_date AS acq_date, revenue_bucket AS founding_bucket
  FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS rn
    FROM order_level
  )
  WHERE rn = 1
),

-- Acquisition bucket: Subscription if ANY order on the acquisition DATE
-- is a subscription type (the client buckets by day, not by single order).
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
    AND (a.founding_bucket IS NULL OR a.founding_bucket != 'TT New')  -- TikTok excluded
    AND IFNULL(t.total_price, 1) != 0                                 -- $0 founding rule
),

-- Orders and returns as one event stream. The published dashboard is
-- NET of returns (doc section 3) -- orders-only runs sit ~1.4% high.
events AS (
  SELECT c.acq_month, c.bucket, o.order_date AS ev_date, o.order_ltr AS ltr
  FROM order_level o
  JOIN cohort_base c USING (customer_id)
  UNION ALL
  SELECT c.acq_month, c.bucket, rl.return_date, -COALESCE(rl.item_subtotal_price, 0)
  FROM `insightsprod.equipfoods_5642_prod_presentation.ReturnLinesMaster` rl
  JOIN cohort_base c ON CAST(rl.customer_id AS STRING) = c.customer_id
  WHERE IFNULL(rl.is_test, FALSE)      = FALSE
    AND IFNULL(rl.is_gift_card, FALSE) = FALSE
    AND rl.platform_name = 'Shopify'
),

-- BEFORE = acquisition bucket applied to every event, for life.
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
  SELECT acq_month, bucket AS b, COUNT(*) AS n FROM cohort_base GROUP BY 1, 2
  UNION ALL
  SELECT acq_month, 'All customers', COUNT(*) FROM cohort_base GROUP BY 1, 2
),

-- Dense grid so a month with no revenue still carries the prior cumulative.
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
         PARTITION BY g.acq_month, g.b ORDER BY g.m), 0)        AS cum_revenue,
       ROUND(SUM(COALESCE(f.v, 0)) OVER (
         PARTITION BY g.acq_month, g.b ORDER BY g.m) / g.n, 2)  AS cum_ltr_per_customer
FROM grid g
LEFT JOIN facts f
  ON f.acq_month = g.acq_month AND f.b = g.b AND f.m = g.m
ORDER BY g.b, acquisition_month, g.m;
