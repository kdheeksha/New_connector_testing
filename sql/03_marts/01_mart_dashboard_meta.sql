-- mart_dashboard_meta: header band + window bounds ("data through ...", "cohorts complete through ...").
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.mart_dashboard_meta` AS
SELECT
  p.as_of_date, p.data_through_date, p.last_complete_month,
  (SELECT MIN(cohort_month) FROM `${PROJECT}.${DATASET}.int_customer_first_order`) AS first_cohort_month,
  (SELECT MIN(spend_date) FROM `${PROJECT}.${DATASET}.stg_ad_spend` WHERE sales_channel = 'Amazon') AS amazon_spend_from
FROM `${PROJECT}.${DATASET}.int_params` p;
