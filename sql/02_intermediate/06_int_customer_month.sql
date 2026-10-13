-- int_customer_month: customer x month-since-acquisition (M0 = acquisition month). Sparse: only active months.
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.int_customer_month` AS
SELECT
  e.customer_key,
  DATE_DIFF(DATE_TRUNC(e.event_date, MONTH), f.cohort_month, MONTH) AS month_since,
  SUM(e.orders)    AS orders,
  SUM(e.net_sales) AS net_sales,
  SUM(e.cogs)      AS cogs
FROM `${PROJECT}.${DATASET}.int_customer_events` e
JOIN `${PROJECT}.${DATASET}.int_customer_first_order` f USING (customer_key)
WHERE DATE_TRUNC(e.event_date, MONTH) >= f.cohort_month
GROUP BY 1, 2;
