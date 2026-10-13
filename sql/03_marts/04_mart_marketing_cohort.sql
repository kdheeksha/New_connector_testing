-- mart_marketing_cohort: per attribution view x cohort x marketing channel: customers credited and ad spend.
-- Grain: attribution_view x cohort_month x marketing_channel   (= D.mkt[view].chans[ch].n / .spend / .paid)
-- Spend is platform spend, independent of attribution view; Superfiliate spend appears only in 'lpcsf'.
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.mart_marketing_cohort` AS
WITH cust AS (
  SELECT attribution_view, cohort_month, marketing_channel, SUM(credit) AS customers_acquired
  FROM `${PROJECT}.${DATASET}.int_customer_attribution` GROUP BY 1, 2, 3
),
spend AS (
  SELECT v AS attribution_view, DATE_TRUNC(s.spend_date, MONTH) AS cohort_month,
         s.marketing_channel, SUM(s.spend) AS ad_spend
  FROM `${PROJECT}.${DATASET}.stg_ad_spend` s
  CROSS JOIN UNNEST(['lpc', 'inc', 'lpcsf']) AS v
  WHERE s.marketing_channel NOT LIKE 'Superfiliate%' OR v = 'lpcsf'
  GROUP BY 1, 2, 3
)
SELECT
  attribution_view, cohort_month, marketing_channel,
  IFNULL(c.customers_acquired, 0) AS customers_acquired,
  s.ad_spend,
  ch.is_paid
FROM cust c
FULL OUTER JOIN spend s USING (attribution_view, cohort_month, marketing_channel)
LEFT JOIN `${PROJECT}.${DATASET}.ref_marketing_channel` ch USING (marketing_channel);
