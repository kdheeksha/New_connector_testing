-- fn_marketing_channel_summary(window_months): the "LTV and CAC by channel" table, long over horizon.
-- Call: SELECT * FROM `${PROJECT}.${DATASET}.fn_marketing_channel_summary`(12) WHERE attribution_view = 'lpc';
-- Pivot horizon_months (3,6,9,12 | +18,24 when window=24) into columns in the app. Highlight horizon is a UI concern.
--   customers/ad_spend/cac cover ALL cohorts in the window; ltv_per_customer uses only cohorts mature for that horizon.
CREATE OR REPLACE TABLE FUNCTION `${PROJECT}.${DATASET}.fn_marketing_channel_summary`(window_months INT64) AS (
  WITH p AS (SELECT last_complete_month AS lcm FROM `${PROJECT}.${DATASET}.int_params`),
  win AS (
    SELECT c.* FROM `${PROJECT}.${DATASET}.mart_marketing_cohort` c, p
    WHERE c.cohort_month > DATE_SUB(p.lcm, INTERVAL window_months MONTH)
  ),
  tot AS (
    SELECT attribution_view, marketing_channel, ANY_VALUE(is_paid) AS is_paid,
           SUM(customers_acquired) AS customers, SUM(ad_spend) AS ad_spend
    FROM win GROUP BY 1, 2
  ),
  hz AS (
    SELECT m.attribution_view, m.marketing_channel, h AS horizon_months,
           SUM(m.net_sales_cum - m.cogs_cum) AS gross_profit, SUM(m.customers_acquired) AS mature_customers
    FROM `${PROJECT}.${DATASET}.mart_marketing_cohort_month` m, p
    CROSS JOIN UNNEST([3, 6, 9, 12, 18, 24]) h
    WHERE m.cohort_month > DATE_SUB(p.lcm, INTERVAL window_months MONTH)
      AND m.month_since = h - 1 AND h <= window_months
    GROUP BY 1, 2, 3
  )
  SELECT
    t.attribution_view, t.marketing_channel, t.is_paid, t.customers,
    SAFE_DIVIDE(t.customers, SUM(t.customers) OVER (PARTITION BY t.attribution_view)) AS customer_share,
    t.ad_spend,
    SAFE_DIVIDE(t.ad_spend, t.customers)                                              AS cac,
    hz.horizon_months,
    SAFE_DIVIDE(hz.gross_profit, hz.mature_customers)                                 AS ltv_per_customer,
    SAFE_DIVIDE(SAFE_DIVIDE(hz.gross_profit, hz.mature_customers),
                SAFE_DIVIDE(t.ad_spend, t.customers))                                 AS ltv_cac
  FROM tot t LEFT JOIN hz USING (attribution_view, marketing_channel)
);
