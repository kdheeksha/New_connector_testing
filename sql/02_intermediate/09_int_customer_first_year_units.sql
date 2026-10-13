-- int_customer_first_year_units: units bought and units returned in each customer's first 365 days.
-- Feeds Return rate (split by repeat vs one-time). Mature customers only (a full first year observed).
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.int_customer_first_year_units` AS
WITH bought AS (
  SELECT l.customer_key, SUM(l.quantity) AS units_purchased
  FROM `${PROJECT}.${DATASET}.int_order_lines` l
  JOIN `${PROJECT}.${DATASET}.int_customer_first_order` f USING (customer_key)
  WHERE l.order_date < DATE_ADD(f.first_order_date, INTERVAL 365 DAY)
  GROUP BY 1
),
returned AS (
  SELECT r.customer_key, SUM(r.refunded_qty) AS units_returned
  FROM `${PROJECT}.${DATASET}.stg_refunds` r
  JOIN `${PROJECT}.${DATASET}.int_order_lines` l USING (order_line_id)
  JOIN `${PROJECT}.${DATASET}.int_customer_first_order` f ON f.customer_key = r.customer_key
  WHERE l.order_date  < DATE_ADD(f.first_order_date, INTERVAL 365 DAY)
    AND r.refund_date < DATE_ADD(f.first_order_date, INTERVAL 365 DAY)
  GROUP BY 1
)
SELECT f.customer_key, IFNULL(b.units_purchased, 0) AS units_purchased, IFNULL(r.units_returned, 0) AS units_returned
FROM `${PROJECT}.${DATASET}.int_customer_first_order` f
LEFT JOIN bought b USING (customer_key)
LEFT JOIN returned r USING (customer_key)
CROSS JOIN `${PROJECT}.${DATASET}.int_params` p
WHERE f.cohort_month <= DATE_SUB(p.last_complete_month, INTERVAL 12 MONTH);
