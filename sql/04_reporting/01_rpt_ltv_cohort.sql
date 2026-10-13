-- rpt_ltv_cohort: the four LTV Cohorts tables + curve, with the page filters as columns.
-- Filter columns use 'All' for "no filter" (Channel: All|Shopify|Amazon; Acquisition type: All|OTP|Sub).
-- App usage: WHERE channel_filter=@ch AND acq_type_filter=@ty AND cohort_month >= @window_start
-- Cells that haven't happened yet are absent (render as "—").
--   ltr = Lifetime Revenue ; ltv = LTR - COGS ; *_pct_of_m0 = "% of M0" toggle ; ltv_cac = ltv_per_customer / cac
-- CAC: spend of the in-scope channels / customers of those channels WITH spend data (deliberate fix: the mock divides
-- by all customers, which understates 'Both' CAC for Amazon-less months). Same CAC for every acq_type.
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.rpt_ltv_cohort` AS
WITH f AS (
  SELECT ch AS channel_filter, ty AS acq_type_filter
  FROM UNNEST(['All', 'Shopify', 'Amazon']) ch CROSS JOIN UNNEST(['All', 'OTP', 'Sub']) ty
),
agg AS (
  SELECT f.channel_filter, f.acq_type_filter, s.cohort_month, s.month_since,
         SUM(s.customers_acquired) AS customers_acquired,
         SUM(s.net_sales_cum)      AS ltr,
         SUM(s.net_sales_cum - s.cogs_cum) AS ltv
  FROM `${PROJECT}.${DATASET}.mart_cohort_segment_month` s
  JOIN f ON (f.channel_filter = 'All' OR f.channel_filter = s.sales_channel)
        AND (f.acq_type_filter = 'All' OR f.acq_type_filter = s.acq_type)
  GROUP BY 1, 2, 3, 4
),
cac AS (
  SELECT ch AS channel_filter, a.cohort_month,
         SAFE_DIVIDE(SUM(a.ad_spend), SUM(IF(a.ad_spend IS NOT NULL, a.customers_acquired, 0))) AS cac
  FROM `${PROJECT}.${DATASET}.mart_ad_spend_cohort` a
  CROSS JOIN UNNEST(['All', 'Shopify', 'Amazon']) ch
  WHERE ch = 'All' OR ch = a.sales_channel
  GROUP BY 1, 2
)
SELECT
  a.channel_filter, a.acq_type_filter, a.cohort_month, a.month_since, a.customers_acquired,
  a.ltr,
  SAFE_DIVIDE(a.ltr, a.customers_acquired)                        AS ltr_per_customer,
  a.ltv,
  SAFE_DIVIDE(a.ltv, a.customers_acquired)                        AS ltv_per_customer,
  SAFE_DIVIDE(a.ltr, FIRST_VALUE(a.ltr) OVER w)                   AS ltr_pct_of_m0,
  SAFE_DIVIDE(a.ltr, FIRST_VALUE(a.ltr) OVER w)                   AS ltr_per_customer_pct_of_m0,  -- same ratio (n constant)
  SAFE_DIVIDE(a.ltv, FIRST_VALUE(a.ltv) OVER w)                   AS ltv_per_customer_pct_of_m0,
  c.cac,
  SAFE_DIVIDE(SAFE_DIVIDE(a.ltv, a.customers_acquired), c.cac)    AS ltv_cac
FROM agg a
LEFT JOIN cac c ON c.channel_filter = a.channel_filter AND c.cohort_month = a.cohort_month
WINDOW w AS (PARTITION BY a.channel_filter, a.acq_type_filter, a.cohort_month ORDER BY a.month_since);
