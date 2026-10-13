-- stg_ad_spend: daily spend by dashboard marketing channel.
-- sales_channel: 'Amazon' for Amazon Ads (drives the Amazon CAC, available from Nov 2025); 'Shopify' for all other spend.
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.stg_ad_spend` AS
SELECT DATE(date) AS spend_date, 'Meta' AS marketing_channel, 'Shopify' AS sales_channel, spend
FROM `${PROJECT}.facebook_ads.basic_ad`                                      -- ASSUMED
UNION ALL
SELECT DATE(date), 'Google', 'Shopify', cost_micros / 1e6
FROM `${PROJECT}.google_ads.campaign_stats`                                  -- ASSUMED
UNION ALL
SELECT DATE(stat_time_day), 'TikTok', 'Shopify', spend
FROM `${PROJECT}.tiktok_ads.ad_group_report`                                 -- ASSUMED
UNION ALL
SELECT DATE(date), 'Amazon Ads', 'Amazon', cost
FROM `${PROJECT}.amazon_ads.campaign_report`                                 -- ASSUMED
UNION ALL
-- Superfiliate commissions/fees; only surfaced in the "Last Paid Click + Superfiliate" view
SELECT DATE(payout_date),
       IF(program_type = 'affiliate', 'Superfiliate – Affiliate', 'Superfiliate – Paid'),
       'Shopify', commission_amount
FROM `${PROJECT}.superfiliate.payouts`;                                      -- ASSUMED
