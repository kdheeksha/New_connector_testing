CREATE OR REPLACE VIEW `daton-project.trueseamoss_5363_prod_presentation_views.All_KPIs_Date_Level_Gummies` AS
WITH
  DailySalesTracker AS (
    WITH
      cte AS (
        SELECT
          date,
          store_name,
          platform_name,
          transaction_type,
          customer_type,
          sns_ntb_amazon_order_id,
          non_sns_ntb_amazon_order_id,
          amazon_customer_id,
          shopify_customer_id,
          shopify_order_id,
          walmart_seller_center_order_id,
          amazon_order_id,
          tiktok_order_id,
          target_order_id,
          returned_order_id,
          total_sales,
          shopify_total_sales,
          amazon_total_sales,
          tiktok_total_sales,
          walmart_seller_center_total_sales,
          target_total_sales,
          CASE
            WHEN customer_type = 'New' THEN coalesce(total_sales, 0)
            ELSE 0
            END AS NTB_Sales,
          CASE
            WHEN customer_type = 'New' THEN coalesce(shopify_total_sales, 0)
            ELSE 0
            END AS NTB_Shopify_Sales,
          CASE
            WHEN customer_type = 'Existing'
              THEN coalesce(shopify_total_sales, 0)
            ELSE 0
            END AS Returning_Shopify_Sales,
          CASE
            WHEN customer_type = 'New' THEN coalesce(shopify_net_sales, 0)
            ELSE 0
            END AS NTB_Shopify_Net_Sales,
          CASE
            WHEN customer_type = 'New'
              THEN
                coalesce(shopify_total_sales, 0)
                + coalesce(amazon_total_sales, 0)
            ELSE 0
            END AS NTB_Amz_Shopify_Sales,
          sns_ntb_amazon_net_sales,
          non_sns_ntb_amazon_net_sales,
          shopify_item_discount,
          shopify_refunded_amount_by_return_date,
          shopify_item_shipping_price,
          shopify_item_total_tax
        FROM
          daton-project.trueseamoss_5363_prod_presentation_datashare.DailySalesTracker
        WHERE product_category_unique IN ('Gummies Bottle', 'Gummies Pouch')
      )
    SELECT
      date,
      store_name,
      COUNT(
        DISTINCT
          CASE
            WHEN
              sns_ntb_amazon_order_id IS NOT NULL
              AND sns_ntb_amazon_order_id <> ''
              AND transaction_type <> 'return'
              THEN sns_ntb_amazon_order_id
            END) AS sns_ntb_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              non_sns_ntb_amazon_order_id IS NOT NULL
              AND non_sns_ntb_amazon_order_id <> ''
              AND transaction_type <> 'return'
              THEN non_sns_ntb_amazon_order_id
            END) AS non_sns_ntb_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              shopify_customer_id IS NOT NULL
              AND shopify_customer_id <> ''
              THEN shopify_customer_id
            END) AS shopify_customers,
      COUNT(
        DISTINCT
          CASE
            WHEN
              shopify_customer_id IS NOT NULL
              AND shopify_customer_id <> ''
              AND customer_type = 'New'
              THEN shopify_customer_id
            END) AS new_shopify_customers,
      COUNT(
        DISTINCT
          CASE
            WHEN
              amazon_customer_id IS NOT NULL
              AND amazon_customer_id <> ''
              AND customer_type = 'New'
              THEN amazon_customer_id
            END) AS new_amazon_customers,
      COUNT(
        DISTINCT
          CASE
            WHEN
              shopify_customer_id IS NOT NULL
              AND shopify_customer_id <> ''
              AND customer_type = 'Existing'
              THEN shopify_customer_id
            END) AS Returning_shopify_customers,
      COUNT(
        DISTINCT
          CASE
            WHEN
              shopify_order_id IS NOT NULL
              AND shopify_order_id <> ''
              AND transaction_type <> 'Return'
              THEN shopify_order_id
            END) AS shopify_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              shopify_order_id IS NOT NULL
              AND shopify_order_id <> ''
              AND customer_type = 'New'
              AND transaction_type <> 'Return'
              THEN shopify_order_id
            END) AS new_shopify_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              shopify_order_id IS NOT NULL
              AND shopify_order_id <> ''
              AND customer_type = 'Existing'
              AND transaction_type <> 'Return'
              THEN shopify_order_id
            END) AS Returning_shopify_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              amazon_order_id IS NOT NULL
              AND amazon_order_id <> ''
              AND transaction_type <> 'Return'
              THEN amazon_order_id
            END) AS Amazon_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              Tiktok_order_id IS NOT NULL
              AND Tiktok_order_id <> ''
              AND transaction_type <> 'Return'
              AND tiktok_total_sales > 0
              THEN Tiktok_order_id
            END) AS TikTok_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              walmart_seller_center_order_id IS NOT NULL
              AND walmart_seller_center_order_id <> ''
              AND transaction_type <> 'Return'
              THEN walmart_seller_center_order_id
            END) AS walmart_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              target_order_id IS NOT NULL
              AND target_order_id <> ''
              AND transaction_type <> 'Return'
              THEN target_order_id
            END) AS target_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              returned_order_id IS NOT NULL
              AND returned_order_id <> ''
              AND platform_name = 'Shopify'
              THEN returned_order_id
            END) AS Returns,
      sum(coalesce(total_sales, 0)) Total_Sales,
      sum(coalesce(shopify_total_sales, 0)) Website_Sales,
      sum(coalesce(amazon_total_sales, 0)) Amazon_Sales,
      sum(coalesce(tiktok_total_sales, 0)) Tiktok_Sales,
      sum(coalesce(walmart_seller_center_total_sales, 0)) Walmart_Sales,
      sum(coalesce(target_total_sales, 0)) Target_Sales,
      sum(NTB_Sales) NTB_Sales,
      sum(NTB_Shopify_Sales) NTB_Shopify_Sales,
      sum(Returning_Shopify_Sales) Returning_Shopify_Sales,
      sum(NTB_Shopify_Net_Sales) NTB_Shopify_Net_Sales,
      sum(NTB_Amz_Shopify_Sales) NTB_Amz_Shopify_Sales,
      sum(sns_ntb_amazon_net_sales) sns_ntb_amazon_net_sales,
      sum(non_sns_ntb_amazon_net_sales) non_sns_ntb_amazon_net_sales,
      sum(shopify_item_discount) shopify_item_discount,
      sum(shopify_refunded_amount_by_return_date)
        shopify_refunded_amount_by_return_date,
      sum(shopify_item_shipping_price) shopify_item_shipping_price,
      sum(shopify_item_total_tax) shopify_item_total_tax
    FROM cte
    GROUP BY ALL
  ),
  DailyShopifyAccountSessionsTracker AS (
    SELECT
      date,
      store_name,
      sum(Online_store_visitors) Online_store_visitors,
      sum(Sessions_with_cart_additions) Sessions_with_cart_additions,
      sum(Sessions_that_reached_checkout) Sessions_that_reached_checkout,
      sum(Sessions_that_completed_checkout) Sessions_that_completed_checkout,
      sum(Sessions) Sessions
    FROM
      daton-project.trueseamoss_5363_prod_presentation_datashare.DailyShopifyProductCategorySessionsTracker
    WHERE
      product_category_new = 'Gummies'
      AND Landing_page_path = '/products/sea-moss-gummies'
    GROUP BY 1, 2
  ),

  -- First, get the base aggregated data without the Canada logic
  DailySpendsTrackerBase AS (
    SELECT
      date,
      store_name,
      is_GMV_Max_campaign,
      sum(coalesce(dsp_sales, 0)) dsp_sales,
      sum(coalesce(spend, 0)) spend,
      sum(coalesce(shopify_adspend, 0)) Shopify_AdSpend,
      sum(coalesce(shopify_tof_adspend, 0)) shopify_tof_adspend,
      sum(coalesce(shopify_non_tof_adspend, 0)) shopify_non_tof_adspend,
      sum(coalesce(meta_non_tof_adspend, 0)) meta_non_tof_adspend,
      sum(coalesce(meta_tof_adspend, 0)) meta_tof_adspend,
      sum(coalesce(youtube_non_tof_adspend, 0)) youtube_non_tof_adspend,
      sum(coalesce(youtube_tof_adspend, 0)) youtube_tof_adspend,
      sum(coalesce(google_adspend, 0)) google_adspend,
      sum(coalesce(google_search_adspend, 0))
        + sum(coalesce(google_shopping_adspend, 0)) google_sands_spend,
      sum(coalesce(google_search_adspend, 0)) google_search_adspend,
      sum(coalesce(google_shopping_adspend, 0)) google_shopping_adspend,
      sum(coalesce(google_performance_max_adspend, 0))
        google_performance_max_adspend,
      sum(coalesce(amazon_adspend, 0)) amazon_adspend,
      sum(coalesce(tiktok_adspend, 0)) tiktok_adspend,
      sum(
        CASE
          WHEN is_GMV_Max_campaign = 1 THEN coalesce(tiktok_adspend, 0)
          ELSE 0
          END)
        TikTokSpend_GMV_Max,
      sum(
        CASE
          WHEN is_GMV_Max_campaign = 0 THEN coalesce(tiktok_adspend, 0)
          ELSE 0
          END)
        TikTokSpend_Campaign,
      sum(coalesce(tiktok_tof_adspend, 0)) tiktok_tof_adspend,
      sum(coalesce(walmart_adspend, 0)) walmart_adspend,
      sum(coalesce(dsp_adspend, 0)) dsp_adspend,
      sum(coalesce(amazon_adspend, 0))
        + sum(coalesce(shopify_adspend, 0)) Amz_Shopify_AdSpend,
      sum(coalesce(meta_adspend, 0)) meta_adspend,
      sum(coalesce(shopify_clicks, 0)) shopify_clicks,
      sum(coalesce(reach, 0)) reach
    FROM
      daton-project.trueseamoss_5363_prod_presentation_datashare.DailySpendsTracker
    WHERE product_category = 'Gummies'
    GROUP BY 1, 2, 3
  ),

  -- Get Canada's google_adspend values
  CanadaGoogleAdSpend AS (
    SELECT
      date,
      google_adspend AS canada_google_adspend
    FROM DailySpendsTrackerBase
    WHERE store_name = 'Canada'
  ),

  -- Final DailySpendsTracker with Canada values for US
  DailySpendsTracker AS (
    SELECT
      d.date,
      d.store_name,
      sum(d.dsp_sales) AS dsp_sales,
      sum(d.spend)
        - CASE
          WHEN d.store_name = 'Canada'
            THEN
              coalesce(
                (
                  SELECT sum(google_adspend)
                  FROM DailySpendsTrackerBase
                  WHERE date = d.date AND store_name = 'Canada'
                ),
                0)
          ELSE 0
          END
        + CASE
          WHEN d.store_name = 'United States'
            THEN
              coalesce(
                (
                  SELECT sum(google_adspend)
                  FROM DailySpendsTrackerBase
                  WHERE date = d.date AND store_name = 'Canada'
                ),
                0)
          ELSE 0
          END AS spend,
      sum(d.Shopify_AdSpend)
        - CASE
          WHEN d.store_name = 'Canada'
            THEN
              coalesce(
                (
                  SELECT sum(google_adspend)
                  FROM DailySpendsTrackerBase
                  WHERE date = d.date AND store_name = 'Canada'
                ),
                0)
          ELSE 0
          END AS Shopify_AdSpend,
      sum(d.shopify_tof_adspend) AS shopify_tof_adspend,
      sum(d.shopify_non_tof_adspend)
        - CASE
          WHEN d.store_name = 'Canada'
            THEN
              coalesce(
                (
                  SELECT sum(google_adspend)
                  FROM DailySpendsTrackerBase
                  WHERE date = d.date AND store_name = 'Canada'
                ),
                0)
          ELSE 0
          END AS shopify_non_tof_adspend,
      sum(d.meta_non_tof_adspend) AS meta_non_tof_adspend,
      sum(d.meta_tof_adspend) AS meta_tof_adspend,
      sum(d.youtube_non_tof_adspend) AS youtube_non_tof_adspend,
      sum(d.youtube_tof_adspend) AS youtube_tof_adspend,

      -- Use Canada's google_adspend for United States via subquery, keep original for others
      CASE
        WHEN d.store_name = 'United States'
          THEN
            coalesce(
              (
                SELECT google_adspend
                FROM DailySpendsTrackerBase
                WHERE
                  date = d.date
                  AND store_name = 'Canada'
              ),
              0)
        WHEN d.store_name = 'Canada' THEN 0
        ELSE sum(d.google_adspend)
        END AS google_adspend,
      CASE
        WHEN d.store_name = 'Canada' THEN 0
        ELSE sum(d.google_sands_spend)
        END AS google_sands_spend,
      CASE
        WHEN d.store_name = 'Canada' THEN 0
        ELSE sum(d.google_search_adspend)
        END AS google_search_adspend,
      CASE
        WHEN d.store_name = 'Canada' THEN 0
        ELSE sum(d.google_shopping_adspend)
        END AS google_shopping_adspend,
      CASE
        WHEN d.store_name = 'Canada' THEN 0
        ELSE sum(d.google_performance_max_adspend)
        END AS google_performance_max_adspend,
      sum(d.amazon_adspend)
        + CASE
          WHEN d.store_name = 'United States'
            THEN
              coalesce(
                (
                  SELECT sum(google_adspend)
                  FROM DailySpendsTrackerBase
                  WHERE date = d.date AND store_name = 'Canada'
                ),
                0)
          ELSE 0
          END AS amazon_adspend,
      sum(d.tiktok_adspend) AS tiktok_adspend,
      sum(d.TikTokSpend_GMV_Max) AS TikTokSpend_GMV_Max,
      sum(d.TikTokSpend_Campaign) AS TikTokSpend_Campaign,
      sum(d.tiktok_tof_adspend) AS tiktok_tof_adspend,
      sum(d.walmart_adspend) AS walmart_adspend,
      sum(d.dsp_adspend) AS dsp_adspend,
      sum(d.Amz_Shopify_AdSpend)
        - CASE
          WHEN d.store_name = 'Canada'
            THEN
              coalesce(
                (
                  SELECT sum(google_adspend)
                  FROM DailySpendsTrackerBase
                  WHERE date = d.date AND store_name = 'Canada'
                ),
                0)
          ELSE 0
          END
        + CASE
          WHEN d.store_name = 'United States'
            THEN
              coalesce(
                (
                  SELECT sum(google_adspend)
                  FROM DailySpendsTrackerBase
                  WHERE date = d.date AND store_name = 'Canada'
                ),
                0)
          ELSE 0
          END AS Amz_Shopify_AdSpend,
      sum(d.meta_adspend) AS meta_adspend,
      sum(d.shopify_clicks) AS shopify_clicks,
      sum(d.reach) AS reach
    FROM DailySpendsTrackerBase d
    GROUP BY d.date, d.store_name
  ),
  DailySubscriptionsTracker AS (
    SELECT
      date,
      store_name,
      sum(coalesce(new_subscribers, 0)) new_subscribers_recharge,
      sum(coalesce(active_subscribers, 0)) active_subscribers_recharge,
      sum(coalesce(churned_subscribers, 0)) churned_subscribers_recharge,
      sum(coalesce(reactivated_subscribers, 0))
        reactivated_subscribers_recharge,
      sum(coalesce(net_gain_loss_subscribers, 0)) net_gain_loss_recharge,
      sum(coalesce(active_subscriptions, 0)) active_subscriptions_recharge,
      avg(avg_active_days_per_subscriber)
        avg_active_days_per_subscriber_recharge
    FROM
      daton-project.trueseamoss_5363_prod_presentation_datashare.DailyCatogerySubscriptionsTracker
    WHERE product_category IN ('Gummies Bottle', 'Gummies Pouch')
    GROUP BY ALL
  ),
  SpendsAgainstSales AS (
    SELECT
      date,
      'United States' AS Store_name,
      COUNT(
        DISTINCT
          CASE
            WHEN
              customer_type = 'New'
              AND shopify_order_id IS NOT NULL
              AND transaction_type <> 'Return'
              THEN shopify_order_id
            END)
        firsttime_customer_shopify_orders_SpendAgainstSales,
      COUNT(
        DISTINCT
          CASE
            WHEN shopify_order_id IS NOT NULL AND transaction_type <> 'Return'
              THEN shopify_order_id
            END)
        shopify_orders_SpendAgainstSales
    FROM
      daton-project.trueseamoss_5363_prod_presentation_datashare.DailySalesTracker
    WHERE product_category_unique IN ('Gummies Bottle', 'Gummies Pouch')
    GROUP BY ALL
  ),
  TikTokShop_gs AS (
    SELECT
      date,
      'United States' AS Store_name,
      sum(coalesce(active_subscriptions, 0)) active_subscriptions_TTS,
      sum(coalesce(active_subscribers, 0)) active_subscribers_TTS,
      sum(coalesce(new_subscriptions, 0)) new_subscriptions_TTS,
      sum(coalesce(churn, 0)) churn_TTS,
      sum(coalesce(net_gain_loss, 0)) net_gain_loss_TTS,
      avg(subs_aov) subs_aov_TTS
    FROM
      daton-project.trueseamoss_5363_prod_presentation_datashare.TikTokShopSubscriptions_gs
    GROUP BY ALL
  ),
  TripleWhale_gs AS (
    SELECT
      date,
      store_name,
      sum(coalesce(triple_whale_meta_cac_first_touch_7d, 0))
        triple_whale_meta_cac_first_touch_7d,
      sum(coalesce(triple_whale_meta_cac_last_touch_7d, 0))
        triple_whale_meta_cac_last_touch_7d,
      sum(coalesce(triple_whale_meta_cac_triple_att_7d, 0))
        triple_whale_meta_cac_triple_att_7d,
      sum(coalesce(meta_in_app_cpa, 0)) meta_in_app_cpa,
      sum(coalesce(triple_whale_meta_ncp_firt_click, 0))
        triple_whale_meta_ncp_first_click,
      sum(coalesce(triple_whale_meta_ncp_lat_click, 0))
        triple_whale_meta_ncp_lat_click,
      sum(coalesce(triple_whale_meta_ncp_triple_att_7d, 0))
        triple_whale_meta_ncp_triple_att_7d,
      sum(coalesce(meta_inapp_purchases, 0)) meta_inapp_purchases,
      sum(coalesce(triple_whale_google_cac_first_touch_7d, 0))
        triple_whale_google_cac_first_touch_7d,
      sum(coalesce(triple_whale_google_cac_last_touch_7d, 0))
        triple_whale_google_cac_last_touch_7d,
      sum(coalesce(triple_whale_google_cac_triple_att_7d, 0))
        triple_whale_google_cac_triple_att_7d,
      sum(coalesce(dg_first_touch_7d, 0)) dg_first_touch_7d,
      sum(coalesce(dg_last_touch_7d, 0)) dg_last_touch_7d,
      sum(coalesce(dg_triple_att_7d, 0)) dg_triple_att_7d,
      sum(coalesce(prospecting_first_touch_7d, 0)) prospecting_first_touch_7d,
      sum(coalesce(prospecting_last_touch_7d, 0)) prospecting_last_touch_7d,
      sum(coalesce(prospecting_triple_att_7d, 0)) prospecting_triple_att_7d,
      sum(coalesce(brand_first_touch_7d, 0)) brand_first_touch_7d,
      sum(coalesce(brand_last_touch_7d, 0)) brand_last_touch_7d,
      sum(coalesce(brand_triple_att_7d, 0)) brand_triple_att_7d
    FROM
      daton-project.trueseamoss_5363_prod_presentation_datashare.TripleWhaleData_gs
    WHERE segment_type = 'Gummies'
    GROUP BY ALL
  ),
  Applovin_data AS (
    SELECT
      date,
      store_name,
      sum(adsales) Applovin_Adsales,
      sum(adspend) Applovin_AdSpend
    FROM
      daton-project.trueseamoss_5363_prod_presentation_datashare.ApplovinData_gs
    GROUP BY ALL
  ),

  -- CTE for Full Outer Join of All Data Sources
  CompleteDataJoin AS (
    SELECT
      coalesce(
        dst.date,
        apv.date,
        dsast.date,
        dspdt.date,
        dsubt.date,
        sas.date,
        tts.date,
        tw.date) AS date,
      coalesce(
        dst.store_name,
        apv.store_name,
        dsast.store_name,
        dspdt.store_name,
        dsubt.store_name,
        sas.store_name,
        tts.store_name,
        tw.store_name) AS store_name,

      -- DailySalesTracker columns
      dst.sns_ntb_orders,
      dst.non_sns_ntb_orders,
      dst.shopify_customers,
      dst.new_shopify_customers,
      dst.new_amazon_customers,
      dst.Returning_shopify_customers,
      dst.shopify_orders,
      dst.new_shopify_orders,
      dst.Returning_shopify_orders,
      dst.Amazon_orders,
      dst.TikTok_orders,
      dst.walmart_orders,
      dst.target_orders,
      dst.Returns,
      dst.Total_Sales,
      dst.Website_Sales,
      dst.Amazon_Sales,
      dst.Tiktok_Sales,
      dst.Walmart_Sales,
      dst.Target_Sales,
      dst.NTB_Sales,
      dst.NTB_Shopify_Sales,
      dst.Returning_Shopify_Sales,
      dst.NTB_Shopify_Net_Sales,
      dst.NTB_Amz_Shopify_Sales,
      dst.sns_ntb_amazon_net_sales,
      dst.non_sns_ntb_amazon_net_sales,
      dst.shopify_item_discount,
      dst.shopify_refunded_amount_by_return_date,
      dst.shopify_item_shipping_price,
      dst.shopify_item_total_tax,

      -- Applovin_data columns
      apv.Applovin_Adsales,
      apv.Applovin_AdSpend,

      -- DailyShopifyAccountSessionsTracker columns
      dsast.Online_store_visitors,
      dsast.Sessions_with_cart_additions,
      dsast.Sessions_that_reached_checkout,
      dsast.Sessions_that_completed_checkout,
      dsast.Sessions,

      -- DailySpendsTracker columns
      dspdt.dsp_sales,
      dspdt.spend,
      dspdt.Shopify_AdSpend,
      dspdt.shopify_tof_adspend,
      dspdt.shopify_non_tof_adspend,
      dspdt.meta_non_tof_adspend,
      dspdt.meta_tof_adspend,
      dspdt.youtube_non_tof_adspend,
      dspdt.youtube_tof_adspend,
      dspdt.google_adspend,  -- Added google_adspend here
      dspdt.google_sands_spend,
      dspdt.google_search_adspend,
      dspdt.google_shopping_adspend,
      dspdt.google_performance_max_adspend,
      dspdt.amazon_adspend,
      dspdt.tiktok_adspend,
      dspdt.TikTokSpend_GMV_Max,
      dspdt.TikTokSpend_Campaign,
      dspdt.tiktok_tof_adspend,
      dspdt.walmart_adspend,
      dspdt.dsp_adspend,
      dspdt.Amz_Shopify_AdSpend,
      dspdt.meta_adspend,
      dspdt.shopify_clicks,
      dspdt.reach,

      -- DailySubscriptionsTracker columns
      dsubt.new_subscribers_recharge,
      dsubt.active_subscribers_recharge,
      dsubt.churned_subscribers_recharge,
      dsubt.reactivated_subscribers_recharge,
      dsubt.net_gain_loss_recharge,
      dsubt.active_subscriptions_recharge,
      dsubt.avg_active_days_per_subscriber_recharge,

      -- SpendsAgainstSales columns
      sas.firsttime_customer_shopify_orders_SpendAgainstSales,
      sas.shopify_orders_SpendAgainstSales,

      -- TikTokShop_gs columns
      tts.active_subscriptions_TTS,
      tts.active_subscribers_TTS,
      tts.new_subscriptions_TTS,
      tts.churn_TTS,
      tts.net_gain_loss_TTS,
      tts.subs_aov_TTS,

      -- TripleWhale_gs columns
      tw.triple_whale_meta_cac_first_touch_7d,
      tw.triple_whale_meta_cac_last_touch_7d,
      tw.triple_whale_meta_cac_triple_att_7d,
      tw.meta_in_app_cpa,
      tw.triple_whale_meta_ncp_first_click,
      tw.triple_whale_meta_ncp_lat_click,
      tw.triple_whale_meta_ncp_triple_att_7d,
      tw.meta_inapp_purchases,
      tw.triple_whale_google_cac_first_touch_7d,
      tw.triple_whale_google_cac_last_touch_7d,
      tw.triple_whale_google_cac_triple_att_7d,
      tw.dg_first_touch_7d,
      tw.dg_last_touch_7d,
      tw.dg_triple_att_7d,
      tw.prospecting_first_touch_7d,
      tw.prospecting_last_touch_7d,
      tw.prospecting_triple_att_7d,
      tw.brand_first_touch_7d,
      tw.brand_last_touch_7d,
      tw.brand_triple_att_7d
    FROM DailySalesTracker dst
    FULL OUTER JOIN Applovin_data apv
      ON
        dst.date = apv.date
        AND dst.store_name = apv.store_name
    FULL OUTER JOIN DailyShopifyAccountSessionsTracker dsast
      ON
        coalesce(dst.date, apv.date) = dsast.date
        AND coalesce(dst.store_name, apv.store_name) = dsast.store_name
    FULL OUTER JOIN DailySpendsTracker dspdt
      ON
        coalesce(dst.date, apv.date, dsast.date) = dspdt.date
        AND coalesce(dst.store_name, apv.store_name, dsast.store_name)
          = dspdt.store_name
    FULL OUTER JOIN DailySubscriptionsTracker dsubt
      ON
        coalesce(dst.date, apv.date, dsast.date, dspdt.date) = dsubt.date
        AND coalesce(
          dst.store_name, apv.store_name, dsast.store_name, dspdt.store_name)
          = dsubt.store_name
    FULL OUTER JOIN SpendsAgainstSales sas
      ON
        coalesce(dst.date, apv.date, dsast.date, dspdt.date, dsubt.date)
          = sas.date
        AND coalesce(
          dst.store_name,
          apv.store_name,
          dsast.store_name,
          dspdt.store_name,
          dsubt.store_name)
          = sas.store_name
    FULL OUTER JOIN TikTokShop_gs tts
      ON
        coalesce(
          dst.date, apv.date, dsast.date, dspdt.date, dsubt.date, sas.date)
          = tts.date
        AND coalesce(
          dst.store_name,
          apv.store_name,
          dsast.store_name,
          dspdt.store_name,
          dsubt.store_name,
          sas.store_name)
          = tts.store_name
    FULL OUTER JOIN TripleWhale_gs tw
      ON
        coalesce(
          dst.date,
          apv.date,
          dsast.date,
          dspdt.date,
          dsubt.date,
          sas.date,
          tts.date)
          = tw.date
        AND coalesce(
          dst.store_name,
          apv.store_name,
          dsast.store_name,
          dspdt.store_name,
          dsubt.store_name,
          sas.store_name,
          tts.store_name)
          = tw.store_name
  ),

  -- Get the latest date in the dataset
  LatestDateCTE AS (
    SELECT max(date) AS latest_date
    FROM CompleteDataJoin
  ),

  -- Calculate month start date for MTD
  MonthStartCTE AS (
    SELECT
      latest_date,
      date_trunc(latest_date, month) AS month_start_date
    FROM LatestDateCTE
  ),

  -- Calculate averages for each period and store_name - ALL METRICS INCLUDED
  PeriodAverages AS (
    SELECT
      cdj.store_name,

      -- SALES SECTION METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Total_Sales
          ELSE NULL
          END) AS Total_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Total_Sales
          ELSE NULL
          END) AS Total_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Total_Sales
          ELSE NULL
          END) AS Total_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Total_Sales
          ELSE NULL
          END) AS Total_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Website_Sales
          ELSE NULL
          END) AS Website_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Website_Sales
          ELSE NULL
          END) AS Website_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Website_Sales
          ELSE NULL
          END) AS Website_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Website_Sales
          ELSE NULL
          END) AS Website_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Amazon_Sales
          ELSE NULL
          END) AS Amazon_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Amazon_Sales
          ELSE NULL
          END) AS Amazon_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Amazon_Sales
          ELSE NULL
          END) AS Amazon_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Amazon_Sales
          ELSE NULL
          END) AS Amazon_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Tiktok_Sales
          ELSE NULL
          END) AS Tiktok_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Tiktok_Sales
          ELSE NULL
          END) AS Tiktok_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Tiktok_Sales
          ELSE NULL
          END) AS Tiktok_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Tiktok_Sales
          ELSE NULL
          END) AS Tiktok_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Walmart_Sales
          ELSE NULL
          END) AS Walmart_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Walmart_Sales
          ELSE NULL
          END) AS Walmart_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Walmart_Sales
          ELSE NULL
          END) AS Walmart_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Walmart_Sales
          ELSE NULL
          END) AS Walmart_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Target_Sales
          ELSE NULL
          END) AS Target_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Target_Sales
          ELSE NULL
          END) AS Target_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Target_Sales
          ELSE NULL
          END) AS Target_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Target_Sales
          ELSE NULL
          END) AS Target_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Applovin_Adsales
          ELSE NULL
          END) AS Applovin_Adsales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Applovin_Adsales
          ELSE NULL
          END) AS Applovin_Adsales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Applovin_Adsales
          ELSE NULL
          END) AS Applovin_Adsales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Applovin_Adsales
          ELSE NULL
          END) AS Applovin_Adsales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.dsp_sales
          ELSE NULL
          END) AS dsp_sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.dsp_sales
          ELSE NULL
          END) AS dsp_sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.dsp_sales
          ELSE NULL
          END) AS dsp_sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.dsp_sales
          ELSE NULL
          END) AS dsp_sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.NTB_Sales
          ELSE NULL
          END) AS NTB_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.NTB_Sales
          ELSE NULL
          END) AS NTB_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.NTB_Sales
          ELSE NULL
          END) AS NTB_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.NTB_Sales
          ELSE NULL
          END) AS NTB_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.NTB_Shopify_Sales
          ELSE NULL
          END) AS NTB_Shopify_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.NTB_Shopify_Sales
          ELSE NULL
          END) AS NTB_Shopify_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.NTB_Shopify_Sales
          ELSE NULL
          END) AS NTB_Shopify_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.NTB_Shopify_Sales
          ELSE NULL
          END) AS NTB_Shopify_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Returning_Shopify_Sales
          ELSE NULL
          END) AS Returning_Shopify_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Returning_Shopify_Sales
          ELSE NULL
          END) AS Returning_Shopify_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Returning_Shopify_Sales
          ELSE NULL
          END) AS Returning_Shopify_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Returning_Shopify_Sales
          ELSE NULL
          END) AS Returning_Shopify_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.NTB_Shopify_Net_Sales
          ELSE NULL
          END) AS NTB_Shopify_Net_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.NTB_Shopify_Net_Sales
          ELSE NULL
          END) AS NTB_Shopify_Net_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.NTB_Shopify_Net_Sales
          ELSE NULL
          END) AS NTB_Shopify_Net_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.NTB_Shopify_Net_Sales
          ELSE NULL
          END) AS NTB_Shopify_Net_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.NTB_Amz_Shopify_Sales
          ELSE NULL
          END) AS NTB_Amz_Shopify_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.NTB_Amz_Shopify_Sales
          ELSE NULL
          END) AS NTB_Amz_Shopify_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.NTB_Amz_Shopify_Sales
          ELSE NULL
          END) AS NTB_Amz_Shopify_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.NTB_Amz_Shopify_Sales
          ELSE NULL
          END) AS NTB_Amz_Shopify_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.sns_ntb_amazon_net_sales
          ELSE NULL
          END) AS sns_ntb_amazon_net_sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.sns_ntb_amazon_net_sales
          ELSE NULL
          END) AS sns_ntb_amazon_net_sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.sns_ntb_amazon_net_sales
          ELSE NULL
          END) AS sns_ntb_amazon_net_sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.sns_ntb_amazon_net_sales
          ELSE NULL
          END) AS sns_ntb_amazon_net_sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.non_sns_ntb_amazon_net_sales
          ELSE NULL
          END) AS non_sns_ntb_amazon_net_sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.non_sns_ntb_amazon_net_sales
          ELSE NULL
          END) AS non_sns_ntb_amazon_net_sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.non_sns_ntb_amazon_net_sales
          ELSE NULL
          END) AS non_sns_ntb_amazon_net_sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.non_sns_ntb_amazon_net_sales
          ELSE NULL
          END) AS non_sns_ntb_amazon_net_sales_MTD,

      -- SPEND SECTION METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.spend
          ELSE NULL
          END) AS spend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.spend
          ELSE NULL
          END) AS spend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.spend
          ELSE NULL
          END) AS spend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.spend
          ELSE NULL
          END) AS spend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Shopify_AdSpend
          ELSE NULL
          END) AS Shopify_AdSpend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Shopify_AdSpend
          ELSE NULL
          END) AS Shopify_AdSpend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Shopify_AdSpend
          ELSE NULL
          END) AS Shopify_AdSpend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Shopify_AdSpend
          ELSE NULL
          END) AS Shopify_AdSpend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_tof_adspend
          ELSE NULL
          END) AS shopify_tof_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_tof_adspend
          ELSE NULL
          END) AS shopify_tof_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_tof_adspend
          ELSE NULL
          END) AS shopify_tof_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_tof_adspend
          ELSE NULL
          END) AS shopify_tof_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_non_tof_adspend
          ELSE NULL
          END) AS shopify_non_tof_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_non_tof_adspend
          ELSE NULL
          END) AS shopify_non_tof_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_non_tof_adspend
          ELSE NULL
          END) AS shopify_non_tof_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_non_tof_adspend
          ELSE NULL
          END) AS shopify_non_tof_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.meta_non_tof_adspend
          ELSE NULL
          END) AS meta_non_tof_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.meta_non_tof_adspend
          ELSE NULL
          END) AS meta_non_tof_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.meta_non_tof_adspend
          ELSE NULL
          END) AS meta_non_tof_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.meta_non_tof_adspend
          ELSE NULL
          END) AS meta_non_tof_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.meta_tof_adspend
          ELSE NULL
          END) AS meta_tof_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.meta_tof_adspend
          ELSE NULL
          END) AS meta_tof_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.meta_tof_adspend
          ELSE NULL
          END) AS meta_tof_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.meta_tof_adspend
          ELSE NULL
          END) AS meta_tof_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.youtube_non_tof_adspend
          ELSE NULL
          END) AS youtube_non_tof_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.youtube_non_tof_adspend
          ELSE NULL
          END) AS youtube_non_tof_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.youtube_non_tof_adspend
          ELSE NULL
          END) AS youtube_non_tof_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.youtube_non_tof_adspend
          ELSE NULL
          END) AS youtube_non_tof_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.youtube_tof_adspend
          ELSE NULL
          END) AS youtube_tof_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.youtube_tof_adspend
          ELSE NULL
          END) AS youtube_tof_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.youtube_tof_adspend
          ELSE NULL
          END) AS youtube_tof_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.youtube_tof_adspend
          ELSE NULL
          END) AS youtube_tof_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.google_adspend
          ELSE NULL
          END) AS google_adspend_L7,  -- Added google_adspend average L7
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.google_adspend
          ELSE NULL
          END) AS google_adspend_L14,  -- Added google_adspend average L14
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.google_adspend
          ELSE NULL
          END) AS google_adspend_L30,  -- Added google_adspend average L30
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.google_adspend
          ELSE NULL
          END) AS google_adspend_MTD,  -- Added google_adspend average MTD
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.google_sands_spend
          ELSE NULL
          END) AS google_sands_spend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.google_sands_spend
          ELSE NULL
          END) AS google_sands_spend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.google_sands_spend
          ELSE NULL
          END) AS google_sands_spend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.google_sands_spend
          ELSE NULL
          END) AS google_sands_spend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.google_search_adspend
          ELSE NULL
          END) AS google_search_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.google_search_adspend
          ELSE NULL
          END) AS google_search_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.google_search_adspend
          ELSE NULL
          END) AS google_search_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.google_search_adspend
          ELSE NULL
          END) AS google_search_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.google_shopping_adspend
          ELSE NULL
          END) AS google_shopping_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.google_shopping_adspend
          ELSE NULL
          END) AS google_shopping_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.google_shopping_adspend
          ELSE NULL
          END) AS google_shopping_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.google_shopping_adspend
          ELSE NULL
          END) AS google_shopping_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.google_performance_max_adspend
          ELSE NULL
          END) AS google_performance_max_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.google_performance_max_adspend
          ELSE NULL
          END) AS google_performance_max_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.google_performance_max_adspend
          ELSE NULL
          END) AS google_performance_max_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.google_performance_max_adspend
          ELSE NULL
          END) AS google_performance_max_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.amazon_adspend
          ELSE NULL
          END) AS amazon_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.amazon_adspend
          ELSE NULL
          END) AS amazon_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.amazon_adspend
          ELSE NULL
          END) AS amazon_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.amazon_adspend
          ELSE NULL
          END) AS amazon_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.tiktok_adspend
          ELSE NULL
          END) AS tiktok_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.tiktok_adspend
          ELSE NULL
          END) AS tiktok_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.tiktok_adspend
          ELSE NULL
          END) AS tiktok_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.tiktok_adspend
          ELSE NULL
          END) AS tiktok_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.TikTokSpend_GMV_Max
          ELSE NULL
          END) AS TikTokSpend_GMV_Max_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.TikTokSpend_GMV_Max
          ELSE NULL
          END) AS TikTokSpend_GMV_Max_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.TikTokSpend_GMV_Max
          ELSE NULL
          END) AS TikTokSpend_GMV_Max_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.TikTokSpend_GMV_Max
          ELSE NULL
          END) AS TikTokSpend_GMV_Max_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.TikTokSpend_Campaign
          ELSE NULL
          END) AS TikTokSpend_Campaign_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.TikTokSpend_Campaign
          ELSE NULL
          END) AS TikTokSpend_Campaign_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.TikTokSpend_Campaign
          ELSE NULL
          END) AS TikTokSpend_Campaign_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.TikTokSpend_Campaign
          ELSE NULL
          END) AS TikTokSpend_Campaign_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.tiktok_tof_adspend
          ELSE NULL
          END) AS tiktok_tof_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.tiktok_tof_adspend
          ELSE NULL
          END) AS tiktok_tof_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.tiktok_tof_adspend
          ELSE NULL
          END) AS tiktok_tof_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.tiktok_tof_adspend
          ELSE NULL
          END) AS tiktok_tof_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Applovin_AdSpend
          ELSE NULL
          END) AS Applovin_AdSpend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Applovin_AdSpend
          ELSE NULL
          END) AS Applovin_AdSpend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Applovin_AdSpend
          ELSE NULL
          END) AS Applovin_AdSpend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Applovin_AdSpend
          ELSE NULL
          END) AS Applovin_AdSpend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.walmart_adspend
          ELSE NULL
          END) AS walmart_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.walmart_adspend
          ELSE NULL
          END) AS walmart_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.walmart_adspend
          ELSE NULL
          END) AS walmart_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.walmart_adspend
          ELSE NULL
          END) AS walmart_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.dsp_adspend
          ELSE NULL
          END) AS dsp_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.dsp_adspend
          ELSE NULL
          END) AS dsp_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.dsp_adspend
          ELSE NULL
          END) AS dsp_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.dsp_adspend
          ELSE NULL
          END) AS dsp_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Amz_Shopify_AdSpend
          ELSE NULL
          END) AS Amz_Shopify_AdSpend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Amz_Shopify_AdSpend
          ELSE NULL
          END) AS Amz_Shopify_AdSpend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Amz_Shopify_AdSpend
          ELSE NULL
          END) AS Amz_Shopify_AdSpend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Amz_Shopify_AdSpend
          ELSE NULL
          END) AS Amz_Shopify_AdSpend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.meta_adspend
          ELSE NULL
          END) AS meta_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.meta_adspend
          ELSE NULL
          END) AS meta_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.meta_adspend
          ELSE NULL
          END) AS meta_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.meta_adspend
          ELSE NULL
          END) AS meta_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_clicks
          ELSE NULL
          END) AS shopify_clicks_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_clicks
          ELSE NULL
          END) AS shopify_clicks_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_clicks
          ELSE NULL
          END) AS shopify_clicks_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_clicks
          ELSE NULL
          END) AS shopify_clicks_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.reach
          ELSE NULL
          END) AS reach_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.reach
          ELSE NULL
          END) AS reach_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.reach
          ELSE NULL
          END) AS reach_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.reach
          ELSE NULL
          END) AS reach_MTD,

      -- TRIPLE WHALE SECTION METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_first_touch_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_first_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_first_touch_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_first_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_first_touch_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_first_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_first_touch_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_first_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_last_touch_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_last_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_last_touch_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_last_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_last_touch_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_last_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_last_touch_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_last_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_triple_att_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_triple_att_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_triple_att_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_triple_att_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_triple_att_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_triple_att_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_triple_att_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_triple_att_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.meta_in_app_cpa
          ELSE NULL
          END) AS meta_in_app_cpa_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.meta_in_app_cpa
          ELSE NULL
          END) AS meta_in_app_cpa_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.meta_in_app_cpa
          ELSE NULL
          END) AS meta_in_app_cpa_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.meta_in_app_cpa
          ELSE NULL
          END) AS meta_in_app_cpa_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_first_click
          ELSE NULL
          END) AS triple_whale_meta_ncp_first_click_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_first_click
          ELSE NULL
          END) AS triple_whale_meta_ncp_first_click_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_first_click
          ELSE NULL
          END) AS triple_whale_meta_ncp_first_click_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_first_click
          ELSE NULL
          END) AS triple_whale_meta_ncp_first_click_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_lat_click
          ELSE NULL
          END) AS triple_whale_meta_ncp_lat_click_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_lat_click
          ELSE NULL
          END) AS triple_whale_meta_ncp_lat_click_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_lat_click
          ELSE NULL
          END) AS triple_whale_meta_ncp_lat_click_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_lat_click
          ELSE NULL
          END) AS triple_whale_meta_ncp_lat_click_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_triple_att_7d
          ELSE NULL
          END) AS triple_whale_meta_ncp_triple_att_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_triple_att_7d
          ELSE NULL
          END) AS triple_whale_meta_ncp_triple_att_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_triple_att_7d
          ELSE NULL
          END) AS triple_whale_meta_ncp_triple_att_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_triple_att_7d
          ELSE NULL
          END) AS triple_whale_meta_ncp_triple_att_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.meta_inapp_purchases
          ELSE NULL
          END) AS meta_inapp_purchases_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.meta_inapp_purchases
          ELSE NULL
          END) AS meta_inapp_purchases_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.meta_inapp_purchases
          ELSE NULL
          END) AS meta_inapp_purchases_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.meta_inapp_purchases
          ELSE NULL
          END) AS meta_inapp_purchases_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_first_touch_7d
          ELSE NULL
          END) AS triple_whale_google_cac_first_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_first_touch_7d
          ELSE NULL
          END) AS triple_whale_google_cac_first_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_first_touch_7d
          ELSE NULL
          END) AS triple_whale_google_cac_first_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_google_cac_first_touch_7d
          ELSE NULL
          END) AS triple_whale_google_cac_first_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_last_touch_7d
          ELSE NULL
          END) AS triple_whale_google_cac_last_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_last_touch_7d
          ELSE NULL
          END) AS triple_whale_google_cac_last_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_last_touch_7d
          ELSE NULL
          END) AS triple_whale_google_cac_last_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_google_cac_last_touch_7d
          ELSE NULL
          END) AS triple_whale_google_cac_last_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_triple_att_7d
          ELSE NULL
          END) AS triple_whale_google_cac_triple_att_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_triple_att_7d
          ELSE NULL
          END) AS triple_whale_google_cac_triple_att_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_triple_att_7d
          ELSE NULL
          END) AS triple_whale_google_cac_triple_att_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_google_cac_triple_att_7d
          ELSE NULL
          END) AS triple_whale_google_cac_triple_att_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.dg_first_touch_7d
          ELSE NULL
          END) AS dg_first_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.dg_first_touch_7d
          ELSE NULL
          END) AS dg_first_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.dg_first_touch_7d
          ELSE NULL
          END) AS dg_first_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.dg_first_touch_7d
          ELSE NULL
          END) AS dg_first_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.dg_last_touch_7d
          ELSE NULL
          END) AS dg_last_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.dg_last_touch_7d
          ELSE NULL
          END) AS dg_last_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.dg_last_touch_7d
          ELSE NULL
          END) AS dg_last_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.dg_last_touch_7d
          ELSE NULL
          END) AS dg_last_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.dg_triple_att_7d
          ELSE NULL
          END) AS dg_triple_att_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.dg_triple_att_7d
          ELSE NULL
          END) AS dg_triple_att_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.dg_triple_att_7d
          ELSE NULL
          END) AS dg_triple_att_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.dg_triple_att_7d
          ELSE NULL
          END) AS dg_triple_att_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.prospecting_first_touch_7d
          ELSE NULL
          END) AS prospecting_first_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.prospecting_first_touch_7d
          ELSE NULL
          END) AS prospecting_first_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.prospecting_first_touch_7d
          ELSE NULL
          END) AS prospecting_first_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.prospecting_first_touch_7d
          ELSE NULL
          END) AS prospecting_first_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.prospecting_last_touch_7d
          ELSE NULL
          END) AS prospecting_last_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.prospecting_last_touch_7d
          ELSE NULL
          END) AS prospecting_last_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.prospecting_last_touch_7d
          ELSE NULL
          END) AS prospecting_last_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.prospecting_last_touch_7d
          ELSE NULL
          END) AS prospecting_last_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.prospecting_triple_att_7d
          ELSE NULL
          END) AS prospecting_triple_att_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.prospecting_triple_att_7d
          ELSE NULL
          END) AS prospecting_triple_att_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.prospecting_triple_att_7d
          ELSE NULL
          END) AS prospecting_triple_att_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.prospecting_triple_att_7d
          ELSE NULL
          END) AS prospecting_triple_att_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.brand_first_touch_7d
          ELSE NULL
          END) AS brand_first_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.brand_first_touch_7d
          ELSE NULL
          END) AS brand_first_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.brand_first_touch_7d
          ELSE NULL
          END) AS brand_first_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.brand_first_touch_7d
          ELSE NULL
          END) AS brand_first_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.brand_last_touch_7d
          ELSE NULL
          END) AS brand_last_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.brand_last_touch_7d
          ELSE NULL
          END) AS brand_last_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.brand_last_touch_7d
          ELSE NULL
          END) AS brand_last_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.brand_last_touch_7d
          ELSE NULL
          END) AS brand_last_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.brand_triple_att_7d
          ELSE NULL
          END) AS brand_triple_att_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.brand_triple_att_7d
          ELSE NULL
          END) AS brand_triple_att_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.brand_triple_att_7d
          ELSE NULL
          END) AS brand_triple_att_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.brand_triple_att_7d
          ELSE NULL
          END) AS brand_triple_att_7d_MTD,

      -- CUSTOMER METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_customers
          ELSE NULL
          END) AS shopify_customers_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_customers
          ELSE NULL
          END) AS shopify_customers_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_customers
          ELSE NULL
          END) AS shopify_customers_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_customers
          ELSE NULL
          END) AS shopify_customers_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.new_shopify_customers
          ELSE NULL
          END) AS new_shopify_customers_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.new_shopify_customers
          ELSE NULL
          END) AS new_shopify_customers_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.new_shopify_customers
          ELSE NULL
          END) AS new_shopify_customers_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.new_shopify_customers
          ELSE NULL
          END) AS new_shopify_customers_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.new_amazon_customers
          ELSE NULL
          END) AS new_amazon_customers_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.new_amazon_customers
          ELSE NULL
          END) AS new_amazon_customers_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.new_amazon_customers
          ELSE NULL
          END) AS new_amazon_customers_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.new_amazon_customers
          ELSE NULL
          END) AS new_amazon_customers_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Returning_shopify_customers
          ELSE NULL
          END) AS Returning_shopify_customers_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Returning_shopify_customers
          ELSE NULL
          END) AS Returning_shopify_customers_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Returning_shopify_customers
          ELSE NULL
          END) AS Returning_shopify_customers_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Returning_shopify_customers
          ELSE NULL
          END) AS Returning_shopify_customers_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.new_subscribers_recharge
          ELSE NULL
          END) AS new_subscribers_recharge_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.new_subscribers_recharge
          ELSE NULL
          END) AS new_subscribers_recharge_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.new_subscribers_recharge
          ELSE NULL
          END) AS new_subscribers_recharge_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.new_subscribers_recharge
          ELSE NULL
          END) AS new_subscribers_recharge_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.active_subscribers_recharge
          ELSE NULL
          END) AS active_subscribers_recharge_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.active_subscribers_recharge
          ELSE NULL
          END) AS active_subscribers_recharge_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.active_subscribers_recharge
          ELSE NULL
          END) AS active_subscribers_recharge_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.active_subscribers_recharge
          ELSE NULL
          END) AS active_subscribers_recharge_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.churned_subscribers_recharge
          ELSE NULL
          END) AS churned_subscribers_recharge_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.churned_subscribers_recharge
          ELSE NULL
          END) AS churned_subscribers_recharge_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.churned_subscribers_recharge
          ELSE NULL
          END) AS churned_subscribers_recharge_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.churned_subscribers_recharge
          ELSE NULL
          END) AS churned_subscribers_recharge_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.reactivated_subscribers_recharge
          ELSE NULL
          END) AS reactivated_subscribers_recharge_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.reactivated_subscribers_recharge
          ELSE NULL
          END) AS reactivated_subscribers_recharge_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.reactivated_subscribers_recharge
          ELSE NULL
          END) AS reactivated_subscribers_recharge_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.reactivated_subscribers_recharge
          ELSE NULL
          END) AS reactivated_subscribers_recharge_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.net_gain_loss_recharge
          ELSE NULL
          END) AS net_gain_loss_recharge_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.net_gain_loss_recharge
          ELSE NULL
          END) AS net_gain_loss_recharge_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.net_gain_loss_recharge
          ELSE NULL
          END) AS net_gain_loss_recharge_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.net_gain_loss_recharge
          ELSE NULL
          END) AS net_gain_loss_recharge_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.active_subscriptions_recharge
          ELSE NULL
          END) AS active_subscriptions_recharge_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.active_subscriptions_recharge
          ELSE NULL
          END) AS active_subscriptions_recharge_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.active_subscriptions_recharge
          ELSE NULL
          END) AS active_subscriptions_recharge_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.active_subscriptions_recharge
          ELSE NULL
          END) AS active_subscriptions_recharge_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.avg_active_days_per_subscriber_recharge
          ELSE NULL
          END) AS avg_active_days_per_subscriber_recharge_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.avg_active_days_per_subscriber_recharge
          ELSE NULL
          END) AS avg_active_days_per_subscriber_recharge_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.avg_active_days_per_subscriber_recharge
          ELSE NULL
          END) AS avg_active_days_per_subscriber_recharge_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.avg_active_days_per_subscriber_recharge
          ELSE NULL
          END) AS avg_active_days_per_subscriber_recharge_MTD,

      -- ORDER METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_orders
          ELSE NULL
          END) AS shopify_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_orders
          ELSE NULL
          END) AS shopify_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_orders
          ELSE NULL
          END) AS shopify_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_orders
          ELSE NULL
          END) AS shopify_orders_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.new_shopify_orders
          ELSE NULL
          END) AS new_shopify_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.new_shopify_orders
          ELSE NULL
          END) AS new_shopify_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.new_shopify_orders
          ELSE NULL
          END) AS new_shopify_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.new_shopify_orders
          ELSE NULL
          END) AS new_shopify_orders_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Returning_shopify_orders
          ELSE NULL
          END) AS Returning_shopify_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Returning_shopify_orders
          ELSE NULL
          END) AS Returning_shopify_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Returning_shopify_orders
          ELSE NULL
          END) AS Returning_shopify_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Returning_shopify_orders
          ELSE NULL
          END) AS Returning_shopify_orders_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Amazon_orders
          ELSE NULL
          END) AS Amazon_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Amazon_orders
          ELSE NULL
          END) AS Amazon_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Amazon_orders
          ELSE NULL
          END) AS Amazon_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Amazon_orders
          ELSE NULL
          END) AS Amazon_orders_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.TikTok_orders
          ELSE NULL
          END) AS TikTok_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.TikTok_orders
          ELSE NULL
          END) AS TikTok_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.TikTok_orders
          ELSE NULL
          END) AS TikTok_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.TikTok_orders
          ELSE NULL
          END) AS TikTok_orders_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.walmart_orders
          ELSE NULL
          END) AS walmart_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.walmart_orders
          ELSE NULL
          END) AS walmart_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.walmart_orders
          ELSE NULL
          END) AS walmart_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.walmart_orders
          ELSE NULL
          END) AS walmart_orders_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.target_orders
          ELSE NULL
          END) AS target_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.target_orders
          ELSE NULL
          END) AS target_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.target_orders
          ELSE NULL
          END) AS target_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.target_orders
          ELSE NULL
          END) AS target_orders_MTD,

      -- AMAZON ORDER METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.sns_ntb_orders
          ELSE NULL
          END) AS sns_ntb_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.sns_ntb_orders
          ELSE NULL
          END) AS sns_ntb_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.sns_ntb_orders
          ELSE NULL
          END) AS sns_ntb_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.sns_ntb_orders
          ELSE NULL
          END) AS sns_ntb_orders_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.non_sns_ntb_orders
          ELSE NULL
          END) AS non_sns_ntb_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.non_sns_ntb_orders
          ELSE NULL
          END) AS non_sns_ntb_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.non_sns_ntb_orders
          ELSE NULL
          END) AS non_sns_ntb_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.non_sns_ntb_orders
          ELSE NULL
          END) AS non_sns_ntb_orders_MTD,

      -- RETURN METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Returns
          ELSE NULL
          END) AS Returns_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Returns
          ELSE NULL
          END) AS Returns_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Returns
          ELSE NULL
          END) AS Returns_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Returns
          ELSE NULL
          END) AS Returns_MTD,

      -- WEBSITE SESSION METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Online_store_visitors
          ELSE NULL
          END) AS Online_store_visitors_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Online_store_visitors
          ELSE NULL
          END) AS Online_store_visitors_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Online_store_visitors
          ELSE NULL
          END) AS Online_store_visitors_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Online_store_visitors
          ELSE NULL
          END) AS Online_store_visitors_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Sessions_with_cart_additions
          ELSE NULL
          END) AS Sessions_with_cart_additions_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Sessions_with_cart_additions
          ELSE NULL
          END) AS Sessions_with_cart_additions_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Sessions_with_cart_additions
          ELSE NULL
          END) AS Sessions_with_cart_additions_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Sessions_with_cart_additions
          ELSE NULL
          END) AS Sessions_with_cart_additions_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Sessions_that_reached_checkout
          ELSE NULL
          END) AS Sessions_that_reached_checkout_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Sessions_that_reached_checkout
          ELSE NULL
          END) AS Sessions_that_reached_checkout_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Sessions_that_reached_checkout
          ELSE NULL
          END) AS Sessions_that_reached_checkout_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Sessions_that_reached_checkout
          ELSE NULL
          END) AS Sessions_that_reached_checkout_MTD, 

  --     avg(case when Date between date_sub(LatestDate, interval 6 day) and LatestDate then Sessions_that_completed_checkout else null end) Sessions_that_completed_checkout_L7,
  -- avg(case when Date between date_sub(LatestDate, interval 13 day) and LatestDate then Sessions_that_completed_checkout else null end) Sessions_that_completed_checkout_L14,
  -- avg(case when Date between date_sub(LatestDate, interval 29 day) and LatestDate then Sessions_that_completed_checkout else null end) Sessions_that_completed_checkout_L30,
  -- avg(case when Date between MonthStart and LatestDate then Sessions_that_completed_checkout else null end) Sessions_that_completed_checkout_MTD, 

  avg(
  CASE
    WHEN
      cdj.date
      BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
      AND ms.latest_date
      THEN cdj.Sessions_that_completed_checkout
    ELSE NULL
    END) AS Sessions_that_completed_checkout_L7,
