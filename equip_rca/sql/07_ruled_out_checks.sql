-- =====================================================================
-- 07_ruled_out_checks.sql
-- Doc section 7 — the three hypotheses that were killed by a one-line
-- fact rather than a model comparison. Kept so nobody re-opens them.
--
--   A. Walmart / source_name '88312' dropped by a platform filter?
--      No -- both carry platform_name = 'Shopify' and are fully present
--      in OrderLinesMaster.
--   B. Faire mis-channelled rather than excluded?
--      No -- only Shopify and Amazon Seller Central channels exist.
--      Faire is removed upstream by the revenue-bucket channel filter.
--   C. The $0-founding rule and the Faire addition touching the same
--      customers?  No -- zero overlap in every cohort.
--
-- Read-only. Single SELECT, three labelled sections unioned.
-- =====================================================================
WITH raw_orders AS (
  SELECT raw_order_id, customer_id, created_at, source_name, total_price
  FROM (
    SELECT CAST(id AS STRING)                          AS raw_order_id,
           CAST(customer[SAFE_OFFSET(0)].id AS STRING) AS customer_id,
           created_at, cancelled_at, source_name,
           SAFE_CAST(total_price AS NUMERIC) AS total_price,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY _daton_batch_runtime DESC) AS rn
    FROM `insightsprod.equipfoods_5642_prod_raw.Equip_SHOPIFYV2_3317_orders`
    WHERE created_at >= TIMESTAMP '2025-01-01'
  )
  WHERE rn = 1 AND cancelled_at IS NULL
),

-- A: how each source_name lands in the presentation layer
check_a AS (
  SELECT 'A source_name -> platform/channel' AS check_name,
         CONCAT(IFNULL(r.source_name, '(null)'), ' | ',
                IFNULL(o.platform_name, 'NOT IN OLM')) AS detail,
         COUNT(DISTINCT r.raw_order_id)                AS n
  FROM raw_orders r
  LEFT JOIN `insightsprod.equipfoods_5642_prod_presentation.OrderLinesMaster` o
    ON CAST(o.order_id AS STRING) = r.raw_order_id
  WHERE r.source_name IN ('faire', 'walmart', '88312', 'shopify_draft_order', '3426665')
  GROUP BY 1, 2
),

-- B: the full channel list in the presentation layer
check_b AS (
  SELECT 'B channels present in OLM' AS check_name,
         IFNULL(channel, '(null)')   AS detail,
         COUNT(*)                    AS n
  FROM `insightsprod.equipfoods_5642_prod_presentation.OrderLinesMaster`
  GROUP BY 1, 2
),

-- C: do the $0-founding customers and the Faire retailers overlap?
olm_founding AS (
  SELECT customer_id, order_id, order_date
  FROM (
    SELECT CAST(customer_id AS STRING) AS customer_id,
           CAST(order_id AS STRING)    AS order_id,
           MIN(order_date)             AS order_date,
           ROW_NUMBER() OVER (PARTITION BY CAST(customer_id AS STRING)
                              ORDER BY MIN(order_date), CAST(order_id AS STRING)) AS rn
    FROM `insightsprod.equipfoods_5642_prod_presentation.OrderLinesMaster`
    WHERE customer_id IS NOT NULL
      AND IFNULL(is_test, FALSE)      = FALSE
      AND IFNULL(is_gift_card, FALSE) = FALSE
      AND platform_name = 'Shopify'
    GROUP BY 1, 2
  )
  WHERE rn = 1
),
zero_founding AS (
  SELECT f.customer_id, DATE_TRUNC(f.order_date, MONTH) AS acq_month
  FROM olm_founding f
  JOIN raw_orders r ON r.raw_order_id = f.order_id
  WHERE r.total_price = 0
),
faire_cust AS (
  SELECT DISTINCT customer_id FROM raw_orders
  WHERE source_name = 'faire' AND customer_id IS NOT NULL
),
check_c AS (
  SELECT 'C $0-founding and Faire overlap' AS check_name,
         FORMAT_DATE('%Y-%m', z.acq_month) AS detail,
         COUNTIF(fc.customer_id IS NOT NULL) AS n   -- expected 0 everywhere
  FROM zero_founding z
  LEFT JOIN faire_cust fc USING (customer_id)
  GROUP BY 1, 2
)

SELECT * FROM check_a
UNION ALL SELECT * FROM check_b
UNION ALL SELECT * FROM check_c
ORDER BY check_name, n DESC, detail;
