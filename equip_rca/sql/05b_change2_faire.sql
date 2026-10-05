-- =====================================================================
-- 05b_change2_faire.sql
-- Doc section 5.2 — "Faire wholesale retailers"
--
-- Establishes the three facts the Faire change rests on:
--   1. Faire orders exist in raw and reach dim_orders.
--   2. Essentially none of them reach OrderLinesMaster -- they are
--      excluded by shopify_revenue_bucket_excluded_channels, applied
--      via the shopify_passes_global_filter macro.
--   3. New Faire retailers appear from 2026-02 onward, which is exactly
--      where our OTP position turns negative against the client.
--
-- Expected: 649 Faire orders, 293 distinct customers, first order
-- 2026-02-10, ~$228K subtotal, only 40 customers with ANY
-- OrderLinesMaster row. New retailers by cohort: Feb 17, Mar 33,
-- Apr 25, May 37, Jun 33, Jul 46.
--
-- The relay-email count is a FLOOR, not a count: only 397 of the 649
-- orders use an @relay.faire.com address, so Faire buyers with ordinary
-- emails are invisible to email matching. Match on customer_id.
--
-- Read-only. Single SELECT.
-- =====================================================================
WITH params AS (
  SELECT DATE '2025-09-01' AS first_cohort,
         DATE '2026-07-01' AS last_cohort
),

raw_orders AS (
  SELECT raw_order_id, customer_id, created_at, source_name, subtotal_after_discount
  FROM (
    SELECT CAST(id AS STRING)                          AS raw_order_id,
           CAST(customer[SAFE_OFFSET(0)].id AS STRING) AS customer_id,
           created_at, cancelled_at, source_name,
           SAFE_CAST(subtotal_price AS NUMERIC) AS subtotal_after_discount,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY _daton_batch_runtime DESC) AS rn
    FROM `insightsprod.equipfoods_5642_prod_raw.Equip_SHOPIFYV2_3317_orders`
    WHERE created_at >= TIMESTAMP '2025-01-01'
  )
  WHERE rn = 1 AND cancelled_at IS NULL
),

faire AS (
  SELECT * FROM raw_orders WHERE source_name = 'faire' AND customer_id IS NOT NULL
),

-- Which Faire customers have ANY OrderLinesMaster row? (expected: 40)
olm_customers AS (
  SELECT DISTINCT CAST(customer_id AS STRING) AS customer_id
  FROM `insightsprod.equipfoods_5642_prod_presentation.OrderLinesMaster`
  WHERE customer_id IS NOT NULL
    AND IFNULL(is_test, FALSE)      = FALSE
    AND IFNULL(is_gift_card, FALSE) = FALSE
    AND platform_name = 'Shopify'
),

-- Faire orders that survive into OrderLinesMaster at all (expected: 0).
faire_in_olm AS (
  SELECT COUNT(*) AS n
  FROM `insightsprod.equipfoods_5642_prod_presentation.OrderLinesMaster` o
  JOIN faire f ON CAST(o.order_id AS STRING) = f.raw_order_id
),

-- One row per Faire retailer, with their first Faire month.
retailers AS (
  SELECT f.customer_id,
         DATE_TRUNC(DATE(MIN(f.created_at), 'America/New_York'), MONTH) AS first_faire_month,
         COUNT(*)                            AS faire_orders,
         SUM(f.subtotal_after_discount)      AS faire_revenue,
         (oc.customer_id IS NOT NULL)        AS has_olm_row
  FROM faire f
  LEFT JOIN olm_customers oc USING (customer_id)
  GROUP BY f.customer_id, oc.customer_id
)

SELECT FORMAT_DATE('%Y-%m', first_faire_month) AS first_faire_cohort,
       COUNT(*)                                AS new_faire_retailers,
       COUNTIF(has_olm_row)                    AS of_which_also_in_olm,
       COUNTIF(NOT has_olm_row)                AS faire_only_added_to_denominator,
       SUM(faire_orders)                       AS faire_orders,
       ROUND(SUM(faire_revenue), 0)            AS faire_revenue,
       -- 87% of revenue sits with retailers who have no OLM row at all:
       -- this is why the change must add customers, not just dollars.
       ROUND(SUM(IF(has_olm_row, 0, faire_revenue)) / SUM(faire_revenue) * 100, 1)
                                               AS pct_revenue_from_faire_only,
       (SELECT n FROM faire_in_olm)            AS faire_orders_reaching_olm
FROM retailers
CROSS JOIN params p
WHERE first_faire_month BETWEEN p.first_cohort AND p.last_cohort
GROUP BY 1
ORDER BY 1;
