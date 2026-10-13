-- stg_orders: one row per order LINE, Shopify + Amazon unified.
-- ALL source references are ASSUMED (Fivetran-style schemas). Confirm with sql/00_discovery/discover_sources.sql,
-- then edit ONLY the staging files; everything downstream reads these views.
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.stg_orders` AS
SELECT
  'Shopify'                                        AS sales_channel,
  CAST(o.id AS STRING)                             AS order_id,
  CAST(ol.id AS STRING)                            AS order_line_id,
  CONCAT('shopify:', CAST(o.customer_id AS STRING)) AS customer_key,       -- ASSUMED: shopify.order.customer_id
  o.created_at                                     AS order_ts,
  ol.sku                                           AS sku,
  ol.quantity                                      AS quantity,
  ol.price                                         AS unit_price,
  ol.quantity * ol.price                           AS gross_sales,         -- excl. tax
  IFNULL(ol.total_discount, 0)                     AS discounts,
  (ol.selling_plan_id IS NOT NULL)                 AS is_subscription      -- ASSUMED: selling plan / Recharge flag
FROM `${PROJECT}.shopify.order` o                                           -- ASSUMED table
JOIN `${PROJECT}.shopify.order_line` ol ON ol.order_id = o.id               -- ASSUMED table
WHERE o.cancelled_at IS NULL
  AND IFNULL(o.test, FALSE) = FALSE
  AND o.customer_id IS NOT NULL

UNION ALL

SELECT
  'Amazon',
  oi.amazon_order_id,
  oi.order_item_id,
  CONCAT('amazon:', o.buyer_id),                   -- ASSUMED + RISK: Amazon rarely exposes a stable buyer id (see docs open question #2)
  o.purchase_date,
  oi.seller_sku,
  oi.quantity_ordered,
  SAFE_DIVIDE(oi.item_price_amount, NULLIF(oi.quantity_ordered, 0)),
  oi.item_price_amount,
  IFNULL(oi.promotion_discount_amount, 0),
  IFNULL(oi.is_subscribe_and_save, FALSE)          -- ASSUMED: Subscribe & Save flag
FROM `${PROJECT}.amazon_selling_partner.orders` o                           -- ASSUMED table
JOIN `${PROJECT}.amazon_selling_partner.order_item` oi
  ON oi.amazon_order_id = o.amazon_order_id                                 -- ASSUMED table
WHERE o.order_status NOT IN ('Canceled', 'Pending')
  AND o.buyer_id IS NOT NULL;
