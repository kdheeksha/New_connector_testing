-- stg_refunds: one row per refunded order line. Refund value excludes tax. Dated by the REFUND date
-- (dashboard rule: "refunds count in the month they occur").
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.stg_refunds` AS
SELECT
  'Shopify'                                         AS sales_channel,
  CAST(r.order_id AS STRING)                        AS order_id,
  CAST(olr.order_line_id AS STRING)                 AS order_line_id,
  CONCAT('shopify:', CAST(o.customer_id AS STRING)) AS customer_key,
  DATE(r.created_at)                                AS refund_date,
  olr.quantity                                      AS refunded_qty,
  olr.subtotal                                      AS refund_amount        -- ASSUMED: pre-tax refunded amount
FROM `${PROJECT}.shopify.refund` r                                           -- ASSUMED table
JOIN `${PROJECT}.shopify.order_line_refund` olr ON olr.refund_id = r.id      -- ASSUMED table
JOIN `${PROJECT}.shopify.order` o ON o.id = r.order_id

UNION ALL

SELECT
  'Amazon',
  rf.amazon_order_id,
  rf.order_item_id,
  CONCAT('amazon:', o.buyer_id),
  DATE(rf.posted_date),
  rf.quantity,
  rf.refund_amount
FROM `${PROJECT}.amazon_selling_partner.refunds` rf                          -- ASSUMED table (finance events)
JOIN `${PROJECT}.amazon_selling_partner.orders` o ON o.amazon_order_id = rf.amazon_order_id;
