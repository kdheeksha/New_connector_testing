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
-- Covers: meta_cac_first_touch_7d, meta_cac_last_touch_7d,
--         meta_cac_triple_att_7d, meta_ncp_first_click, meta_ncp_last_click,
--         meta_ncp_triple_att_7d  (plus 28-day equivalents)
-- Target BQ table: e.g. tsm_meta_pixel
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
  AND (
        (model IN ('Clicks & Views', 'Last Click')
         AND attribution_window IN ('7_days', '28_days'))
     OR (model = 'Triple Attribution'
         AND attribution_window IN ('lifetime', '28_days'))
  )
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
-- QUERY 4 of 4: Meta In-App Purchases & CPA — ads_table
-- Covers: meta_inapp_purchases, meta_in_app_cpa
-- Target BQ table: e.g. tsm_meta_inapp
--
-- ⚠  STATUS: DRAFT — action_type NOT YET CONFIRMED
--
-- Context:
--   - ads_table.onsite_purchases = 0 for this account (no Meta Shop)
--   - Sheet shows 2,530 purchases on Aug 1 (spend $207,561.88 → CPA ~$82)
--   - Source is ads_table.actions array (a Meta mobile-app or website event)
--   - The exact action_type string must be read from the TW dashboard tile
--
-- To confirm action_type: in Willy SQL Studio run the discovery query below,
-- then replace '<CONFIRM_ACTION_TYPE>' in the production query with the result.
--
-- DISCOVERY QUERY (run once in Willy — do not load into Daton):
--   SELECT
--       action.action_type,
--       SUM(CAST(action.value AS FLOAT64)) AS total_value
--   FROM ads_table
--   CROSS JOIN UNNEST(actions) AS action
--   WHERE channel = 'facebook-ads'
--     AND event_date = '2024-08-01'
--   GROUP BY action.action_type
--   ORDER BY total_value DESC
--   LIMIT 20;
--
-- Look for the row whose total_value is closest to 2,530 — that is the
-- action_type to substitute below. Common candidates:
--   'offsite_conversion.fb_pixel_purchase'
--   'app_custom_event.fb_mobile_purchase'
-- -----------------------------------------------------------------------------

-- PRODUCTION QUERY (activate once action_type is confirmed):
SELECT
    event_date,
    SUM(adt.spend)                                        AS meta_total_spend,
    SUM(CAST(action.value AS FLOAT64))                    AS meta_inapp_purchases,
    SUM(adt.spend)
        / NULLIF(SUM(CAST(action.value AS FLOAT64)), 0)   AS meta_in_app_cpa
FROM ads_table AS adt
CROSS JOIN UNNEST(adt.actions) AS action
WHERE adt.channel = 'facebook-ads'
  AND action.action_type = '<CONFIRM_ACTION_TYPE>'
  AND adt.event_date BETWEEN @startDate AND @endDate
GROUP BY event_date
ORDER BY event_date;

-- INTERIM FALLBACK (if Daton is needed before action_type is confirmed,
-- use onsite_seven_day_click_purchases as a proxy — will be 0 for this
-- account but keeps the table shape correct):
-- SELECT
--     event_date,
--     SUM(spend)                                                        AS meta_total_spend,
--     SUM(onsite_seven_day_click_purchases)                             AS meta_inapp_purchases,
--     SUM(spend) / NULLIF(SUM(onsite_seven_day_click_purchases), 0)    AS meta_in_app_cpa
-- FROM ads_table
-- WHERE channel = 'facebook-ads'
--   AND event_date BETWEEN @startDate AND @endDate
-- GROUP BY event_date
-- ORDER BY event_date;
