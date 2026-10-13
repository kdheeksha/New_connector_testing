-- fn_product_summary(window_months, acq_type_filter): the "Entry-product performance" table.
-- Rows are emitted at all three levels (level = 'category' | 'sub_category' | 'product'); the app filters on
-- level + category / sub_category / product for the cascading dropdowns. acq_type_filter: 'All' | 'OTP' | 'Sub'.
--   ltr_pc_{3,6,9,12,18,24} : LTR per customer at that horizon (mature cohorts only)
--   ltv_pc_12               : LTV per customer at 12 months
--   repurchase_12m_rate     : mature cohorts only ; lifetime_repurchase_rate : all cohorts in window
--   median_days_to_second_order : APPROXIMATE median over repurchasers (computed on customers, not a weighted
--                                 average of medians as in the mock)
--   return_rate_repeat / _one_time : first-year units returned / units purchased (unit-weighted)
CREATE OR REPLACE TABLE FUNCTION `${PROJECT}.${DATASET}.fn_product_summary`(window_months INT64, acq_type_filter STRING) AS (
  WITH p AS (SELECT last_complete_month AS lcm FROM `${PROJECT}.${DATASET}.int_params`),
  lv AS (SELECT lvl FROM UNNEST(['category', 'sub_category', 'product']) lvl),
  coh AS (
    SELECT c.* FROM `${PROJECT}.${DATASET}.mart_product_cohort` c, p
    WHERE c.cohort_month > DATE_SUB(p.lcm, INTERVAL window_months MONTH)
      AND (acq_type_filter = 'All' OR c.acq_type = acq_type_filter)
  ),
  cohm AS (
    SELECT m.* FROM `${PROJECT}.${DATASET}.mart_product_cohort_month` m, p
    WHERE m.cohort_month > DATE_SUB(p.lcm, INTERVAL window_months MONTH)
      AND (acq_type_filter = 'All' OR m.acq_type = acq_type_filter)
  ),
  cust AS (
    SELECT cp.*, u.units_purchased, u.units_returned
    FROM `${PROJECT}.${DATASET}.int_customer_profile` cp CROSS JOIN p
    LEFT JOIN `${PROJECT}.${DATASET}.int_customer_first_year_units` u USING (customer_key)
    WHERE cp.cohort_month > DATE_SUB(p.lcm, INTERVAL window_months MONTH)
      AND (acq_type_filter = 'All' OR cp.acq_type = acq_type_filter)
      AND cp.entry_product IS NOT NULL
  ),
  a AS (   -- cohort-level measures rolled to each level
    SELECT lvl,
      IF(lvl = 'product' OR lvl = 'sub_category' OR lvl = 'category', category, NULL)                 AS category,
      IF(lvl IN ('product', 'sub_category'), sub_category, NULL)                                      AS sub_category,
      IF(lvl = 'product', product, NULL)                                                              AS product,
      SUM(customers_acquired)                                  AS customers,
      SUM(IF(repurchased_12m IS NOT NULL, customers_acquired, 0)) AS mature_customers_12m,
      SUM(repurchased_12m)                                     AS repurchased_12m,
      SUM(repurchased_ever)                                    AS repurchased_ever
    FROM coh CROSS JOIN lv GROUP BY 1, 2, 3, 4
  ),
  h AS (   -- horizon measures
    SELECT lvl,
      IF(TRUE, category, NULL) AS category,
      IF(lvl IN ('product', 'sub_category'), sub_category, NULL) AS sub_category,
      IF(lvl = 'product', product, NULL) AS product,
      SAFE_DIVIDE(SUM(IF(month_since = 2,  net_sales_cum, 0)), SUM(IF(month_since = 2,  customers_acquired, 0))) AS ltr_pc_3,
      SAFE_DIVIDE(SUM(IF(month_since = 5,  net_sales_cum, 0)), SUM(IF(month_since = 5,  customers_acquired, 0))) AS ltr_pc_6,
      SAFE_DIVIDE(SUM(IF(month_since = 8,  net_sales_cum, 0)), SUM(IF(month_since = 8,  customers_acquired, 0))) AS ltr_pc_9,
      SAFE_DIVIDE(SUM(IF(month_since = 11, net_sales_cum, 0)), SUM(IF(month_since = 11, customers_acquired, 0))) AS ltr_pc_12,
      SAFE_DIVIDE(SUM(IF(month_since = 17, net_sales_cum, 0)), SUM(IF(month_since = 17, customers_acquired, 0))) AS ltr_pc_18,
      SAFE_DIVIDE(SUM(IF(month_since = 23, net_sales_cum, 0)), SUM(IF(month_since = 23, customers_acquired, 0))) AS ltr_pc_24,
      SAFE_DIVIDE(SUM(IF(month_since = 11, net_sales_cum - cogs_cum, 0)), SUM(IF(month_since = 11, customers_acquired, 0))) AS ltv_pc_12
    FROM cohm CROSS JOIN lv GROUP BY 1, 2, 3, 4
  ),
  b AS (   -- customer-level measures
    SELECT lvl,
      category_ AS category,
      IF(lvl IN ('product', 'sub_category'), sub_category_, NULL) AS sub_category,
      IF(lvl = 'product', product_, NULL) AS product,
      APPROX_QUANTILES(IF(lifetime_orders > 1, days_to_second_order, NULL), 100 IGNORE NULLS)[OFFSET(50)] AS median_days_to_second_order,
      SAFE_DIVIDE(SUM(IF(purchasing_pattern = 'Repeat',   units_returned, 0)), SUM(IF(purchasing_pattern = 'Repeat',   units_purchased, 0))) AS return_rate_repeat,
      SAFE_DIVIDE(SUM(IF(purchasing_pattern = 'One-time', units_returned, 0)), SUM(IF(purchasing_pattern = 'One-time', units_purchased, 0))) AS return_rate_one_time
    FROM (SELECT cust.*, entry_category AS category_, entry_sub_category AS sub_category_, entry_product AS product_ FROM cust) c
    CROSS JOIN lv GROUP BY 1, 2, 3, 4
  )
  SELECT
    a.lvl AS level, a.category, a.sub_category, a.product, a.customers,
    SAFE_DIVIDE(a.customers, SUM(a.customers) OVER (PARTITION BY a.lvl)) AS customer_share,
    h.ltr_pc_3, h.ltr_pc_6, h.ltr_pc_9, h.ltr_pc_12, h.ltr_pc_18, h.ltr_pc_24, h.ltv_pc_12,
    SAFE_DIVIDE(a.repurchased_12m, NULLIF(a.mature_customers_12m, 0)) AS repurchase_12m_rate,
    SAFE_DIVIDE(a.repurchased_ever, a.customers)                      AS lifetime_repurchase_rate,
    b.median_days_to_second_order, b.return_rate_repeat, b.return_rate_one_time
  FROM a
  LEFT JOIN h ON h.lvl = a.lvl AND h.category IS NOT DISTINCT FROM a.category
             AND h.sub_category IS NOT DISTINCT FROM a.sub_category AND h.product IS NOT DISTINCT FROM a.product
  LEFT JOIN b ON b.lvl = a.lvl AND b.category IS NOT DISTINCT FROM a.category
             AND b.sub_category IS NOT DISTINCT FROM a.sub_category AND b.product IS NOT DISTINCT FROM a.product
);
