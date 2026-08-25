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
-- To confirm action_type: run the DISCOVERY QUERY below in Willy SQL Studio
-- (do NOT load into Daton). The row with seven_day_click closest to 2,530
-- is the action_type to substitute in the production query.
--
-- DISCOVERY QUERY — purchase-filtered (run once in Willy):
--   SELECT
--       action.action_type,
--       action.display_name,
--       SUM(action.seven_day_click)       AS seven_day_click_actions,
--       SUM(action.one_day_view)          AS one_day_view_actions,
--       SUM(action.seven_day_click_value) AS seven_day_click_value,
--       SUM(action.one_day_view_value)    AS one_day_view_value
--   FROM ads_table AS adt
--   ARRAY JOIN adt.actions AS action
--   WHERE adt.channel = 'facebook-ads'
--     AND adt.event_date = toDate('2024-08-01')
--     AND (action.action_type ILIKE '%purchase%'
--          OR action.display_name ILIKE '%purchase%')
--   GROUP BY action.action_type, action.display_name
--   ORDER BY seven_day_click_actions DESC
--   LIMIT 20;
--
-- Expected candidates: 'omni_purchase', 'offsite_conversion.fb_pixel_purchase',
--   'app_custom_event.fb_mobile_purchase'
-- Note: keep seven_day_click and one_day_view SEPARATE — adding them
--       can double-count depending on Meta's attribution config.
-- -----------------------------------------------------------------------------

-- PRODUCTION QUERY (substitute confirmed action_type before loading into Daton):
SELECT
    event_date,
    SUM(adt.spend)                                       AS meta_total_spend,
    SUM(action.seven_day_click)                          AS meta_inapp_purchases,
    SUM(adt.spend)
        / NULLIF(SUM(action.seven_day_click), 0)         AS meta_in_app_cpa
FROM ads_table AS adt
ARRAY JOIN adt.actions AS action
WHERE adt.channel = 'facebook-ads'
  AND action.action_type = '<CONFIRM_ACTION_TYPE>'
  AND adt.event_date BETWEEN @startDate AND @endDate
GROUP BY event_date
ORDER BY event_date;
