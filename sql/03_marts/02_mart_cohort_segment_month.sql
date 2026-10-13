-- mart_cohort_segment_month: THE core fact for the LTV Cohorts and Retention tabs.
-- Grain: cohort_month x sales_channel x acq_type x purchasing_pattern x month_since  (= D.seg[...] in the mock).
-- Only (cohort, month) cells that have actually happened are emitted, so "n/a" cells are simply absent.
-- Monthly columns are additive across segments; *_cum columns are running totals within a segment-cohort.
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.mart_cohort_segment_month` AS
WITH p AS (SELECT last_complete_month FROM `${PROJECT}.${DATASET}.int_params`),
cust AS (
  SELECT customer_key, cohort_month, sales_channel, acq_type, purchasing_pattern, last_order_month_since
  FROM `${PROJECT}.${DATASET}.int_customer_profile`
),
seg AS (
  SELECT cohort_month, sales_channel, acq_type, purchasing_pattern, COUNT(*) AS customers_acquired
  FROM cust GROUP BY 1, 2, 3, 4
),
grid AS (
  SELECT s.*, ms AS month_since
  FROM seg s CROSS JOIN p
  CROSS JOIN UNNEST(GENERATE_ARRAY(0, DATE_DIFF(p.last_complete_month, s.cohort_month, MONTH))) AS ms
),
activity AS (
  SELECT c.cohort_month, c.sales_channel, c.acq_type, c.purchasing_pattern, m.month_since,
         COUNTIF(m.orders > 0) AS customers_active,
         SUM(m.orders) AS orders, SUM(m.net_sales) AS net_sales, SUM(m.cogs) AS cogs
  FROM `${PROJECT}.${DATASET}.int_customer_month` m
  JOIN cust c ON c.customer_key = m.customer_key
  GROUP BY 1, 2, 3, 4, 5
),
last_hist AS (
  SELECT cohort_month, sales_channel, acq_type, purchasing_pattern,
         last_order_month_since AS ms, COUNT(*) AS cnt
  FROM cust GROUP BY 1, 2, 3, 4, 5
),
retained AS (   -- customers whose LAST order is in month >= h  => "ordered at or after month h"
  SELECT g.cohort_month, g.sales_channel, g.acq_type, g.purchasing_pattern, g.month_since,
         SUM(h.cnt) AS customers_retained
  FROM grid g
  JOIN last_hist h
    ON h.cohort_month = g.cohort_month AND h.sales_channel = g.sales_channel
   AND h.acq_type = g.acq_type AND h.purchasing_pattern = g.purchasing_pattern
   AND h.ms >= g.month_since
  GROUP BY 1, 2, 3, 4, 5
)
SELECT
  g.cohort_month, g.sales_channel, g.acq_type, g.purchasing_pattern, g.month_since,
  g.customers_acquired,
  IFNULL(a.customers_active, 0)    AS customers_active,
  IFNULL(r.customers_retained, 0)  AS customers_retained,
  IFNULL(a.orders, 0)              AS orders,
  IFNULL(a.net_sales, 0)           AS net_sales,
  IFNULL(a.cogs, 0)                AS cogs,
  SUM(IFNULL(a.net_sales, 0)) OVER w AS net_sales_cum,
  SUM(IFNULL(a.cogs, 0))      OVER w AS cogs_cum
FROM grid g
LEFT JOIN activity a USING (cohort_month, sales_channel, acq_type, purchasing_pattern, month_since)
LEFT JOIN retained r USING (cohort_month, sales_channel, acq_type, purchasing_pattern, month_since)
WINDOW w AS (PARTITION BY g.cohort_month, g.sales_channel, g.acq_type, g.purchasing_pattern
             ORDER BY g.month_since);
