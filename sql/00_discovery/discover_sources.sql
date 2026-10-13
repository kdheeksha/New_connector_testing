-- Run these in BigQuery (replace <project>) and share the results so staging can be finalised.
-- 1) Datasets
SELECT schema_name FROM `<project>`.INFORMATION_SCHEMA.SCHEMATA ORDER BY 1;

-- 2) Tables per dataset with row counts and freshness  (repeat per dataset or use region-level view)
SELECT table_schema, table_name, table_type, row_count, TIMESTAMP_MILLIS(last_modified_time) AS last_modified
FROM `region-us`.INFORMATION_SCHEMA.TABLE_STORAGE_BY_PROJECT   -- adjust region
WHERE project_id = '<project>' ORDER BY table_schema, table_name;

-- 3) Candidate tables for each dashboard input, by name
SELECT table_schema, table_name
FROM `<project>`.`region-us`.INFORMATION_SCHEMA.TABLES
WHERE REGEXP_CONTAINS(LOWER(table_name),
  r'order|refund|customer|product|variant|sku|cost|cogs|spend|ad_|campaign|attribution|workmagic|northbeam|superfiliate|subscription|recharge|klaviyo')
ORDER BY 1, 2;

-- 4) Column dictionary for the shortlisted tables (edit the IN list)
SELECT table_schema, table_name, column_name, data_type
FROM `<project>`.`region-us`.INFORMATION_SCHEMA.COLUMNS
WHERE table_name IN ('order', 'order_line', 'refund', 'order_line_refund')   -- add the Amazon / ads / attribution tables
ORDER BY table_schema, table_name, ordinal_position;

-- 5) Sanity: does a stable customer id exist for Amazon?  (distinct buyers vs orders)
-- SELECT COUNT(DISTINCT buyer_id) buyers, COUNT(DISTINCT amazon_order_id) orders FROM `<project>.<amazon_dataset>.orders`;
