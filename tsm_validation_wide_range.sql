-- =============================================================================
-- TSM Wide-Range Validation — 18 metrics side by side
-- Run in Willy SQL Studio (ClickHouse)
-- Adjust dates below as needed; July 1 – Aug 22 gives ~7.5 weeks of data
-- =============================================================================
-- STEP 1: Run this in Willy → exports all 18 SQL-computed values per date
-- STEP 2: Run the BigQuery query at the bottom → gets ground-truth sheet values
-- STEP 3: Join / compare to compute average delta per metric
-- =============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- WILLY QUERY (paste into Willy SQL Studio)
-- Returns one row per date, 18 metric columns
-- ─────────────────────────────────────────────────────────────────────────────
WITH all_data AS (

    -- Meta: Clicks & Views + Last Click (7_days), Triple Attribution (lifetime)
    SELECT
        event_date,
        'meta'            AS source,
        ''                AS segment,
        model,
        attribution_window,
        SUM(spend)              AS spend,
        SUM(new_customer_orders) AS ncp
    FROM pixel_joined_tvf()
    WHERE channel = 'facebook-ads'
      AND (
            (model IN ('Clicks & Views', 'Last Click') AND attribution_window = '7_days')
         OR (model = 'Triple Attribution' AND attribution_window = 'lifetime')
      )
      AND event_date BETWEEN '2024-07-01' AND '2024-08-22'
    GROUP BY event_date, model, attribution_window

    UNION ALL

    -- Google all campaigns: First Click (lifetime), Last Click (7_days), TA (lifetime)
    SELECT
        event_date,
        'google'          AS source,
        ''                AS segment,
        model,
        attribution_window,
        SUM(spend)              AS spend,
        SUM(new_customer_orders) AS ncp
    FROM pixel_joined_tvf()
    WHERE channel = 'google-ads'
      AND (
            (model = 'First Click'       AND attribution_window = 'lifetime')
         OR (model = 'Last Click'        AND attribution_window = '7_days')
         OR (model = 'Triple Attribution' AND attribution_window = 'lifetime')
      )
      AND event_date BETWEEN '2024-07-01' AND '2024-08-22'
    GROUP BY event_date, model, attribution_window

    UNION ALL

    -- Google campaign segments (Brand / DG / Prospecting)
    SELECT
        event_date,
        'segment'         AS source,
        CASE
            WHEN campaign_name LIKE '%Brand%'       THEN 'Brand'
            WHEN campaign_name LIKE '%Demand Gen%'  THEN 'DG'
            WHEN campaign_name LIKE '%Prospecting%' THEN 'Prospecting'
        END               AS segment,
        model,
        attribution_window,
        SUM(spend)              AS spend,
        SUM(new_customer_orders) AS ncp
    FROM pixel_joined_tvf()
    WHERE channel = 'google-ads'
      AND (
            campaign_name LIKE '%Brand%'
         OR campaign_name LIKE '%Demand Gen%'
         OR campaign_name LIKE '%Prospecting%'
      )
      AND (
            (model = 'First Click'       AND attribution_window = 'lifetime')
         OR (model = 'Last Click'        AND attribution_window = '7_days')
         OR (model = 'Triple Attribution' AND attribution_window = 'lifetime')
      )
      AND event_date BETWEEN '2024-07-01' AND '2024-08-22'
    GROUP BY event_date, segment, model, attribution_window
)

