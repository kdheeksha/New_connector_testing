-- int_orders: one row per order, with the customer's order sequence (1 = first order).
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.int_orders` AS
WITH o AS (
  SELECT sales_channel, order_id, customer_key,
         MIN(order_ts) AS order_ts, MIN(order_date) AS order_date,
         SUM(net_sales) AS net_sales, SUM(quantity) AS units,
         LOGICAL_OR(is_subscription) AS has_subscription_line
  FROM `${PROJECT}.${DATASET}.int_order_lines`
  GROUP BY 1, 2, 3
)
SELECT o.*,
  ROW_NUMBER() OVER (PARTITION BY customer_key ORDER BY order_ts, order_id) AS order_seq
FROM o;
