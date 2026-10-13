-- stg_attribution: first-order channel credit for each attribution view on the Marketing tab.
--   lpc   = Last Paid Click  : WorkMagic last paid click, Northbeam clicks-only
--   inc   = Incrementality   : WorkMagic IDDA, Northbeam CO+DV
--   lpcsf = lpc + Superfiliate: a Superfiliate referral code on the first order supersedes the click
-- `credit` is 1.0 for deterministic models; fractional if IDDA / CO+DV return modelled credit (open question #3).
-- Labels are normalised to: Meta, Google, TikTok, Amazon Ads, Email & SMS, Organic, Unattributed.
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.stg_attribution` AS
WITH wm AS (       -- ASSUMED: WorkMagic order-level attribution export
  SELECT CAST(order_id AS STRING) AS order_id, model, channel_raw, credit
  FROM `${PROJECT}.workmagic.order_attribution`
),
nb AS (            -- ASSUMED: Northbeam order-level attribution export
  SELECT CAST(order_id AS STRING) AS order_id, attribution_model AS model, channel_raw, credit
  FROM `${PROJECT}.northbeam.orders_attribution`
),
norm AS (
  SELECT order_id, 'wm' AS src, model, credit,
    CASE
      WHEN LOWER(channel_raw) IN ('facebook','meta','instagram') THEN 'Meta'
      WHEN LOWER(channel_raw) LIKE 'google%'                      THEN 'Google'
      WHEN LOWER(channel_raw) LIKE 'tiktok%'                      THEN 'TikTok'
      WHEN LOWER(channel_raw) LIKE 'amazon%'                      THEN 'Amazon Ads'
      WHEN LOWER(channel_raw) IN ('email','sms','klaviyo')        THEN 'Email & SMS'
      WHEN LOWER(channel_raw) IN ('direct','organic','organic search','none') THEN 'Organic'
      ELSE 'Unattributed' END AS marketing_channel
  FROM wm
  UNION ALL
  SELECT order_id, 'nb', model, credit,
    CASE
      WHEN LOWER(channel_raw) IN ('facebook','meta','instagram') THEN 'Meta'
      WHEN LOWER(channel_raw) LIKE 'google%'                      THEN 'Google'
      WHEN LOWER(channel_raw) LIKE 'tiktok%'                      THEN 'TikTok'
      WHEN LOWER(channel_raw) LIKE 'amazon%'                      THEN 'Amazon Ads'
      WHEN LOWER(channel_raw) IN ('email','sms','klaviyo')        THEN 'Email & SMS'
      WHEN LOWER(channel_raw) IN ('direct','organic','organic search','none') THEN 'Organic'
      ELSE 'Unattributed' END
  FROM nb
),
lpc AS (   -- prefer WorkMagic, fall back to Northbeam clicks-only
  SELECT order_id, marketing_channel, credit FROM norm
  WHERE (src = 'wm' AND model = 'last_paid_click') OR (src = 'nb' AND model = 'clicks_only')
  QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY IF(src = 'wm', 0, 1)) = 1
),
inc AS (
  SELECT order_id, marketing_channel, credit FROM norm
  WHERE (src = 'wm' AND model = 'idda') OR (src = 'nb' AND model = 'co_dv')
  QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY IF(src = 'wm', 0, 1)) = 1
),
sf AS (    -- ASSUMED: Superfiliate referral on an order
  SELECT CAST(order_id AS STRING) AS order_id,
         IF(program_type = 'affiliate', 'Superfiliate – Affiliate', 'Superfiliate – Paid') AS marketing_channel
  FROM `${PROJECT}.superfiliate.referrals`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY referred_at) = 1
)
SELECT order_id, 'lpc'   AS attribution_view, marketing_channel, credit FROM lpc
UNION ALL
SELECT order_id, 'inc',   marketing_channel, credit FROM inc
UNION ALL
SELECT l.order_id, 'lpcsf', IFNULL(sf.marketing_channel, l.marketing_channel), l.credit
FROM lpc l LEFT JOIN sf USING (order_id);
