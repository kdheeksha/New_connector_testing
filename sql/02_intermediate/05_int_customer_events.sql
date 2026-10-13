-- int_customer_events: every dated money / order event, complete months only.
--   Orders land on the order date; refunds land on the REFUND date and reduce net sales.
--   COGS is not reversed on refunds (assumption: refunded food is not restocked) - see docs open question #5.
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.int_customer_events` AS
WITH ev AS (
  SELECT customer_key, order_date AS event_date, 0 AS orders, net_sales, cogs
  FROM `${PROJECT}.${DATASET}.int_order_lines`
  UNION ALL
  SELECT customer_key, order_date, 1, 0, 0
  FROM `${PROJECT}.${DATASET}.int_orders`
  UNION ALL
  SELECT customer_key, refund_date, 0, -refund_amount, 0
  FROM `${PROJECT}.${DATASET}.stg_refunds`
)
SELECT ev.* FROM ev
CROSS JOIN `${PROJECT}.${DATASET}.int_params` p
WHERE ev.event_date < p.current_month_start;
