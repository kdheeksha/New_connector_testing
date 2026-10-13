-- int_customer_profile: one row per customer with cohort attributes + repurchase behaviour.
--   purchasing_pattern : 'Repeat' if >1 order through the last complete month, else 'One-time'
--   last_order_month_since : drives Retention Rate ("ordered at or after month h")
--   repurchased_12m    : second order inside months 0-11; NULL until the cohort has 12 months of age (mature)
--   days_to_second_order : feeds "Median days to second order"
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.int_customer_profile` AS
WITH act AS (
  SELECT customer_key,
         SUM(orders)                               AS lifetime_orders,
         MAX(IF(orders > 0, month_since, NULL))    AS last_order_month_since
  FROM `${PROJECT}.${DATASET}.int_customer_month`
  GROUP BY 1
),
second AS (
  SELECT customer_key, order_date AS second_order_date
  FROM `${PROJECT}.${DATASET}.int_orders`
  WHERE order_seq = 2
)
SELECT
  f.*,
  IFNULL(a.lifetime_orders, 0)                                       AS lifetime_orders,
  IFNULL(a.last_order_month_since, 0)                                AS last_order_month_since,
  IF(IFNULL(a.lifetime_orders, 0) > 1, 'Repeat', 'One-time')         AS purchasing_pattern,
  s.second_order_date,
  DATE_DIFF(s.second_order_date, f.first_order_date, DAY)            AS days_to_second_order,
  DATE_DIFF(DATE_TRUNC(s.second_order_date, MONTH), f.cohort_month, MONTH) AS second_order_month_since,
  IF(f.cohort_month <= DATE_SUB(p.last_complete_month, INTERVAL 11 MONTH),
     IFNULL(DATE_DIFF(DATE_TRUNC(s.second_order_date, MONTH), f.cohort_month, MONTH) <= 11, FALSE),
     NULL)                                                           AS repurchased_12m,
  d.product_name AS entry_product, d.sub_category AS entry_sub_category, d.category AS entry_category
FROM `${PROJECT}.${DATASET}.int_customer_first_order` f
LEFT JOIN act a USING (customer_key)
LEFT JOIN second s USING (customer_key)
LEFT JOIN `${PROJECT}.${DATASET}.stg_product_dim` d ON d.sku = f.entry_sku
CROSS JOIN `${PROJECT}.${DATASET}.int_params` p;
