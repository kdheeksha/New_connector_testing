-- mart_product_cohort_month: cumulative net sales / COGS by entry product, type, cohort and month since acquisition
-- (= D.prod[i][type].salesCum / cogsCum). LTR/customer = net_sales_cum / customers_acquired; LTV adds - cogs_cum.
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.mart_product_cohort_month` AS
WITH p AS (SELECT last_complete_month FROM `${PROJECT}.${DATASET}.int_params`),
base AS (
  SELECT category, sub_category, product, acq_type, cohort_month, customers_acquired
  FROM `${PROJECT}.${DATASET}.mart_product_cohort`
),
grid AS (
  SELECT b.*, ms AS month_since FROM base b CROSS JOIN p
  CROSS JOIN UNNEST(GENERATE_ARRAY(0, DATE_DIFF(p.last_complete_month, b.cohort_month, MONTH))) AS ms
),
m AS (
  SELECT cp.entry_category AS category, cp.entry_sub_category AS sub_category, cp.entry_product AS product,
         cp.acq_type, cp.cohort_month, cm.month_since,
         SUM(cm.net_sales) AS net_sales, SUM(cm.cogs) AS cogs
  FROM `${PROJECT}.${DATASET}.int_customer_month` cm
  JOIN `${PROJECT}.${DATASET}.int_customer_profile` cp USING (customer_key)
  WHERE cp.entry_product IS NOT NULL
  GROUP BY 1, 2, 3, 4, 5, 6
)
SELECT g.category, g.sub_category, g.product, g.acq_type, g.cohort_month, g.month_since, g.customers_acquired,
       SUM(IFNULL(m.net_sales, 0)) OVER w AS net_sales_cum,
       SUM(IFNULL(m.cogs, 0))      OVER w AS cogs_cum
FROM grid g
LEFT JOIN m USING (category, sub_category, product, acq_type, cohort_month, month_since)
WINDOW w AS (PARTITION BY g.category, g.sub_category, g.product, g.acq_type, g.cohort_month ORDER BY g.month_since);
