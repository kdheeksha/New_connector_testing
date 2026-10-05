-- =====================================================================
-- 05c_change3_zero_founding.sql
-- Doc section 5.3 — "$0 founding orders (July 2026)"
--
-- Profiles the 2026-07-09 free-product promotion and shows what the
-- exclusion rule removes, cohort by cohort.
--
-- Expected: 875 founding orders under $5, 871 of them on 2026-07-09;
-- 66 shipping-only ($0 total_price with non-zero shipping); 936
-- customers dropped from the July cohort; dropped customers average
-- ~$3.57 lifetime against a cohort average of ~$93.96.
--
-- NOTE the rule uses total_price, NOT total_line_items_price -- the
-- latter misses 2 of the 875 and all 66 shipping-only cases.
--
-- Read-only. Single SELECT.
-- =====================================================================
WITH params AS (
  SELECT DATE '2025-09-01' AS first_cohort,
         DATE '2026-07-01' AS last_cohort
),

raw_orders AS (
  SELECT raw_order_id, customer_id, created_at, total_price, total_line_items_price
  FROM (
    SELECT CAST(id AS STRING)                       AS raw_order_id,
           CAST(customer[SAFE_OFFSET(0)].id AS STRING) AS customer_id,
           created_at, cancelled_at,
           SAFE_CAST(total_price AS NUMERIC)            AS total_price,
           SAFE_CAST(total_line_items_price AS NUMERIC) AS total_line_items_price,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY _daton_batch_runtime DESC) AS rn
    FROM `insightsprod.equipfoods_5642_prod_raw.Equip_SHOPIFYV2_3317_orders`
    WHERE created_at >= TIMESTAMP '2025-01-01'
  )
  WHERE rn = 1 AND cancelled_at IS NULL
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
  SELECT customer_id, order_id, order_date AS acq_date, revenue_bucket AS founding_bucket
  FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS rn
    FROM order_level
  )
  WHERE rn = 1
),

-- Every cohort customer, flagged by whether the rule would drop them,
-- alongside their full lifetime value so the "worth nothing" claim is
-- checkable rather than asserted.
tagged AS (
  SELECT DATE_TRUNC(f.acq_date, MONTH)  AS acq_month,
         f.customer_id,
         r.total_price                  AS founding_total_price,
         r.total_line_items_price       AS founding_line_items_price,
         DATE(r.created_at, 'America/New_York') AS founding_day,
         (r.total_price = 0)            AS dropped_by_rule,
         (SELECT SUM(o.order_ltr) FROM order_level o
           WHERE o.customer_id = f.customer_id) AS lifetime_ltr
  FROM founding f
  CROSS JOIN params p
  JOIN raw_orders r ON r.raw_order_id = f.order_id
  WHERE DATE_TRUNC(f.acq_date, MONTH) BETWEEN p.first_cohort AND p.last_cohort
    AND (f.founding_bucket IS NULL OR f.founding_bucket != 'TT New')
)

SELECT FORMAT_DATE('%Y-%m', acq_month) AS acquisition_month,
       COUNT(*)                                            AS cohort_before_rule,
       COUNTIF(dropped_by_rule)                            AS dropped,
       COUNT(*) - COUNTIF(dropped_by_rule)                 AS cohort_after_rule,
       COUNTIF(dropped_by_rule AND founding_day = DATE '2026-07-09') AS dropped_on_promo_day,
       -- shipping-only: total_price 0 but line items priced, i.e. the
       -- cases a "< $5" cut on line items would miss
       COUNTIF(dropped_by_rule AND IFNULL(founding_line_items_price, 0) != 0) AS shipping_only,
       ROUND(AVG(IF(dropped_by_rule, lifetime_ltr, NULL)), 2)   AS avg_ltr_dropped,
       ROUND(AVG(IF(dropped_by_rule, NULL, lifetime_ltr)), 2)   AS avg_ltr_kept
FROM tagged
GROUP BY 1
ORDER BY 1;