SELECT
    event_date,

    -- ── Meta CAC ──────────────────────────────────────────────────────────────
    SUM(CASE WHEN source='meta' AND model='Clicks & Views'    AND attribution_window='7_days'  THEN spend END) /
    NULLIF(SUM(CASE WHEN source='meta' AND model='Clicks & Views'    AND attribution_window='7_days'  THEN ncp END), 0)
        AS meta_cac_first_touch_7d,

    SUM(CASE WHEN source='meta' AND model='Last Click'         AND attribution_window='7_days'  THEN spend END) /
    NULLIF(SUM(CASE WHEN source='meta' AND model='Last Click'         AND attribution_window='7_days'  THEN ncp END), 0)
        AS meta_cac_last_touch_7d,

    SUM(CASE WHEN source='meta' AND model='Triple Attribution' AND attribution_window='lifetime' THEN spend END) /
    NULLIF(SUM(CASE WHEN source='meta' AND model='Triple Attribution' AND attribution_window='lifetime' THEN ncp END), 0)
        AS meta_cac_triple_att_7d,

    -- ── Meta NCP ──────────────────────────────────────────────────────────────
    SUM(CASE WHEN source='meta' AND model='Clicks & Views'    AND attribution_window='7_days'  THEN ncp END)
        AS meta_ncp_first_click,

    SUM(CASE WHEN source='meta' AND model='Last Click'         AND attribution_window='7_days'  THEN ncp END)
        AS meta_ncp_last_click,

    SUM(CASE WHEN source='meta' AND model='Triple Attribution' AND attribution_window='lifetime' THEN ncp END)
        AS meta_ncp_triple_att,

    -- ── Google All-Campaign CAC ───────────────────────────────────────────────
    SUM(CASE WHEN source='google' AND model='First Click'       AND attribution_window='lifetime' THEN spend END) /
    NULLIF(SUM(CASE WHEN source='google' AND model='First Click'       AND attribution_window='lifetime' THEN ncp END), 0)
        AS google_cac_first_touch_7d,

    SUM(CASE WHEN source='google' AND model='Last Click'        AND attribution_window='7_days'  THEN spend END) /
    NULLIF(SUM(CASE WHEN source='google' AND model='Last Click'        AND attribution_window='7_days'  THEN ncp END), 0)
        AS google_cac_last_touch_7d,

    SUM(CASE WHEN source='google' AND model='Triple Attribution' AND attribution_window='lifetime' THEN spend END) /
    NULLIF(SUM(CASE WHEN source='google' AND model='Triple Attribution' AND attribution_window='lifetime' THEN ncp END), 0)
        AS google_cac_triple_att_7d,

    -- ── Brand CAC ─────────────────────────────────────────────────────────────
    SUM(CASE WHEN source='segment' AND segment='Brand' AND model='First Click'       AND attribution_window='lifetime' THEN spend END) /
    NULLIF(SUM(CASE WHEN source='segment' AND segment='Brand' AND model='First Click'       AND attribution_window='lifetime' THEN ncp END), 0)
        AS brand_first_touch_7d,

    SUM(CASE WHEN source='segment' AND segment='Brand' AND model='Last Click'        AND attribution_window='7_days'  THEN spend END) /
    NULLIF(SUM(CASE WHEN source='segment' AND segment='Brand' AND model='Last Click'        AND attribution_window='7_days'  THEN ncp END), 0)
        AS brand_last_touch_7d,

    SUM(CASE WHEN source='segment' AND segment='Brand' AND model='Triple Attribution' AND attribution_window='lifetime' THEN spend END) /
    NULLIF(SUM(CASE WHEN source='segment' AND segment='Brand' AND model='Triple Attribution' AND attribution_window='lifetime' THEN ncp END), 0)
        AS brand_triple_att_7d,

    -- ── DG CAC ────────────────────────────────────────────────────────────────
    SUM(CASE WHEN source='segment' AND segment='DG' AND model='First Click'       AND attribution_window='lifetime' THEN spend END) /
    NULLIF(SUM(CASE WHEN source='segment' AND segment='DG' AND model='First Click'       AND attribution_window='lifetime' THEN ncp END), 0)
        AS dg_first_touch_7d,

    SUM(CASE WHEN source='segment' AND segment='DG' AND model='Last Click'        AND attribution_window='7_days'  THEN spend END) /
    NULLIF(SUM(CASE WHEN source='segment' AND segment='DG' AND model='Last Click'        AND attribution_window='7_days'  THEN ncp END), 0)
        AS dg_last_touch_7d,

    SUM(CASE WHEN source='segment' AND segment='DG' AND model='Triple Attribution' AND attribution_window='lifetime' THEN spend END) /
    NULLIF(SUM(CASE WHEN source='segment' AND segment='DG' AND model='Triple Attribution' AND attribution_window='lifetime' THEN ncp END), 0)
        AS dg_triple_att_7d,

    -- ── Prospecting CAC ───────────────────────────────────────────────────────
    SUM(CASE WHEN source='segment' AND segment='Prospecting' AND model='First Click'       AND attribution_window='lifetime' THEN spend END) /
    NULLIF(SUM(CASE WHEN source='segment' AND segment='Prospecting' AND model='First Click'       AND attribution_window='lifetime' THEN ncp END), 0)
        AS prospecting_first_touch_7d,

    SUM(CASE WHEN source='segment' AND segment='Prospecting' AND model='Last Click'        AND attribution_window='7_days'  THEN spend END) /
    NULLIF(SUM(CASE WHEN source='segment' AND segment='Prospecting' AND model='Last Click'        AND attribution_window='7_days'  THEN ncp END), 0)
        AS prospecting_last_touch_7d,

    SUM(CASE WHEN source='segment' AND segment='Prospecting' AND model='Triple Attribution' AND attribution_window='lifetime' THEN spend END) /
    NULLIF(SUM(CASE WHEN source='segment' AND segment='Prospecting' AND model='Triple Attribution' AND attribution_window='lifetime' THEN ncp END), 0)
        AS prospecting_triple_att_7d

