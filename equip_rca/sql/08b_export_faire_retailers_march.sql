-- =====================================================================
-- 08b_export_faire_retailers_march.sql
-- Produces exports/faire_retailers_march.csv
--
-- One row per Faire retailer whose FIRST Faire order falls in March
-- 2026 (expected: 33), with whether they also appear in
-- OrderLinesMaster and what they add to the cohort.
--
-- NOT YET RUN -- see doc section 11. This file is the recipe.
--
-- Read-only. Single SELECT.
-- =====================================================================
WITH params AS (
  SELECT DATE '2026-03-01' AS cohort_month
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

first_faire AS (
  SELECT customer_id,
         DATE(MIN(created_at), 'America/New_York') AS first_faire_date,
         DATE_TRUNC(DATE(MIN(created_at), 'America/New_York'), MONTH) AS first_faire_month
  FROM faire GROUP BY customer_id
),

olm AS (
  SELECT CAST(customer_id AS STRING) AS customer_id,
         COUNT(DISTINCT CAST(order_id AS STRING)) AS olm_orders,
         MIN(order_date)                          AS olm_first_order_date
  FROM `insightsprod.equipfoods_5642_prod_presentation.OrderLinesMaster`
  WHERE customer_id IS NOT NULL
    AND IFNULL(is_test, FALSE) = FALSE AND IFNULL(is_gift_card, FALSE) = FALSE
    AND platform_name = 'Shopify'
  GROUP BY 1
)

SELECT ff.customer_id,
       ff.first_faire_date,
       dc.email,
       ENDS_WITH(IFNULL(dc.email, ''), '@relay.faire.com') AS is_relay_email,
       COUNT(DISTINCT f.raw_order_id)                      AS faire_orders,
       ROUND(SUM(f.subtotal_after_discount), 2)            AS faire_revenue,
       IFNULL(o.olm_orders, 0)                             AS olm_orders,
       o.olm_first_order_date,
       (o.customer_id IS NULL) AS faire_only_adds_to_denominator
FROM first_faire ff
CROSS JOIN params p
JOIN faire f USING (customer_id)
LEFT JOIN olm o USING (customer_id)
LEFT JOIN `insightsprod.equipfoods_5642_prod_presentation.dim_customer` dc
  ON CAST(dc.customer_id AS STRING) = ff.customer_id
WHERE ff.first_faire_month = p.cohort_month
GROUP BY 1, 2, 3, 4, 7, 8, 9
ORDER BY faire_revenue DESC;
