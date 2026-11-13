---
name: amazon-dashboard-metric-catalog
description: Build and audit the Adverio Amazon/Daton dashboard metric catalog — use-case map workbook, dataset consolidation, YoY chart tables, Luzmo datasets, and brand onboarding in the master-sheet dbt models. Use for Adverio dataset redundancy, metric accuracy and new-brand blocks.
---

# Adverio Amazon dashboard metric catalog & brand onboarding

## Context
Adverio warehouse: BigQuery project `adveriodatondw` (raw: `daton_raw_data`), prod dataset `production_dataset`,
dev/test schema `dev_edm`. Dashboards in **Luzmo**. Marketplaces: Amazon US/CA, Walmart/Target P&L, DSP. 17 brands.
Brand start dates live in `Brand_Start_Date` (`Adverio_Start_Date`).

## Use-case map workbook (v4)
Tabs: **Overview** (12 use cases · Business Definition · Metric Mix · Datasets) · **Metric Detail** (100 dataset rows,
98 unique, full metric breakdown) · **Rules & Notes** (picker-column rule for 15 datasets, PPS parent/child dedup,
Account Overview merge caveat, removed-datasets log, test-dashboard exclusions).
Counts: 254 metrics (Account Overview), 123 (PPS), 1,327 metric entries audited.
Always recompute counts and set-diff Overview vs Metric Detail after each edit.

## Audit method
1. Pull real column lists from BigQuery for each disputed metric; claim = exists / missing / mislabelled.
2. Verified 7 of 7 sampled disputes (e.g. `YOY_Fees` has no ad columns; `YOY_ASIN` has Gross_Margin/ROI, no Profit;
   `Order_Level_Customer_Division` has Customers + Revenue only → "AOV" is really revenue per customer).
3. Source Excel can **undercount**: `YOY_Charts_Ratios` stores AdSpend/AdSales but the catalog did not list them.
   7 of 8 "unique KPIs" in `YOY_Charts_Ratios_Advertising` were false positives; **CTR** is the real gap
   (Impressions/Clicks absent across all 270 columns).
4. ACoS, TACoS, RoAS, TROAS, Ad Sales % can be Luzmo formula fields from stored components.
5. `_temp` tables (`Brand_Level_Cohorts_temp`, `Product_Level_Cohorts_temp`, 25M rows, current through 2026-09-01, in
   `production_dataset`) are live — judge by freshness/schema/location, not by name. `dev_edm` is the true test schema.
   Needs Luzmo access or `bigquery.jobs.listAll` to prove dashboard usage.
6. Decisions for owners: add Impressions/Clicks to YoY and retire the Advertising table / keep for CTR / wait for Luzmo check.

## Adding a brand to master-sheet dbt models (RainEyeDropsUS example)
- Product categories model: add block at end of `final` CTE with `Product_Lifecycle` mapping
  (Active/Active-OOS→Active; Inactive/Closed→Discontinued), `WHERE Product_Lifecycle <> 'Parent'`, `QUALIFY ROW_NUMBER() OVER (PARTITION BY ASIN)=1`.
- COGS Masterfile model: `Child_ASIN as asin, SKU, COGS/fees cast to NUMERIC with null/'' → 0`,
  `QUALIFY ROW_NUMBER() OVER (PARTITION BY Child_ASIN, SKU)=1`, restore the `Child_ASIN <> 'B07CX95VRT' and <> ''` filter.
- Provide duplicate-check SQL (`GROUP BY Child_ASIN, SKU HAVING COUNT(*)>1`) and `GROUP BY Product_Lifecycle` profile query.
- Known risk: arbitrary survivor with no ORDER BY — an ASIN with both Active and Closed rows can flip between runs.

## Presentation-layer question answered
Temp presentation models vs actual dashboards: verify by Luzmo dataset connections, not table name.
