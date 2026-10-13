-- mart_product_cohort: per entry product x acquisition type x cohort: customers and repurchase counts.
-- Grain: entry_product x acq_type x cohort_month   (= D.prod[i][type].n / .rep12 / .repEver)
--   repurchased_12m is NULL until the cohort is mature (acquired 12+ months ago).
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.mart_product_cohort` AS
SELECT
  entry_category AS category, entry_sub_category AS sub_category, entry_product AS product,
  acq_type, cohort_month,
  COUNT(*)                           AS customers_acquired,
  IF(COUNTIF(repurchased_12m IS NULL) > 0, NULL, COUNTIF(repurchased_12m)) AS repurchased_12m,
  COUNTIF(lifetime_orders > 1)       AS repurchased_ever
FROM `${PROJECT}.${DATASET}.int_customer_profile`
WHERE entry_product IS NOT NULL
GROUP BY 1, 2, 3, 4, 5;
