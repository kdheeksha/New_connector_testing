-- =====================================================================
-- 08a_export_march_customer_level.sql
-- Produces exports/march_cohort_customer_level.csv
--
-- One row per March 2026 cohort customer, with their bucket under each
-- logic and their M0-M4 cumulative LTR. This is the grain to pivot in
-- Excel to reproduce the validation sheet, and the grain to join to the
-- client's customer list.
--
-- NOT YET RUN -- see doc section 11. This file is the recipe.
--
-- Read-only. Single SELECT. ~11,253 rows.
-- =====================================================================
WITH params AS (
  SELECT DATE '2026-03-01' AS cohort_month, 4 AS max_month_index
),

raw_orders AS (
  SELECT raw_order_id, customer_id, created_at, source_name,
         total_price, subtotal_after_discount
  FROM (
    SELECT CAST(id AS STRING)                          AS raw_order_id,
           CAST(customer[SAFE_OFFSET(0)].id AS STRING) AS customer_id,
           created_at, cancelled_at, source_name,
           SAFE_CAST(total_price AS NUMERIC)    AS total_price,
           SAFE_CAST(subtotal_price AS NUMERIC) AS subtotal_after_discount,
           ROW_NUMBER() OVER (PARTITION BY id ORDER BY _daton_batch_runtime DESC) AS rn
    FROM `insightsprod.equipfoods_5642_prod_raw.Equip_SHOPIFYV2_3317_orders`
    WHERE created_at >= TIMESTAMP '2025-01-01'
  )
  WHERE rn = 1 AND cancelled_at IS NULL
),

order_level AS (
  SELECT CAST(customer_id AS STRING) AS customer_id,
         CAST(order_id    AS STRING) AS order_id,
         MIN(order_date)     AS order_date,
         MAX(revenue_bucket) AS revenue_bucket,
         SUM(COALESCE(item_subtotal_price, 0) - COALESCE(item_discount, 0)
           + COALESCE(item_shipping_price, 0) - COALESCE(item_shipping_tax, 0)) AS order_ltr
  FROM `insightsprod.equipfoods_5642_prod_presentation.OrderLinesMaster`
  WHERE customer_id IS NOT NULL
    AND IFNULL(is_test, FALSE)      = FALSE
    AND IFNULL(is_gift_card, FALSE) = FALSE
    AND platform_name = 'Shopify'
  GROUP BY 1, 2
),

founding AS (
  SELECT customer_id, order_id, order_date AS acq_date, revenue_bucket AS founding_bucket
  FROM (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS rn
    FROM order_level
  )
  WHERE rn = 1
),

acq AS (
  SELECT f.customer_id, f.order_id, f.acq_date, f.founding_bucket,
         IF(LOGICAL_OR(ol.revenue_bucket IN ('NC Subs', 'Recurring Day Of', 'SKIO (Recurring)')),
            'Subscription', 'OTP') AS bucket
  FROM founding f
  JOIN order_level ol ON ol.customer_id = f.customer_id AND ol.order_date = f.acq_date
  GROUP BY 1, 2, 3, 4
),

cohort_base AS (
  SELECT a.customer_id, a.bucket, DATE_TRUNC(a.acq_date, MONTH) AS acq_month, FALSE AS is_faire_only
  FROM acq a
  CROSS JOIN params p
  LEFT JOIN raw_orders t ON t.raw_order_id = a.order_id
  WHERE DATE_TRUNC(a.acq_date, MONTH) = p.cohort_month
    AND (a.founding_bucket IS NULL OR a.founding_bucket != 'TT New')
    AND IFNULL(t.total_price, 1) != 0
),

faire_first AS (
  SELECT customer_id,
         DATE_TRUNC(DATE(MIN(created_at), 'America/New_York'), MONTH) AS first_faire_month
  FROM raw_orders
  WHERE source_name = 'faire' AND customer_id IS NOT NULL
  GROUP BY customer_id
),

