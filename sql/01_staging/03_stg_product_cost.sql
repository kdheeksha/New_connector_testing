-- stg_product_cost: unit cost of goods per SKU. Where a SKU has no cost, downstream applies the
-- dashboard fallback (55% margin => COGS = 45% of net sales).
CREATE OR REPLACE VIEW `${PROJECT}.${DATASET}.stg_product_cost` AS
SELECT sku, unit_cost
FROM `${PROJECT}.finance.product_cost`          -- ASSUMED: ERP / finance sheet / COGS table
WHERE unit_cost IS NOT NULL;
