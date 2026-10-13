-- int_customer_first_order: cohort assignment per customer.
--   cohort_month   : calendar month of the first order            [Glossary: Cohort]
--   sales_channel  : channel of the first order (Shopify / Amazon)
--   acq_type       : 'Sub' if the first order has a subscription line, else 'OTP'
--   entry_sku      : first-order line, preferring subscription items then highest price [Glossary: Entry product]
-- Customers whose first order falls in the current (partial) month are excluded.
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.int_customer_first_order` AS
WITH entry AS (
  SELECT order_id, sku AS entry_sku
  FROM `${PROJECT}.${DATASET}.int_order_lines`
  WHERE TRUE
  QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id
                             ORDER BY is_subscription DESC, unit_price DESC, order_line_id) = 1
)
SELECT
  o.customer_key,
  o.sales_channel,
  o.order_id                                   AS first_order_id,
  o.order_date                                 AS first_order_date,
  DATE_TRUNC(o.order_date, MONTH)              AS cohort_month,
  IF(o.has_subscription_line, 'Sub', 'OTP')    AS acq_type,
  e.entry_sku
FROM `${PROJECT}.${DATASET}.int_orders` o
JOIN entry e USING (order_id)
CROSS JOIN `${PROJECT}.${DATASET}.int_params` p
WHERE o.order_seq = 1
  AND DATE_TRUNC(o.order_date, MONTH) <= p.last_complete_month;
