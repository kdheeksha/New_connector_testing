-- ref_marketing_channel: channel list, display order and the `paid` flag (paid channels get CAC / LTV-CAC).
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.ref_marketing_channel` AS
SELECT * FROM UNNEST([
  STRUCT('Meta' AS marketing_channel, TRUE AS is_paid, 1 AS sort_order),
  ('Google', TRUE, 2), ('TikTok', TRUE, 3), ('Amazon Ads', TRUE, 4),
  ('Email & SMS', FALSE, 5), ('Organic', FALSE, 6), ('Unattributed', FALSE, 7),
  ('Superfiliate – Affiliate', TRUE, 8), ('Superfiliate – Paid', TRUE, 9)
]);
