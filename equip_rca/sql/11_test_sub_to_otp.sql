-- =====================================================================
-- 11_test_sub_to_otp.sql
-- ONE QUESTION: when a customer who joined on a subscription stops
-- subscribing, does the client move their later spending to OTP?
--
-- Our production rule (09) is one-way and nobody stated it out loud
-- until it was questioned:
--     OTP customer starts subscribing   -> we move them
--     Subscriber stops subscribing      -> we never move them
--
-- The first half is tested and confirmed. The second half never was.
-- It was only ever touched inside the rejected "switch back" rule,
-- which changed both halves at once, so its loss proves nothing about
-- this half on its own.
--
-- This query runs two rules side by side over the same cohort:
--
--   B  current production. Once you subscribe you stay Subscription,
--      and if you joined on Subscription you are Subscription for life.
--
--   D  identical to B in every way EXCEPT: a customer who joined on
--      Subscription reverts to OTP for orders placed after their last
--      subscription-type order. An OTP-acquired customer who subscribes
--      still never switches back -- that behaviour is already settled
--      and is deliberately left alone, so only ONE thing differs.
--
-- HOW TO READ THE RESULT
--   Score both against the client, divided by ours, at each cohort's
--   latest month. Today B scores: mean 1.11%, worst 3.48%, no cell
--   over 5%.
--     D clearly better  -> the client does revert them; adopt D.
--     D clearly worse   -> the client does not; B is right, and now
--                          for a measured reason rather than an
--                          unexamined assumption.
--     Too close to call -> look at affected_customers. If it is tiny
--                          the question does not matter either way,
--                          and that is a fine answer to record.
--
-- BUILT-IN CHECK: the logic = 'B current' rows must reproduce the
-- After tab exactly. If they do not, something else moved and the
-- comparison is void. Targets are at the foot of this file.
--
-- Read-only. Single SELECT. Same LineItemMaster notes as 09: returns
-- are rows in this table, no is_test / is_gift_card filter,
-- item_gross_sales = item_subtotal_price, channel not platform_name,
-- and `date` needs backticks.
-- =====================================================================
WITH params AS (
  SELECT DATE '2025-09-01' AS first_cohort,
         DATE '2026-07-01' AS last_cohort,
         10                AS max_month_index,
         0                 AS return_shipping_sign   -- must match 09 and 10
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
         MIN(`date`)         AS order_date,
         MAX(revenue_bucket) AS revenue_bucket,
         SUM(COALESCE(item_gross_sales, 0)    - COALESCE(item_discounts, 0)
           + COALESCE(item_shipping_price, 0) - COALESCE(item_shipping_tax, 0)) AS order_ltr
  FROM `insightsprod.equipfoods_5642_prod_presentation.LineItemMaster`
  WHERE customer_id IS NOT NULL
    AND channel = 'Shopify'
    AND transaction_type = 'Order'
  GROUP BY 1, 2
),

return_level AS (
  SELECT CAST(customer_id AS STRING) AS customer_id,
         CAST(order_id    AS STRING) AS order_id,
         MIN(`date`) AS return_date,
         SUM(COALESCE(item_returns, 0))        AS return_value,
         SUM(COALESCE(item_shipping_price, 0)) AS return_shipping
  FROM `insightsprod.equipfoods_5642_prod_presentation.LineItemMaster`
  WHERE customer_id IS NOT NULL
    AND channel = 'Shopify'
    AND transaction_type = 'Return'
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
  JOIN order_level ol
    ON ol.customer_id = f.customer_id
   AND ol.order_date  = f.acq_date
  GROUP BY 1, 2, 3, 4
),

cohort_base AS (
  SELECT a.customer_id, a.bucket, DATE_TRUNC(a.acq_date, MONTH) AS acq_month
  FROM acq a
  CROSS JOIN params p
  LEFT JOIN raw_orders t ON t.raw_order_id = a.order_id
  WHERE DATE_TRUNC(a.acq_date, MONTH) BETWEEN p.first_cohort AND p.last_cohort
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
  SELECT f.customer_id, 'OTP' AS bucket, f.first_faire_month AS acq_month
  FROM faire_first f
  CROSS JOIN params p
  LEFT JOIN order_level o USING (customer_id)
  WHERE o.customer_id IS NULL
    AND f.first_faire_month BETWEEN p.first_cohort AND p.last_cohort
  GROUP BY 1, 2, 3
),

cohort_plus AS (
  SELECT * FROM cohort_base UNION ALL SELECT * FROM cohort_faire_new
),

faire_rev AS (
  SELECT cp.acq_month, cp.customer_id,
         DATE_DIFF(DATE_TRUNC(DATE(r.created_at, 'America/New_York'), MONTH),
                   cp.acq_month, MONTH) AS m,
         SUM(r.subtotal_after_discount) AS ltr
  FROM raw_orders r
  JOIN cohort_plus cp USING (customer_id)
  WHERE r.source_name = 'faire'
  GROUP BY 1, 2, 3
),

-- First AND last subscription-type order per customer. B needs only the
-- first; D needs the last as well.
cust_orders AS (
  SELECT o.customer_id, o.order_id, o.order_date, o.order_ltr, c.bucket, c.acq_month,
         MIN(IF(o.revenue_bucket IN ('NC Subs', 'Recurring Day Of', 'SKIO (Recurring)'),
                o.order_date, NULL)) OVER (PARTITION BY o.customer_id) AS first_sub_date,
         MAX(IF(o.revenue_bucket IN ('NC Subs', 'Recurring Day Of', 'SKIO (Recurring)'),
                o.order_date, NULL)) OVER (PARTITION BY o.customer_id) AS last_sub_date
  FROM order_level o
  JOIN cohort_base c USING (customer_id)
),

