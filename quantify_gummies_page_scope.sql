-- ============================================================================
-- QUANTIFY: impact of page-scoping NEW Shopify Gummies customers
--
-- Compares the current product-scoped numbers (SKU / product_category_unique)
-- against page-scoped numbers (order entered via /products/sea-moss-gummies).
--
-- landing_site is NOT yet in DailySalesTracker -- that is the pending dbt
-- change. Until it lands, we simulate it by joining DailySalesTracker back to
-- staging ShopifyOrders on order_id. This produces exactly what the view will
-- return once the column is plumbed through.
--
-- Scope note: New + Shopify only. Existing customers carry landing_site on
-- just 4.5% of orders, and subscriptions have no order grain at all, so
-- neither can be page-scoped.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- QUERY 1 - monthly comparison
-- ---------------------------------------------------------------------------
WITH gummies_new AS (
  SELECT
    date,
    shopify_order_id,
    shopify_customer_id,
    COALESCE(shopify_total_sales, 0) AS sales
  FROM `daton-project.trueseamoss_5363_prod_presentation_datashare.DailySalesTracker`
  WHERE product_category_unique IN ('Gummies Bottle', 'Gummies Pouch')
    AND platform_name    = 'shopify'
    AND customer_type    = 'New'
    AND transaction_type <> 'Return'
    AND shopify_order_id IS NOT NULL
    AND shopify_order_id <> ''
    AND date >= '2025-10-01'
),

-- Flag each order as having entered on the Gummies product page.
-- The regex accepts Shopify's collection-prefixed and trailing-slash forms
-- of the SAME product page, and nothing else:
--   /products/sea-moss-gummies
--   /collections/all/products/sea-moss-gummies
--   /collections/sea-moss-gummies/products/sea-moss-gummies
-- It deliberately excludes different products such as
-- -shop, -10-blends-in-1, copy-of-, and sea-moss-elderberry-gummies.
orders AS (
  SELECT
    CAST(order_id AS STRING) AS oid,
    REGEXP_CONTAINS(
      REGEXP_EXTRACT(landing_site, r'^[^?]*'),
      r'^(/collections/[^/]+)?/products/sea-moss-gummies/?$'
    ) AS on_gummies_page
  FROM `daton-project.trueseamoss_5363_prod_staging_datashare.ShopifyOrders`
)

SELECT
  FORMAT_DATE('%Y-%m', g.date) AS mth,
  COUNT(DISTINCT g.shopify_customer_id) AS customers_now,
  COUNT(DISTINCT IF(o.on_gummies_page, g.shopify_customer_id, NULL))
    AS customers_page_scoped,
  ROUND(SUM(g.sales), 0) AS sales_now,
  ROUND(SUM(IF(o.on_gummies_page, g.sales, 0)), 0) AS sales_page_scoped
FROM gummies_new g
LEFT JOIN orders o ON o.oid = g.shopify_order_id
GROUP BY 1
ORDER BY 1;

-- RESULT (run 2026-09-08):
-- mth      | customers_now | page_scoped | sales_now | sales_page
-- 2025-10  |         1789  |         22  |    44029  |      1151
-- 2025-11  |         2158  |         12  |    49396  |       523
-- 2025-12  |          844  |          5  |    22812  |       191
-- 2026-01  |          468  |          6  |    15938  |       314
-- 2026-02  |         1117  |          1  |    25230  |        26
-- 2026-03  |          704  |          4  |    16342  |       166
-- 2026-04  |          537  |          4  |    13658  |       161
-- 2026-05  |         1831  |          5  |    34783  |       241
-- 2026-06  |         1638  |          3  |    31704  |       119
-- 2026-07  |         2078  |          6  |    39494  |       260
-- 2026-08  |         2060  |         68  |    45311  |      2838
-- 2026-09  |          704  |         42  |    16014  |      1394
--
-- The near-zero months are real: nothing was driving traffic to the Gummies
-- page until the two Meta campaigns launched 18 Aug and 28 Aug 2026.


-- ---------------------------------------------------------------------------
-- QUERY 2 - DTC NCPA since the campaigns went live
-- ---------------------------------------------------------------------------
WITH gummies_new AS (
  SELECT shopify_order_id, shopify_customer_id,
         COALESCE(shopify_total_sales, 0) AS sales
  FROM `daton-project.trueseamoss_5363_prod_presentation_datashare.DailySalesTracker`
  WHERE product_category_unique IN ('Gummies Bottle', 'Gummies Pouch')
    AND platform_name    = 'shopify'
    AND customer_type    = 'New'
    AND transaction_type <> 'Return'
    AND shopify_order_id IS NOT NULL
    AND shopify_order_id <> ''
    AND date >= '2026-08-18'
),
orders AS (
  SELECT CAST(order_id AS STRING) AS oid,
         REGEXP_CONTAINS(
           REGEXP_EXTRACT(landing_site, r'^[^?]*'),
           r'^(/collections/[^/]+)?/products/sea-moss-gummies/?$'
         ) AS on_gummies_page
  FROM `daton-project.trueseamoss_5363_prod_staging_datashare.ShopifyOrders`
),
customers AS (
  SELECT
    COUNT(DISTINCT g.shopify_customer_id) AS customers_now,
    COUNT(DISTINCT IF(o.on_gummies_page, g.shopify_customer_id, NULL))
      AS customers_page_scoped,
    SUM(g.sales) AS sales_now,
    SUM(IF(o.on_gummies_page, g.sales, 0)) AS sales_page_scoped
  FROM gummies_new g
  LEFT JOIN orders o ON o.oid = g.shopify_order_id
),
-- Spend needs no page-scoping: both Gummies campaigns are 100% verified to
-- the target URL (see verify_gummies_spend.sql), and meta_adspend equals
-- shopify_adspend exactly, with google and youtube at zero.
spend AS (
  SELECT SUM(COALESCE(meta_adspend, 0)) AS meta_spend
  FROM `daton-project.trueseamoss_5363_prod_presentation_datashare.DailySpendsTracker`
  WHERE product_category = 'Gummies'
    AND date >= '2026-08-18'
)

SELECT
  ROUND(s.meta_spend, 2) AS meta_spend,
  c.customers_now,
  c.customers_page_scoped,
  ROUND(c.sales_now, 0)         AS sales_now,
  ROUND(c.sales_page_scoped, 0) AS sales_page_scoped,
  ROUND(SAFE_DIVIDE(s.meta_spend, c.customers_now), 2)
    AS dtc_ncpa_now,
  ROUND(SAFE_DIVIDE(s.meta_spend, c.customers_page_scoped), 2)
    AS dtc_ncpa_page_scoped
FROM customers c, spend s;

-- RESULT (run 2026-09-08, 18 Aug onward):
-- meta_spend | cust_now | cust_page | sales_now | sales_page | ncpa_now | ncpa_page
--   16105.30 |     1697 |       106 |     39379 |       3993 |     9.49 |    151.94
