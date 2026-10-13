-- int_order_lines: net sales and COGS per order line.
--   net_sales = gross sales - discounts (excl. tax)
--   cogs      = SKU unit cost x qty, else (1 - 55%) x net sales   [Glossary: "Lifetime Value (LTV)"]
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.int_order_lines` AS
SELECT
  l.sales_channel, l.order_id, l.order_line_id, l.customer_key, l.order_ts,
  DATE(l.order_ts)                                    AS order_date,
  l.sku, l.quantity, l.unit_price, l.is_subscription,
  l.gross_sales - l.discounts                         AS net_sales,
  COALESCE(c.unit_cost * l.quantity,
           (1 - p.fallback_margin) * (l.gross_sales - l.discounts)) AS cogs,
  c.unit_cost IS NULL                                 AS cogs_is_fallback
FROM `${PROJECT}.${DATASET}.stg_orders` l
LEFT JOIN `${PROJECT}.${DATASET}.stg_product_cost` c ON c.sku = l.sku
CROSS JOIN `${PROJECT}.${DATASET}.int_params` p;