cohort_faire_new AS (
  SELECT f.customer_id, 'OTP' AS bucket, f.first_faire_month AS acq_month, TRUE AS is_faire_only
  FROM faire_first f
  CROSS JOIN params p
  LEFT JOIN order_level o USING (customer_id)
  WHERE o.customer_id IS NULL AND f.first_faire_month = p.cohort_month
  GROUP BY 1, 2, 3, 4
),

cohort AS (
  SELECT * FROM cohort_base UNION ALL SELECT * FROM cohort_faire_new
),

cust_orders AS (
  SELECT o.customer_id, o.order_id, o.order_date, o.order_ltr, c.bucket, c.acq_month,
         MIN(IF(o.revenue_bucket IN ('NC Subs', 'Recurring Day Of', 'SKIO (Recurring)'),
                o.order_date, NULL)) OVER (PARTITION BY o.customer_id) AS first_sub_date
  FROM order_level o
  JOIN cohort c USING (customer_id)
),

-- Every revenue event, allocated under both logics.
ev AS (
  SELECT customer_id, acq_month, bucket, order_ltr AS ltr,
         DATE_DIFF(DATE_TRUNC(order_date, MONTH), acq_month, MONTH) AS m,
         IF(DATE_DIFF(DATE_TRUNC(order_date, MONTH), acq_month, MONTH) = 0, bucket,
            IF(bucket = 'Subscription'
               OR (first_sub_date IS NOT NULL AND order_date >= first_sub_date),
               'Subscription', 'OTP')) AS alloc_after
  FROM cust_orders
  UNION ALL
  SELECT c.customer_id, c.acq_month, c.bucket, -COALESCE(rl.item_subtotal_price, 0),
         DATE_DIFF(DATE_TRUNC(rl.return_date, MONTH), c.acq_month, MONTH),
         c.bucket
  FROM `insightsprod.equipfoods_5642_prod_presentation.ReturnLinesMaster` rl
  JOIN cohort c ON CAST(rl.customer_id AS STRING) = c.customer_id
  WHERE IFNULL(rl.is_test, FALSE) = FALSE AND IFNULL(rl.is_gift_card, FALSE) = FALSE
    AND rl.platform_name = 'Shopify'
  UNION ALL
  SELECT c.customer_id, c.acq_month, c.bucket, r.subtotal_after_discount,
         DATE_DIFF(DATE_TRUNC(DATE(r.created_at, 'America/New_York'), MONTH),
                   c.acq_month, MONTH),
         'OTP'
  FROM raw_orders r
  JOIN cohort c USING (customer_id)
  WHERE r.source_name = 'faire'
)

SELECT c.customer_id,
       FORMAT_DATE('%Y-%m', c.acq_month)  AS acquisition_month,
       c.bucket                           AS bucket_before,
       c.is_faire_only,
       ROUND(SUM(IF(e.m <= 0, e.ltr, 0)), 2) AS ltr_m0,
       ROUND(SUM(IF(e.m <= 1, e.ltr, 0)), 2) AS ltr_m1,
       ROUND(SUM(IF(e.m <= 2, e.ltr, 0)), 2) AS ltr_m2,
       ROUND(SUM(IF(e.m <= 3, e.ltr, 0)), 2) AS ltr_m3,
       ROUND(SUM(IF(e.m <= 4, e.ltr, 0)), 2) AS ltr_m4,
       -- same five columns, split by the AFTER allocation
       ROUND(SUM(IF(e.m <= 4 AND e.alloc_after = 'OTP',          e.ltr, 0)), 2) AS ltr_m4_otp_after,
       ROUND(SUM(IF(e.m <= 4 AND e.alloc_after = 'Subscription', e.ltr, 0)), 2) AS ltr_m4_sub_after
FROM cohort c
LEFT JOIN ev e
  ON e.customer_id = c.customer_id
 AND e.m BETWEEN 0 AND (SELECT max_month_index FROM params)
GROUP BY 1, 2, 3, 4
ORDER BY c.bucket, c.customer_id;
