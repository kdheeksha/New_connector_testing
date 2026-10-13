-- int_customer_attribution: channel credit of each customer's FIRST order, per attribution view.
-- Customers with no attribution row fall to 'Unattributed' (credit 1).
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.int_customer_attribution` AS
SELECT
  f.customer_key, f.cohort_month, attribution_view_t.attribution_view,
  IFNULL(a.marketing_channel, 'Unattributed') AS marketing_channel,
  IFNULL(a.credit, 1.0)                       AS credit
FROM `${PROJECT}.${DATASET}.int_customer_first_order` f
CROSS JOIN (SELECT attribution_view FROM UNNEST(['lpc', 'inc', 'lpcsf']) AS attribution_view) attribution_view_t
LEFT JOIN `${PROJECT}.${DATASET}.stg_attribution` a
  ON a.order_id = f.first_order_id AND a.attribution_view = attribution_view_t.attribution_view;
