-- rpt_retention_cohort: Repurchase Rate, Retention Rate and Revenue Retention tables (+ retention curve).
-- Filters: channel_filter All|Shopify|Amazon ; acq_type_filter All|OTP|Sub ; pattern_filter All|Repeat|One-time.
--   repurchase_rate   = customers_active / customers_acquired        (ordered IN that month)
--   retention_rate    = customers_retained / customers_acquired       (ordered AT OR AFTER that month; only falls)
--   revenue_retention = net_sales(month h) / net_sales(month 0)       (> 100% = spending more than at acquisition)
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.rpt_retention_cohort` AS
WITH f AS (
  SELECT ch AS channel_filter, ty AS acq_type_filter, pt AS pattern_filter
  FROM UNNEST(['All', 'Shopify', 'Amazon']) ch
  CROSS JOIN UNNEST(['All', 'OTP', 'Sub']) ty
  CROSS JOIN UNNEST(['All', 'Repeat', 'One-time']) pt
),
agg AS (
  SELECT f.channel_filter, f.acq_type_filter, f.pattern_filter, s.cohort_month, s.month_since,
         SUM(s.customers_acquired) AS customers_acquired,
         SUM(s.customers_active)   AS customers_active,
         SUM(s.customers_retained) AS customers_retained,
         SUM(s.net_sales)          AS net_sales
  FROM `${PROJECT}.${DATASET}.mart_cohort_segment_month` s
  JOIN f ON (f.channel_filter = 'All' OR f.channel_filter = s.sales_channel)
        AND (f.acq_type_filter = 'All' OR f.acq_type_filter = s.acq_type)
        AND (f.pattern_filter = 'All' OR f.pattern_filter = s.purchasing_pattern)
  GROUP BY 1, 2, 3, 4, 5
)
SELECT
  a.*,
  SAFE_DIVIDE(customers_active, customers_acquired)   AS repurchase_rate,
  SAFE_DIVIDE(customers_retained, customers_acquired) AS retention_rate,
  SAFE_DIVIDE(net_sales, FIRST_VALUE(net_sales) OVER (
    PARTITION BY channel_filter, acq_type_filter, pattern_filter, cohort_month ORDER BY month_since)) AS revenue_retention
FROM agg a;
