-- stg_product_dim: SKU -> product -> sub-category -> category. Drives the Product tab cascading filters.
-- The category hierarchy is business-defined; it will likely come from a mapping sheet, not Shopify.
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.stg_product_dim` AS
SELECT sku, product_name, sub_category, category
FROM `${PROJECT}.reference.product_hierarchy`;  -- ASSUMED: mapping table (Google Sheet -> BQ external table)
