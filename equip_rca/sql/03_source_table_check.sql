-- =====================================================================
-- 03_source_table_check.sql
-- Doc section 3 — "Which source table, and why it mattered"
--
-- Two questions in one query, both for the March 2026 cohort at M0:
--   1. Is the published dashboard net of returns?  (yes)
--   2. Does OrderLinesMaster reproduce it better than LineItemMaster?
--
-- The published M0 total is passed in as a parameter -- it is read off
-- the client-facing dashboard, not queryable.
--
-- Expected:
--   orders only          1,109,523   +1.42%
--   net of returns       1,093,509   -0.04%   <-- the baseline we adopt
--
-- CAVEAT: the LineItemMaster leg below reproduces what our LineItemMaster
-- runs actually DID, so it is the starting point for the gap, not an
-- explanation of it. Note it uses a different revenue term
-- (item_gross_sales - item_discounts), takes returns from the
-- item_returns column rather than ReturnLinesMaster, and applies no
-- is_test / is_gift_card filter -- three differences at once, which is
-- why the 1.2-3.7% gap was never attributable to the table choice.
--
-- To actually isolate it, run this four times, changing ONE thing per
-- run: (1) as written, (2) + is_test/is_gift_card filters, (3) + returns
-- from ReturnLinesMaster instead of item_returns, (4) + item_subtotal_price
-- in place of item_gross_sales. Whichever step moves the number is the
-- cause. See doc section 3.
--
-- Was NOT re-run in the session that produced this document.
--
-- Read-only. Single SELECT.
-- =====================================================================
WITH params AS (
  SELECT DATE '2026-03-01' AS cohort_month,
         1093954.0         AS published_m0_total   -- from the published dashboard
),

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
  SELECT customer_id, order_date AS acq_date, revenue_bucket AS founding_bucket
  FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS rn
    FROM order_level
  )
  WHERE rn = 1
),

cohort AS (
  SELECT f.customer_id, DATE_TRUNC(f.acq_date, MONTH) AS acq_month
  FROM founding f
  CROSS JOIN params p
  WHERE DATE_TRUNC(f.acq_date, MONTH) = p.cohort_month
    AND (f.founding_bucket IS NULL OR f.founding_bucket != 'TT New')
),

-- M0 revenue, orders only
m0_orders AS (
  SELECT SUM(o.order_ltr) AS v
  FROM order_level o
  JOIN cohort c USING (customer_id)
  WHERE DATE_TRUNC(o.order_date, MONTH) = c.acq_month
),

-- M0 returns, same window
m0_returns AS (
  SELECT SUM(COALESCE(rl.item_subtotal_price, 0)) AS v
  FROM `insightsprod.equipfoods_5642_prod_presentation.ReturnLinesMaster` rl
  JOIN cohort c ON CAST(rl.customer_id AS STRING) = c.customer_id
  WHERE IFNULL(rl.is_test, FALSE)      = FALSE
    AND IFNULL(rl.is_gift_card, FALSE) = FALSE
    AND rl.platform_name = 'Shopify'
    AND DATE_TRUNC(rl.return_date, MONTH) = c.acq_month
),

-- Same measure built from LineItemMaster, for the table-choice comparison.
m0_lim AS (
  SELECT SUM(COALESCE(li.item_subtotal_price, 0) - COALESCE(li.item_discount, 0)
           + COALESCE(li.item_shipping_price, 0) - COALESCE(li.item_shipping_tax, 0)) AS v
  FROM `insightsprod.equipfoods_5642_prod_presentation.LineItemMaster` li
  JOIN cohort c ON CAST(li.customer_id AS STRING) = c.customer_id
  WHERE li.platform_name = 'Shopify'
    AND DATE_TRUNC(li.order_date, MONTH) = c.acq_month
)

SELECT measure, ROUND(value, 0) AS value,
       ROUND((value - p.published_m0_total) / p.published_m0_total * 100, 2) AS pct_vs_published
FROM params p,
UNNEST([
  STRUCT('OLM, orders only'           AS measure, (SELECT v FROM m0_orders)                            AS value),
  STRUCT('OLM, net of returns',              (SELECT v FROM m0_orders) - (SELECT v FROM m0_returns)),
  STRUCT('LineItemMaster, orders only',      (SELECT v FROM m0_lim)),
  STRUCT('published dashboard',              p.published_m0_total)
])
ORDER BY measure;
