-- mart_marketing_cohort_month: cumulative net sales / COGS per credited customer group, by month since acquisition.
-- Grain: attribution_view x cohort_month x marketing_channel x month_since  (= D.mkt[...].salesCum / cogsCum)
-- Credit-weighted. LTV/customer at horizon N = SUM(net_sales_cum - cogs_cum) / SUM(customers_acquired)
-- over cohorts that have a row at month_since = N-1 (mature cohorts only).
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.mart_marketing_cohort_month` AS
WITH p AS (SELECT last_complete_month FROM `${PROJECT}.${DATASET}.int_params`),
base AS (
  SELECT a.attribution_view, a.cohort_month, a.marketing_channel, SUM(a.credit) AS customers_acquired
  FROM `${PROJECT}.${DATASET}.int_customer_attribution` a GROUP BY 1, 2, 3
),
grid AS (
  SELECT b.*, ms AS month_since FROM base b CROSS JOIN p
  CROSS JOIN UNNEST(GENERATE_ARRAY(0, DATE_DIFF(p.last_complete_month, b.cohort_month, MONTH))) AS ms
),
m AS (
  SELECT a.attribution_view, a.cohort_month, a.marketing_channel, cm.month_since,
         SUM(a.credit * cm.net_sales) AS net_sales, SUM(a.credit * cm.cogs) AS cogs
  FROM `${PROJECT}.${DATASET}.int_customer_attribution` a
  JOIN `${PROJECT}.${DATASET}.int_customer_month` cm USING (customer_key)
  GROUP BY 1, 2, 3, 4
)
SELECT g.attribution_view, g.cohort_month, g.marketing_channel, g.month_since, g.customers_acquired,
       SUM(IFNULL(m.net_sales, 0)) OVER w AS net_sales_cum,
       SUM(IFNULL(m.cogs, 0))      OVER w AS cogs_cum
FROM grid g
LEFT JOIN m USING (attribution_view, cohort_month, marketing_channel, month_since)
WINDOW w AS (PARTITION BY g.attribution_view, g.cohort_month, g.marketing_channel ORDER BY g.month_since);