avg(
  CASE
    WHEN
      cdj.date
      BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
      AND ms.latest_date
      THEN cdj.Sessions_that_completed_checkout
    ELSE NULL
    END) AS Sessions_that_completed_checkout_L14,
avg(
  CASE
    WHEN
      cdj.date
      BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
      AND ms.latest_date
      THEN cdj.Sessions_that_completed_checkout
    ELSE NULL
    END) AS Sessions_that_completed_checkout_L30,
avg(
  CASE
    WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
      THEN cdj.Sessions_that_completed_checkout
    ELSE NULL
    END) AS Sessions_that_completed_checkout_MTD,


      avg(case when cdj.date between date_sub(ms.latest_date, interval 6 day) and ms.latest_date then cdj.Sessions else null end) as Sessions_L7,
      avg(case when cdj.date between date_sub(ms.latest_date, interval 13 day) and ms.latest_date then cdj.Sessions else null end) as Sessions_L14,
      avg(case when cdj.date between date_sub(ms.latest_date, interval 29 day) and ms.latest_date then cdj.Sessions else null end) as Sessions_L30,
      avg(case when cdj.date between ms.month_start_date and ms.latest_date then cdj.Sessions else null end) as Sessions_MTD,

      -- SPENDS AGAINST SALES METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.firsttime_customer_shopify_orders_SpendAgainstSales
          ELSE NULL
          END) AS firsttime_customer_shopify_orders_SpendAgainstSales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.firsttime_customer_shopify_orders_SpendAgainstSales
          ELSE NULL
          END) AS firsttime_customer_shopify_orders_SpendAgainstSales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.firsttime_customer_shopify_orders_SpendAgainstSales
          ELSE NULL
          END) AS firsttime_customer_shopify_orders_SpendAgainstSales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.firsttime_customer_shopify_orders_SpendAgainstSales
          ELSE NULL
          END) AS firsttime_customer_shopify_orders_SpendAgainstSales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_orders_SpendAgainstSales
          ELSE NULL
          END) AS shopify_orders_SpendAgainstSales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_orders_SpendAgainstSales
          ELSE NULL
          END) AS shopify_orders_SpendAgainstSales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_orders_SpendAgainstSales
          ELSE NULL
          END) AS shopify_orders_SpendAgainstSales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_orders_SpendAgainstSales
          ELSE NULL
          END) AS shopify_orders_SpendAgainstSales_MTD,

      -- TIKTOK SHOP SUBSCRIPTION METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.active_subscriptions_TTS
          ELSE NULL
          END) AS active_subscriptions_TTS_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.active_subscriptions_TTS
          ELSE NULL
          END) AS active_subscriptions_TTS_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.active_subscriptions_TTS
          ELSE NULL
          END) AS active_subscriptions_TTS_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.active_subscriptions_TTS
          ELSE NULL
          END) AS active_subscriptions_TTS_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.active_subscribers_TTS
          ELSE NULL
          END) AS active_subscribers_TTS_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.active_subscribers_TTS
          ELSE NULL
          END) AS active_subscribers_TTS_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.active_subscribers_TTS
          ELSE NULL
          END) AS active_subscribers_TTS_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.active_subscribers_TTS
          ELSE NULL
          END) AS active_subscribers_TTS_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.new_subscriptions_TTS
          ELSE NULL
          END) AS new_subscriptions_TTS_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.new_subscriptions_TTS
          ELSE NULL
          END) AS new_subscriptions_TTS_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.new_subscriptions_TTS
          ELSE NULL
          END) AS new_subscriptions_TTS_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.new_subscriptions_TTS
          ELSE NULL
          END) AS new_subscriptions_TTS_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.churn_TTS
          ELSE NULL
          END) AS churn_TTS_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.churn_TTS
          ELSE NULL
          END) AS churn_TTS_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.churn_TTS
          ELSE NULL
          END) AS churn_TTS_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.churn_TTS
          ELSE NULL
          END) AS churn_TTS_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.net_gain_loss_TTS
          ELSE NULL
          END) AS net_gain_loss_TTS_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.net_gain_loss_TTS
          ELSE NULL
          END) AS net_gain_loss_TTS_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.net_gain_loss_TTS
          ELSE NULL
          END) AS net_gain_loss_TTS_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.net_gain_loss_TTS
          ELSE NULL
          END) AS net_gain_loss_TTS_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.subs_aov_TTS
          ELSE NULL
          END) AS subs_aov_TTS_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.subs_aov_TTS
          ELSE NULL
          END) AS subs_aov_TTS_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.subs_aov_TTS
          ELSE NULL
          END) AS subs_aov_TTS_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.subs_aov_TTS
          ELSE NULL
          END) AS subs_aov_TTS_MTD,

      -- COST METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_item_discount
          ELSE NULL
          END) AS shopify_item_discount_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_item_discount
          ELSE NULL
          END) AS shopify_item_discount_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_item_discount
          ELSE NULL
          END) AS shopify_item_discount_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_item_discount
          ELSE NULL
          END) AS shopify_item_discount_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_refunded_amount_by_return_date
          ELSE NULL
          END) AS shopify_refunded_amount_by_return_date_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_refunded_amount_by_return_date
          ELSE NULL
          END) AS shopify_refunded_amount_by_return_date_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_refunded_amount_by_return_date
          ELSE NULL
          END) AS shopify_refunded_amount_by_return_date_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_refunded_amount_by_return_date
          ELSE NULL
          END) AS shopify_refunded_amount_by_return_date_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_item_shipping_price
          ELSE NULL
          END) AS shopify_item_shipping_price_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_item_shipping_price
          ELSE NULL
          END) AS shopify_item_shipping_price_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_item_shipping_price
          ELSE NULL
          END) AS shopify_item_shipping_price_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_item_shipping_price
          ELSE NULL
          END) AS shopify_item_shipping_price_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_item_total_tax
          ELSE NULL
          END) AS shopify_item_total_tax_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_item_total_tax
          ELSE NULL
          END) AS shopify_item_total_tax_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_item_total_tax
          ELSE NULL
          END) AS shopify_item_total_tax_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_item_total_tax
          ELSE NULL
          END) AS shopify_item_total_tax_MTD
    FROM CompleteDataJoin cdj
    CROSS JOIN MonthStartCTE ms
    GROUP BY cdj.store_name
  ),

  -- Union of daily data and period averages
  FinalResults AS (

    -- Daily data with original date
    SELECT
      CAST(date AS string) AS date,
      store_name,
      Total_Sales,
      Website_Sales,
      Amazon_Sales,
      Tiktok_Sales,
      Walmart_Sales,
      Target_Sales,

      -- Applovin_Adsales as Applovin_Sales,
      dsp_sales AS DSP_Sales,
      safe_divide(NTB_Sales, Total_Sales) AS NTB_Sales_Perc,
      spend AS Total_Spend,
      Shopify_AdSpend AS Website_Spend,
      shopify_tof_adspend AS Website_TOF_Spend,
      shopify_non_tof_adspend AS Website_Spend_w_o_TOF,
      meta_non_tof_adspend AS Meta_Spend_w_o_TOF,
      meta_tof_adspend AS Meta_TOF_Spend,
      youtube_non_tof_adspend AS YouTube_Spend_w_o_TOF,
      youtube_tof_adspend AS YouTube_TOF_Spend,
      google_sands_spend AS Google_S_S_Spend,
      google_adspend AS Google_AdSpend,
      google_search_adspend AS Google_Search_Spend,
      google_shopping_adspend AS Google_Shopping_Spend,
      google_performance_max_adspend AS Google_Pmax_Spend,
      amazon_adspend AS Amazon_Spend,
      tiktok_adspend AS TikTok_Spend,
      TikTokSpend_GMV_Max AS TikTok_Spend_GMV_Max,
      TikTokSpend_Campaign AS TikTok_Spend_Campaign,
      tiktok_tof_adspend AS TikTok_TOF_Spend,

      -- Applovin_AdSpend as Applovin_Spend,
      walmart_adspend AS Walmart_Spend,
      dsp_adspend AS DSP_Spend,
      safe_divide(shopify_non_tof_adspend, new_shopify_customers) AS DTC_NCPA,
      safe_divide(shopify_tof_adspend, new_shopify_customers) AS TOF_DTC_NCPA,
      safe_divide(
        Amz_Shopify_AdSpend, (new_shopify_customers + new_amazon_customers))
        AS Blended_CAC,
      triple_whale_meta_cac_first_touch_7d AS Meta_CAC_First_Touch_7D,
      triple_whale_meta_cac_last_touch_7d AS Meta_CAC_Last_Touch_7D,
      triple_whale_meta_cac_triple_att_7d AS Meta_CAC_Triple_Att_7D,
      meta_in_app_cpa AS Meta_In_App_CPA,
      triple_whale_meta_ncp_first_click AS Meta_NCP_First_Click,
      triple_whale_meta_ncp_lat_click AS Meta_NCP_Last_Click,
      triple_whale_meta_ncp_triple_att_7d AS Meta_NCP_Triple_Att_7D,
      meta_inapp_purchases AS Meta_In_App_Purchases,
      safe_divide(triple_whale_meta_ncp_triple_att_7d, new_shopify_orders)
        AS Meta_NCP_New_Orders_Shopify_Ratio,
      safe_divide(meta_inapp_purchases, shopify_orders)
        AS Meta_In_App_Purchases_Orders_Shopify_Ratio,
      safe_divide(meta_adspend, Shopify_AdSpend)
        AS Meta_Spend_Total_Website_Spend,
      safe_divide(triple_whale_meta_ncp_triple_att_7d, meta_inapp_purchases)
        AS Meta_NCP_In_App_Purchases_Ratio,
      triple_whale_google_cac_first_touch_7d AS Google_CAC_First_Touch_7D,
      triple_whale_google_cac_last_touch_7d AS Google_CAC_Last_Touch_7D,
      triple_whale_google_cac_triple_att_7d AS Google_CAC_Triple_Att_7D,
      dg_first_touch_7d AS DG_First_Touch_7D,
      dg_last_touch_7d AS DG_Last_Touch_7D,
      dg_triple_att_7d AS DG_Triple_Att_7D,
      prospecting_first_touch_7d AS Prospecting_First_Touch_7D,
      prospecting_last_touch_7d AS Prospecting_Last_Touch_7D,
      prospecting_triple_att_7d AS Prospecting_Triple_Att_7D,
      brand_first_touch_7d AS Brand_First_Touch_7D,
      brand_last_touch_7d AS Brand_Last_Touch_7D,
      brand_triple_att_7d AS Brand_Triple_Att_7D,
      safe_divide(Shopify_AdSpend, Website_Sales) AS Website_TACOS,
      safe_divide(amazon_adspend, Amazon_Sales) AS Amazon_TACOS,
      safe_divide(tiktok_adspend, Tiktok_Sales) AS TikTok_TACOS,

      -- safe_divide(new_subscribers_recharge, new_shopify_customers) as N_Sub_Perc,
      safe_divide(NTB_Shopify_Sales, shopify_non_tof_adspend) AS aMER,
      safe_divide(shopify_non_tof_adspend, Website_Sales) AS MER,
      safe_divide(NTB_Amz_Shopify_Sales, (amazon_adspend + Shopify_AdSpend))
        AS NTB_aMER,
      sns_ntb_amazon_net_sales AS SNS_NTB_Sales,
      non_sns_ntb_amazon_net_sales AS NON_SNS_NTB_Sales,
      sns_ntb_orders AS SNS_NTB_Orders,
      non_sns_ntb_orders AS NON_SNS_NTB_Orders,
      Website_Sales AS Total_Sales_Website,
      NTB_Shopify_Net_Sales AS First_Time_Customer_Net_Sales,
      NTB_Shopify_Sales AS First_Time_Customer_Sales,
      Returning_Shopify_Sales AS Returning_Customer_Sales,
      shopify_customers AS Total_Customers,
      new_shopify_customers AS First_Time_Customers,
      Returning_shopify_customers AS Returning_Customers,

      -- new_subscribers_recharge as New_Subscribers,
      -- safe_divide(new_subscribers_recharge, new_shopify_customers) as New_Subscribers_Perc,
      new_shopify_orders AS New_Orders,
      Returning_shopify_orders AS Returning_Orders,
      shopify_orders AS Shopify_Orders,
      walmart_orders AS Walmart_Orders,
      Amazon_orders AS Amazon_Orders,
      TikTok_orders AS TikTok_Orders,
      target_orders AS Target_Orders,
      safe_divide(Amazon_Sales, Amazon_orders) AS Amazon_AOV,
      safe_divide(Tiktok_Sales, TikTok_orders) AS TikTok_AOV,
      safe_divide(Walmart_Sales, walmart_orders) AS Walmart_AOV,
      safe_divide(Target_Sales, target_orders) AS Target_AOV,
      safe_divide(NTB_Shopify_Net_Sales, new_shopify_orders) AS N_AOV_Net_Sales,
      safe_divide(NTB_Shopify_Sales, new_shopify_orders) AS N_AOV,
      safe_divide(Returning_Shopify_Sales, Returning_shopify_orders) AS R_AOV,
      safe_divide(Shopify_AdSpend, Website_Sales) AS ACOS,
      safe_divide(Shopify_AdSpend, Total_Sales) AS TACOS_Website,
      Returns,
      safe_divide(Returns, shopify_orders) AS Return_Rate_Perc,
      safe_divide(Website_Sales, Shopify_AdSpend) AS MER_Website,
      safe_divide(Shopify_AdSpend, shopify_clicks) AS CPC,
      Online_store_visitors AS Visitors,
      Sessions AS Sessions,

      -- safe_divide(new_shopify_customers, Online_store_visitors) as CVR,
      -- safe_divide(Shopify_AdSpend, Online_store_visitors) as CPV,
      -- safe_divide(NTB_Shopify_Sales, Online_store_visitors) as N_RPV,
      -- safe_divide(Website_Sales, Online_store_visitors) as RPV,
      Sessions_with_cart_additions AS ATC,

      -- safe_divide(spend, (reach/1000)) as CPMr,
      -- safe_divide(Shopify_AdSpend, Sessions_with_cart_additions) as Cost_per_ATC,
      safe_divide(Sessions_with_cart_additions, Online_store_visitors)
        AS ATC_Perc,
      safe_divide(new_shopify_orders, Sessions_with_cart_additions)
        AS ATC_to_PU_Perc,
      Sessions_that_reached_checkout AS Initiated_Check_Out,
      Sessions_that_completed_checkout AS Completed_Check_Out,

      -- safe_divide(Shopify_AdSpend, Sessions_that_reached_checkout) as Cost_per_Initiated_Check_Out,
      safe_divide(new_shopify_orders, Sessions_that_reached_checkout)
        AS IC_to_PU_Perc,
      safe_divide(Sessions_that_reached_checkout, Sessions_with_cart_additions)
        AS ATC_to_IC_Perc,
      active_subscribers_recharge AS Active_Subscribers,
      new_subscribers_recharge AS New_Subscribers_Recharge,
      churned_subscribers_recharge AS Churned_Subscribers,
      reactivated_subscribers_recharge AS Reactivated_Subscribers,
      net_gain_loss_recharge AS Net_Gain_Loss,
      safe_divide(active_subscriptions_recharge, active_subscribers_recharge)
        AS Avg_Subscriptions_per_Active_Subscriber,
      safe_divide(shopify_orders, active_subscribers_recharge)
        AS Avg_Orders_per_Active_Subscriber,
      avg_active_days_per_subscriber_recharge AS Avg_Active_Days_per_Subscriber,

      -- active_subscriptions_TTS as Active_Subscriptions_TTS,
      -- active_subscribers_TTS as Active_Subscribers_TTS,
      -- new_subscriptions_TTS as New_Subscriptions_TTS,
      -- churn_TTS as Churned_Subscriptions_TTS,
      -- net_gain_loss_TTS as Net_Gain_Loss_TTS,
      -- subs_aov_TTS as Subscription_AOV_TTS,
      safe_divide(shopify_item_discount, shopify_orders) AS Discount_Per_Order,
      safe_divide(shopify_refunded_amount_by_return_date, shopify_orders)
        AS Return_Amount_Per_Order,
      safe_divide(shopify_item_shipping_price, shopify_orders)
        AS Shipping_Charge_Per_Order,
      safe_divide(shopify_item_total_tax, shopify_orders) AS Tax_Per_Order
    FROM CompleteDataJoin
    UNION ALL

    -- L7 Average row for each store
    SELECT
      'L7 AVG' AS date,
      pa.store_name,
      pa.Total_Sales_L7,
      pa.Website_Sales_L7,
      pa.Amazon_Sales_L7,
      pa.Tiktok_Sales_L7,
      pa.Walmart_Sales_L7,
      pa.Target_Sales_L7,

      -- pa.Applovin_Adsales_L7,
      pa.dsp_sales_L7,
      safe_divide(pa.NTB_Sales_L7, pa.Total_Sales_L7) AS NTB_Sales_Perc,
      pa.spend_L7,
      pa.Shopify_AdSpend_L7,
      pa.shopify_tof_adspend_L7,
      pa.shopify_non_tof_adspend_L7,
      pa.meta_non_tof_adspend_L7,
      pa.meta_tof_adspend_L7,
      pa.youtube_non_tof_adspend_L7,
      pa.youtube_tof_adspend_L7,
      pa.google_sands_spend_L7,
      pa.google_adspend_L7,
      pa.google_search_adspend_L7,
      pa.google_shopping_adspend_L7,
      pa.google_performance_max_adspend_L7,
      pa.amazon_adspend_L7,
      pa.tiktok_adspend_L7,
      pa.TikTokSpend_GMV_Max_L7,
      pa.TikTokSpend_Campaign_L7,
      pa.tiktok_tof_adspend_L7,

      -- pa.Applovin_AdSpend_L7,
      pa.walmart_adspend_L7,
      pa.dsp_adspend_L7,
      safe_divide(pa.shopify_non_tof_adspend_L7, pa.new_shopify_customers_L7)
        AS DTC_NCPA,
      safe_divide(pa.shopify_tof_adspend_L7, pa.new_shopify_customers_L7)
        AS TOF_DTC_NCPA,
      safe_divide(
        pa.Amz_Shopify_AdSpend_L7,
        (pa.new_shopify_customers_L7 + pa.new_amazon_customers_L7))
        AS Blended_CAC,
      pa.triple_whale_meta_cac_first_touch_7d_L7,
      pa.triple_whale_meta_cac_last_touch_7d_L7,
      pa.triple_whale_meta_cac_triple_att_7d_L7,
      pa.meta_in_app_cpa_L7,
      pa.triple_whale_meta_ncp_first_click_L7,
      pa.triple_whale_meta_ncp_lat_click_L7,
      pa.triple_whale_meta_ncp_triple_att_7d_L7,
      pa.meta_inapp_purchases_L7,
      safe_divide(
        pa.triple_whale_meta_ncp_triple_att_7d_L7, pa.new_shopify_orders_L7)
        AS Meta_NCP_New_Orders_Shopify_Ratio,
      safe_divide(pa.meta_inapp_purchases_L7, pa.shopify_orders_L7)
        AS Meta_In_App_Purchases_Orders_Shopify_Ratio,
      safe_divide(pa.meta_adspend_L7, pa.Shopify_AdSpend_L7)
        AS Meta_Spend_Total_Website_Spend,
      safe_divide(
        pa.triple_whale_meta_ncp_triple_att_7d_L7, pa.meta_inapp_purchases_L7)
        AS Meta_NCP_In_App_Purchases_Ratio,
      pa.triple_whale_google_cac_first_touch_7d_L7,
      pa.triple_whale_google_cac_last_touch_7d_L7,
      pa.triple_whale_google_cac_triple_att_7d_L7,
      pa.dg_first_touch_7d_L7,
      pa.dg_last_touch_7d_L7,
      pa.dg_triple_att_7d_L7,
      pa.prospecting_first_touch_7d_L7,
      pa.prospecting_last_touch_7d_L7,
      pa.prospecting_triple_att_7d_L7,
      pa.brand_first_touch_7d_L7,
      pa.brand_last_touch_7d_L7,
      pa.brand_triple_att_7d_L7,
      safe_divide(pa.Shopify_AdSpend_L7, pa.Website_Sales_L7) AS Website_TACOS,
      safe_divide(pa.amazon_adspend_L7, pa.Amazon_Sales_L7) AS Amazon_TACOS,
      safe_divide(pa.tiktok_adspend_L7, pa.Tiktok_Sales_L7) AS TikTok_TACOS,

      -- safe_divide(pa.new_subscribers_recharge_L7, pa.new_shopify_customers_L7) as N_Sub_Perc,
      safe_divide(pa.NTB_Shopify_Sales_L7, pa.shopify_non_tof_adspend_L7)
        AS aMER,
      safe_divide(pa.shopify_non_tof_adspend_L7, pa.Website_Sales_L7) AS MER,
      safe_divide(
        pa.NTB_Amz_Shopify_Sales_L7,
        (pa.amazon_adspend_L7 + pa.Shopify_AdSpend_L7)) AS NTB_aMER,
      pa.sns_ntb_amazon_net_sales_L7,
      pa.non_sns_ntb_amazon_net_sales_L7,
      pa.sns_ntb_orders_L7,
      pa.non_sns_ntb_orders_L7,
      pa.Website_Sales_L7 AS Total_Sales_Website,
      pa.NTB_Shopify_Net_Sales_L7 AS First_Time_Customer_Net_Sales,
      pa.NTB_Shopify_Sales_L7 AS First_Time_Customer_Sales,
      pa.Returning_Shopify_Sales_L7 AS Returning_Customer_Sales,
      pa.shopify_customers_L7 AS Total_Customers,
      pa.new_shopify_customers_L7 AS First_Time_Customers,
      pa.Returning_shopify_customers_L7 AS Returning_Customers,

      -- pa.new_subscribers_recharge_L7 as New_Subscribers,
      -- safe_divide(pa.new_subscribers_recharge_L7, pa.new_shopify_customers_L7) as New_Subscribers_Perc,
      pa.new_shopify_orders_L7 AS New_Orders,
      pa.Returning_shopify_orders_L7 AS Returning_Orders,
      pa.shopify_orders_L7 AS Shopify_Orders,
      pa.walmart_orders_L7 AS Walmart_Orders,
      pa.Amazon_orders_L7 AS Amazon_Orders,
      pa.TikTok_orders_L7 AS TikTok_Orders,
      pa.target_orders_L7 AS Target_Orders,
      safe_divide(pa.Amazon_Sales_L7, pa.Amazon_orders_L7) AS Amazon_AOV,
      safe_divide(pa.Tiktok_Sales_L7, pa.TikTok_orders_L7) AS TikTok_AOV,
      safe_divide(pa.Walmart_Sales_L7, pa.walmart_orders_L7) AS Walmart_AOV,
      safe_divide(pa.Target_Sales_L7, pa.target_orders_L7) AS Target_AOV,
      safe_divide(pa.NTB_Shopify_Net_Sales_L7, pa.new_shopify_orders_L7)
        AS N_AOV_Net_Sales,
      safe_divide(pa.NTB_Shopify_Sales_L7, pa.new_shopify_orders_L7) AS N_AOV,
      safe_divide(pa.Returning_Shopify_Sales_L7, pa.Returning_shopify_orders_L7)
        AS R_AOV,
      safe_divide(pa.Shopify_AdSpend_L7, pa.Website_Sales_L7) AS ACOS,
      safe_divide(pa.Shopify_AdSpend_L7, pa.Total_Sales_L7) AS TACOS_Website,
      pa.Returns_L7,
      safe_divide(pa.Returns_L7, pa.shopify_orders_L7) AS Return_Rate_Perc,
      safe_divide(pa.Website_Sales_L7, pa.Shopify_AdSpend_L7) AS MER_Website,
      safe_divide(pa.Shopify_AdSpend_L7, pa.shopify_clicks_L7) AS CPC,
      pa.Online_store_visitors_L7 AS Visitors,
      pa.Sessions_L7 AS Sessions,

      -- safe_divide(pa.new_shopify_customers_L7, pa.Online_store_visitors_L7) as CVR,
      -- safe_divide(pa.Shopify_AdSpend_L7, pa.Online_store_visitors_L7) as CPV,
      -- safe_divide(pa.NTB_Shopify_Sales_L7, pa.Online_store_visitors_L7) as N_RPV,
      -- safe_divide(pa.Website_Sales_L7, pa.Online_store_visitors_L7) as RPV,
      pa.Sessions_with_cart_additions_L7 AS ATC,

      -- safe_divide(pa.spend_L7, (pa.reach_L7/1000)) as CPMr,
      -- safe_divide(pa.Shopify_AdSpend_L7, pa.Sessions_with_cart_additions_L7) as Cost_per_ATC,
      safe_divide(
        pa.Sessions_with_cart_additions_L7, pa.Online_store_visitors_L7)
        AS ATC_Perc,
      safe_divide(pa.new_shopify_orders_L7, pa.Sessions_with_cart_additions_L7)
        AS ATC_to_PU_Perc,
      pa.Sessions_that_reached_checkout_L7 AS Initiated_Check_Out,
      pa.Sessions_that_completed_checkout_L7 AS Completed_Check_Out,

      -- safe_divide(pa.Shopify_AdSpend_L7, pa.Sessions_that_reached_checkout_L7) as Cost_per_Initiated_Check_Out,
      safe_divide(
        pa.new_shopify_orders_L7, pa.Sessions_that_reached_checkout_L7)
        AS IC_to_PU_Perc,
      safe_divide(
        pa.Sessions_that_reached_checkout_L7,
        
        pa.Sessions_with_cart_additions_L7) AS ATC_to_IC_Perc,
      pa.active_subscribers_recharge_L7 AS Active_Subscribers,
      pa.new_subscribers_recharge_L7 AS New_Subscribers_Recharge,
      pa.churned_subscribers_recharge_L7 AS Churned_Subscribers,
      pa.reactivated_subscribers_recharge_L7 AS Reactivated_Subscribers,
      pa.net_gain_loss_recharge_L7 AS Net_Gain_Loss,
      safe_divide(
        pa.active_subscriptions_recharge_L7, pa.active_subscribers_recharge_L7)
        AS Avg_Subscriptions_per_Active_Subscriber,
      safe_divide(pa.shopify_orders_L7, pa.active_subscribers_recharge_L7)
        AS Avg_Orders_per_Active_Subscriber,
      pa.avg_active_days_per_subscriber_recharge_L7
        AS Avg_Active_Days_per_Subscriber,

      -- pa.active_subscriptions_TTS_L7 as Active_Subscriptions_TTS,
      -- pa.active_subscribers_TTS_L7 as Active_Subscribers_TTS,
      -- pa.new_subscriptions_TTS_L7 as New_Subscriptions_TTS,
      -- pa.churn_TTS_L7 as Churned_Subscriptions_TTS,
      -- pa.net_gain_loss_TTS_L7 as Net_Gain_Loss_TTS,
      -- pa.subs_aov_TTS_L7 as Subscription_AOV_TTS,
      safe_divide(pa.shopify_item_discount_L7, pa.shopify_orders_L7)
        AS Discount_Per_Order,
      safe_divide(
        pa.shopify_refunded_amount_by_return_date_L7, pa.shopify_orders_L7)
        AS Return_Amount_Per_Order,
      safe_divide(pa.shopify_item_shipping_price_L7, pa.shopify_orders_L7)
        AS Shipping_Charge_Per_Order,
      safe_divide(pa.shopify_item_total_tax_L7, pa.shopify_orders_L7)
        AS Tax_Per_Order
    FROM PeriodAverages pa
    CROSS JOIN MonthStartCTE ms
    UNION ALL

    -- L14 Average row for each store
    SELECT
      'L14 AVG' AS date,
      pa.store_name,
      pa.Total_Sales_L14,
      pa.Website_Sales_L14,
      pa.Amazon_Sales_L14,
      pa.Tiktok_Sales_L14,
      pa.Walmart_Sales_L14,
      pa.Target_Sales_L14,

      -- pa.Applovin_Adsales_L14,
      pa.dsp_sales_L14,
      safe_divide(pa.NTB_Sales_L14, pa.Total_Sales_L14) AS NTB_Sales_Perc,
      pa.spend_L14,
      pa.Shopify_AdSpend_L14,
      pa.shopify_tof_adspend_L14,
      pa.shopify_non_tof_adspend_L14,
      pa.meta_non_tof_adspend_L14,
      pa.meta_tof_adspend_L14,
      pa.youtube_non_tof_adspend_L14,
      pa.youtube_tof_adspend_L14,
      pa.google_sands_spend_L14,
      pa.google_adspend_L14,
      pa.google_search_adspend_L14,
      pa.google_shopping_adspend_L14,
      pa.google_performance_max_adspend_L14,
      pa.amazon_adspend_L14,
      pa.tiktok_adspend_L14,
      pa.TikTokSpend_GMV_Max_L14,
      pa.TikTokSpend_Campaign_L14,
      pa.tiktok_tof_adspend_L14,

      -- pa.Applovin_AdSpend_L14,
      pa.walmart_adspend_L14,
      pa.dsp_adspend_L14,
      safe_divide(pa.shopify_non_tof_adspend_L14, pa.new_shopify_customers_L14)
        AS DTC_NCPA,
      safe_divide(pa.shopify_tof_adspend_L14, pa.new_shopify_customers_L14)
        AS TOF_DTC_NCPA,
      safe_divide(
        pa.Amz_Shopify_AdSpend_L14,
        (pa.new_shopify_customers_L14 + pa.new_amazon_customers_L14))
        AS Blended_CAC,
      pa.triple_whale_meta_cac_first_touch_7d_L14,
      pa.triple_whale_meta_cac_last_touch_7d_L14,
      pa.triple_whale_meta_cac_triple_att_7d_L14,
      pa.meta_in_app_cpa_L14,
      pa.triple_whale_meta_ncp_first_click_L14,
      pa.triple_whale_meta_ncp_lat_click_L14,
      pa.triple_whale_meta_ncp_triple_att_7d_L14,
      pa.meta_inapp_purchases_L14,
      safe_divide(
        pa.triple_whale_meta_ncp_triple_att_7d_L14, pa.new_shopify_orders_L14)
        AS Meta_NCP_New_Orders_Shopify_Ratio,
      safe_divide(pa.meta_inapp_purchases_L14, pa.shopify_orders_L14)
        AS Meta_In_App_Purchases_Orders_Shopify_Ratio,
      safe_divide(pa.meta_adspend_L14, pa.Shopify_AdSpend_L14)
        AS Meta_Spend_Total_Website_Spend,
      safe_divide(
        pa.triple_whale_meta_ncp_triple_att_7d_L14, pa.meta_inapp_purchases_L14)
        AS Meta_NCP_In_App_Purchases_Ratio,
      pa.triple_whale_google_cac_first_touch_7d_L14,
      pa.triple_whale_google_cac_last_touch_7d_L14,
      pa.triple_whale_google_cac_triple_att_7d_L14,
      pa.dg_first_touch_7d_L14,
      pa.dg_last_touch_7d_L14,
      pa.dg_triple_att_7d_L14,
      pa.prospecting_first_touch_7d_L14,
      pa.prospecting_last_touch_7d_L14,
      pa.prospecting_triple_att_7d_L14,
      pa.brand_first_touch_7d_L14,
      pa.brand_last_touch_7d_L14,
      pa.brand_triple_att_7d_L14,
      safe_divide(pa.Shopify_AdSpend_L14, pa.Website_Sales_L14)
        AS Website_TACOS,
      safe_divide(pa.amazon_adspend_L14, pa.Amazon_Sales_L14) AS Amazon_TACOS,
      safe_divide(pa.tiktok_adspend_L14, pa.Tiktok_Sales_L14) AS TikTok_TACOS,

      -- safe_divide(pa.new_subscribers_recharge_L14, pa.new_shopify_customers_L14) as N_Sub_Perc,
      safe_divide(pa.NTB_Shopify_Sales_L14, pa.shopify_non_tof_adspend_L14)
        AS aMER,
      safe_divide(pa.shopify_non_tof_adspend_L14, pa.Website_Sales_L14) AS MER,
      safe_divide(
        pa.NTB_Amz_Shopify_Sales_L14,
        (pa.amazon_adspend_L14 + pa.Shopify_AdSpend_L14)) AS NTB_aMER,
      pa.sns_ntb_amazon_net_sales_L14,
      pa.non_sns_ntb_amazon_net_sales_L14,
      pa.sns_ntb_orders_L14,
      pa.non_sns_ntb_orders_L14,
      pa.Website_Sales_L14 AS Total_Sales_Website,
      pa.NTB_Shopify_Net_Sales_L14 AS First_Time_Customer_Net_Sales,
      pa.NTB_Shopify_Sales_L14 AS First_Time_Customer_Sales,
      pa.Returning_Shopify_Sales_L14 AS Returning_Customer_Sales,
      pa.shopify_customers_L14 AS Total_Customers,
      pa.new_shopify_customers_L14 AS First_Time_Customers,
      pa.Returning_shopify_customers_L14 AS Returning_Customers,

      -- pa.new_subscribers_recharge_L14 as New_Subscribers,
      -- safe_divide(pa.new_subscribers_recharge_L14, pa.new_shopify_customers_L14) as New_Subscribers_Perc,
      pa.new_shopify_orders_L14 AS New_Orders,
      pa.Returning_shopify_orders_L14 AS Returning_Orders,
      pa.shopify_orders_L14 AS Shopify_Orders,
      pa.walmart_orders_L14 AS Walmart_Orders,
      pa.Amazon_orders_L14 AS Amazon_Orders,
      pa.TikTok_orders_L14 AS TikTok_Orders,
      pa.target_orders_L14 AS Target_Orders,
      safe_divide(pa.Amazon_Sales_L14, pa.Amazon_orders_L14) AS Amazon_AOV,
      safe_divide(pa.Tiktok_Sales_L14, pa.TikTok_orders_L14) AS TikTok_AOV,
      safe_divide(pa.Walmart_Sales_L14, pa.walmart_orders_L14) AS Walmart_AOV,
      safe_divide(pa.Target_Sales_L14, pa.target_orders_L14) AS Target_AOV,
      safe_divide(pa.NTB_Shopify_Net_Sales_L14, pa.new_shopify_orders_L14)
        AS N_AOV_Net_Sales,
      safe_divide(pa.NTB_Shopify_Sales_L14, pa.new_shopify_orders_L14) AS N_AOV,
      safe_divide(
        pa.Returning_Shopify_Sales_L14, pa.Returning_shopify_orders_L14)
        AS R_AOV,
      safe_divide(pa.Shopify_AdSpend_L14, pa.Website_Sales_L14) AS ACOS,
      safe_divide(pa.Shopify_AdSpend_L14, pa.Total_Sales_L14) AS TACOS_Website,
      pa.Returns_L14,
      safe_divide(pa.Returns_L14, pa.shopify_orders_L14) AS Return_Rate_Perc,
      safe_divide(pa.Website_Sales_L14, pa.Shopify_AdSpend_L14) AS MER_Website,
      safe_divide(pa.Shopify_AdSpend_L14, pa.shopify_clicks_L14) AS CPC,
      pa.Online_store_visitors_L14 AS Visitors,
      pa.Sessions_L14 AS Sessions,

      -- safe_divide(pa.new_shopify_customers_L14, pa.Online_store_visitors_L14) as CVR,
      -- safe_divide(pa.Shopify_AdSpend_L14, pa.Online_store_visitors_L14) as CPV,
      -- safe_divide(pa.NTB_Shopify_Sales_L14, pa.Online_store_visitors_L14) as N_RPV,
      -- safe_divide(pa.Website_Sales_L14, pa.Online_store_visitors_L14) as RPV,
      pa.Sessions_with_cart_additions_L14 AS ATC,

      -- safe_divide(pa.spend_L14, (pa.reach_L14/1000)) as CPMr,
      -- safe_divide(pa.Shopify_AdSpend_L14, pa.Sessions_with_cart_additions_L14) as Cost_per_ATC,
      safe_divide(
        pa.Sessions_with_cart_additions_L14, pa.Online_store_visitors_L14)
        AS ATC_Perc,
      safe_divide(
        pa.new_shopify_orders_L14, pa.Sessions_with_cart_additions_L14)
        AS ATC_to_PU_Perc,
      pa.Sessions_that_reached_checkout_L14 AS Initiated_Check_Out,
      pa.Sessions_that_completed_checkout_L14 AS Completed_Check_Out,

      -- safe_divide(pa.Shopify_AdSpend_L14, pa.Sessions_that_reached_checkout_L14) as Cost_per_Initiated_Check_Out,
      safe_divide(
        pa.new_shopify_orders_L14, pa.Sessions_that_reached_checkout_L14)
        AS IC_to_PU_Perc,
      safe_divide(
        pa.Sessions_that_reached_checkout_L14,
        pa.Sessions_with_cart_additions_L14) AS ATC_to_IC_Perc,
      pa.active_subscribers_recharge_L14 AS Active_Subscribers,
      pa.new_subscribers_recharge_L14 AS New_Subscribers_Recharge,
      pa.churned_subscribers_recharge_L14 AS Churned_Subscribers,
      pa.reactivated_subscribers_recharge_L14 AS Reactivated_Subscribers,
      pa.net_gain_loss_recharge_L14 AS Net_Gain_Loss,
      safe_divide(
        pa.active_subscriptions_recharge_L14,
        pa.active_subscribers_recharge_L14)
        AS Avg_Subscriptions_per_Active_Subscriber,
      safe_divide(pa.shopify_orders_L14, pa.active_subscribers_recharge_L14)
        AS Avg_Orders_per_Active_Subscriber,
      pa.avg_active_days_per_subscriber_recharge_L14
        AS Avg_Active_Days_per_Subscriber,

      -- pa.active_subscriptions_TTS_L14 as Active_Subscriptions_TTS,
      -- pa.active_subscribers_TTS_L14 as Active_Subscribers_TTS,
      -- pa.new_subscriptions_TTS_L14 as New_Subscriptions_TTS,
      -- pa.churn_TTS_L14 as Churned_Subscriptions_TTS,
      -- pa.net_gain_loss_TTS_L14 as Net_Gain_Loss_TTS,
      -- pa.subs_aov_TTS_L14 as Subscription_AOV_TTS,
      safe_divide(pa.shopify_item_discount_L14, pa.shopify_orders_L14)
        AS Discount_Per_Order,
      safe_divide(
        pa.shopify_refunded_amount_by_return_date_L14, pa.shopify_orders_L14)
        AS Return_Amount_Per_Order,
      safe_divide(pa.shopify_item_shipping_price_L14, pa.shopify_orders_L14)
        AS Shipping_Charge_Per_Order,
      safe_divide(pa.shopify_item_total_tax_L14, pa.shopify_orders_L14)
        AS Tax_Per_Order
    FROM PeriodAverages pa
    CROSS JOIN MonthStartCTE ms
    UNION ALL

    -- L30 Average row for each store
    SELECT
      'L30 AVG' AS date,
      pa.store_name,
      pa.Total_Sales_L30,
      pa.Website_Sales_L30,
      pa.Amazon_Sales_L30,
      pa.Tiktok_Sales_L30,
      pa.Walmart_Sales_L30,
      pa.Target_Sales_L30,

      -- pa.Applovin_Adsales_L30,
      pa.dsp_sales_L30,
      safe_divide(pa.NTB_Sales_L30, pa.Total_Sales_L30) AS NTB_Sales_Perc,
      pa.spend_L30,
      pa.Shopify_AdSpend_L30,
      pa.shopify_tof_adspend_L30,
      pa.shopify_non_tof_adspend_L30,
      pa.meta_non_tof_adspend_L30,
      pa.meta_tof_adspend_L30,
      pa.youtube_non_tof_adspend_L30,
      pa.youtube_tof_adspend_L30,
      pa.google_sands_spend_L30,
      pa.google_adspend_L30,
      pa.google_search_adspend_L30,
      pa.google_shopping_adspend_L30,
      pa.google_performance_max_adspend_L30,
      pa.amazon_adspend_L30,
      pa.tiktok_adspend_L30,
      pa.TikTokSpend_GMV_Max_L30,
      pa.TikTokSpend_Campaign_L30,
      pa.tiktok_tof_adspend_L30,

      -- pa.Applovin_AdSpend_L30,
      pa.walmart_adspend_L30,
      pa.dsp_adspend_L30,
      safe_divide(pa.shopify_non_tof_adspend_L30, pa.new_shopify_customers_L30)
        AS DTC_NCPA,
      safe_divide(pa.shopify_tof_adspend_L30, pa.new_shopify_customers_L30)
        AS TOF_DTC_NCPA,
      safe_divide(
        pa.Amz_Shopify_AdSpend_L30,
        (pa.new_shopify_customers_L30 + pa.new_amazon_customers_L30))
        AS Blended_CAC,
      pa.triple_whale_meta_cac_first_touch_7d_L30,
      pa.triple_whale_meta_cac_last_touch_7d_L30,
      pa.triple_whale_meta_cac_triple_att_7d_L30,
      pa.meta_in_app_cpa_L30,
      pa.triple_whale_meta_ncp_first_click_L30,
      pa.triple_whale_meta_ncp_lat_click_L30,
      pa.triple_whale_meta_ncp_triple_att_7d_L30,
      pa.meta_inapp_purchases_L30,
      safe_divide(
        pa.triple_whale_meta_ncp_triple_att_7d_L30, pa.new_shopify_orders_L30)
        AS Meta_NCP_New_Orders_Shopify_Ratio,
      safe_divide(pa.meta_inapp_purchases_L30, pa.shopify_orders_L30)
        AS Meta_In_App_Purchases_Orders_Shopify_Ratio,
      safe_divide(pa.meta_adspend_L30, pa.Shopify_AdSpend_L30)
        AS Meta_Spend_Total_Website_Spend,
      safe_divide(
        pa.triple_whale_meta_ncp_triple_att_7d_L30, pa.meta_inapp_purchases_L30)
        AS Meta_NCP_In_App_Purchases_Ratio,
      pa.triple_whale_google_cac_first_touch_7d_L30,
      pa.triple_whale_google_cac_last_touch_7d_L30,
      pa.triple_whale_google_cac_triple_att_7d_L30,
      pa.dg_first_touch_7d_L30,
      pa.dg_last_touch_7d_L30,
      pa.dg_triple_att_7d_L30,
      pa.prospecting_first_touch_7d_L30,
      pa.prospecting_last_touch_7d_L30,
      pa.prospecting_triple_att_7d_L30,
      pa.brand_first_touch_7d_L30,
      pa.brand_last_touch_7d_L30,
      pa.brand_triple_att_7d_L30,
      safe_divide(pa.Shopify_AdSpend_L30, pa.Website_Sales_L30)
        AS Website_TACOS,
      safe_divide(pa.amazon_adspend_L30, pa.Amazon_Sales_L30) AS Amazon_TACOS,
      safe_divide(pa.tiktok_adspend_L30, pa.Tiktok_Sales_L30) AS TikTok_TACOS,

      -- safe_divide(pa.new_subscribers_recharge_L30, pa.new_shopify_customers_L30) as N_Sub_Perc,
      safe_divide(pa.NTB_Shopify_Sales_L30, pa.shopify_non_tof_adspend_L30)
        AS aMER,
      safe_divide(pa.shopify_non_tof_adspend_L30, pa.Website_Sales_L30) AS MER,
      safe_divide(
        pa.NTB_Amz_Shopify_Sales_L30,
        (pa.amazon_adspend_L30 + pa.Shopify_AdSpend_L30)) AS NTB_aMER,
      pa.sns_ntb_amazon_net_sales_L30,
      pa.non_sns_ntb_amazon_net_sales_L30,
      pa.sns_ntb_orders_L30,
      pa.non_sns_ntb_orders_L30,
      pa.Website_Sales_L30 AS Total_Sales_Website,
      pa.NTB_Shopify_Net_Sales_L30 AS First_Time_Customer_Net_Sales,
      pa.NTB_Shopify_Sales_L30 AS First_Time_Customer_Sales,
      pa.Returning_Shopify_Sales_L30 AS Returning_Customer_Sales,
      pa.shopify_customers_L30 AS Total_Customers,
      pa.new_shopify_customers_L30 AS First_Time_Customers,
      pa.Returning_shopify_customers_L30 AS Returning_Customers,

      -- pa.new_subscribers_recharge_L30 as New_Subscribers,
      -- safe_divide(pa.new_subscribers_recharge_L30, pa.new_shopify_customers_L30) as New_Subscribers_Perc,
      pa.new_shopify_orders_L30 AS New_Orders,
      pa.Returning_shopify_orders_L30 AS Returning_Orders,
      pa.shopify_orders_L30 AS Shopify_Orders,
      pa.walmart_orders_L30 AS Walmart_Orders,
      pa.Amazon_orders_L30 AS Amazon_Orders,
      pa.TikTok_orders_L30 AS TikTok_Orders,
      pa.target_orders_L30 AS Target_Orders,
      safe_divide(pa.Amazon_Sales_L30, pa.Amazon_orders_L30) AS Amazon_AOV,
      safe_divide(pa.Tiktok_Sales_L30, pa.TikTok_orders_L30) AS TikTok_AOV,
      safe_divide(pa.Walmart_Sales_L30, pa.walmart_orders_L30) AS Walmart_AOV,
      safe_divide(pa.Target_Sales_L30, pa.target_orders_L30) AS Target_AOV,
      safe_divide(pa.NTB_Shopify_Net_Sales_L30, pa.new_shopify_orders_L30)
        AS N_AOV_Net_Sales,
      safe_divide(pa.NTB_Shopify_Sales_L30, pa.new_shopify_orders_L30) AS N_AOV,
      safe_divide(
        pa.Returning_Shopify_Sales_L30, pa.Returning_shopify_orders_L30)
        AS R_AOV,
      safe_divide(pa.Shopify_AdSpend_L30, pa.Website_Sales_L30) AS ACOS,
      safe_divide(pa.Shopify_AdSpend_L30, pa.Total_Sales_L30) AS TACOS_Website,
      pa.Returns_L30,
      safe_divide(pa.Returns_L30, pa.shopify_orders_L30) AS Return_Rate_Perc,
      safe_divide(pa.Website_Sales_L30, pa.Shopify_AdSpend_L30) AS MER_Website,
      safe_divide(pa.Shopify_AdSpend_L30, pa.shopify_clicks_L30) AS CPC,
      pa.Online_store_visitors_L30 AS Visitors,
      pa.Sessions_L30 AS Sessions,

      -- safe_divide(pa.new_shopify_customers_L30, pa.Online_store_visitors_L30) as CVR,
      -- safe_divide(pa.Shopify_AdSpend_L30, pa.Online_store_visitors_L30) as CPV,
      -- safe_divide(pa.NTB_Shopify_Sales_L30, pa.Online_store_visitors_L30) as N_RPV,
      -- safe_divide(pa.Website_Sales_L30, pa.Online_store_visitors_L30) as RPV,
      pa.Sessions_with_cart_additions_L30 AS ATC,

      -- safe_divide(pa.spend_L30, (pa.reach_L30/1000)) as CPMr,
      -- safe_divide(pa.Shopify_AdSpend_L30, pa.Sessions_with_cart_additions_L30) as Cost_per_ATC,
      safe_divide(
        pa.Sessions_with_cart_additions_L30, pa.Online_store_visitors_L30)
        AS ATC_Perc,
      safe_divide(
        pa.new_shopify_orders_L30, pa.Sessions_with_cart_additions_L30)
        AS ATC_to_PU_Perc,
      pa.Sessions_that_reached_checkout_L30 AS Initiated_Check_Out,
      pa.Sessions_that_completed_checkout_L30 AS Completed_Check_Out,

      -- safe_divide(pa.Shopify_AdSpend_L30, pa.Sessions_that_reached_checkout_L30) as Cost_per_Initiated_Check_Out,
      safe_divide(
        pa.new_shopify_orders_L30, pa.Sessions_that_reached_checkout_L30)
        AS IC_to_PU_Perc,
      safe_divide(
        pa.Sessions_that_reached_checkout_L30,
        pa.Sessions_with_cart_additions_L30) AS ATC_to_IC_Perc,
      pa.active_subscribers_recharge_L30 AS Active_Subscribers,
      pa.new_subscribers_recharge_L30 AS New_Subscribers_Recharge,
      pa.churned_subscribers_recharge_L30 AS Churned_Subscribers,
      pa.reactivated_subscribers_recharge_L30 AS Reactivated_Subscribers,
      pa.net_gain_loss_recharge_L30 AS Net_Gain_Loss,
      safe_divide(
        pa.active_subscriptions_recharge_L30,
        pa.active_subscribers_recharge_L30)
        AS Avg_Subscriptions_per_Active_Subscriber,
      safe_divide(pa.shopify_orders_L30, pa.active_subscribers_recharge_L30)
        AS Avg_Orders_per_Active_Subscriber,
      pa.avg_active_days_per_subscriber_recharge_L30
        AS Avg_Active_Days_per_Subscriber,

      -- pa.active_subscriptions_TTS_L30 as Active_Subscriptions_TTS,
      -- pa.active_subscribers_TTS_L30 as Active_Subscribers_TTS,
      -- pa.new_subscriptions_TTS_L30 as New_Subscriptions_TTS,
      -- pa.churn_TTS_L30 as Churned_Subscriptions_TTS,
      -- pa.net_gain_loss_TTS_L30 as Net_Gain_Loss_TTS,
      -- pa.subs_aov_TTS_L30 as Subscription_AOV_TTS,
      safe_divide(pa.shopify_item_discount_L30, pa.shopify_orders_L30)
        AS Discount_Per_Order,
      safe_divide(
        pa.shopify_refunded_amount_by_return_date_L30, pa.shopify_orders_L30)
        AS Return_Amount_Per_Order,
      safe_divide(pa.shopify_item_shipping_price_L30, pa.shopify_orders_L30)
        AS Shipping_Charge_Per_Order,
      safe_divide(pa.shopify_item_total_tax_L30, pa.shopify_orders_L30)
        AS Tax_Per_Order
    FROM PeriodAverages pa
    CROSS JOIN MonthStartCTE ms
    UNION ALL

    -- MTD Average row for each store
    SELECT
      'MTD AVG' AS date,
      pa.store_name,
      pa.Total_Sales_MTD,
      pa.Website_Sales_MTD,
      pa.Amazon_Sales_MTD,
      pa.Tiktok_Sales_MTD,
      pa.Walmart_Sales_MTD,
      pa.Target_Sales_MTD,

      -- pa.Applovin_Adsales_MTD,
      pa.dsp_sales_MTD,
      safe_divide(pa.NTB_Sales_MTD, pa.Total_Sales_MTD) AS NTB_Sales_Perc,
      pa.spend_MTD,
      pa.Shopify_AdSpend_MTD,
      pa.shopify_tof_adspend_MTD,
      pa.shopify_non_tof_adspend_MTD,
      pa.meta_non_tof_adspend_MTD,
      pa.meta_tof_adspend_MTD,
      pa.youtube_non_tof_adspend_MTD,
      pa.youtube_tof_adspend_MTD,
      pa.google_sands_spend_MTD,
      pa.google_adspend_MTD,
      pa.google_search_adspend_MTD,
      pa.google_shopping_adspend_MTD,
      pa.google_performance_max_adspend_MTD,
      pa.amazon_adspend_MTD,
      pa.tiktok_adspend_MTD,
      pa.TikTokSpend_GMV_Max_MTD,
      pa.TikTokSpend_Campaign_MTD,
      pa.tiktok_tof_adspend_MTD,

      -- pa.Applovin_AdSpend_MTD,
      pa.walmart_adspend_MTD,
      pa.dsp_adspend_MTD,
      safe_divide(pa.shopify_non_tof_adspend_MTD, pa.new_shopify_customers_MTD)
        AS DTC_NCPA,
      safe_divide(pa.shopify_tof_adspend_MTD, pa.new_shopify_customers_MTD)
        AS TOF_DTC_NCPA,
      safe_divide(
        pa.Amz_Shopify_AdSpend_MTD,
        (pa.new_shopify_customers_MTD + pa.new_amazon_customers_MTD))
        AS Blended_CAC,
      pa.triple_whale_meta_cac_first_touch_7d_MTD,
      pa.triple_whale_meta_cac_last_touch_7d_MTD,
      pa.triple_whale_meta_cac_triple_att_7d_MTD,
      pa.meta_in_app_cpa_MTD,
      pa.triple_whale_meta_ncp_first_click_MTD,
      pa.triple_whale_meta_ncp_lat_click_MTD,
      pa.triple_whale_meta_ncp_triple_att_7d_MTD,
      pa.meta_inapp_purchases_MTD,
      safe_divide(
        pa.triple_whale_meta_ncp_triple_att_7d_MTD, pa.new_shopify_orders_MTD)
        AS Meta_NCP_New_Orders_Shopify_Ratio,
      safe_divide(pa.meta_inapp_purchases_MTD, pa.shopify_orders_MTD)
        AS Meta_In_App_Purchases_Orders_Shopify_Ratio,
      safe_divide(pa.meta_adspend_MTD, pa.Shopify_AdSpend_MTD)
        AS Meta_Spend_Total_Website_Spend,
      safe_divide(
        pa.triple_whale_meta_ncp_triple_att_7d_MTD, pa.meta_inapp_purchases_MTD)
        AS Meta_NCP_In_App_Purchases_Ratio,
      pa.triple_whale_google_cac_first_touch_7d_MTD,
      pa.triple_whale_google_cac_last_touch_7d_MTD,
      pa.triple_whale_google_cac_triple_att_7d_MTD,
      pa.dg_first_touch_7d_MTD,
      pa.dg_last_touch_7d_MTD,
      pa.dg_triple_att_7d_MTD,
      pa.prospecting_first_touch_7d_MTD,
      pa.prospecting_last_touch_7d_MTD,
      pa.prospecting_triple_att_7d_MTD,
      pa.brand_first_touch_7d_MTD,
      pa.brand_last_touch_7d_MTD,
      pa.brand_triple_att_7d_MTD,
      safe_divide(pa.Shopify_AdSpend_MTD, pa.Website_Sales_MTD)
        AS Website_TACOS,
      safe_divide(pa.amazon_adspend_MTD, pa.Amazon_Sales_MTD) AS Amazon_TACOS,
      safe_divide(pa.tiktok_adspend_MTD, pa.Tiktok_Sales_MTD) AS TikTok_TACOS,

      -- safe_divide(pa.new_subscribers_recharge_MTD, pa.new_shopify_customers_MTD) as N_Sub_Perc,
      safe_divide(pa.NTB_Shopify_Sales_MTD, pa.shopify_non_tof_adspend_MTD)
        AS aMER,
      safe_divide(pa.shopify_non_tof_adspend_MTD, pa.Website_Sales_MTD) AS MER,
      safe_divide(
        pa.NTB_Amz_Shopify_Sales_MTD,
        (pa.amazon_adspend_MTD + pa.Shopify_AdSpend_MTD)) AS NTB_aMER,
      pa.sns_ntb_amazon_net_sales_MTD,
      pa.non_sns_ntb_amazon_net_sales_MTD,
      pa.sns_ntb_orders_MTD,
      pa.non_sns_ntb_orders_MTD,
      pa.Website_Sales_MTD AS Total_Sales_Website,
      pa.NTB_Shopify_Net_Sales_MTD AS First_Time_Customer_Net_Sales,
      pa.NTB_Shopify_Sales_MTD AS First_Time_Customer_Sales,
      pa.Returning_Shopify_Sales_MTD AS Returning_Customer_Sales,
      pa.shopify_customers_MTD AS Total_Customers,
      pa.new_shopify_customers_MTD AS First_Time_Customers,
      pa.Returning_shopify_customers_MTD AS Returning_Customers,

      -- pa.new_subscribers_recharge_MTD as New_Subscribers,
      -- safe_divide(pa.new_subscribers_recharge_MTD, pa.new_shopify_customers_MTD) as New_Subscribers_Perc,
      pa.new_shopify_orders_MTD AS New_Orders,
      pa.Returning_shopify_orders_MTD AS Returning_Orders,
      pa.shopify_orders_MTD AS Shopify_Orders,
      pa.walmart_orders_MTD AS Walmart_Orders,
      pa.Amazon_orders_MTD AS Amazon_Orders,
      pa.TikTok_orders_MTD AS TikTok_Orders,
      pa.target_orders_MTD AS Target_Orders,
      safe_divide(pa.Amazon_Sales_MTD, pa.Amazon_orders_MTD) AS Amazon_AOV,
      safe_divide(pa.Tiktok_Sales_MTD, pa.TikTok_orders_MTD) AS TikTok_AOV,
      safe_divide(pa.Walmart_Sales_MTD, pa.walmart_orders_MTD) AS Walmart_AOV,
      safe_divide(pa.Target_Sales_MTD, pa.target_orders_MTD) AS Target_AOV,
      safe_divide(pa.NTB_Shopify_Net_Sales_MTD, pa.new_shopify_orders_MTD)
        AS N_AOV_Net_Sales,
      safe_divide(pa.NTB_Shopify_Sales_MTD, pa.new_shopify_orders_MTD) AS N_AOV,
      safe_divide(
        pa.Returning_Shopify_Sales_MTD, pa.Returning_shopify_orders_MTD)
        AS R_AOV,
      safe_divide(pa.Shopify_AdSpend_MTD, pa.Website_Sales_MTD) AS ACOS,
      safe_divide(pa.Shopify_AdSpend_MTD, pa.Total_Sales_MTD) AS TACOS_Website,
      pa.Returns_MTD,
      safe_divide(pa.Returns_MTD, pa.shopify_orders_MTD) AS Return_Rate_Perc,
      safe_divide(pa.Website_Sales_MTD, pa.Shopify_AdSpend_MTD) AS MER_Website,
      safe_divide(pa.Shopify_AdSpend_MTD, pa.shopify_clicks_MTD) AS CPC,
      pa.Online_store_visitors_MTD AS Visitors,
      pa.Sessions_MTD AS Sessions,

      -- safe_divide(pa.new_shopify_customers_MTD, pa.Online_store_visitors_MTD) as CVR,
      -- safe_divide(pa.Shopify_AdSpend_MTD, pa.Online_store_visitors_MTD) as CPV,
      -- safe_divide(pa.NTB_Shopify_Sales_MTD, pa.Online_store_visitors_MTD) as N_RPV,
      -- safe_divide(pa.Website_Sales_MTD, pa.Online_store_visitors_MTD) as RPV,
      pa.Sessions_with_cart_additions_MTD AS ATC,

      -- safe_divide(pa.spend_MTD, (pa.reach_MTD/1000)) as CPMr,
      -- safe_divide(pa.Shopify_AdSpend_MTD, pa.Sessions_with_cart_additions_MTD) as Cost_per_ATC,
      safe_divide(
        pa.Sessions_with_cart_additions_MTD, pa.Online_store_visitors_MTD)
        AS ATC_Perc,
      safe_divide(
        pa.new_shopify_orders_MTD, pa.Sessions_with_cart_additions_MTD)
        AS ATC_to_PU_Perc,
      pa.Sessions_that_reached_checkout_MTD AS Initiated_Check_Out,
      pa.Sessions_that_completed_checkout_MTD AS Completed_Check_Out,

      -- safe_divide(pa.Shopify_AdSpend_MTD, pa.Sessions_that_reached_checkout_MTD) as Cost_per_Initiated_Check_Out,
      safe_divide(
        pa.new_shopify_orders_MTD, pa.Sessions_that_reached_checkout_MTD)
        AS IC_to_PU_Perc,
      safe_divide(
        pa.Sessions_that_reached_checkout_MTD,

        pa.Sessions_with_cart_additions_MTD) AS ATC_to_IC_Perc,
      pa.active_subscribers_recharge_MTD AS Active_Subscribers,
      pa.new_subscribers_recharge_MTD AS New_Subscribers_Recharge,
      pa.churned_subscribers_recharge_MTD AS Churned_Subscribers,
      pa.reactivated_subscribers_recharge_MTD AS Reactivated_Subscribers,
      pa.net_gain_loss_recharge_MTD AS Net_Gain_Loss,
      safe_divide(
        pa.active_subscriptions_recharge_MTD,
        pa.active_subscribers_recharge_MTD)
        AS Avg_Subscriptions_per_Active_Subscriber,
      safe_divide(pa.shopify_orders_MTD, pa.active_subscribers_recharge_MTD)
        AS Avg_Orders_per_Active_Subscriber,
      pa.avg_active_days_per_subscriber_recharge_MTD
        AS Avg_Active_Days_per_Subscriber,

      -- pa.active_subscriptions_TTS_MTD as Active_Subscriptions_TTS,
      -- pa.active_subscribers_TTS_MTD as Active_Subscribers_TTS,
      -- pa.new_subscriptions_TTS_MTD as New_Subscriptions_TTS,
      -- pa.churn_TTS_MTD as Churned_Subscriptions_TTS,
      -- pa.net_gain_loss_TTS_MTD as Net_Gain_Loss_TTS,
      -- pa.subs_aov_TTS_MTD as Subscription_AOV_TTS,
      safe_divide(pa.shopify_item_discount_MTD, pa.shopify_orders_MTD)
        AS Discount_Per_Order,
      safe_divide(
        pa.shopify_refunded_amount_by_return_date_MTD, pa.shopify_orders_MTD)
        AS Return_Amount_Per_Order,
      safe_divide(pa.shopify_item_shipping_price_MTD, pa.shopify_orders_MTD)
        AS Shipping_Charge_Per_Order,
      safe_divide(pa.shopify_item_total_tax_MTD, pa.shopify_orders_MTD)
        AS Tax_Per_Order
    FROM PeriodAverages pa
    CROSS JOIN MonthStartCTE ms
  )

