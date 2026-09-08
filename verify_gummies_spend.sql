-- ============================================================================
-- VERIFY: Gummies Meta ad spend lands on /products/sea-moss-gummies
--
-- Method: Meta stamps h_ad_id into the destination URL, which survives into
--         Shopify's landing_site on the order. Join that ad_id back to
--         FacebookAdinsights to get the campaign, then show where each
--         campaign's buyers actually landed.
-- ============================================================================
WITH
-- 1. Campaigns carrying Gummies Meta spend (per the current view logic)
gummies_campaigns AS (
  SELECT
    campaign_id,
    campaign_name,
    ROUND(SUM(COALESCE(meta_adspend, 0)), 2) AS meta_spend
  FROM `daton-project.trueseamoss_5363_prod_presentation_datashare.DailySpendsTracker`
  WHERE product_category = 'Gummies'
    AND date >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
  GROUP BY 1, 2
  HAVING meta_spend > 0
),

-- 2. Map every Meta ad_id to its campaign
ad_to_campaign AS (
  SELECT DISTINCT ad_id, campaign_id
  FROM `daton-project.trueseamoss_5363_prod_staging_datashare.FacebookAdinsights`
  WHERE ad_id IS NOT NULL
    AND date_start >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
),

-- 3. Pull the ad_id and landing page off every Meta-attributed order
orders AS (
  SELECT
    REGEXP_EXTRACT(landing_site, r'h_ad_id=(\d+)') AS ad_id,
    REGEXP_EXTRACT(landing_site, r'^[^?]*')        AS landing_path
  FROM `daton-project.trueseamoss_5363_prod_staging_datashare.ShopifyOrders`
  WHERE REGEXP_CONTAINS(landing_site, r'h_ad_id=\d')
    AND DATE(created_at) >= DATE_SUB(CURRENT_DATE(), INTERVAL 90 DAY)
)

-- 4. Where did each campaign's buyers actually land?
SELECT
  c.campaign_name,
  c.meta_spend,
  o.landing_path,
  COUNT(*) AS orders,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY c.campaign_id), 1)
    AS pct_of_campaign_orders,
  CASE
    WHEN REGEXP_CONTAINS(o.landing_path,
           r'^(/collections/[^/]+)?/products/sea-moss-gummies/?$')
    THEN 'YES - Gummies page'
    ELSE 'NO  - different page'
  END AS is_target_url
FROM gummies_campaigns c
JOIN ad_to_campaign a USING (campaign_id)
JOIN orders o         USING (ad_id)
GROUP BY c.campaign_id, c.campaign_name, c.meta_spend, o.landing_path
ORDER BY c.meta_spend DESC, orders DESC

-- ============================================================================
-- RESULT (run 2026-09-08, trailing 90 days):
--
-- campaign_name                                     | meta_spend | landing_path               | orders | pct   | is_target_url
-- AA2 | TSM | Gummies | Video | Main Creative Test. | 10475.32   | /products/sea-moss-gummies | 76     | 100.0 | YES - Gummies page
-- AA2 | TSM | Gummies | Video | Scaling             |  4067.60   | /products/sea-moss-gummies | 54     | 100.0 | YES - Gummies page
--
-- Two campaigns = 100% of Gummies Meta spend ($14,542.92).
-- 130 orders checked, 130 on the target URL, 1 distinct page per campaign.
-- No campaign sends traffic anywhere else. Spend needs no change.
-- ============================================================================
