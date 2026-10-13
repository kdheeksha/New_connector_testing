-- dim_product_hierarchy: values for the Category / Sub-category / Product cascading dropdowns.
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.dim_product_hierarchy` AS
SELECT DISTINCT category, sub_category, product_name AS product
FROM `${PROJECT}.${DATASET}.stg_product_dim`
WHERE product_name IS NOT NULL;