-- Final output
SELECT *
FROM FinalResults
ORDER BY
  CASE
    WHEN date IN ('L7 AVG', 'L14 AVG', 'L30 AVG', 'MTD AVG') THEN 0
    ELSE 1
    END,
  CASE
    WHEN date = 'L7 AVG' THEN 1
    WHEN date = 'L14 AVG' THEN 2
    WHEN date = 'L30 AVG' THEN 3
    WHEN date = 'MTD AVG' THEN 4
    ELSE 5
    END,
  date DESC

=== All_KPIs_Date_Level_Electrolytes ===
WITH
  DailySalesTracker AS (
    WITH
      cte AS (
        SELECT
          date,
          store_name,
          platform_name,
          transaction_type,
          customer_type,
          sns_ntb_amazon_order_id,
          non_sns_ntb_amazon_order_id,
          amazon_customer_id,
          shopify_customer_id,
          shopify_order_id,
          walmart_seller_center_order_id,
          amazon_order_id,
          tiktok_order_id,
          target_order_id,
          returned_order_id,
          total_sales,
          shopify_total_sales,
          amazon_total_sales,
          tiktok_total_sales,
          walmart_seller_center_total_sales,
          target_total_sales,
          CASE
            WHEN customer_type = 'New' THEN coalesce(total_sales, 0)
            ELSE 0
            END AS NTB_Sales,
          CASE
            WHEN customer_type = 'New' THEN coalesce(shopify_total_sales, 0)
            ELSE 0
            END AS NTB_Shopify_Sales,
          CASE
            WHEN customer_type = 'Existing'
              THEN coalesce(shopify_total_sales, 0)
            ELSE 0
            END AS Returning_Shopify_Sales,
          CASE
            WHEN customer_type = 'New' THEN coalesce(shopify_net_sales, 0)
            ELSE 0
            END AS NTB_Shopify_Net_Sales,
          CASE
            WHEN customer_type = 'New'
              THEN
                coalesce(shopify_total_sales, 0)
                + coalesce(amazon_total_sales, 0)
            ELSE 0
            END AS NTB_Amz_Shopify_Sales,
          sns_ntb_amazon_net_sales,
          non_sns_ntb_amazon_net_sales,
          shopify_item_discount,
          shopify_refunded_amount_by_return_date,
          shopify_item_shipping_price,
          shopify_item_total_tax
        FROM
          daton-project.trueseamoss_5363_prod_presentation_datashare.DailySalesTracker
        WHERE product_category_unique = 'Electrolytes'
      )
    SELECT
      date,
      store_name,
      COUNT(
        DISTINCT
          CASE
            WHEN
              sns_ntb_amazon_order_id IS NOT NULL
              AND sns_ntb_amazon_order_id <> ''
              AND transaction_type <> 'return'
              THEN sns_ntb_amazon_order_id
            END) AS sns_ntb_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              non_sns_ntb_amazon_order_id IS NOT NULL
              AND non_sns_ntb_amazon_order_id <> ''
              AND transaction_type <> 'return'
              THEN non_sns_ntb_amazon_order_id
            END) AS non_sns_ntb_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              shopify_customer_id IS NOT NULL
              AND shopify_customer_id <> ''
              THEN shopify_customer_id
            END) AS shopify_customers,
      COUNT(
        DISTINCT
          CASE
            WHEN
              shopify_customer_id IS NOT NULL
              AND shopify_customer_id <> ''
              AND customer_type = 'New'
              THEN shopify_customer_id
            END) AS new_shopify_customers,
      COUNT(
        DISTINCT
          CASE
            WHEN
              amazon_customer_id IS NOT NULL
              AND amazon_customer_id <> ''
              AND customer_type = 'New'
              THEN amazon_customer_id
            END) AS new_amazon_customers,
      COUNT(
        DISTINCT
          CASE
            WHEN
              shopify_customer_id IS NOT NULL
              AND shopify_customer_id <> ''
              AND customer_type = 'Existing'
              THEN shopify_customer_id
            END) AS Returning_shopify_customers,
      COUNT(
        DISTINCT
          CASE
            WHEN
              shopify_order_id IS NOT NULL
              AND shopify_order_id <> ''
              AND transaction_type <> 'Return'
              THEN shopify_order_id
            END) AS shopify_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              shopify_order_id IS NOT NULL
              AND shopify_order_id <> ''
              AND customer_type = 'New'
              AND transaction_type <> 'Return'
              THEN shopify_order_id
            END) AS new_shopify_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              shopify_order_id IS NOT NULL
              AND shopify_order_id <> ''
              AND customer_type = 'Existing'
              AND transaction_type <> 'Return'
              THEN shopify_order_id
            END) AS Returning_shopify_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              amazon_order_id IS NOT NULL
              AND amazon_order_id <> ''
              AND transaction_type <> 'Return'
              THEN amazon_order_id
            END) AS Amazon_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              Tiktok_order_id IS NOT NULL
              AND Tiktok_order_id <> ''
              AND transaction_type <> 'Return'
              AND tiktok_total_sales > 0
              THEN Tiktok_order_id
            END) AS TikTok_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              walmart_seller_center_order_id IS NOT NULL
              AND walmart_seller_center_order_id <> ''
              AND transaction_type <> 'Return'
              THEN walmart_seller_center_order_id
            END) AS walmart_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              target_order_id IS NOT NULL
              AND target_order_id <> ''
              AND transaction_type <> 'Return'
              THEN target_order_id
            END) AS target_orders,
      COUNT(
        DISTINCT
          CASE
            WHEN
              returned_order_id IS NOT NULL
              AND returned_order_id <> ''
              AND platform_name = 'Shopify'
              THEN returned_order_id
            END) AS Returns,
      sum(coalesce(total_sales, 0)) Total_Sales,
      sum(coalesce(shopify_total_sales, 0)) Website_Sales,
      sum(coalesce(amazon_total_sales, 0)) Amazon_Sales,
      sum(coalesce(tiktok_total_sales, 0)) Tiktok_Sales,
      sum(coalesce(walmart_seller_center_total_sales, 0)) Walmart_Sales,
      sum(coalesce(target_total_sales, 0)) Target_Sales,
      sum(NTB_Sales) NTB_Sales,
      sum(NTB_Shopify_Sales) NTB_Shopify_Sales,
      sum(Returning_Shopify_Sales) Returning_Shopify_Sales,
      sum(NTB_Shopify_Net_Sales) NTB_Shopify_Net_Sales,
      sum(NTB_Amz_Shopify_Sales) NTB_Amz_Shopify_Sales,
      sum(sns_ntb_amazon_net_sales) sns_ntb_amazon_net_sales,
      sum(non_sns_ntb_amazon_net_sales) non_sns_ntb_amazon_net_sales,
      sum(shopify_item_discount) shopify_item_discount,
      sum(shopify_refunded_amount_by_return_date)
        shopify_refunded_amount_by_return_date,
      sum(shopify_item_shipping_price) shopify_item_shipping_price,
      sum(shopify_item_total_tax) shopify_item_total_tax
    FROM cte
    GROUP BY ALL
  ),
  DailyShopifyAccountSessionsTracker AS (
    SELECT
      date,
      store_name,
      sum(Online_store_visitors) Online_store_visitors,
      sum(Sessions_with_cart_additions) Sessions_with_cart_additions,
      sum(Sessions_that_reached_checkout) Sessions_that_reached_checkout,
      sum(Sessions_that_completed_checkout) Sessions_that_completed_checkout,
      sum(Sessions) Sessions
    FROM
      daton-project.trueseamoss_5363_prod_presentation_datashare.DailyShopifyProductCategorySessionsTracker
    WHERE
      product_category_new = 'Electrolytes'
      AND Landing_page_path = '/collections/all/products/sea-moss-electrolytes'
    GROUP BY 1, 2
  ),

  -- First, get the base aggregated data without the Canada logic
  DailySpendsTrackerBase AS (
    SELECT
      date,
      store_name,
      is_GMV_Max_campaign,
      sum(coalesce(dsp_sales, 0)) dsp_sales,
      sum(coalesce(spend, 0)) spend,
      sum(coalesce(shopify_adspend, 0)) Shopify_AdSpend,
      sum(coalesce(shopify_tof_adspend, 0)) shopify_tof_adspend,
      sum(coalesce(shopify_non_tof_adspend, 0)) shopify_non_tof_adspend,
      sum(coalesce(meta_non_tof_adspend, 0)) meta_non_tof_adspend,
      sum(coalesce(meta_tof_adspend, 0)) meta_tof_adspend,
      sum(coalesce(youtube_non_tof_adspend, 0)) youtube_non_tof_adspend,
      sum(coalesce(youtube_tof_adspend, 0)) youtube_tof_adspend,
      sum(coalesce(google_adspend, 0)) google_adspend,
      sum(coalesce(google_search_adspend, 0))
        + sum(coalesce(google_shopping_adspend, 0)) google_sands_spend,
      sum(coalesce(google_search_adspend, 0)) google_search_adspend,
      sum(coalesce(google_shopping_adspend, 0)) google_shopping_adspend,
      sum(coalesce(google_performance_max_adspend, 0))
        google_performance_max_adspend,
      sum(coalesce(amazon_adspend, 0)) amazon_adspend,
      sum(coalesce(tiktok_adspend, 0)) tiktok_adspend,
      sum(
        CASE
          WHEN is_GMV_Max_campaign = 1 THEN coalesce(tiktok_adspend, 0)
          ELSE 0
          END)
        TikTokSpend_GMV_Max,
      sum(
        CASE
          WHEN is_GMV_Max_campaign = 0 THEN coalesce(tiktok_adspend, 0)
          ELSE 0
          END)
        TikTokSpend_Campaign,
      sum(coalesce(tiktok_tof_adspend, 0)) tiktok_tof_adspend,
      sum(coalesce(walmart_adspend, 0)) walmart_adspend,
      sum(coalesce(dsp_adspend, 0)) dsp_adspend,
      sum(coalesce(amazon_adspend, 0))
        + sum(coalesce(shopify_adspend, 0)) Amz_Shopify_AdSpend,
      sum(coalesce(meta_adspend, 0)) meta_adspend,
      sum(coalesce(shopify_clicks, 0)) shopify_clicks,
      sum(coalesce(reach, 0)) reach
    FROM
      daton-project.trueseamoss_5363_prod_presentation_datashare.DailySpendsTracker
    WHERE product_category = 'Electrolytes'
    GROUP BY 1, 2, 3
  ),

  -- Get Canada's google_adspend values
  CanadaGoogleAdSpend AS (
    SELECT
      date,
      google_adspend AS canada_google_adspend
    FROM DailySpendsTrackerBase
    WHERE store_name = 'Canada'
  ),

  -- Final DailySpendsTracker with Canada values for US
  DailySpendsTracker AS (
    SELECT
      d.date,
      d.store_name,
      sum(d.dsp_sales) AS dsp_sales,
      sum(d.spend)
        - CASE
          WHEN d.store_name = 'Canada'
            THEN
              coalesce(
                (
                  SELECT sum(google_adspend)
                  FROM DailySpendsTrackerBase
                  WHERE date = d.date AND store_name = 'Canada'
                ),
                0)
          ELSE 0
          END
        + CASE
          WHEN d.store_name = 'United States'
            THEN
              coalesce(
                (
                  SELECT sum(google_adspend)
                  FROM DailySpendsTrackerBase
                  WHERE date = d.date AND store_name = 'Canada'
                ),
                0)
          ELSE 0
          END AS spend,
      sum(d.Shopify_AdSpend)
        - CASE
          WHEN d.store_name = 'Canada'
            THEN
              coalesce(
                (
                  SELECT sum(google_adspend)
                  FROM DailySpendsTrackerBase
                  WHERE date = d.date AND store_name = 'Canada'
                ),
                0)
          ELSE 0
          END AS Shopify_AdSpend,
      sum(d.shopify_tof_adspend) AS shopify_tof_adspend,
      sum(d.shopify_non_tof_adspend)
        - CASE
          WHEN d.store_name = 'Canada'
            THEN
              coalesce(
                (
                  SELECT sum(google_adspend)
                  FROM DailySpendsTrackerBase
                  WHERE date = d.date AND store_name = 'Canada'
                ),
                0)
          ELSE 0
          END AS shopify_non_tof_adspend,
      sum(d.meta_non_tof_adspend) AS meta_non_tof_adspend,
      sum(d.meta_tof_adspend) AS meta_tof_adspend,
      sum(d.youtube_non_tof_adspend) AS youtube_non_tof_adspend,
      sum(d.youtube_tof_adspend) AS youtube_tof_adspend,

      -- Use Canada's google_adspend for United States via subquery, keep original for others
      CASE
        WHEN d.store_name = 'United States'
          THEN
            coalesce(
              (
                SELECT google_adspend
                FROM DailySpendsTrackerBase
                WHERE
                  date = d.date
                  AND store_name = 'Canada'
              ),
              0)
        WHEN d.store_name = 'Canada' THEN 0
        ELSE sum(d.google_adspend)
        END AS google_adspend,
      CASE
        WHEN d.store_name = 'Canada' THEN 0
        ELSE sum(d.google_sands_spend)
        END AS google_sands_spend,
      CASE
        WHEN d.store_name = 'Canada' THEN 0
        ELSE sum(d.google_search_adspend)
        END AS google_search_adspend,
      CASE
        WHEN d.store_name = 'Canada' THEN 0
        ELSE sum(d.google_shopping_adspend)
        END AS google_shopping_adspend,
      CASE
        WHEN d.store_name = 'Canada' THEN 0
        ELSE sum(d.google_performance_max_adspend)
        END AS google_performance_max_adspend,
      sum(d.amazon_adspend)
        + CASE
          WHEN d.store_name = 'United States'
            THEN
              coalesce(
                (
                  SELECT sum(google_adspend)
                  FROM DailySpendsTrackerBase
                  WHERE date = d.date AND store_name = 'Canada'
                ),
                0)
          ELSE 0
          END AS amazon_adspend,
      sum(d.tiktok_adspend) AS tiktok_adspend,
      sum(d.TikTokSpend_GMV_Max) AS TikTokSpend_GMV_Max,
      sum(d.TikTokSpend_Campaign) AS TikTokSpend_Campaign,
      sum(d.tiktok_tof_adspend) AS tiktok_tof_adspend,
      sum(d.walmart_adspend) AS walmart_adspend,
      sum(d.dsp_adspend) AS dsp_adspend,
      sum(d.Amz_Shopify_AdSpend)
        - CASE
          WHEN d.store_name = 'Canada'
            THEN
              coalesce(
                (
                  SELECT sum(google_adspend)
                  FROM DailySpendsTrackerBase
                  WHERE date = d.date AND store_name = 'Canada'
                ),
                0)
          ELSE 0
          END
        + CASE
          WHEN d.store_name = 'United States'
            THEN
              coalesce(
                (
                  SELECT sum(google_adspend)
                  FROM DailySpendsTrackerBase
                  WHERE date = d.date AND store_name = 'Canada'
                ),
                0)
          ELSE 0
          END AS Amz_Shopify_AdSpend,
      sum(d.meta_adspend) AS meta_adspend,
      sum(d.shopify_clicks) AS shopify_clicks,
      sum(d.reach) AS reach
    FROM DailySpendsTrackerBase d
    GROUP BY d.date, d.store_name
  ),
  DailySubscriptionsTracker AS (
    SELECT
      date,
      store_name,
      sum(coalesce(new_subscribers, 0)) new_subscribers_recharge,
      sum(coalesce(active_subscribers, 0)) active_subscribers_recharge,
      sum(coalesce(churned_subscribers, 0)) churned_subscribers_recharge,
      sum(coalesce(reactivated_subscribers, 0))
        reactivated_subscribers_recharge,
      sum(coalesce(net_gain_loss_subscribers, 0)) net_gain_loss_recharge,
      sum(coalesce(active_subscriptions, 0)) active_subscriptions_recharge,
      avg(avg_active_days_per_subscriber)
        avg_active_days_per_subscriber_recharge
    FROM
      daton-project.trueseamoss_5363_prod_presentation_datashare.DailyCatogerySubscriptionsTracker
    WHERE product_category = 'Electrolytes'
    GROUP BY ALL
  ),
  SpendsAgainstSales AS (
    SELECT
      date,
      'United States' AS Store_name,
      COUNT(
        DISTINCT
          CASE
            WHEN
              customer_type = 'New'
              AND shopify_order_id IS NOT NULL
              AND transaction_type <> 'Return'
              THEN shopify_order_id
            END)
        firsttime_customer_shopify_orders_SpendAgainstSales,
      COUNT(
        DISTINCT
          CASE
            WHEN shopify_order_id IS NOT NULL AND transaction_type <> 'Return'
              THEN shopify_order_id
            END)
        shopify_orders_SpendAgainstSales
    FROM
      daton-project.trueseamoss_5363_prod_presentation_datashare.DailySalesTracker
    WHERE product_category_unique = 'Electrolytes'
    GROUP BY ALL
  ),
  TikTokShop_gs AS (
    SELECT
      date,
      'United States' AS Store_name,
      sum(coalesce(active_subscriptions, 0)) active_subscriptions_TTS,
      sum(coalesce(active_subscribers, 0)) active_subscribers_TTS,
      sum(coalesce(new_subscriptions, 0)) new_subscriptions_TTS,
      sum(coalesce(churn, 0)) churn_TTS,
      sum(coalesce(net_gain_loss, 0)) net_gain_loss_TTS,
      avg(subs_aov) subs_aov_TTS
    FROM
      daton-project.trueseamoss_5363_prod_presentation_datashare.TikTokShopSubscriptions_gs
    GROUP BY ALL
  ),
  TripleWhale_gs AS (
    SELECT
      date,
      store_name,
      sum(coalesce(triple_whale_meta_cac_first_touch_7d, 0))
        triple_whale_meta_cac_first_touch_7d,
      sum(coalesce(triple_whale_meta_cac_last_touch_7d, 0))
        triple_whale_meta_cac_last_touch_7d,
      sum(coalesce(triple_whale_meta_cac_triple_att_7d, 0))
        triple_whale_meta_cac_triple_att_7d,
      sum(coalesce(meta_in_app_cpa, 0)) meta_in_app_cpa,
      sum(coalesce(triple_whale_meta_ncp_firt_click, 0))
        triple_whale_meta_ncp_first_click,
      sum(coalesce(triple_whale_meta_ncp_lat_click, 0))
        triple_whale_meta_ncp_lat_click,
      sum(coalesce(triple_whale_meta_ncp_triple_att_7d, 0))
        triple_whale_meta_ncp_triple_att_7d,
      sum(coalesce(meta_inapp_purchases, 0)) meta_inapp_purchases,
      sum(coalesce(triple_whale_google_cac_first_touch_7d, 0))
        triple_whale_google_cac_first_touch_7d,
      sum(coalesce(triple_whale_google_cac_last_touch_7d, 0))
        triple_whale_google_cac_last_touch_7d,
      sum(coalesce(triple_whale_google_cac_triple_att_7d, 0))
        triple_whale_google_cac_triple_att_7d,
      sum(coalesce(dg_first_touch_7d, 0)) dg_first_touch_7d,
      sum(coalesce(dg_last_touch_7d, 0)) dg_last_touch_7d,
      sum(coalesce(dg_triple_att_7d, 0)) dg_triple_att_7d,
      sum(coalesce(prospecting_first_touch_7d, 0)) prospecting_first_touch_7d,
      sum(coalesce(prospecting_last_touch_7d, 0)) prospecting_last_touch_7d,
      sum(coalesce(prospecting_triple_att_7d, 0)) prospecting_triple_att_7d,
      sum(coalesce(brand_first_touch_7d, 0)) brand_first_touch_7d,
      sum(coalesce(brand_last_touch_7d, 0)) brand_last_touch_7d,
      sum(coalesce(brand_triple_att_7d, 0)) brand_triple_att_7d
    FROM
      daton-project.trueseamoss_5363_prod_presentation_datashare.TripleWhaleData_gs
    WHERE segment_type = 'Electrolytes'
    GROUP BY ALL
  ),
  Applovin_data AS (
    SELECT
      date,
      store_name,
      sum(adsales) Applovin_Adsales,
      sum(adspend) Applovin_AdSpend
    FROM
      daton-project.trueseamoss_5363_prod_presentation_datashare.ApplovinData_gs
    GROUP BY ALL
  ),

  -- CTE for Full Outer Join of All Data Sources
  CompleteDataJoin AS (
    SELECT
      coalesce(
        dst.date,
        apv.date,
        dsast.date,
        dspdt.date,
        dsubt.date,
        sas.date,
        tts.date,
        tw.date) AS date,
      coalesce(
        dst.store_name,
        apv.store_name,
        dsast.store_name,
        dspdt.store_name,
        dsubt.store_name,
        sas.store_name,
        tts.store_name,
        tw.store_name) AS store_name,

      -- DailySalesTracker columns
      dst.sns_ntb_orders,
      dst.non_sns_ntb_orders,
      dst.shopify_customers,
      dst.new_shopify_customers,
      dst.new_amazon_customers,
      dst.Returning_shopify_customers,
      dst.shopify_orders,
      dst.new_shopify_orders,
      dst.Returning_shopify_orders,
      dst.Amazon_orders,
      dst.TikTok_orders,
      dst.walmart_orders,
      dst.target_orders,
      dst.Returns,
      dst.Total_Sales,
      dst.Website_Sales,
      dst.Amazon_Sales,
      dst.Tiktok_Sales,
      dst.Walmart_Sales,
      dst.Target_Sales,
      dst.NTB_Sales,
      dst.NTB_Shopify_Sales,
      dst.Returning_Shopify_Sales,
      dst.NTB_Shopify_Net_Sales,
      dst.NTB_Amz_Shopify_Sales,
      dst.sns_ntb_amazon_net_sales,
      dst.non_sns_ntb_amazon_net_sales,
      dst.shopify_item_discount,
      dst.shopify_refunded_amount_by_return_date,
      dst.shopify_item_shipping_price,
      dst.shopify_item_total_tax,

      -- Applovin_data columns
      apv.Applovin_Adsales,
      apv.Applovin_AdSpend,

      -- DailyShopifyAccountSessionsTracker columns
      dsast.Online_store_visitors,
      dsast.Sessions_with_cart_additions,
      dsast.Sessions_that_reached_checkout,
      dsast.Sessions_that_completed_checkout,
      dsast.Sessions,

      -- DailySpendsTracker columns
      dspdt.dsp_sales,
      dspdt.spend,
      dspdt.Shopify_AdSpend,
      dspdt.shopify_tof_adspend,
      dspdt.shopify_non_tof_adspend,
      dspdt.meta_non_tof_adspend,
      dspdt.meta_tof_adspend,
      dspdt.youtube_non_tof_adspend,
      dspdt.youtube_tof_adspend,
      dspdt.google_adspend,  -- Added google_adspend here
      dspdt.google_sands_spend,
      dspdt.google_search_adspend,
      dspdt.google_shopping_adspend,
      dspdt.google_performance_max_adspend,
      dspdt.amazon_adspend,
      dspdt.tiktok_adspend,
      dspdt.TikTokSpend_GMV_Max,
      dspdt.TikTokSpend_Campaign,
      dspdt.tiktok_tof_adspend,
      dspdt.walmart_adspend,
      dspdt.dsp_adspend,
      dspdt.Amz_Shopify_AdSpend,
      dspdt.meta_adspend,
      dspdt.shopify_clicks,
      dspdt.reach,

      -- DailySubscriptionsTracker columns
      dsubt.new_subscribers_recharge,
      dsubt.active_subscribers_recharge,
      dsubt.churned_subscribers_recharge,
      dsubt.reactivated_subscribers_recharge,
      dsubt.net_gain_loss_recharge,
      dsubt.active_subscriptions_recharge,
      dsubt.avg_active_days_per_subscriber_recharge,

      -- SpendsAgainstSales columns
      sas.firsttime_customer_shopify_orders_SpendAgainstSales,
      sas.shopify_orders_SpendAgainstSales,

      -- TikTokShop_gs columns
      tts.active_subscriptions_TTS,
      tts.active_subscribers_TTS,
      tts.new_subscriptions_TTS,
      tts.churn_TTS,
      tts.net_gain_loss_TTS,
      tts.subs_aov_TTS,

      -- TripleWhale_gs columns
      tw.triple_whale_meta_cac_first_touch_7d,
      tw.triple_whale_meta_cac_last_touch_7d,
      tw.triple_whale_meta_cac_triple_att_7d,
      tw.meta_in_app_cpa,
      tw.triple_whale_meta_ncp_first_click,
      tw.triple_whale_meta_ncp_lat_click,
      tw.triple_whale_meta_ncp_triple_att_7d,
      tw.meta_inapp_purchases,
      tw.triple_whale_google_cac_first_touch_7d,
      tw.triple_whale_google_cac_last_touch_7d,
      tw.triple_whale_google_cac_triple_att_7d,
      tw.dg_first_touch_7d,
      tw.dg_last_touch_7d,
      tw.dg_triple_att_7d,
      tw.prospecting_first_touch_7d,
      tw.prospecting_last_touch_7d,
      tw.prospecting_triple_att_7d,
      tw.brand_first_touch_7d,
      tw.brand_last_touch_7d,
      tw.brand_triple_att_7d
    FROM DailySalesTracker dst
    FULL OUTER JOIN Applovin_data apv
      ON
        dst.date = apv.date
        AND dst.store_name = apv.store_name
    FULL OUTER JOIN DailyShopifyAccountSessionsTracker dsast
      ON
        coalesce(dst.date, apv.date) = dsast.date
        AND coalesce(dst.store_name, apv.store_name) = dsast.store_name
    FULL OUTER JOIN DailySpendsTracker dspdt
      ON
        coalesce(dst.date, apv.date, dsast.date) = dspdt.date
        AND coalesce(dst.store_name, apv.store_name, dsast.store_name)
          = dspdt.store_name
    FULL OUTER JOIN DailySubscriptionsTracker dsubt
      ON
        coalesce(dst.date, apv.date, dsast.date, dspdt.date) = dsubt.date
        AND coalesce(
          dst.store_name, apv.store_name, dsast.store_name, dspdt.store_name)
          = dsubt.store_name
    FULL OUTER JOIN SpendsAgainstSales sas
      ON
        coalesce(dst.date, apv.date, dsast.date, dspdt.date, dsubt.date)
          = sas.date
        AND coalesce(
          dst.store_name,
          apv.store_name,
          dsast.store_name,
          dspdt.store_name,
          dsubt.store_name)
          = sas.store_name
    FULL OUTER JOIN TikTokShop_gs tts
      ON
        coalesce(
          dst.date, apv.date, dsast.date, dspdt.date, dsubt.date, sas.date)
          = tts.date
        AND coalesce(
          dst.store_name,
          apv.store_name,
          dsast.store_name,
          dspdt.store_name,
          dsubt.store_name,
          sas.store_name)
          = tts.store_name
    FULL OUTER JOIN TripleWhale_gs tw
      ON
        coalesce(
          dst.date,
          apv.date,
          dsast.date,
          dspdt.date,
          dsubt.date,
          sas.date,
          tts.date)
          = tw.date
        AND coalesce(
          dst.store_name,
          apv.store_name,
          dsast.store_name,
          dspdt.store_name,
          dsubt.store_name,
          sas.store_name,
          tts.store_name)
          = tw.store_name
  ),

  -- Get the latest date in the dataset
  LatestDateCTE AS (
    SELECT max(date) AS latest_date
    FROM CompleteDataJoin
  ),

  -- Calculate month start date for MTD
  MonthStartCTE AS (
    SELECT
      latest_date,
      date_trunc(latest_date, month) AS month_start_date
    FROM LatestDateCTE
  ),

  -- Calculate averages for each period and store_name - ALL METRICS INCLUDED
  PeriodAverages AS (
    SELECT
      cdj.store_name,

      -- SALES SECTION METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Total_Sales
          ELSE NULL
          END) AS Total_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Total_Sales
          ELSE NULL
          END) AS Total_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Total_Sales
          ELSE NULL
          END) AS Total_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Total_Sales
          ELSE NULL
          END) AS Total_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Website_Sales
          ELSE NULL
          END) AS Website_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Website_Sales
          ELSE NULL
          END) AS Website_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Website_Sales
          ELSE NULL
          END) AS Website_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Website_Sales
          ELSE NULL
          END) AS Website_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Amazon_Sales
          ELSE NULL
          END) AS Amazon_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Amazon_Sales
          ELSE NULL
          END) AS Amazon_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Amazon_Sales
          ELSE NULL
          END) AS Amazon_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Amazon_Sales
          ELSE NULL
          END) AS Amazon_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Tiktok_Sales
          ELSE NULL
          END) AS Tiktok_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Tiktok_Sales
          ELSE NULL
          END) AS Tiktok_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Tiktok_Sales
          ELSE NULL
          END) AS Tiktok_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Tiktok_Sales
          ELSE NULL
          END) AS Tiktok_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Walmart_Sales
          ELSE NULL
          END) AS Walmart_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Walmart_Sales
          ELSE NULL
          END) AS Walmart_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Walmart_Sales
          ELSE NULL
          END) AS Walmart_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Walmart_Sales
          ELSE NULL
          END) AS Walmart_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Target_Sales
          ELSE NULL
          END) AS Target_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Target_Sales
          ELSE NULL
          END) AS Target_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Target_Sales
          ELSE NULL
          END) AS Target_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Target_Sales
          ELSE NULL
          END) AS Target_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Applovin_Adsales
          ELSE NULL
          END) AS Applovin_Adsales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Applovin_Adsales
          ELSE NULL
          END) AS Applovin_Adsales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Applovin_Adsales
          ELSE NULL
          END) AS Applovin_Adsales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Applovin_Adsales
          ELSE NULL
          END) AS Applovin_Adsales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.dsp_sales
          ELSE NULL
          END) AS dsp_sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.dsp_sales
          ELSE NULL
          END) AS dsp_sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.dsp_sales
          ELSE NULL
          END) AS dsp_sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.dsp_sales
          ELSE NULL
          END) AS dsp_sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.NTB_Sales
          ELSE NULL
          END) AS NTB_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.NTB_Sales
          ELSE NULL
          END) AS NTB_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.NTB_Sales
          ELSE NULL
          END) AS NTB_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.NTB_Sales
          ELSE NULL
          END) AS NTB_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.NTB_Shopify_Sales
          ELSE NULL
          END) AS NTB_Shopify_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.NTB_Shopify_Sales
          ELSE NULL
          END) AS NTB_Shopify_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.NTB_Shopify_Sales
          ELSE NULL
          END) AS NTB_Shopify_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.NTB_Shopify_Sales
          ELSE NULL
          END) AS NTB_Shopify_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Returning_Shopify_Sales
          ELSE NULL
          END) AS Returning_Shopify_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Returning_Shopify_Sales
          ELSE NULL
          END) AS Returning_Shopify_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Returning_Shopify_Sales
          ELSE NULL
          END) AS Returning_Shopify_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Returning_Shopify_Sales
          ELSE NULL
          END) AS Returning_Shopify_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.NTB_Shopify_Net_Sales
          ELSE NULL
          END) AS NTB_Shopify_Net_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.NTB_Shopify_Net_Sales
          ELSE NULL
          END) AS NTB_Shopify_Net_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.NTB_Shopify_Net_Sales
          ELSE NULL
          END) AS NTB_Shopify_Net_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.NTB_Shopify_Net_Sales
          ELSE NULL
          END) AS NTB_Shopify_Net_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.NTB_Amz_Shopify_Sales
          ELSE NULL
          END) AS NTB_Amz_Shopify_Sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.NTB_Amz_Shopify_Sales
          ELSE NULL
          END) AS NTB_Amz_Shopify_Sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.NTB_Amz_Shopify_Sales
          ELSE NULL
          END) AS NTB_Amz_Shopify_Sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.NTB_Amz_Shopify_Sales
          ELSE NULL
          END) AS NTB_Amz_Shopify_Sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.sns_ntb_amazon_net_sales
          ELSE NULL
          END) AS sns_ntb_amazon_net_sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.sns_ntb_amazon_net_sales
          ELSE NULL
          END) AS sns_ntb_amazon_net_sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.sns_ntb_amazon_net_sales
          ELSE NULL
          END) AS sns_ntb_amazon_net_sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.sns_ntb_amazon_net_sales
          ELSE NULL
          END) AS sns_ntb_amazon_net_sales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.non_sns_ntb_amazon_net_sales
          ELSE NULL
          END) AS non_sns_ntb_amazon_net_sales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.non_sns_ntb_amazon_net_sales
          ELSE NULL
          END) AS non_sns_ntb_amazon_net_sales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.non_sns_ntb_amazon_net_sales
          ELSE NULL
          END) AS non_sns_ntb_amazon_net_sales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.non_sns_ntb_amazon_net_sales
          ELSE NULL
          END) AS non_sns_ntb_amazon_net_sales_MTD,

      -- SPEND SECTION METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.spend
          ELSE NULL
          END) AS spend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.spend
          ELSE NULL
          END) AS spend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.spend
          ELSE NULL
          END) AS spend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.spend
          ELSE NULL
          END) AS spend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Shopify_AdSpend
          ELSE NULL
          END) AS Shopify_AdSpend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Shopify_AdSpend
          ELSE NULL
          END) AS Shopify_AdSpend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Shopify_AdSpend
          ELSE NULL
          END) AS Shopify_AdSpend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Shopify_AdSpend
          ELSE NULL
          END) AS Shopify_AdSpend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_tof_adspend
          ELSE NULL
          END) AS shopify_tof_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_tof_adspend
          ELSE NULL
          END) AS shopify_tof_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_tof_adspend
          ELSE NULL
          END) AS shopify_tof_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_tof_adspend
          ELSE NULL
          END) AS shopify_tof_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_non_tof_adspend
          ELSE NULL
          END) AS shopify_non_tof_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_non_tof_adspend
          ELSE NULL
          END) AS shopify_non_tof_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_non_tof_adspend
          ELSE NULL
          END) AS shopify_non_tof_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_non_tof_adspend
          ELSE NULL
          END) AS shopify_non_tof_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.meta_non_tof_adspend
          ELSE NULL
          END) AS meta_non_tof_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.meta_non_tof_adspend
          ELSE NULL
          END) AS meta_non_tof_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.meta_non_tof_adspend
          ELSE NULL
          END) AS meta_non_tof_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.meta_non_tof_adspend
          ELSE NULL
          END) AS meta_non_tof_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.meta_tof_adspend
          ELSE NULL
          END) AS meta_tof_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.meta_tof_adspend
          ELSE NULL
          END) AS meta_tof_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.meta_tof_adspend
          ELSE NULL
          END) AS meta_tof_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.meta_tof_adspend
          ELSE NULL
          END) AS meta_tof_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.youtube_non_tof_adspend
          ELSE NULL
          END) AS youtube_non_tof_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.youtube_non_tof_adspend
          ELSE NULL
          END) AS youtube_non_tof_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.youtube_non_tof_adspend
          ELSE NULL
          END) AS youtube_non_tof_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.youtube_non_tof_adspend
          ELSE NULL
          END) AS youtube_non_tof_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.youtube_tof_adspend
          ELSE NULL
          END) AS youtube_tof_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.youtube_tof_adspend
          ELSE NULL
          END) AS youtube_tof_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.youtube_tof_adspend
          ELSE NULL
          END) AS youtube_tof_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.youtube_tof_adspend
          ELSE NULL
          END) AS youtube_tof_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.google_adspend
          ELSE NULL
          END) AS google_adspend_L7,  -- Added google_adspend average L7
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.google_adspend
          ELSE NULL
          END) AS google_adspend_L14,  -- Added google_adspend average L14
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.google_adspend
          ELSE NULL
          END) AS google_adspend_L30,  -- Added google_adspend average L30
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.google_adspend
          ELSE NULL
          END) AS google_adspend_MTD,  -- Added google_adspend average MTD
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.google_sands_spend
          ELSE NULL
          END) AS google_sands_spend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.google_sands_spend
          ELSE NULL
          END) AS google_sands_spend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.google_sands_spend
          ELSE NULL
          END) AS google_sands_spend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.google_sands_spend
          ELSE NULL
          END) AS google_sands_spend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.google_search_adspend
          ELSE NULL
          END) AS google_search_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.google_search_adspend
          ELSE NULL
          END) AS google_search_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.google_search_adspend
          ELSE NULL
          END) AS google_search_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.google_search_adspend
          ELSE NULL
          END) AS google_search_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.google_shopping_adspend
          ELSE NULL
          END) AS google_shopping_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.google_shopping_adspend
          ELSE NULL
          END) AS google_shopping_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.google_shopping_adspend
          ELSE NULL
          END) AS google_shopping_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.google_shopping_adspend
          ELSE NULL
          END) AS google_shopping_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.google_performance_max_adspend
          ELSE NULL
          END) AS google_performance_max_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.google_performance_max_adspend
          ELSE NULL
          END) AS google_performance_max_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.google_performance_max_adspend
          ELSE NULL
          END) AS google_performance_max_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.google_performance_max_adspend
          ELSE NULL
          END) AS google_performance_max_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.amazon_adspend
          ELSE NULL
          END) AS amazon_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.amazon_adspend
          ELSE NULL
          END) AS amazon_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.amazon_adspend
          ELSE NULL
          END) AS amazon_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.amazon_adspend
          ELSE NULL
          END) AS amazon_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.tiktok_adspend
          ELSE NULL
          END) AS tiktok_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.tiktok_adspend
          ELSE NULL
          END) AS tiktok_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.tiktok_adspend
          ELSE NULL
          END) AS tiktok_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.tiktok_adspend
          ELSE NULL
          END) AS tiktok_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.TikTokSpend_GMV_Max
          ELSE NULL
          END) AS TikTokSpend_GMV_Max_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.TikTokSpend_GMV_Max
          ELSE NULL
          END) AS TikTokSpend_GMV_Max_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.TikTokSpend_GMV_Max
          ELSE NULL
          END) AS TikTokSpend_GMV_Max_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.TikTokSpend_GMV_Max
          ELSE NULL
          END) AS TikTokSpend_GMV_Max_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.TikTokSpend_Campaign
          ELSE NULL
          END) AS TikTokSpend_Campaign_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.TikTokSpend_Campaign
          ELSE NULL
          END) AS TikTokSpend_Campaign_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.TikTokSpend_Campaign
          ELSE NULL
          END) AS TikTokSpend_Campaign_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.TikTokSpend_Campaign
          ELSE NULL
          END) AS TikTokSpend_Campaign_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.tiktok_tof_adspend
          ELSE NULL
          END) AS tiktok_tof_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.tiktok_tof_adspend
          ELSE NULL
          END) AS tiktok_tof_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.tiktok_tof_adspend
          ELSE NULL
          END) AS tiktok_tof_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.tiktok_tof_adspend
          ELSE NULL
          END) AS tiktok_tof_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Applovin_AdSpend
          ELSE NULL
          END) AS Applovin_AdSpend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Applovin_AdSpend
          ELSE NULL
          END) AS Applovin_AdSpend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Applovin_AdSpend
          ELSE NULL
          END) AS Applovin_AdSpend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Applovin_AdSpend
          ELSE NULL
          END) AS Applovin_AdSpend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.walmart_adspend
          ELSE NULL
          END) AS walmart_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.walmart_adspend
          ELSE NULL
          END) AS walmart_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.walmart_adspend
          ELSE NULL
          END) AS walmart_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.walmart_adspend
          ELSE NULL
          END) AS walmart_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.dsp_adspend
          ELSE NULL
          END) AS dsp_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.dsp_adspend
          ELSE NULL
          END) AS dsp_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.dsp_adspend
          ELSE NULL
          END) AS dsp_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.dsp_adspend
          ELSE NULL
          END) AS dsp_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Amz_Shopify_AdSpend
          ELSE NULL
          END) AS Amz_Shopify_AdSpend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Amz_Shopify_AdSpend
          ELSE NULL
          END) AS Amz_Shopify_AdSpend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Amz_Shopify_AdSpend
          ELSE NULL
          END) AS Amz_Shopify_AdSpend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Amz_Shopify_AdSpend
          ELSE NULL
          END) AS Amz_Shopify_AdSpend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.meta_adspend
          ELSE NULL
          END) AS meta_adspend_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.meta_adspend
          ELSE NULL
          END) AS meta_adspend_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.meta_adspend
          ELSE NULL
          END) AS meta_adspend_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.meta_adspend
          ELSE NULL
          END) AS meta_adspend_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_clicks
          ELSE NULL
          END) AS shopify_clicks_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_clicks
          ELSE NULL
          END) AS shopify_clicks_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_clicks
          ELSE NULL
          END) AS shopify_clicks_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_clicks
          ELSE NULL
          END) AS shopify_clicks_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.reach
          ELSE NULL
          END) AS reach_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.reach
          ELSE NULL
          END) AS reach_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.reach
          ELSE NULL
          END) AS reach_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.reach
          ELSE NULL
          END) AS reach_MTD,

      -- TRIPLE WHALE SECTION METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_first_touch_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_first_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_first_touch_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_first_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_first_touch_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_first_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_first_touch_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_first_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_last_touch_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_last_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_last_touch_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_last_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_last_touch_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_last_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_last_touch_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_last_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_triple_att_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_triple_att_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_triple_att_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_triple_att_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_triple_att_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_triple_att_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_meta_cac_triple_att_7d
          ELSE NULL
          END) AS triple_whale_meta_cac_triple_att_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.meta_in_app_cpa
          ELSE NULL
          END) AS meta_in_app_cpa_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.meta_in_app_cpa
          ELSE NULL
          END) AS meta_in_app_cpa_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.meta_in_app_cpa
          ELSE NULL
          END) AS meta_in_app_cpa_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.meta_in_app_cpa
          ELSE NULL
          END) AS meta_in_app_cpa_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_first_click
          ELSE NULL
          END) AS triple_whale_meta_ncp_first_click_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_first_click
          ELSE NULL
          END) AS triple_whale_meta_ncp_first_click_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_first_click
          ELSE NULL
          END) AS triple_whale_meta_ncp_first_click_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_first_click
          ELSE NULL
          END) AS triple_whale_meta_ncp_first_click_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_lat_click
          ELSE NULL
          END) AS triple_whale_meta_ncp_lat_click_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_lat_click
          ELSE NULL
          END) AS triple_whale_meta_ncp_lat_click_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_lat_click
          ELSE NULL
          END) AS triple_whale_meta_ncp_lat_click_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_lat_click
          ELSE NULL
          END) AS triple_whale_meta_ncp_lat_click_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_triple_att_7d
          ELSE NULL
          END) AS triple_whale_meta_ncp_triple_att_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_triple_att_7d
          ELSE NULL
          END) AS triple_whale_meta_ncp_triple_att_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_triple_att_7d
          ELSE NULL
          END) AS triple_whale_meta_ncp_triple_att_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_meta_ncp_triple_att_7d
          ELSE NULL
          END) AS triple_whale_meta_ncp_triple_att_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.meta_inapp_purchases
          ELSE NULL
          END) AS meta_inapp_purchases_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.meta_inapp_purchases
          ELSE NULL
          END) AS meta_inapp_purchases_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.meta_inapp_purchases
          ELSE NULL
          END) AS meta_inapp_purchases_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.meta_inapp_purchases
          ELSE NULL
          END) AS meta_inapp_purchases_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_first_touch_7d
          ELSE NULL
          END) AS triple_whale_google_cac_first_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_first_touch_7d
          ELSE NULL
          END) AS triple_whale_google_cac_first_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_first_touch_7d
          ELSE NULL
          END) AS triple_whale_google_cac_first_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_google_cac_first_touch_7d
          ELSE NULL
          END) AS triple_whale_google_cac_first_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_last_touch_7d
          ELSE NULL
          END) AS triple_whale_google_cac_last_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_last_touch_7d
          ELSE NULL
          END) AS triple_whale_google_cac_last_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_last_touch_7d
          ELSE NULL
          END) AS triple_whale_google_cac_last_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_google_cac_last_touch_7d
          ELSE NULL
          END) AS triple_whale_google_cac_last_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_triple_att_7d
          ELSE NULL
          END) AS triple_whale_google_cac_triple_att_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_triple_att_7d
          ELSE NULL
          END) AS triple_whale_google_cac_triple_att_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.triple_whale_google_cac_triple_att_7d
          ELSE NULL
          END) AS triple_whale_google_cac_triple_att_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.triple_whale_google_cac_triple_att_7d
          ELSE NULL
          END) AS triple_whale_google_cac_triple_att_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.dg_first_touch_7d
          ELSE NULL
          END) AS dg_first_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.dg_first_touch_7d
          ELSE NULL
          END) AS dg_first_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.dg_first_touch_7d
          ELSE NULL
          END) AS dg_first_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.dg_first_touch_7d
          ELSE NULL
          END) AS dg_first_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.dg_last_touch_7d
          ELSE NULL
          END) AS dg_last_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.dg_last_touch_7d
          ELSE NULL
          END) AS dg_last_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.dg_last_touch_7d
          ELSE NULL
          END) AS dg_last_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.dg_last_touch_7d
          ELSE NULL
          END) AS dg_last_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.dg_triple_att_7d
          ELSE NULL
          END) AS dg_triple_att_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.dg_triple_att_7d
          ELSE NULL
          END) AS dg_triple_att_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.dg_triple_att_7d
          ELSE NULL
          END) AS dg_triple_att_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.dg_triple_att_7d
          ELSE NULL
          END) AS dg_triple_att_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.prospecting_first_touch_7d
          ELSE NULL
          END) AS prospecting_first_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.prospecting_first_touch_7d
          ELSE NULL
          END) AS prospecting_first_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.prospecting_first_touch_7d
          ELSE NULL
          END) AS prospecting_first_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.prospecting_first_touch_7d
          ELSE NULL
          END) AS prospecting_first_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.prospecting_last_touch_7d
          ELSE NULL
          END) AS prospecting_last_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.prospecting_last_touch_7d
          ELSE NULL
          END) AS prospecting_last_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.prospecting_last_touch_7d
          ELSE NULL
          END) AS prospecting_last_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.prospecting_last_touch_7d
          ELSE NULL
          END) AS prospecting_last_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.prospecting_triple_att_7d
          ELSE NULL
          END) AS prospecting_triple_att_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.prospecting_triple_att_7d
          ELSE NULL
          END) AS prospecting_triple_att_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.prospecting_triple_att_7d
          ELSE NULL
          END) AS prospecting_triple_att_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.prospecting_triple_att_7d
          ELSE NULL
          END) AS prospecting_triple_att_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.brand_first_touch_7d
          ELSE NULL
          END) AS brand_first_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.brand_first_touch_7d
          ELSE NULL
          END) AS brand_first_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.brand_first_touch_7d
          ELSE NULL
          END) AS brand_first_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.brand_first_touch_7d
          ELSE NULL
          END) AS brand_first_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.brand_last_touch_7d
          ELSE NULL
          END) AS brand_last_touch_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.brand_last_touch_7d
          ELSE NULL
          END) AS brand_last_touch_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.brand_last_touch_7d
          ELSE NULL
          END) AS brand_last_touch_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.brand_last_touch_7d
          ELSE NULL
          END) AS brand_last_touch_7d_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.brand_triple_att_7d
          ELSE NULL
          END) AS brand_triple_att_7d_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.brand_triple_att_7d
          ELSE NULL
          END) AS brand_triple_att_7d_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.brand_triple_att_7d
          ELSE NULL
          END) AS brand_triple_att_7d_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.brand_triple_att_7d
          ELSE NULL
          END) AS brand_triple_att_7d_MTD,

      -- CUSTOMER METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_customers
          ELSE NULL
          END) AS shopify_customers_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_customers
          ELSE NULL
          END) AS shopify_customers_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_customers
          ELSE NULL
          END) AS shopify_customers_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_customers
          ELSE NULL
          END) AS shopify_customers_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.new_shopify_customers
          ELSE NULL
          END) AS new_shopify_customers_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.new_shopify_customers
          ELSE NULL
          END) AS new_shopify_customers_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.new_shopify_customers
          ELSE NULL
          END) AS new_shopify_customers_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.new_shopify_customers
          ELSE NULL
          END) AS new_shopify_customers_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.new_amazon_customers
          ELSE NULL
          END) AS new_amazon_customers_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.new_amazon_customers
          ELSE NULL
          END) AS new_amazon_customers_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.new_amazon_customers
          ELSE NULL
          END) AS new_amazon_customers_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.new_amazon_customers
          ELSE NULL
          END) AS new_amazon_customers_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Returning_shopify_customers
          ELSE NULL
          END) AS Returning_shopify_customers_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Returning_shopify_customers
          ELSE NULL
          END) AS Returning_shopify_customers_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Returning_shopify_customers
          ELSE NULL
          END) AS Returning_shopify_customers_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Returning_shopify_customers
          ELSE NULL
          END) AS Returning_shopify_customers_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.new_subscribers_recharge
          ELSE NULL
          END) AS new_subscribers_recharge_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.new_subscribers_recharge
          ELSE NULL
          END) AS new_subscribers_recharge_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.new_subscribers_recharge
          ELSE NULL
          END) AS new_subscribers_recharge_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.new_subscribers_recharge
          ELSE NULL
          END) AS new_subscribers_recharge_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.active_subscribers_recharge
          ELSE NULL
          END) AS active_subscribers_recharge_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.active_subscribers_recharge
          ELSE NULL
          END) AS active_subscribers_recharge_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.active_subscribers_recharge
          ELSE NULL
          END) AS active_subscribers_recharge_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.active_subscribers_recharge
          ELSE NULL
          END) AS active_subscribers_recharge_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.churned_subscribers_recharge
          ELSE NULL
          END) AS churned_subscribers_recharge_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.churned_subscribers_recharge
          ELSE NULL
          END) AS churned_subscribers_recharge_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.churned_subscribers_recharge
          ELSE NULL
          END) AS churned_subscribers_recharge_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.churned_subscribers_recharge
          ELSE NULL
          END) AS churned_subscribers_recharge_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.reactivated_subscribers_recharge
          ELSE NULL
          END) AS reactivated_subscribers_recharge_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.reactivated_subscribers_recharge
          ELSE NULL
          END) AS reactivated_subscribers_recharge_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.reactivated_subscribers_recharge
          ELSE NULL
          END) AS reactivated_subscribers_recharge_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.reactivated_subscribers_recharge
          ELSE NULL
          END) AS reactivated_subscribers_recharge_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.net_gain_loss_recharge
          ELSE NULL
          END) AS net_gain_loss_recharge_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.net_gain_loss_recharge
          ELSE NULL
          END) AS net_gain_loss_recharge_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.net_gain_loss_recharge
          ELSE NULL
          END) AS net_gain_loss_recharge_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.net_gain_loss_recharge
          ELSE NULL
          END) AS net_gain_loss_recharge_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.active_subscriptions_recharge
          ELSE NULL
          END) AS active_subscriptions_recharge_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.active_subscriptions_recharge
          ELSE NULL
          END) AS active_subscriptions_recharge_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.active_subscriptions_recharge
          ELSE NULL
          END) AS active_subscriptions_recharge_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.active_subscriptions_recharge
          ELSE NULL
          END) AS active_subscriptions_recharge_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.avg_active_days_per_subscriber_recharge
          ELSE NULL
          END) AS avg_active_days_per_subscriber_recharge_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.avg_active_days_per_subscriber_recharge
          ELSE NULL
          END) AS avg_active_days_per_subscriber_recharge_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.avg_active_days_per_subscriber_recharge
          ELSE NULL
          END) AS avg_active_days_per_subscriber_recharge_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.avg_active_days_per_subscriber_recharge
          ELSE NULL
          END) AS avg_active_days_per_subscriber_recharge_MTD,

      -- ORDER METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_orders
          ELSE NULL
          END) AS shopify_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_orders
          ELSE NULL
          END) AS shopify_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_orders
          ELSE NULL
          END) AS shopify_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_orders
          ELSE NULL
          END) AS shopify_orders_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.new_shopify_orders
          ELSE NULL
          END) AS new_shopify_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.new_shopify_orders
          ELSE NULL
          END) AS new_shopify_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.new_shopify_orders
          ELSE NULL
          END) AS new_shopify_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.new_shopify_orders
          ELSE NULL
          END) AS new_shopify_orders_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Returning_shopify_orders
          ELSE NULL
          END) AS Returning_shopify_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Returning_shopify_orders
          ELSE NULL
          END) AS Returning_shopify_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Returning_shopify_orders
          ELSE NULL
          END) AS Returning_shopify_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Returning_shopify_orders
          ELSE NULL
          END) AS Returning_shopify_orders_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Amazon_orders
          ELSE NULL
          END) AS Amazon_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Amazon_orders
          ELSE NULL
          END) AS Amazon_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Amazon_orders
          ELSE NULL
          END) AS Amazon_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Amazon_orders
          ELSE NULL
          END) AS Amazon_orders_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.TikTok_orders
          ELSE NULL
          END) AS TikTok_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.TikTok_orders
          ELSE NULL
          END) AS TikTok_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.TikTok_orders
          ELSE NULL
          END) AS TikTok_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.TikTok_orders
          ELSE NULL
          END) AS TikTok_orders_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.walmart_orders
          ELSE NULL
          END) AS walmart_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.walmart_orders
          ELSE NULL
          END) AS walmart_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.walmart_orders
          ELSE NULL
          END) AS walmart_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.walmart_orders
          ELSE NULL
          END) AS walmart_orders_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.target_orders
          ELSE NULL
          END) AS target_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.target_orders
          ELSE NULL
          END) AS target_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.target_orders
          ELSE NULL
          END) AS target_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.target_orders
          ELSE NULL
          END) AS target_orders_MTD,

      -- AMAZON ORDER METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.sns_ntb_orders
          ELSE NULL
          END) AS sns_ntb_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.sns_ntb_orders
          ELSE NULL
          END) AS sns_ntb_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.sns_ntb_orders
          ELSE NULL
          END) AS sns_ntb_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.sns_ntb_orders
          ELSE NULL
          END) AS sns_ntb_orders_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.non_sns_ntb_orders
          ELSE NULL
          END) AS non_sns_ntb_orders_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.non_sns_ntb_orders
          ELSE NULL
          END) AS non_sns_ntb_orders_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.non_sns_ntb_orders
          ELSE NULL
          END) AS non_sns_ntb_orders_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.non_sns_ntb_orders
          ELSE NULL
          END) AS non_sns_ntb_orders_MTD,

      -- RETURN METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Returns
          ELSE NULL
          END) AS Returns_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Returns
          ELSE NULL
          END) AS Returns_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Returns
          ELSE NULL
          END) AS Returns_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Returns
          ELSE NULL
          END) AS Returns_MTD,

      -- WEBSITE SESSION METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Online_store_visitors
          ELSE NULL
          END) AS Online_store_visitors_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Online_store_visitors
          ELSE NULL
          END) AS Online_store_visitors_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Online_store_visitors
          ELSE NULL
          END) AS Online_store_visitors_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Online_store_visitors
          ELSE NULL
          END) AS Online_store_visitors_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Sessions_with_cart_additions
          ELSE NULL
          END) AS Sessions_with_cart_additions_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Sessions_with_cart_additions
          ELSE NULL
          END) AS Sessions_with_cart_additions_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Sessions_with_cart_additions
          ELSE NULL
          END) AS Sessions_with_cart_additions_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Sessions_with_cart_additions
          ELSE NULL
          END) AS Sessions_with_cart_additions_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Sessions_that_reached_checkout
          ELSE NULL
          END) AS Sessions_that_reached_checkout_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Sessions_that_reached_checkout
          ELSE NULL
          END) AS Sessions_that_reached_checkout_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Sessions_that_reached_checkout
          ELSE NULL
          END) AS Sessions_that_reached_checkout_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Sessions_that_reached_checkout
          ELSE NULL
          END) AS Sessions_that_reached_checkout_MTD, 
        
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.Sessions_that_completed_checkout
          ELSE NULL
          END) AS Sessions_that_completed_checkout_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.Sessions_that_completed_checkout
          ELSE NULL
          END) AS Sessions_that_completed_checkout_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.Sessions_that_completed_checkout
          ELSE NULL
          END) AS Sessions_that_completed_checkout_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.Sessions_that_completed_checkout
          ELSE NULL
          END) AS Sessions_that_completed_checkout_MTD,

      
      avg(case when cdj.date between date_sub(ms.latest_date, interval 6 day) and ms.latest_date then cdj.Sessions else null end) as Sessions_L7,
    avg(case when cdj.date between date_sub(ms.latest_date, interval 13 day) and ms.latest_date then cdj.Sessions else null end) as Sessions_L14,
    avg(case when cdj.date between date_sub(ms.latest_date, interval 29 day) and ms.latest_date then cdj.Sessions else null end) as Sessions_L30,
    avg(case when cdj.date between ms.month_start_date and ms.latest_date then cdj.Sessions else null end) as Sessions_MTD,

      -- SPENDS AGAINST SALES METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.firsttime_customer_shopify_orders_SpendAgainstSales
          ELSE NULL
          END) AS firsttime_customer_shopify_orders_SpendAgainstSales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.firsttime_customer_shopify_orders_SpendAgainstSales
          ELSE NULL
          END) AS firsttime_customer_shopify_orders_SpendAgainstSales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.firsttime_customer_shopify_orders_SpendAgainstSales
          ELSE NULL
          END) AS firsttime_customer_shopify_orders_SpendAgainstSales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.firsttime_customer_shopify_orders_SpendAgainstSales
          ELSE NULL
          END) AS firsttime_customer_shopify_orders_SpendAgainstSales_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_orders_SpendAgainstSales
          ELSE NULL
          END) AS shopify_orders_SpendAgainstSales_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_orders_SpendAgainstSales
          ELSE NULL
          END) AS shopify_orders_SpendAgainstSales_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_orders_SpendAgainstSales
          ELSE NULL
          END) AS shopify_orders_SpendAgainstSales_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_orders_SpendAgainstSales
          ELSE NULL
          END) AS shopify_orders_SpendAgainstSales_MTD,

      -- TIKTOK SHOP SUBSCRIPTION METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.active_subscriptions_TTS
          ELSE NULL
          END) AS active_subscriptions_TTS_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.active_subscriptions_TTS
          ELSE NULL
          END) AS active_subscriptions_TTS_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.active_subscriptions_TTS
          ELSE NULL
          END) AS active_subscriptions_TTS_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.active_subscriptions_TTS
          ELSE NULL
          END) AS active_subscriptions_TTS_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.active_subscribers_TTS
          ELSE NULL
          END) AS active_subscribers_TTS_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.active_subscribers_TTS
          ELSE NULL
          END) AS active_subscribers_TTS_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.active_subscribers_TTS
          ELSE NULL
          END) AS active_subscribers_TTS_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.active_subscribers_TTS
          ELSE NULL
          END) AS active_subscribers_TTS_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.new_subscriptions_TTS
          ELSE NULL
          END) AS new_subscriptions_TTS_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.new_subscriptions_TTS
          ELSE NULL
          END) AS new_subscriptions_TTS_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.new_subscriptions_TTS
          ELSE NULL
          END) AS new_subscriptions_TTS_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.new_subscriptions_TTS
          ELSE NULL
          END) AS new_subscriptions_TTS_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.churn_TTS
          ELSE NULL
          END) AS churn_TTS_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.churn_TTS
          ELSE NULL
          END) AS churn_TTS_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.churn_TTS
          ELSE NULL
          END) AS churn_TTS_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.churn_TTS
          ELSE NULL
          END) AS churn_TTS_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.net_gain_loss_TTS
          ELSE NULL
          END) AS net_gain_loss_TTS_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.net_gain_loss_TTS
          ELSE NULL
          END) AS net_gain_loss_TTS_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.net_gain_loss_TTS
          ELSE NULL
          END) AS net_gain_loss_TTS_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.net_gain_loss_TTS
          ELSE NULL
          END) AS net_gain_loss_TTS_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.subs_aov_TTS
          ELSE NULL
          END) AS subs_aov_TTS_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.subs_aov_TTS
          ELSE NULL
          END) AS subs_aov_TTS_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.subs_aov_TTS
          ELSE NULL
          END) AS subs_aov_TTS_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.subs_aov_TTS
          ELSE NULL
          END) AS subs_aov_TTS_MTD,

      -- COST METRICS
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_item_discount
          ELSE NULL
          END) AS shopify_item_discount_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_item_discount
          ELSE NULL
          END) AS shopify_item_discount_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_item_discount
          ELSE NULL
          END) AS shopify_item_discount_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_item_discount
          ELSE NULL
          END) AS shopify_item_discount_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_refunded_amount_by_return_date
          ELSE NULL
          END) AS shopify_refunded_amount_by_return_date_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_refunded_amount_by_return_date
          ELSE NULL
          END) AS shopify_refunded_amount_by_return_date_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_refunded_amount_by_return_date
          ELSE NULL
          END) AS shopify_refunded_amount_by_return_date_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_refunded_amount_by_return_date
          ELSE NULL
          END) AS shopify_refunded_amount_by_return_date_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_item_shipping_price
          ELSE NULL
          END) AS shopify_item_shipping_price_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_item_shipping_price
          ELSE NULL
          END) AS shopify_item_shipping_price_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_item_shipping_price
          ELSE NULL
          END) AS shopify_item_shipping_price_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_item_shipping_price
          ELSE NULL
          END) AS shopify_item_shipping_price_MTD,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 6 day)
            AND ms.latest_date
            THEN cdj.shopify_item_total_tax
          ELSE NULL
          END) AS shopify_item_total_tax_L7,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 13 day)
            AND ms.latest_date
            THEN cdj.shopify_item_total_tax
          ELSE NULL
          END) AS shopify_item_total_tax_L14,
      avg(
        CASE
          WHEN
            cdj.date
            BETWEEN date_sub(ms.latest_date, INTERVAL 29 day)
            AND ms.latest_date
            THEN cdj.shopify_item_total_tax
          ELSE NULL
          END) AS shopify_item_total_tax_L30,
      avg(
        CASE
          WHEN cdj.date BETWEEN ms.month_start_date AND ms.latest_date
            THEN cdj.shopify_item_total_tax
          ELSE NULL
          END) AS shopify_item_total_tax_MTD
    FROM CompleteDataJoin cdj
    CROSS JOIN MonthStartCTE ms
    GROUP BY cdj.store_name
  ),

  -- Union of daily data and period averages
  FinalResults AS (

    -- Daily data with original date
    SELECT
      CAST(date AS string) AS date,
      store_name,
      Total_Sales,
      Website_Sales,
      Amazon_Sales,
      Tiktok_Sales,
      Walmart_Sales,
      Target_Sales,

      -- Applovin_Adsales as Applovin_Sales,
      dsp_sales AS DSP_Sales,
      safe_divide(NTB_Sales, Total_Sales) AS NTB_Sales_Perc,
      spend AS Total_Spend,
      Shopify_AdSpend AS Website_Spend,
      shopify_tof_adspend AS Website_TOF_Spend,
      shopify_non_tof_adspend AS Website_Spend_w_o_TOF,
      meta_non_tof_adspend AS Meta_Spend_w_o_TOF,
      meta_tof_adspend AS Meta_TOF_Spend,
      youtube_non_tof_adspend AS YouTube_Spend_w_o_TOF,
      youtube_tof_adspend AS YouTube_TOF_Spend,
      google_sands_spend AS Google_S_S_Spend,
      google_adspend AS Google_AdSpend,
      google_search_adspend AS Google_Search_Spend,
      google_shopping_adspend AS Google_Shopping_Spend,
      google_performance_max_adspend AS Google_Pmax_Spend,
      amazon_adspend AS Amazon_Spend,
      tiktok_adspend AS TikTok_Spend,
      TikTokSpend_GMV_Max AS TikTok_Spend_GMV_Max,
      TikTokSpend_Campaign AS TikTok_Spend_Campaign,
      tiktok_tof_adspend AS TikTok_TOF_Spend,

      -- Applovin_AdSpend as Applovin_Spend,
      walmart_adspend AS Walmart_Spend,
      dsp_adspend AS DSP_Spend,
      safe_divide(shopify_non_tof_adspend, new_shopify_customers) AS DTC_NCPA,
      safe_divide(shopify_tof_adspend, new_shopify_customers) AS TOF_DTC_NCPA,
      safe_divide(
        Amz_Shopify_AdSpend, (new_shopify_customers + new_amazon_customers))
        AS Blended_CAC,
      triple_whale_meta_cac_first_touch_7d AS Meta_CAC_First_Touch_7D,
      triple_whale_meta_cac_last_touch_7d AS Meta_CAC_Last_Touch_7D,
      triple_whale_meta_cac_triple_att_7d AS Meta_CAC_Triple_Att_7D,
      meta_in_app_cpa AS Meta_In_App_CPA,
      triple_whale_meta_ncp_first_click AS Meta_NCP_First_Click,
      triple_whale_meta_ncp_lat_click AS Meta_NCP_Last_Click,
      triple_whale_meta_ncp_triple_att_7d AS Meta_NCP_Triple_Att_7D,
      meta_inapp_purchases AS Meta_In_App_Purchases,
      safe_divide(triple_whale_meta_ncp_triple_att_7d, new_shopify_orders)
        AS Meta_NCP_New_Orders_Shopify_Ratio,
      safe_divide(meta_inapp_purchases, shopify_orders)
        AS Meta_In_App_Purchases_Orders_Shopify_Ratio,
      safe_divide(meta_adspend, Shopify_AdSpend)
        AS Meta_Spend_Total_Website_Spend,
      safe_divide(triple_whale_meta_ncp_triple_att_7d, meta_inapp_purchases)
        AS Meta_NCP_In_App_Purchases_Ratio,
      triple_whale_google_cac_first_touch_7d AS Google_CAC_First_Touch_7D,
      triple_whale_google_cac_last_touch_7d AS Google_CAC_Last_Touch_7D,
      triple_whale_google_cac_triple_att_7d AS Google_CAC_Triple_Att_7D,
      dg_first_touch_7d AS DG_First_Touch_7D,
      dg_last_touch_7d AS DG_Last_Touch_7D,
      dg_triple_att_7d AS DG_Triple_Att_7D,
      prospecting_first_touch_7d AS Prospecting_First_Touch_7D,
      prospecting_last_touch_7d AS Prospecting_Last_Touch_7D,
      prospecting_triple_att_7d AS Prospecting_Triple_Att_7D,
      brand_first_touch_7d AS Brand_First_Touch_7D,
      brand_last_touch_7d AS Brand_Last_Touch_7D,
      brand_triple_att_7d AS Brand_Triple_Att_7D,
      safe_divide(Shopify_AdSpend, Website_Sales) AS Website_TACOS,
      safe_divide(amazon_adspend, Amazon_Sales) AS Amazon_TACOS,
      safe_divide(tiktok_adspend, Tiktok_Sales) AS TikTok_TACOS,

      -- safe_divide(new_subscribers_recharge, new_shopify_customers) as N_Sub_Perc,
      safe_divide(NTB_Shopify_Sales, shopify_non_tof_adspend) AS aMER,
      safe_divide(shopify_non_tof_adspend, Website_Sales) AS MER,
      safe_divide(NTB_Amz_Shopify_Sales, (amazon_adspend + Shopify_AdSpend))
        AS NTB_aMER,
      sns_ntb_amazon_net_sales AS SNS_NTB_Sales,
      non_sns_ntb_amazon_net_sales AS NON_SNS_NTB_Sales,
      sns_ntb_orders AS SNS_NTB_Orders,
      non_sns_ntb_orders AS NON_SNS_NTB_Orders,
      Website_Sales AS Total_Sales_Website,
      NTB_Shopify_Net_Sales AS First_Time_Customer_Net_Sales,
      NTB_Shopify_Sales AS First_Time_Customer_Sales,
      Returning_Shopify_Sales AS Returning_Customer_Sales,
      shopify_customers AS Total_Customers,
      new_shopify_customers AS First_Time_Customers,
      Returning_shopify_customers AS Returning_Customers,

      -- new_subscribers_recharge as New_Subscribers,
      -- safe_divide(new_subscribers_recharge, new_shopify_customers) as New_Subscribers_Perc,
      new_shopify_orders AS New_Orders,
      Returning_shopify_orders AS Returning_Orders,
      shopify_orders AS Shopify_Orders,
      walmart_orders AS Walmart_Orders,
      Amazon_orders AS Amazon_Orders,
      TikTok_orders AS TikTok_Orders,
      target_orders AS Target_Orders,
      safe_divide(Amazon_Sales, Amazon_orders) AS Amazon_AOV,
      safe_divide(Tiktok_Sales, TikTok_orders) AS TikTok_AOV,
      safe_divide(Walmart_Sales, walmart_orders) AS Walmart_AOV,
      safe_divide(Target_Sales, target_orders) AS Target_AOV,
      safe_divide(NTB_Shopify_Net_Sales, new_shopify_orders) AS N_AOV_Net_Sales,
      safe_divide(NTB_Shopify_Sales, new_shopify_orders) AS N_AOV,
      safe_divide(Returning_Shopify_Sales, Returning_shopify_orders) AS R_AOV,
      safe_divide(Shopify_AdSpend, Website_Sales) AS ACOS,
      safe_divide(Shopify_AdSpend, Total_Sales) AS TACOS_Website,
      Returns,
      safe_divide(Returns, shopify_orders) AS Return_Rate_Perc,
      safe_divide(Website_Sales, Shopify_AdSpend) AS MER_Website,
      safe_divide(Shopify_AdSpend, shopify_clicks) AS CPC,
      Online_store_visitors AS Visitors,
      Sessions as Sessions,

      -- safe_divide(new_shopify_customers, Online_store_visitors) as CVR,
      -- safe_divide(Shopify_AdSpend, Online_store_visitors) as CPV,
      -- safe_divide(NTB_Shopify_Sales, Online_store_visitors) as N_RPV,
      -- safe_divide(Website_Sales, Online_store_visitors) as RPV,
      Sessions_with_cart_additions AS ATC,

      -- safe_divide(spend, (reach/1000)) as CPMr,
      -- safe_divide(Shopify_AdSpend, Sessions_with_cart_additions) as Cost_per_ATC,
      safe_divide(Sessions_with_cart_additions, Online_store_visitors)
        AS ATC_Perc,
      safe_divide(new_shopify_orders, Sessions_with_cart_additions)
        AS ATC_to_PU_Perc,
      Sessions_that_reached_checkout AS Initiated_Check_Out,
      Sessions_that_completed_checkout AS Completed_Check_Out,

      -- safe_divide(Shopify_AdSpend, Sessions_that_reached_checkout) as Cost_per_Initiated_Check_Out,
      safe_divide(new_shopify_orders, Sessions_that_reached_checkout)
        AS IC_to_PU_Perc,
      safe_divide(Sessions_that_reached_checkout, Sessions_with_cart_additions)
        AS ATC_to_IC_Perc,
      active_subscribers_recharge AS Active_Subscribers,
      new_subscribers_recharge AS New_Subscribers_Recharge,
      churned_subscribers_recharge AS Churned_Subscribers,
      reactivated_subscribers_recharge AS Reactivated_Subscribers,
      net_gain_loss_recharge AS Net_Gain_Loss,
      safe_divide(active_subscriptions_recharge, active_subscribers_recharge)
        AS Avg_Subscriptions_per_Active_Subscriber,
      safe_divide(shopify_orders, active_subscribers_recharge)
        AS Avg_Orders_per_Active_Subscriber,
      avg_active_days_per_subscriber_recharge AS Avg_Active_Days_per_Subscriber,

      -- active_subscriptions_TTS as Active_Subscriptions_TTS,
      -- active_subscribers_TTS as Active_Subscribers_TTS,
      -- new_subscriptions_TTS as New_Subscriptions_TTS,
      -- churn_TTS as Churned_Subscriptions_TTS,
      -- net_gain_loss_TTS as Net_Gain_Loss_TTS,
      -- subs_aov_TTS as Subscription_AOV_TTS,
      safe_divide(shopify_item_discount, shopify_orders) AS Discount_Per_Order,
      safe_divide(shopify_refunded_amount_by_return_date, shopify_orders)
        AS Return_Amount_Per_Order,
      safe_divide(shopify_item_shipping_price, shopify_orders)
        AS Shipping_Charge_Per_Order,
      safe_divide(shopify_item_total_tax, shopify_orders) AS Tax_Per_Order
    FROM CompleteDataJoin
    UNION ALL

    -- L7 Average row for each store
    SELECT
      'L7 AVG' AS date,
      pa.store_name,
      pa.Total_Sales_L7,
      pa.Website_Sales_L7,
      pa.Amazon_Sales_L7,
      pa.Tiktok_Sales_L7,
      pa.Walmart_Sales_L7,
      pa.Target_Sales_L7,

      -- pa.Applovin_Adsales_L7,
      pa.dsp_sales_L7,
      safe_divide(pa.NTB_Sales_L7, pa.Total_Sales_L7) AS NTB_Sales_Perc,
      pa.spend_L7,
      pa.Shopify_AdSpend_L7,
      pa.shopify_tof_adspend_L7,
      pa.shopify_non_tof_adspend_L7,
      pa.meta_non_tof_adspend_L7,
      pa.meta_tof_adspend_L7,
      pa.youtube_non_tof_adspend_L7,
      pa.youtube_tof_adspend_L7,
      pa.google_sands_spend_L7,
      pa.google_adspend_L7,
      pa.google_search_adspend_L7,
      pa.google_shopping_adspend_L7,
      pa.google_performance_max_adspend_L7,
      pa.amazon_adspend_L7,
      pa.tiktok_adspend_L7,
      pa.TikTokSpend_GMV_Max_L7,
      pa.TikTokSpend_Campaign_L7,
      pa.tiktok_tof_adspend_L7,

      -- pa.Applovin_AdSpend_L7,
      pa.walmart_adspend_L7,
      pa.dsp_adspend_L7,
      safe_divide(pa.shopify_non_tof_adspend_L7, pa.new_shopify_customers_L7)
        AS DTC_NCPA,
      safe_divide(pa.shopify_tof_adspend_L7, pa.new_shopify_customers_L7)
        AS TOF_DTC_NCPA,
      safe_divide(
        pa.Amz_Shopify_AdSpend_L7,
        (pa.new_shopify_customers_L7 + pa.new_amazon_customers_L7))
        AS Blended_CAC,
      pa.triple_whale_meta_cac_first_touch_7d_L7,
      pa.triple_whale_meta_cac_last_touch_7d_L7,
      pa.triple_whale_meta_cac_triple_att_7d_L7,
      pa.meta_in_app_cpa_L7,
      pa.triple_whale_meta_ncp_first_click_L7,
      pa.triple_whale_meta_ncp_lat_click_L7,
      pa.triple_whale_meta_ncp_triple_att_7d_L7,
      pa.meta_inapp_purchases_L7,
      safe_divide(
        pa.triple_whale_meta_ncp_triple_att_7d_L7, pa.new_shopify_orders_L7)
        AS Meta_NCP_New_Orders_Shopify_Ratio,
      safe_divide(pa.meta_inapp_purchases_L7, pa.shopify_orders_L7)
        AS Meta_In_App_Purchases_Orders_Shopify_Ratio,
      safe_divide(pa.meta_adspend_L7, pa.Shopify_AdSpend_L7)
        AS Meta_Spend_Total_Website_Spend,
      safe_divide(
        pa.triple_whale_meta_ncp_triple_att_7d_L7, pa.meta_inapp_purchases_L7)
        AS Meta_NCP_In_App_Purchases_Ratio,
      pa.triple_whale_google_cac_first_touch_7d_L7,
      pa.triple_whale_google_cac_last_touch_7d_L7,
      pa.triple_whale_google_cac_triple_att_7d_L7,
      pa.dg_first_touch_7d_L7,
      pa.dg_last_touch_7d_L7,
      pa.dg_triple_att_7d_L7,
      pa.prospecting_first_touch_7d_L7,
      pa.prospecting_last_touch_7d_L7,
      pa.prospecting_triple_att_7d_L7,
      pa.brand_first_touch_7d_L7,
      pa.brand_last_touch_7d_L7,
      pa.brand_triple_att_7d_L7,
      safe_divide(pa.Shopify_AdSpend_L7, pa.Website_Sales_L7) AS Website_TACOS,
      safe_divide(pa.amazon_adspend_L7, pa.Amazon_Sales_L7) AS Amazon_TACOS,
      safe_divide(pa.tiktok_adspend_L7, pa.Tiktok_Sales_L7) AS TikTok_TACOS,

      -- safe_divide(pa.new_subscribers_recharge_L7, pa.new_shopify_customers_L7) as N_Sub_Perc,
      safe_divide(pa.NTB_Shopify_Sales_L7, pa.shopify_non_tof_adspend_L7)
        AS aMER,
      safe_divide(pa.shopify_non_tof_adspend_L7, pa.Website_Sales_L7) AS MER,
      safe_divide(
        pa.NTB_Amz_Shopify_Sales_L7,
        (pa.amazon_adspend_L7 + pa.Shopify_AdSpend_L7)) AS NTB_aMER,
      pa.sns_ntb_amazon_net_sales_L7,
      pa.non_sns_ntb_amazon_net_sales_L7,
      pa.sns_ntb_orders_L7,
      pa.non_sns_ntb_orders_L7,
      pa.Website_Sales_L7 AS Total_Sales_Website,
      pa.NTB_Shopify_Net_Sales_L7 AS First_Time_Customer_Net_Sales,
      pa.NTB_Shopify_Sales_L7 AS First_Time_Customer_Sales,
      pa.Returning_Shopify_Sales_L7 AS Returning_Customer_Sales,
      pa.shopify_customers_L7 AS Total_Customers,
      pa.new_shopify_customers_L7 AS First_Time_Customers,
      pa.Returning_shopify_customers_L7 AS Returning_Customers,

      -- pa.new_subscribers_recharge_L7 as New_Subscribers,
      -- safe_divide(pa.new_subscribers_recharge_L7, pa.new_shopify_customers_L7) as New_Subscribers_Perc,
      pa.new_shopify_orders_L7 AS New_Orders,
      pa.Returning_shopify_orders_L7 AS Returning_Orders,
      pa.shopify_orders_L7 AS Shopify_Orders,
      pa.walmart_orders_L7 AS Walmart_Orders,
      pa.Amazon_orders_L7 AS Amazon_Orders,
      pa.TikTok_orders_L7 AS TikTok_Orders,
      pa.target_orders_L7 AS Target_Orders,
      safe_divide(pa.Amazon_Sales_L7, pa.Amazon_orders_L7) AS Amazon_AOV,
      safe_divide(pa.Tiktok_Sales_L7, pa.TikTok_orders_L7) AS TikTok_AOV,
      safe_divide(pa.Walmart_Sales_L7, pa.walmart_orders_L7) AS Walmart_AOV,
      safe_divide(pa.Target_Sales_L7, pa.target_orders_L7) AS Target_AOV,
      safe_divide(pa.NTB_Shopify_Net_Sales_L7, pa.new_shopify_orders_L7)
        AS N_AOV_Net_Sales,
      safe_divide(pa.NTB_Shopify_Sales_L7, pa.new_shopify_orders_L7) AS N_AOV,
      safe_divide(pa.Returning_Shopify_Sales_L7, pa.Returning_shopify_orders_L7)
        AS R_AOV,
      safe_divide(pa.Shopify_AdSpend_L7, pa.Website_Sales_L7) AS ACOS,
      safe_divide(pa.Shopify_AdSpend_L7, pa.Total_Sales_L7) AS TACOS_Website,
      pa.Returns_L7,
      safe_divide(pa.Returns_L7, pa.shopify_orders_L7) AS Return_Rate_Perc,
      safe_divide(pa.Website_Sales_L7, pa.Shopify_AdSpend_L7) AS MER_Website,
      safe_divide(pa.Shopify_AdSpend_L7, pa.shopify_clicks_L7) AS CPC,
      pa.Online_store_visitors_L7 AS Visitors,
      pa.Sessions_L7 as Sessions,

      -- safe_divide(pa.new_shopify_customers_L7, pa.Online_store_visitors_L7) as CVR,
      -- safe_divide(pa.Shopify_AdSpend_L7, pa.Online_store_visitors_L7) as CPV,
      -- safe_divide(pa.NTB_Shopify_Sales_L7, pa.Online_store_visitors_L7) as N_RPV,
      -- safe_divide(pa.Website_Sales_L7, pa.Online_store_visitors_L7) as RPV,
      pa.Sessions_with_cart_additions_L7 AS ATC,

      -- safe_divide(pa.spend_L7, (pa.reach_L7/1000)) as CPMr,
      -- safe_divide(pa.Shopify_AdSpend_L7, pa.Sessions_with_cart_additions_L7) as Cost_per_ATC,
      safe_divide(
        pa.Sessions_with_cart_additions_L7, pa.Online_store_visitors_L7)
        AS ATC_Perc,
      safe_divide(pa.new_shopify_orders_L7, pa.Sessions_with_cart_additions_L7)
        AS ATC_to_PU_Perc,
      pa.Sessions_that_reached_checkout_L7 AS Initiated_Check_Out,
      pa.Sessions_that_completed_checkout_L7 AS Completed_Check_Out,

      -- safe_divide(pa.Shopify_AdSpend_L7, pa.Sessions_that_reached_checkout_L7) as Cost_per_Initiated_Check_Out,
      safe_divide(
        pa.new_shopify_orders_L7, pa.Sessions_that_reached_checkout_L7)
        AS IC_to_PU_Perc,
      safe_divide(
        pa.Sessions_that_reached_checkout_L7,
        pa.Sessions_with_cart_additions_L7) AS ATC_to_IC_Perc,
      pa.active_subscribers_recharge_L7 AS Active_Subscribers,
      pa.new_subscribers_recharge_L7 AS New_Subscribers_Recharge,
      pa.churned_subscribers_recharge_L7 AS Churned_Subscribers,
      pa.reactivated_subscribers_recharge_L7 AS Reactivated_Subscribers,
      pa.net_gain_loss_recharge_L7 AS Net_Gain_Loss,
      safe_divide(
        pa.active_subscriptions_recharge_L7, pa.active_subscribers_recharge_L7)
        AS Avg_Subscriptions_per_Active_Subscriber,
      safe_divide(pa.shopify_orders_L7, pa.active_subscribers_recharge_L7)
        AS Avg_Orders_per_Active_Subscriber,
      pa.avg_active_days_per_subscriber_recharge_L7
        AS Avg_Active_Days_per_Subscriber,

      -- pa.active_subscriptions_TTS_L7 as Active_Subscriptions_TTS,
      -- pa.active_subscribers_TTS_L7 as Active_Subscribers_TTS,
      -- pa.new_subscriptions_TTS_L7 as New_Subscriptions_TTS,
      -- pa.churn_TTS_L7 as Churned_Subscriptions_TTS,
      -- pa.net_gain_loss_TTS_L7 as Net_Gain_Loss_TTS,
      -- pa.subs_aov_TTS_L7 as Subscription_AOV_TTS,
      safe_divide(pa.shopify_item_discount_L7, pa.shopify_orders_L7)
        AS Discount_Per_Order,
      safe_divide(
        pa.shopify_refunded_amount_by_return_date_L7, pa.shopify_orders_L7)
        AS Return_Amount_Per_Order,
      safe_divide(pa.shopify_item_shipping_price_L7, pa.shopify_orders_L7)
        AS Shipping_Charge_Per_Order,
      safe_divide(pa.shopify_item_total_tax_L7, pa.shopify_orders_L7)
        AS Tax_Per_Order
    FROM PeriodAverages pa
    CROSS JOIN MonthStartCTE ms
    UNION ALL

    -- L14 Average row for each store
    SELECT
      'L14 AVG' AS date,
      pa.store_name,
      pa.Total_Sales_L14,
      pa.Website_Sales_L14,
      pa.Amazon_Sales_L14,
      pa.Tiktok_Sales_L14,
      pa.Walmart_Sales_L14,
      pa.Target_Sales_L14,

      -- pa.Applovin_Adsales_L14,
      pa.dsp_sales_L14,
      safe_divide(pa.NTB_Sales_L14, pa.Total_Sales_L14) AS NTB_Sales_Perc,
      pa.spend_L14,
      pa.Shopify_AdSpend_L14,
      pa.shopify_tof_adspend_L14,
      pa.shopify_non_tof_adspend_L14,
      pa.meta_non_tof_adspend_L14,
      pa.meta_tof_adspend_L14,
      pa.youtube_non_tof_adspend_L14,
      pa.youtube_tof_adspend_L14,
      pa.google_sands_spend_L14,
      pa.google_adspend_L14,
      pa.google_search_adspend_L14,
      pa.google_shopping_adspend_L14,
      pa.google_performance_max_adspend_L14,
      pa.amazon_adspend_L14,
      pa.tiktok_adspend_L14,
      pa.TikTokSpend_GMV_Max_L14,
      pa.TikTokSpend_Campaign_L14,
      pa.tiktok_tof_adspend_L14,

      -- pa.Applovin_AdSpend_L14,
      pa.walmart_adspend_L14,
      pa.dsp_adspend_L14,
      safe_divide(pa.shopify_non_tof_adspend_L14, pa.new_shopify_customers_L14)
        AS DTC_NCPA,
      safe_divide(pa.shopify_tof_adspend_L14, pa.new_shopify_customers_L14)
        AS TOF_DTC_NCPA,
      safe_divide(
        pa.Amz_Shopify_AdSpend_L14,
        (pa.new_shopify_customers_L14 + pa.new_amazon_customers_L14))
        AS Blended_CAC,
      pa.triple_whale_meta_cac_first_touch_7d_L14,
      pa.triple_whale_meta_cac_last_touch_7d_L14,
      pa.triple_whale_meta_cac_triple_att_7d_L14,
      pa.meta_in_app_cpa_L14,
      pa.triple_whale_meta_ncp_first_click_L14,
      pa.triple_whale_meta_ncp_lat_click_L14,
      pa.triple_whale_meta_ncp_triple_att_7d_L14,
      pa.meta_inapp_purchases_L14,
      safe_divide(
        pa.triple_whale_meta_ncp_triple_att_7d_L14, pa.new_shopify_orders_L14)
        AS Meta_NCP_New_Orders_Shopify_Ratio,
      safe_divide(pa.meta_inapp_purchases_L14, pa.shopify_orders_L14)
        AS Meta_In_App_Purchases_Orders_Shopify_Ratio,
      safe_divide(pa.meta_adspend_L14, pa.Shopify_AdSpend_L14)
        AS Meta_Spend_Total_Website_Spend,
      safe_divide(
        pa.triple_whale_meta_ncp_triple_att_7d_L14, pa.meta_inapp_purchases_L14)
        AS Meta_NCP_In_App_Purchases_Ratio,
      pa.triple_whale_google_cac_first_touch_7d_L14,
      pa.triple_whale_google_cac_last_touch_7d_L14,
      pa.triple_whale_google_cac_triple_att_7d_L14,
      pa.dg_first_touch_7d_L14,
      pa.dg_last_touch_7d_L14,
      pa.dg_triple_att_7d_L14,
      pa.prospecting_first_touch_7d_L14,
      pa.prospecting_last_touch_7d_L14,
      pa.prospecting_triple_att_7d_L14,
      pa.brand_first_touch_7d_L14,
      pa.brand_last_touch_7d_L14,
      pa.brand_triple_att_7d_L14,
      safe_divide(pa.Shopify_AdSpend_L14, pa.Website_Sales_L14)
        AS Website_TACOS,
      safe_divide(pa.amazon_adspend_L14, pa.Amazon_Sales_L14) AS Amazon_TACOS,
      safe_divide(pa.tiktok_adspend_L14, pa.Tiktok_Sales_L14) AS TikTok_TACOS,

      -- safe_divide(pa.new_subscribers_recharge_L14, pa.new_shopify_customers_L14) as N_Sub_Perc,
      safe_divide(pa.NTB_Shopify_Sales_L14, pa.shopify_non_tof_adspend_L14)
        AS aMER,
      safe_divide(pa.shopify_non_tof_adspend_L14, pa.Website_Sales_L14) AS MER,
      safe_divide(
        pa.NTB_Amz_Shopify_Sales_L14,
        (pa.amazon_adspend_L14 + pa.Shopify_AdSpend_L14)) AS NTB_aMER,
      pa.sns_ntb_amazon_net_sales_L14,
      pa.non_sns_ntb_amazon_net_sales_L14,
      pa.sns_ntb_orders_L14,
      pa.non_sns_ntb_orders_L14,
      pa.Website_Sales_L14 AS Total_Sales_Website,
      pa.NTB_Shopify_Net_Sales_L14 AS First_Time_Customer_Net_Sales,
      pa.NTB_Shopify_Sales_L14 AS First_Time_Customer_Sales,
      pa.Returning_Shopify_Sales_L14 AS Returning_Customer_Sales,
      pa.shopify_customers_L14 AS Total_Customers,
      pa.new_shopify_customers_L14 AS First_Time_Customers,
      pa.Returning_shopify_customers_L14 AS Returning_Customers,

      -- pa.new_subscribers_recharge_L14 as New_Subscribers,
      -- safe_divide(pa.new_subscribers_recharge_L14, pa.new_shopify_customers_L14) as New_Subscribers_Perc,
      pa.new_shopify_orders_L14 AS New_Orders,
      pa.Returning_shopify_orders_L14 AS Returning_Orders,
      pa.shopify_orders_L14 AS Shopify_Orders,
      pa.walmart_orders_L14 AS Walmart_Orders,
      pa.Amazon_orders_L14 AS Amazon_Orders,
      pa.TikTok_orders_L14 AS TikTok_Orders,
      pa.target_orders_L14 AS Target_Orders,
      safe_divide(pa.Amazon_Sales_L14, pa.Amazon_orders_L14) AS Amazon_AOV,
      safe_divide(pa.Tiktok_Sales_L14, pa.TikTok_orders_L14) AS TikTok_AOV,
      safe_divide(pa.Walmart_Sales_L14, pa.walmart_orders_L14) AS Walmart_AOV,
      safe_divide(pa.Target_Sales_L14, pa.target_orders_L14) AS Target_AOV,
      safe_divide(pa.NTB_Shopify_Net_Sales_L14, pa.new_shopify_orders_L14)
        AS N_AOV_Net_Sales,
      safe_divide(pa.NTB_Shopify_Sales_L14, pa.new_shopify_orders_L14) AS N_AOV,
      safe_divide(
        pa.Returning_Shopify_Sales_L14, pa.Returning_shopify_orders_L14)
        AS R_AOV,
      safe_divide(pa.Shopify_AdSpend_L14, pa.Website_Sales_L14) AS ACOS,
      safe_divide(pa.Shopify_AdSpend_L14, pa.Total_Sales_L14) AS TACOS_Website,
      pa.Returns_L14,
      safe_divide(pa.Returns_L14, pa.shopify_orders_L14) AS Return_Rate_Perc,
      safe_divide(pa.Website_Sales_L14, pa.Shopify_AdSpend_L14) AS MER_Website,
      safe_divide(pa.Shopify_AdSpend_L14, pa.shopify_clicks_L14) AS CPC,
      pa.Online_store_visitors_L14 AS Visitors,
      pa.Sessions_L14 as Sessions,

      -- safe_divide(pa.new_shopify_customers_L14, pa.Online_store_visitors_L14) as CVR,
      -- safe_divide(pa.Shopify_AdSpend_L14, pa.Online_store_visitors_L14) as CPV,
      -- safe_divide(pa.NTB_Shopify_Sales_L14, pa.Online_store_visitors_L14) as N_RPV,
      -- safe_divide(pa.Website_Sales_L14, pa.Online_store_visitors_L14) as RPV,
      pa.Sessions_with_cart_additions_L14 AS ATC,

      -- safe_divide(pa.spend_L14, (pa.reach_L14/1000)) as CPMr,
      -- safe_divide(pa.Shopify_AdSpend_L14, pa.Sessions_with_cart_additions_L14) as Cost_per_ATC,
      safe_divide(
        pa.Sessions_with_cart_additions_L14, pa.Online_store_visitors_L14)
        AS ATC_Perc,
      safe_divide(
        pa.new_shopify_orders_L14, pa.Sessions_with_cart_additions_L14)
        AS ATC_to_PU_Perc,
      pa.Sessions_that_reached_checkout_L14 AS Initiated_Check_Out,
      pa.Sessions_that_completed_checkout_L14 AS Completed_Check_Out,

      -- safe_divide(pa.Shopify_AdSpend_L14, pa.Sessions_that_reached_checkout_L14) as Cost_per_Initiated_Check_Out,
      safe_divide(
        pa.new_shopify_orders_L14, pa.Sessions_that_reached_checkout_L14)
        AS IC_to_PU_Perc,
      safe_divide(
        pa.Sessions_that_reached_checkout_L14,
        pa.Sessions_with_cart_additions_L14) AS ATC_to_IC_Perc,
      pa.active_subscribers_recharge_L14 AS Active_Subscribers,
      pa.new_subscribers_recharge_L14 AS New_Subscribers_Recharge,
      pa.churned_subscribers_recharge_L14 AS Churned_Subscribers,
      pa.reactivated_subscribers_recharge_L14 AS Reactivated_Subscribers,
      pa.net_gain_loss_recharge_L14 AS Net_Gain_Loss,
      safe_divide(
        pa.active_subscriptions_recharge_L14,
        pa.active_subscribers_recharge_L14)
        AS Avg_Subscriptions_per_Active_Subscriber,
      safe_divide(pa.shopify_orders_L14, pa.active_subscribers_recharge_L14)
        AS Avg_Orders_per_Active_Subscriber,
      pa.avg_active_days_per_subscriber_recharge_L14
        AS Avg_Active_Days_per_Subscriber,

      -- pa.active_subscriptions_TTS_L14 as Active_Subscriptions_TTS,
      -- pa.active_subscribers_TTS_L14 as Active_Subscribers_TTS,
      -- pa.new_subscriptions_TTS_L14 as New_Subscriptions_TTS,
      -- pa.churn_TTS_L14 as Churned_Subscriptions_TTS,
      -- pa.net_gain_loss_TTS_L14 as Net_Gain_Loss_TTS,
      -- pa.subs_aov_TTS_L14 as Subscription_AOV_TTS,
      safe_divide(pa.shopify_item_discount_L14, pa.shopify_orders_L14)
        AS Discount_Per_Order,
      safe_divide(
        pa.shopify_refunded_amount_by_return_date_L14, pa.shopify_orders_L14)
        AS Return_Amount_Per_Order,
      safe_divide(pa.shopify_item_shipping_price_L14, pa.shopify_orders_L14)
        AS Shipping_Charge_Per_Order,
      safe_divide(pa.shopify_item_total_tax_L14, pa.shopify_orders_L14)
        AS Tax_Per_Order
    FROM PeriodAverages pa
    CROSS JOIN MonthStartCTE ms
    UNION ALL

    -- L30 Average row for each store
    SELECT
      'L30 AVG' AS date,
      pa.store_name,
      pa.Total_Sales_L30,
      pa.Website_Sales_L30,
      pa.Amazon_Sales_L30,
      pa.Tiktok_Sales_L30,
      pa.Walmart_Sales_L30,
      pa.Target_Sales_L30,

      -- pa.Applovin_Adsales_L30,
      pa.dsp_sales_L30,
      safe_divide(pa.NTB_Sales_L30, pa.Total_Sales_L30) AS NTB_Sales_Perc,
      pa.spend_L30,
      pa.Shopify_AdSpend_L30,
      pa.shopify_tof_adspend_L30,
      pa.shopify_non_tof_adspend_L30,
      pa.meta_non_tof_adspend_L30,
      pa.meta_tof_adspend_L30,
      pa.youtube_non_tof_adspend_L30,
      pa.youtube_tof_adspend_L30,
      pa.google_sands_spend_L30,
      pa.google_adspend_L30,
      pa.google_search_adspend_L30,
      pa.google_shopping_adspend_L30,
      pa.google_performance_max_adspend_L30,
      pa.amazon_adspend_L30,
      pa.tiktok_adspend_L30,
      pa.TikTokSpend_GMV_Max_L30,
      pa.TikTokSpend_Campaign_L30,
      pa.tiktok_tof_adspend_L30,

      -- pa.Applovin_AdSpend_L30,
      pa.walmart_adspend_L30,
      pa.dsp_adspend_L30,
      safe_divide(pa.shopify_non_tof_adspend_L30, pa.new_shopify_customers_L30)
        AS DTC_NCPA,
      safe_divide(pa.shopify_tof_adspend_L30, pa.new_shopify_customers_L30)
        AS TOF_DTC_NCPA,
      safe_divide(
        pa.Amz_Shopify_AdSpend_L30,
        (pa.new_shopify_customers_L30 + pa.new_amazon_customers_L30))
        AS Blended_CAC,
      pa.triple_whale_meta_cac_first_touch_7d_L30,
      pa.triple_whale_meta_cac_last_touch_7d_L30,
      pa.triple_whale_meta_cac_triple_att_7d_L30,
      pa.meta_in_app_cpa_L30,
      pa.triple_whale_meta_ncp_first_click_L30,
      pa.triple_whale_meta_ncp_lat_click_L30,
      pa.triple_whale_meta_ncp_triple_att_7d_L30,
      pa.meta_inapp_purchases_L30,
      safe_divide(
        pa.triple_whale_meta_ncp_triple_att_7d_L30, pa.new_shopify_orders_L30)
        AS Meta_NCP_New_Orders_Shopify_Ratio,
      safe_divide(pa.meta_inapp_purchases_L30, pa.shopify_orders_L30)
        AS Meta_In_App_Purchases_Orders_Shopify_Ratio,
      safe_divide(pa.meta_adspend_L30, pa.Shopify_AdSpend_L30)
        AS Meta_Spend_Total_Website_Spend,
      safe_divide(
        pa.triple_whale_meta_ncp_triple_att_7d_L30, pa.meta_inapp_purchases_L30)
        AS Meta_NCP_In_App_Purchases_Ratio,
      pa.triple_whale_google_cac_first_touch_7d_L30,
      pa.triple_whale_google_cac_last_touch_7d_L30,
      pa.triple_whale_google_cac_triple_att_7d_L30,
      pa.dg_first_touch_7d_L30,
      pa.dg_last_touch_7d_L30,
      pa.dg_triple_att_7d_L30,
      pa.prospecting_first_touch_7d_L30,
      pa.prospecting_last_touch_7d_L30,
      pa.prospecting_triple_att_7d_L30,
      pa.brand_first_touch_7d_L30,
      pa.brand_last_touch_7d_L30,
      pa.brand_triple_att_7d_L30,
      safe_divide(pa.Shopify_AdSpend_L30, pa.Website_Sales_L30)
        AS Website_TACOS,
      safe_divide(pa.amazon_adspend_L30, pa.Amazon_Sales_L30) AS Amazon_TACOS,
      safe_divide(pa.tiktok_adspend_L30, pa.Tiktok_Sales_L30) AS TikTok_TACOS,

      -- safe_divide(pa.new_subscribers_recharge_L30, pa.new_shopify_customers_L30) as N_Sub_Perc,
      safe_divide(pa.NTB_Shopify_Sales_L30, pa.shopify_non_tof_adspend_L30)
        AS aMER,
      safe_divide(pa.shopify_non_tof_adspend_L30, pa.Website_Sales_L30) AS MER,
      safe_divide(
        pa.NTB_Amz_Shopify_Sales_L30,
        (pa.amazon_adspend_L30 + pa.Shopify_AdSpend_L30)) AS NTB_aMER,
      pa.sns_ntb_amazon_net_sales_L30,
      pa.non_sns_ntb_amazon_net_sales_L30,
      pa.sns_ntb_orders_L30,
      pa.non_sns_ntb_orders_L30,
      pa.Website_Sales_L30 AS Total_Sales_Website,
      pa.NTB_Shopify_Net_Sales_L30 AS First_Time_Customer_Net_Sales,
      pa.NTB_Shopify_Sales_L30 AS First_Time_Customer_Sales,
      pa.Returning_Shopify_Sales_L30 AS Returning_Customer_Sales,
      pa.shopify_customers_L30 AS Total_Customers,
      pa.new_shopify_customers_L30 AS First_Time_Customers,
      pa.Returning_shopify_customers_L30 AS Returning_Customers,

      -- pa.new_subscribers_recharge_L30 as New_Subscribers,
      -- safe_divide(pa.new_subscribers_recharge_L30, pa.new_shopify_customers_L30) as New_Subscribers_Perc,
      pa.new_shopify_orders_L30 AS New_Orders,
      pa.Returning_shopify_orders_L30 AS Returning_Orders,
      pa.shopify_orders_L30 AS Shopify_Orders,
      pa.walmart_orders_L30 AS Walmart_Orders,
      pa.Amazon_orders_L30 AS Amazon_Orders,
      pa.TikTok_orders_L30 AS TikTok_Orders,
      pa.target_orders_L30 AS Target_Orders,
      safe_divide(pa.Amazon_Sales_L30, pa.Amazon_orders_L30) AS Amazon_AOV,
      safe_divide(pa.Tiktok_Sales_L30, pa.TikTok_orders_L30) AS TikTok_AOV,
      safe_divide(pa.Walmart_Sales_L30, pa.walmart_orders_L30) AS Walmart_AOV,
      safe_divide(pa.Target_Sales_L30, pa.target_orders_L30) AS Target_AOV,
      safe_divide(pa.NTB_Shopify_Net_Sales_L30, pa.new_shopify_orders_L30)
        AS N_AOV_Net_Sales,
      safe_divide(pa.NTB_Shopify_Sales_L30, pa.new_shopify_orders_L30) AS N_AOV,
      safe_divide(
        pa.Returning_Shopify_Sales_L30, pa.Returning_shopify_orders_L30)
        AS R_AOV,
      safe_divide(pa.Shopify_AdSpend_L30, pa.Website_Sales_L30) AS ACOS,
      safe_divide(pa.Shopify_AdSpend_L30, pa.Total_Sales_L30) AS TACOS_Website,
      pa.Returns_L30,
      safe_divide(pa.Returns_L30, pa.shopify_orders_L30) AS Return_Rate_Perc,
      safe_divide(pa.Website_Sales_L30, pa.Shopify_AdSpend_L30) AS MER_Website,
      safe_divide(pa.Shopify_AdSpend_L30, pa.shopify_clicks_L30) AS CPC,
      pa.Online_store_visitors_L30 AS Visitors,
      pa.Sessions_L30 as Sessions,

      -- safe_divide(pa.new_shopify_customers_L30, pa.Online_store_visitors_L30) as CVR,
      -- safe_divide(pa.Shopify_AdSpend_L30, pa.Online_store_visitors_L30) as CPV,
      -- safe_divide(pa.NTB_Shopify_Sales_L30, pa.Online_store_visitors_L30) as N_RPV,
      -- safe_divide(pa.Website_Sales_L30, pa.Online_store_visitors_L30) as RPV,
      pa.Sessions_with_cart_additions_L30 AS ATC,

      -- safe_divide(pa.spend_L30, (pa.reach_L30/1000)) as CPMr,
      -- safe_divide(pa.Shopify_AdSpend_L30, pa.Sessions_with_cart_additions_L30) as Cost_per_ATC,
      safe_divide(
        pa.Sessions_with_cart_additions_L30, pa.Online_store_visitors_L30)
        AS ATC_Perc,
      safe_divide(
        pa.new_shopify_orders_L30, pa.Sessions_with_cart_additions_L30)
        AS ATC_to_PU_Perc,
      pa.Sessions_that_reached_checkout_L30 AS Initiated_Check_Out,
      pa.Sessions_that_completed_checkout_L30 AS Completed_Check_Out,

      -- safe_divide(pa.Shopify_AdSpend_L30, pa.Sessions_that_reached_checkout_L30) as Cost_per_Initiated_Check_Out,
      safe_divide(
        pa.new_shopify_orders_L30, pa.Sessions_that_reached_checkout_L30)
        AS IC_to_PU_Perc,
      safe_divide(
        pa.Sessions_that_reached_checkout_L30,
        pa.Sessions_with_cart_additions_L30) AS ATC_to_IC_Perc,
      pa.active_subscribers_recharge_L30 AS Active_Subscribers,
      pa.new_subscribers_recharge_L30 AS New_Subscribers_Recharge,
      pa.churned_subscribers_recharge_L30 AS Churned_Subscribers,
      pa.reactivated_subscribers_recharge_L30 AS Reactivated_Subscribers,
      pa.net_gain_loss_recharge_L30 AS Net_Gain_Loss,
      safe_divide(
        pa.active_subscriptions_recharge_L30,
        pa.active_subscribers_recharge_L30)
        AS Avg_Subscriptions_per_Active_Subscriber,
      safe_divide(pa.shopify_orders_L30, pa.active_subscribers_recharge_L30)
        AS Avg_Orders_per_Active_Subscriber,
      pa.avg_active_days_per_subscriber_recharge_L30
        AS Avg_Active_Days_per_Subscriber,

      -- pa.active_subscriptions_TTS_L30 as Active_Subscriptions_TTS,
      -- pa.active_subscribers_TTS_L30 as Active_Subscribers_TTS,
      -- pa.new_subscriptions_TTS_L30 as New_Subscriptions_TTS,
      -- pa.churn_TTS_L30 as Churned_Subscriptions_TTS,
      -- pa.net_gain_loss_TTS_L30 as Net_Gain_Loss_TTS,
      -- pa.subs_aov_TTS_L30 as Subscription_AOV_TTS,
      safe_divide(pa.shopify_item_discount_L30, pa.shopify_orders_L30)
        AS Discount_Per_Order,
      safe_divide(
        pa.shopify_refunded_amount_by_return_date_L30, pa.shopify_orders_L30)
        AS Return_Amount_Per_Order,
      safe_divide(pa.shopify_item_shipping_price_L30, pa.shopify_orders_L30)
        AS Shipping_Charge_Per_Order,
      safe_divide(pa.shopify_item_total_tax_L30, pa.shopify_orders_L30)
        AS Tax_Per_Order
    FROM PeriodAverages pa
    CROSS JOIN MonthStartCTE ms
    UNION ALL

    -- MTD Average row for each store
    SELECT
      'MTD AVG' AS date,
      pa.store_name,
      pa.Total_Sales_MTD,
      pa.Website_Sales_MTD,
      pa.Amazon_Sales_MTD,
      pa.Tiktok_Sales_MTD,
      pa.Walmart_Sales_MTD,
      pa.Target_Sales_MTD,

      -- pa.Applovin_Adsales_MTD,
      pa.dsp_sales_MTD,
      safe_divide(pa.NTB_Sales_MTD, pa.Total_Sales_MTD) AS NTB_Sales_Perc,
      pa.spend_MTD,
      pa.Shopify_AdSpend_MTD,
      pa.shopify_tof_adspend_MTD,
      pa.shopify_non_tof_adspend_MTD,
      pa.meta_non_tof_adspend_MTD,
      pa.meta_tof_adspend_MTD,
      pa.youtube_non_tof_adspend_MTD,
      pa.youtube_tof_adspend_MTD,
      pa.google_sands_spend_MTD,
      pa.google_adspend_MTD,
      pa.google_search_adspend_MTD,
      pa.google_shopping_adspend_MTD,
      pa.google_performance_max_adspend_MTD,
      pa.amazon_adspend_MTD,
      pa.tiktok_adspend_MTD,
      pa.TikTokSpend_GMV_Max_MTD,
      pa.TikTokSpend_Campaign_MTD,
      pa.tiktok_tof_adspend_MTD,

      -- pa.Applovin_AdSpend_MTD,
      pa.walmart_adspend_MTD,
      pa.dsp_adspend_MTD,
      safe_divide(pa.shopify_non_tof_adspend_MTD, pa.new_shopify_customers_MTD)
        AS DTC_NCPA,
      safe_divide(pa.shopify_tof_adspend_MTD, pa.new_shopify_customers_MTD)
        AS TOF_DTC_NCPA,
      safe_divide(
        pa.Amz_Shopify_AdSpend_MTD,
        (pa.new_shopify_customers_MTD + pa.new_amazon_customers_MTD))
        AS Blended_CAC,
      pa.triple_whale_meta_cac_first_touch_7d_MTD,
      pa.triple_whale_meta_cac_last_touch_7d_MTD,
      pa.triple_whale_meta_cac_triple_att_7d_MTD,
      pa.meta_in_app_cpa_MTD,
      pa.triple_whale_meta_ncp_first_click_MTD,
      pa.triple_whale_meta_ncp_lat_click_MTD,
      pa.triple_whale_meta_ncp_triple_att_7d_MTD,
      pa.meta_inapp_purchases_MTD,
      safe_divide(
        pa.triple_whale_meta_ncp_triple_att_7d_MTD, pa.new_shopify_orders_MTD)
        AS Meta_NCP_New_Orders_Shopify_Ratio,
      safe_divide(pa.meta_inapp_purchases_MTD, pa.shopify_orders_MTD)
        AS Meta_In_App_Purchases_Orders_Shopify_Ratio,
      safe_divide(pa.meta_adspend_MTD, pa.Shopify_AdSpend_MTD)
        AS Meta_Spend_Total_Website_Spend,
      safe_divide(
        pa.triple_whale_meta_ncp_triple_att_7d_MTD, pa.meta_inapp_purchases_MTD)
        AS Meta_NCP_In_App_Purchases_Ratio,
      pa.triple_whale_google_cac_first_touch_7d_MTD,
      pa.triple_whale_google_cac_last_touch_7d_MTD,
      pa.triple_whale_google_cac_triple_att_7d_MTD,
      pa.dg_first_touch_7d_MTD,
      pa.dg_last_touch_7d_MTD,
      pa.dg_triple_att_7d_MTD,
      pa.prospecting_first_touch_7d_MTD,
      pa.prospecting_last_touch_7d_MTD,
      pa.prospecting_triple_att_7d_MTD,
      pa.brand_first_touch_7d_MTD,
      pa.brand_last_touch_7d_MTD,
      pa.brand_triple_att_7d_MTD,
      safe_divide(pa.Shopify_AdSpend_MTD, pa.Website_Sales_MTD)
        AS Website_TACOS,
      safe_divide(pa.amazon_adspend_MTD, pa.Amazon_Sales_MTD) AS Amazon_TACOS,
      safe_divide(pa.tiktok_adspend_MTD, pa.Tiktok_Sales_MTD) AS TikTok_TACOS,

      -- safe_divide(pa.new_subscribers_recharge_MTD, pa.new_shopify_customers_MTD) as N_Sub_Perc,
      safe_divide(pa.NTB_Shopify_Sales_MTD, pa.shopify_non_tof_adspend_MTD)
        AS aMER,
      safe_divide(pa.shopify_non_tof_adspend_MTD, pa.Website_Sales_MTD) AS MER,
      safe_divide(
        pa.NTB_Amz_Shopify_Sales_MTD,
        (pa.amazon_adspend_MTD + pa.Shopify_AdSpend_MTD)) AS NTB_aMER,
      pa.sns_ntb_amazon_net_sales_MTD,
      pa.non_sns_ntb_amazon_net_sales_MTD,
      pa.sns_ntb_orders_MTD,
      pa.non_sns_ntb_orders_MTD,
      pa.Website_Sales_MTD AS Total_Sales_Website,
      pa.NTB_Shopify_Net_Sales_MTD AS First_Time_Customer_Net_Sales,
      pa.NTB_Shopify_Sales_MTD AS First_Time_Customer_Sales,
      pa.Returning_Shopify_Sales_MTD AS Returning_Customer_Sales,
      pa.shopify_customers_MTD AS Total_Customers,
      pa.new_shopify_customers_MTD AS First_Time_Customers,
      pa.Returning_shopify_customers_MTD AS Returning_Customers,

      -- pa.new_subscribers_recharge_MTD as New_Subscribers,
      -- safe_divide(pa.new_subscribers_recharge_MTD, pa.new_shopify_customers_MTD) as New_Subscribers_Perc,
      pa.new_shopify_orders_MTD AS New_Orders,
      pa.Returning_shopify_orders_MTD AS Returning_Orders,
      pa.shopify_orders_MTD AS Shopify_Orders,
      pa.walmart_orders_MTD AS Walmart_Orders,
      pa.Amazon_orders_MTD AS Amazon_Orders,
      pa.TikTok_orders_MTD AS TikTok_Orders,
      pa.target_orders_MTD AS Target_Orders,
      safe_divide(pa.Amazon_Sales_MTD, pa.Amazon_orders_MTD) AS Amazon_AOV,
      safe_divide(pa.Tiktok_Sales_MTD, pa.TikTok_orders_MTD) AS TikTok_AOV,
      safe_divide(pa.Walmart_Sales_MTD, pa.walmart_orders_MTD) AS Walmart_AOV,
      safe_divide(pa.Target_Sales_MTD, pa.target_orders_MTD) AS Target_AOV,
      safe_divide(pa.NTB_Shopify_Net_Sales_MTD, pa.new_shopify_orders_MTD)
        AS N_AOV_Net_Sales,
      safe_divide(pa.NTB_Shopify_Sales_MTD, pa.new_shopify_orders_MTD) AS N_AOV,
      safe_divide(
        pa.Returning_Shopify_Sales_MTD, pa.Returning_shopify_orders_MTD)
        AS R_AOV,
      safe_divide(pa.Shopify_AdSpend_MTD, pa.Website_Sales_MTD) AS ACOS,
      safe_divide(pa.Shopify_AdSpend_MTD, pa.Total_Sales_MTD) AS TACOS_Website,
      pa.Returns_MTD,
      safe_divide(pa.Returns_MTD, pa.shopify_orders_MTD) AS Return_Rate_Perc,
      safe_divide(pa.Website_Sales_MTD, pa.Shopify_AdSpend_MTD) AS MER_Website,
      safe_divide(pa.Shopify_AdSpend_MTD, pa.shopify_clicks_MTD) AS CPC,
      pa.Online_store_visitors_MTD AS Visitors,
      pa.Sessions_MTD as Sessions,

      -- safe_divide(pa.new_shopify_customers_MTD, pa.Online_store_visitors_MTD) as CVR,
      -- safe_divide(pa.Shopify_AdSpend_MTD, pa.Online_store_visitors_MTD) as CPV,
      -- safe_divide(pa.NTB_Shopify_Sales_MTD, pa.Online_store_visitors_MTD) as N_RPV,
      -- safe_divide(pa.Website_Sales_MTD, pa.Online_store_visitors_MTD) as RPV,
      pa.Sessions_with_cart_additions_MTD AS ATC,

      -- safe_divide(pa.spend_MTD, (pa.reach_MTD/1000)) as CPMr,
      -- safe_divide(pa.Shopify_AdSpend_MTD, pa.Sessions_with_cart_additions_MTD) as Cost_per_ATC,
      safe_divide(
        pa.Sessions_with_cart_additions_MTD, pa.Online_store_visitors_MTD)
        AS ATC_Perc,
      safe_divide(
        pa.new_shopify_orders_MTD, pa.Sessions_with_cart_additions_MTD)
        AS ATC_to_PU_Perc,
      pa.Sessions_that_reached_checkout_MTD AS Initiated_Check_Out,
      pa.Sessions_that_completed_checkout_MTD AS Completed_Check_Out,


      -- safe_divide(pa.Shopify_AdSpend_MTD, pa.Sessions_that_reached_checkout_MTD) as Cost_per_Initiated_Check_Out,
      safe_divide(
        pa.new_shopify_orders_MTD, pa.Sessions_that_reached_checkout_MTD)
        AS IC_to_PU_Perc,
      safe_divide(
        pa.Sessions_that_reached_checkout_MTD,
        pa.Sessions_with_cart_additions_MTD) AS ATC_to_IC_Perc,
      pa.active_subscribers_recharge_MTD AS Active_Subscribers,
      pa.new_subscribers_recharge_MTD AS New_Subscribers_Recharge,
      pa.churned_subscribers_recharge_MTD AS Churned_Subscribers,
      pa.reactivated_subscribers_recharge_MTD AS Reactivated_Subscribers,
      pa.net_gain_loss_recharge_MTD AS Net_Gain_Loss,
      safe_divide(
        pa.active_subscriptions_recharge_MTD,
        pa.active_subscribers_recharge_MTD)
        AS Avg_Subscriptions_per_Active_Subscriber,
      safe_divide(pa.shopify_orders_MTD, pa.active_subscribers_recharge_MTD)
        AS Avg_Orders_per_Active_Subscriber,
      pa.avg_active_days_per_subscriber_recharge_MTD
        AS Avg_Active_Days_per_Subscriber,

      -- pa.active_subscriptions_TTS_MTD as Active_Subscriptions_TTS,
      -- pa.active_subscribers_TTS_MTD as Active_Subscribers_TTS,
      -- pa.new_subscriptions_TTS_MTD as New_Subscriptions_TTS,
      -- pa.churn_TTS_MTD as Churned_Subscriptions_TTS,
      -- pa.net_gain_loss_TTS_MTD as Net_Gain_Loss_TTS,
      -- pa.subs_aov_TTS_MTD as Subscription_AOV_TTS,
      safe_divide(pa.shopify_item_discount_MTD, pa.shopify_orders_MTD)
        AS Discount_Per_Order,
      safe_divide(
        pa.shopify_refunded_amount_by_return_date_MTD, pa.shopify_orders_MTD)
        AS Return_Amount_Per_Order,
      safe_divide(pa.shopify_item_shipping_price_MTD, pa.shopify_orders_MTD)
        AS Shipping_Charge_Per_Order,
      safe_divide(pa.shopify_item_total_tax_MTD, pa.shopify_orders_MTD)
        AS Tax_Per_Order
    FROM PeriodAverages pa
    CROSS JOIN MonthStartCTE ms
  )

-- Final output
SELECT *
FROM FinalResults
ORDER BY
  CASE
    WHEN date IN ('L7 AVG', 'L14 AVG', 'L30 AVG', 'MTD AVG') THEN 0
    ELSE 1
    END,
  CASE
    WHEN date = 'L7 AVG' THEN 1
    WHEN date = 'L14 AVG' THEN 2
    WHEN date = 'L30 AVG' THEN 3
    WHEN date = 'MTD AVG' THEN 4
    ELSE 5
    END,
  date DESC

