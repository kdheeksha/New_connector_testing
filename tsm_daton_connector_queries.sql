-- =============================================================================
-- TrueSeaMoss (TSM) — Daton Connector Queries
-- Triple Whale Custom SQL Connector
-- Parameters: @startDate, @endDate  (format: YYYY-MM-DD)
-- Max 5 queries; each becomes one BigQuery table
-- =============================================================================
-- Validated attribution model / window map:
--   facebook-ads | Clicks & Views   | 7_days   (first-touch 7d)
--   facebook-ads | Last Click       | 7_days   (last-touch 7d)
--   facebook-ads | Triple Attribution | lifetime (TA standard)
--   google-ads   | First Click      | lifetime  (first-touch — lifetime window matches TW tile)
--   google-ads   | Last Click       | 7_days    (last-touch 7d)
--   google-ads   | Triple Attribution | lifetime (TA standard)
-- 28-day rows included for all models/channels via attribution_window='28_days'
-- =============================================================================


-- -----------------------------------------------------------------------------
-- QUERY 1 of 4: Meta (Facebook Ads) — pixel_joined_tvf
-- Covers: meta_cac_triple_att_7d, meta_ncp_triple_att_7d (plus 28-day equivalent)
-- Target BQ table: e.g. tsm_meta_pixel
--
-- NOTE: This account only has Triple Attribution enabled for facebook-ads in
-- Triple Whale. Clicks & Views and Last Click models do not exist in
-- pixel_joined_tvf() for this account (confirmed via DISTINCT query Jan–Aug 2026).
-- meta_cac_first_touch_7d, meta_cac_last_touch_7d, meta_ncp_firt_click, and
-- meta_ncp_lat_click must remain manually entered in the Google Sheet.
-- -----------------------------------------------------------------------------
SELECT
    event_date,
    model,
    attribution_window,
    SUM(spend)                                        AS total_spend,
    SUM(new_customer_orders)                          AS total_ncp,
    SUM(spend) / NULLIF(SUM(new_customer_orders), 0)  AS nccpa
FROM pixel_joined_tvf()
WHERE channel = 'facebook-ads'
  AND model = 'Triple Attribution'
  AND attribution_window IN ('lifetime', '28_days')
  AND event_date BETWEEN @startDate AND @endDate
GROUP BY event_date, model, attribution_window
ORDER BY event_date, model, attribution_window;


-- -----------------------------------------------------------------------------
-- QUERY 2 of 4: Google Ads (all campaigns) — pixel_joined_tvf
-- Covers: google_cac_first_touch_7d, google_cac_last_touch_7d,
--         google_cac_triple_att_7d  (plus 28-day equivalents)
-- Target BQ table: e.g. tsm_google_pixel
-- Note: First Click uses 'lifetime' window — confirmed match to TW dashboard
-- -----------------------------------------------------------------------------
SELECT
    event_date,
    model,
    attribution_window,
    SUM(spend)                                        AS total_spend,
    SUM(new_customer_orders)                          AS total_ncp,
    SUM(spend) / NULLIF(SUM(new_customer_orders), 0)  AS nccpa
FROM pixel_joined_tvf()
WHERE channel = 'google-ads'
  AND (
        (model IN ('First Click', 'Last Click')
         AND attribution_window IN ('lifetime', '7_days', '28_days'))
     OR (model = 'Triple Attribution'
         AND attribution_window IN ('lifetime', '28_days'))
  )
  AND event_date BETWEEN @startDate AND @endDate
GROUP BY event_date, model, attribution_window
ORDER BY event_date, model, attribution_window;


-- -----------------------------------------------------------------------------
-- QUERY 3 of 4: Google Campaign Segments — pixel_joined_tvf
-- Covers: brand / dg / prospecting × first_touch / last_touch / triple_att
--         (9 sheet metrics + 28-day equivalents)
-- Target BQ table: e.g. tsm_google_segments_pixel
-- Campaign filters validated for Aug 2024 (100% coverage on Aug 1 test):
--   Brand:       campaign_name LIKE '%Brand%'
--   Demand Gen:  campaign_name LIKE '%Demand Gen%'
--   Prospecting: campaign_name LIKE '%Prospecting%'
-- -----------------------------------------------------------------------------
SELECT
    event_date,
    CASE
        WHEN campaign_name LIKE '%Brand%'      THEN 'Brand'
        WHEN campaign_name LIKE '%Demand Gen%' THEN 'DG'
        WHEN campaign_name LIKE '%Prospecting%' THEN 'Prospecting'
    END                                               AS segment,
    model,
    attribution_window,
    SUM(spend)                                        AS total_spend,
    SUM(new_customer_orders)                          AS total_ncp,
    SUM(spend) / NULLIF(SUM(new_customer_orders), 0)  AS nccpa
FROM pixel_joined_tvf()
WHERE channel = 'google-ads'
  AND (
        campaign_name LIKE '%Brand%'
     OR campaign_name LIKE '%Demand Gen%'
     OR campaign_name LIKE '%Prospecting%'
  )
  AND (
        (model IN ('First Click', 'Last Click')
         AND attribution_window IN ('lifetime', '7_days', '28_days'))
     OR (model = 'Triple Attribution'
         AND attribution_window IN ('lifetime', '28_days'))
  )
  AND event_date BETWEEN @startDate AND @endDate
GROUP BY event_date, segment, model, attribution_window
ORDER BY event_date, segment, model, attribution_window;


-- -----------------------------------------------------------------------------
-- QUERY 4 of 4: Meta Platform-Reported Purchases & CPA — ads_table
-- Covers: meta_inapp_purchases, meta_in_app_cpa
-- Target BQ table: e.g. tsm_meta_inapp
--
-- ✅ STATUS: VALIDATED
-- Source: ads_table.conversions — Meta's normalized platform-reported purchase
--         count received from the Meta integration. NOT onsite_purchases,
--         NOT the actions array. Verified Aug 1 2026:
--           spend = $207,561.88 | conversions = 2,530 | CPA = $82.04
-- -----------------------------------------------------------------------------
SELECT
    event_date,
    SUM(spend)                                        AS meta_total_spend,
    SUM(conversions)                                  AS meta_inapp_purchases,
    SUM(spend) / NULLIF(SUM(conversions), 0)          AS meta_in_app_cpa
FROM ads_table
WHERE channel = 'facebook-ads'
  AND event_date BETWEEN @startDate AND @endDate
GROUP BY event_date
ORDER BY event_date;
