-- int_params: the dashboard's time rules in one place.
--   Header reads "Today 17 Sep 2026 · data through 16 Sep 2026 (t-1) · cohorts complete through Aug 2026".
--   Only COMPLETE calendar months are ever used, so the partial current month never appears in a cohort.
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.int_params` AS
SELECT
  CURRENT_DATE()                                                       AS as_of_date,
  DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)                             AS data_through_date,
  DATE_TRUNC(CURRENT_DATE(), MONTH)                                    AS current_month_start,
  DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 1 MONTH)        AS last_complete_month,
  0.55                                                                 AS fallback_margin;   -- LTV fallback when no SKU cost