FROM all_data
GROUP BY event_date
ORDER BY event_date;


-- =============================================================================
-- BIGQUERY BASELINE QUERY
-- Run in BQ to pull ground-truth sheet values for the same date range
-- Adjust date column name if different from 'date'
-- =============================================================================
SELECT
    date                              AS event_date,

    -- Meta CAC
    triple_whale_meta_cac_first_touch_7d,
    triple_whale_meta_cac_last_touch_7d,
    triple_whale_meta_cac_triple_att_7d,

    -- Meta NCP
    triple_whale_meta_ncp_firt_click  AS meta_ncp_first_click,
    triple_whale_meta_ncp_lat_click   AS meta_ncp_last_click,
    triple_whale_meta_ncp_triple_att_7d,

    -- Google CAC
    triple_whale_google_cac_first_touch_7d,
    triple_whale_google_cac_last_touch_7d,
    triple_whale_google_cac_triple_att_7d,

    -- Brand
    brand_first_touch_7d,
    brand_last_touch_7d,
    brand_triple_att_7d,

    -- DG
    dg_first_touch_7d,
    dg_last_touch_7d,
    dg_triple_att_7d,

    -- Prospecting
    prospecting_first_touch_7d,
    prospecting_last_touch_7d,
    prospecting_triple_att_7d

FROM `daton-project.trueseamoss_5363_prod_presentation_datashare.TripleWhaleData_gs`
WHERE date BETWEEN '2024-07-01' AND '2024-08-22'
ORDER BY date;