order_alloc AS (
  SELECT customer_id, order_id, acq_month, bucket, order_date, order_ltr,
         -- B: current production
         IF(bucket = 'Subscription'
            OR (first_sub_date IS NOT NULL AND order_date >= first_sub_date),
            'Subscription', 'OTP') AS alloc_b,
         -- D: identical, except a Subscription-acquired customer drops
         --    back to OTP once past their last subscription order
         CASE
           WHEN bucket = 'Subscription' THEN
             IF(last_sub_date IS NOT NULL AND order_date > last_sub_date,
                'OTP', 'Subscription')
           ELSE
             IF(first_sub_date IS NOT NULL AND order_date >= first_sub_date,
                'Subscription', 'OTP')
         END AS alloc_d
  FROM cust_orders
),

-- How many customers does this question even touch? If this is tiny,
-- the scores will barely move and that is itself the answer.
affected AS (
  SELECT acq_month, COUNT(DISTINCT customer_id) AS n_affected
  FROM order_alloc
  WHERE bucket = 'Subscription' AND alloc_d = 'OTP'
  GROUP BY 1
),

events AS (
  SELECT acq_month, bucket, order_date AS ev_date, order_ltr AS ltr, alloc_b, alloc_d
  FROM order_alloc
  UNION ALL
  SELECT c.acq_month, c.bucket, rl.return_date,
         -rl.return_value + (p.return_shipping_sign * rl.return_shipping),
         COALESCE(oa.alloc_b, c.bucket), COALESCE(oa.alloc_d, c.bucket)
  FROM return_level rl
  CROSS JOIN params p
  JOIN cohort_base c ON rl.customer_id = c.customer_id
  LEFT JOIN order_alloc oa ON oa.order_id = rl.order_id
  UNION ALL
  SELECT fr.acq_month, 'OTP', DATE_ADD(fr.acq_month, INTERVAL fr.m MONTH),
         fr.ltr, 'OTP', 'OTP'
  FROM faire_rev fr
),

ev AS (
  SELECT acq_month, bucket, alloc_b, alloc_d, ltr,
         DATE_DIFF(DATE_TRUNC(ev_date, MONTH), acq_month, MONTH)     AS m,
         DATE_DIFF(DATE_TRUNC(ev_date, MONTH), acq_month, MONTH) = 0 AS is_m0
  FROM events
),

-- M0 always stays in the acquisition bucket, same as production.
facts AS (
  SELECT acq_month, 'B current' AS logic, IF(is_m0, bucket, alloc_b) AS b, m, SUM(ltr) AS v
  FROM ev GROUP BY 1, 2, 3, 4
  UNION ALL
  SELECT acq_month, 'D sub reverts', IF(is_m0, bucket, alloc_d), m, SUM(ltr)
  FROM ev GROUP BY 1, 2, 3, 4
),

facts2 AS (
  SELECT acq_month, logic, b, m, SUM(v) AS v FROM facts GROUP BY 1, 2, 3, 4
  UNION ALL
  SELECT acq_month, logic, 'All customers', m, SUM(v) FROM facts GROUP BY 1, 2, 4
),

sizes AS (
  SELECT acq_month, l AS logic, bucket AS b, COUNT(*) AS n
  FROM cohort_plus CROSS JOIN UNNEST(['B current', 'D sub reverts']) AS l
  GROUP BY 1, 2, 3
  UNION ALL
  SELECT acq_month, l, 'All customers', COUNT(*)
  FROM cohort_plus CROSS JOIN UNNEST(['B current', 'D sub reverts']) AS l
  GROUP BY 1, 2, 3
),

grid AS (
  SELECT s.acq_month, s.logic, s.b, s.n, mm AS m
  FROM sizes s
  CROSS JOIN params p
  CROSS JOIN UNNEST(GENERATE_ARRAY(0, p.max_month_index)) AS mm
  WHERE DATE_ADD(s.acq_month, INTERVAL mm MONTH) < DATE_TRUNC(CURRENT_DATE(), MONTH)
)

SELECT FORMAT_DATE('%Y-%m', g.acq_month)   AS acquisition_month,
       g.logic,
       g.b                                 AS bucket,
       g.m                                 AS month_index,
       g.n                                 AS cohort_customers,
       IFNULL(af.n_affected, 0)            AS subs_who_stopped,
       ROUND(SUM(COALESCE(f.v, 0)) OVER (
         PARTITION BY g.acq_month, g.logic, g.b ORDER BY g.m), 0)       AS cum_revenue,
       ROUND(SUM(COALESCE(f.v, 0)) OVER (
         PARTITION BY g.acq_month, g.logic, g.b ORDER BY g.m) / g.n, 2) AS cum_ltr_per_customer
FROM grid g
LEFT JOIN facts2 f
  ON f.acq_month = g.acq_month AND f.logic = g.logic AND f.b = g.b AND f.m = g.m
LEFT JOIN affected af
  ON af.acq_month = g.acq_month
ORDER BY g.logic, g.b, acquisition_month, g.m;

-- =====================================================================
-- VALIDATION -- the 'B current' rows must match the After tab exactly.
--
--   2026-03  OTP            6,676 customers   M0  97.08   M4 128.78
--            Subscription   4,577 customers   M0 101.02   M4 255.93
--            All customers 11,253 customers   M0  98.68   M4 180.50
--   2025-09  OTP            4,767 customers   M10 136.51
--            Subscription   3,153 customers   M10 411.00
--
-- Both logics must have IDENTICAL customer counts -- D reallocates
-- revenue, it does not add or remove anyone. If the counts differ, the
-- query is wrong, not the rule.
--
-- 'All customers' must also be identical between B and D in every cell,
-- for the same reason: D only moves money between the two buckets.
-- =====================================================================
