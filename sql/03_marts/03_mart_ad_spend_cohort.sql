-- mart_ad_spend_cohort: acquisition spend and CAC per cohort month and sales channel (D.spend + cac()).
--   ad_spend is NULL when the channel has no spend data that month (Amazon before Nov 2025) -> no CAC / ratio.
--   customers_acquired counts ALL customers of the channel regardless of type / pattern: CAC is the same for
--   every segment ("allocated to segments by their share of customers").
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.mart_ad_spend_cohort` AS
WITH spend AS (
  SELECT DATE_TRUNC(spend_date, MONTH) AS cohort_month, sales_channel, SUM(spend) AS ad_spend
  FROM `${PROJECT}.${DATASET}.stg_ad_spend`
  WHERE marketing_channel NOT LIKE 'Superfiliate%'    -- base CAC excludes Superfiliate payouts
  GROUP BY 1, 2
),
cust AS (
  SELECT cohort_month, sales_channel, COUNT(*) AS customers_acquired
  FROM `${PROJECT}.${DATASET}.int_customer_first_order` GROUP BY 1, 2
)
SELECT c.cohort_month, c.sales_channel, c.customers_acquired, s.ad_spend,
       SAFE_DIVIDE(s.ad_spend, c.customers_acquired) AS cac
FROM cust c
LEFT JOIN spend s USING (cohort_month, sales_channel);