-- =============================================================================
-- DELTA COMPUTATION QUERY (BigQuery)
-- Run AFTER loading Willy results into BQ as a temp table named `willy_results`
-- Replace `willy_results` with your actual table name
-- =============================================================================
WITH deltas AS (
    SELECT
        gs.event_date,

        -- ── Meta CAC deltas ──────────────────────────────────────────────────
        ABS(w.meta_cac_first_touch_7d - gs.triple_whale_meta_cac_first_touch_7d)
            / NULLIF(gs.triple_whale_meta_cac_first_touch_7d, 0) * 100  AS meta_cv_cac_pct_delta,

        ABS(w.meta_cac_last_touch_7d  - gs.triple_whale_meta_cac_last_touch_7d)
            / NULLIF(gs.triple_whale_meta_cac_last_touch_7d, 0)  * 100  AS meta_lc_cac_pct_delta,

        ABS(w.meta_cac_triple_att_7d  - gs.triple_whale_meta_cac_triple_att_7d)
            / NULLIF(gs.triple_whale_meta_cac_triple_att_7d, 0)  * 100  AS meta_ta_cac_pct_delta,

        -- ── Meta NCP deltas ──────────────────────────────────────────────────
        ABS(w.meta_ncp_first_click - gs.triple_whale_meta_ncp_firt_click)
            / NULLIF(gs.triple_whale_meta_ncp_firt_click, 0) * 100      AS meta_cv_ncp_pct_delta,

        ABS(w.meta_ncp_last_click  - gs.triple_whale_meta_ncp_lat_click)
            / NULLIF(gs.triple_whale_meta_ncp_lat_click, 0)  * 100      AS meta_lc_ncp_pct_delta,

        ABS(w.meta_ncp_triple_att  - gs.triple_whale_meta_ncp_triple_att_7d)
            / NULLIF(gs.triple_whale_meta_ncp_triple_att_7d, 0) * 100   AS meta_ta_ncp_pct_delta,

        -- ── Google CAC deltas ────────────────────────────────────────────────
        ABS(w.google_cac_first_touch_7d - gs.triple_whale_google_cac_first_touch_7d)
            / NULLIF(gs.triple_whale_google_cac_first_touch_7d, 0) * 100 AS google_fc_cac_pct_delta,

        ABS(w.google_cac_last_touch_7d  - gs.triple_whale_google_cac_last_touch_7d)
            / NULLIF(gs.triple_whale_google_cac_last_touch_7d, 0)  * 100 AS google_lc_cac_pct_delta,

        ABS(w.google_cac_triple_att_7d  - gs.triple_whale_google_cac_triple_att_7d)
            / NULLIF(gs.triple_whale_google_cac_triple_att_7d, 0)  * 100 AS google_ta_cac_pct_delta,

        -- ── Brand deltas ─────────────────────────────────────────────────────
        ABS(w.brand_first_touch_7d - gs.brand_first_touch_7d) / NULLIF(gs.brand_first_touch_7d, 0) * 100 AS brand_fc_pct_delta,
        ABS(w.brand_last_touch_7d  - gs.brand_last_touch_7d)  / NULLIF(gs.brand_last_touch_7d, 0)  * 100 AS brand_lc_pct_delta,
        ABS(w.brand_triple_att_7d  - gs.brand_triple_att_7d)  / NULLIF(gs.brand_triple_att_7d, 0)  * 100 AS brand_ta_pct_delta,

        -- ── DG deltas ────────────────────────────────────────────────────────
        ABS(w.dg_first_touch_7d - gs.dg_first_touch_7d) / NULLIF(gs.dg_first_touch_7d, 0) * 100 AS dg_fc_pct_delta,
        ABS(w.dg_last_touch_7d  - gs.dg_last_touch_7d)  / NULLIF(gs.dg_last_touch_7d, 0)  * 100 AS dg_lc_pct_delta,
        ABS(w.dg_triple_att_7d  - gs.dg_triple_att_7d)  / NULLIF(gs.dg_triple_att_7d, 0)  * 100 AS dg_ta_pct_delta,

        -- ── Prospecting deltas ───────────────────────────────────────────────
        ABS(w.prospecting_first_touch_7d - gs.prospecting_first_touch_7d) / NULLIF(gs.prospecting_first_touch_7d, 0) * 100 AS prosp_fc_pct_delta,
        ABS(w.prospecting_last_touch_7d  - gs.prospecting_last_touch_7d)  / NULLIF(gs.prospecting_last_touch_7d, 0)  * 100 AS prosp_lc_pct_delta,
        ABS(w.prospecting_triple_att_7d  - gs.prospecting_triple_att_7d)  / NULLIF(gs.prospecting_triple_att_7d, 0)  * 100 AS prosp_ta_pct_delta

    FROM `willy_results` w
    JOIN `daton-project.trueseamoss_5363_prod_presentation_datashare.TripleWhaleData_gs` gs
      ON w.event_date = gs.date
    WHERE gs.date BETWEEN '2024-07-01' AND '2024-08-22'
)

SELECT
    -- Average % delta per metric across all dates
    ROUND(AVG(meta_cv_cac_pct_delta),  2) AS avg_meta_cv_cac_delta_pct,
    ROUND(AVG(meta_lc_cac_pct_delta),  2) AS avg_meta_lc_cac_delta_pct,
    ROUND(AVG(meta_ta_cac_pct_delta),  2) AS avg_meta_ta_cac_delta_pct,
    ROUND(AVG(meta_cv_ncp_pct_delta),  2) AS avg_meta_cv_ncp_delta_pct,
    ROUND(AVG(meta_lc_ncp_pct_delta),  2) AS avg_meta_lc_ncp_delta_pct,
    ROUND(AVG(meta_ta_ncp_pct_delta),  2) AS avg_meta_ta_ncp_delta_pct,
    ROUND(AVG(google_fc_cac_pct_delta),2) AS avg_google_fc_cac_delta_pct,
    ROUND(AVG(google_lc_cac_pct_delta),2) AS avg_google_lc_cac_delta_pct,
    ROUND(AVG(google_ta_cac_pct_delta),2) AS avg_google_ta_cac_delta_pct,
    ROUND(AVG(brand_fc_pct_delta),     2) AS avg_brand_fc_delta_pct,
    ROUND(AVG(brand_lc_pct_delta),     2) AS avg_brand_lc_delta_pct,
    ROUND(AVG(brand_ta_pct_delta),     2) AS avg_brand_ta_delta_pct,
    ROUND(AVG(dg_fc_pct_delta),        2) AS avg_dg_fc_delta_pct,
    ROUND(AVG(dg_lc_pct_delta),        2) AS avg_dg_lc_delta_pct,
    ROUND(AVG(dg_ta_pct_delta),        2) AS avg_dg_ta_delta_pct,
    ROUND(AVG(prosp_fc_pct_delta),     2) AS avg_prosp_fc_delta_pct,
    ROUND(AVG(prosp_lc_pct_delta),     2) AS avg_prosp_lc_delta_pct,
    ROUND(AVG(prosp_ta_pct_delta),     2) AS avg_prosp_ta_delta_pct,

    -- Max % delta per metric (worst-case day)
    ROUND(MAX(meta_cv_cac_pct_delta),  2) AS max_meta_cv_cac_delta_pct,
    ROUND(MAX(meta_lc_cac_pct_delta),  2) AS max_meta_lc_cac_delta_pct,
    ROUND(MAX(meta_ta_cac_pct_delta),  2) AS max_meta_ta_cac_delta_pct,
    ROUND(MAX(meta_cv_ncp_pct_delta),  2) AS max_meta_cv_ncp_delta_pct,
    ROUND(MAX(meta_lc_ncp_pct_delta),  2) AS max_meta_lc_ncp_delta_pct,
    ROUND(MAX(meta_ta_ncp_pct_delta),  2) AS max_meta_ta_ncp_delta_pct,
    ROUND(MAX(google_fc_cac_pct_delta),2) AS max_google_fc_cac_delta_pct,
    ROUND(MAX(google_lc_cac_pct_delta),2) AS max_google_lc_cac_delta_pct,
    ROUND(MAX(google_ta_cac_pct_delta),2) AS max_google_ta_cac_delta_pct,
    ROUND(MAX(brand_fc_pct_delta),     2) AS max_brand_fc_delta_pct,
    ROUND(MAX(brand_lc_pct_delta),     2) AS max_brand_lc_delta_pct,
    ROUND(MAX(brand_ta_pct_delta),     2) AS max_brand_ta_delta_pct,
    ROUND(MAX(dg_fc_pct_delta),        2) AS max_dg_fc_delta_pct,
    ROUND(MAX(dg_lc_pct_delta),        2) AS max_dg_lc_delta_pct,
    ROUND(MAX(dg_ta_pct_delta),        2) AS max_dg_ta_delta_pct,
    ROUND(MAX(prosp_fc_pct_delta),     2) AS max_prosp_fc_delta_pct,
    ROUND(MAX(prosp_lc_pct_delta),     2) AS max_prosp_lc_delta_pct,
    ROUND(MAX(prosp_ta_pct_delta),     2) AS max_prosp_ta_delta_pct

FROM deltas;
