# Equip Foods – Business Logic Documentation

---

## Table of Contents

0. [Rule Precedence](#0-rule-precedence)
1. [General Rules & Client-Specific Configuration](#1-general-rules--client-specific-configuration)
2. [Metric Definitions, Formulas & Edge Cases](#2-metric-definitions-formulas--edge-cases)
3. [Table Selection & Conflict Resolution](#3-table-selection--conflict-resolution)
4. [Domains & Sub-Domains](#4-domains--sub-domains)
5. [Client Expectations & Contextual Knowledge](#5-client-expectations--contextual-knowledge)

---

## 0. Rule Precedence

When two rules in this file could both apply and would produce different results, resolve the conflict using this order — highest first. A lower-priority rule must never override a higher-priority one.

1. **Explicit instruction from the user in the current request.**
2. **Context already confirmed earlier in the same conversation** (Section 1.0).
3. **Metric-specific rules** (the individual metric's own Definition/Formula/SQL in Section 2).
4. **Table/grain-specific mandatory rules** (e.g. Sections 1.11, 1.12, 1.16's TikTok exclusion, 1.17's table selection).
5. **Client-wide defaults** (e.g. Section 1.3 channel default to `acq_channel`).
6. **Clarification/disambiguation rules** (e.g. Section 1.1 Time Period Confirmation Rule, Section 1.7 SKU vs Entry SKU default, Section 1.16 Revenue Bucket level, Section 1.17 cohort vs business-level, Section 1.18 month-based vs order-sequence anchor).
7. **Formatting/display rules** (Section 1.14, Section 5.2).

Example: if the user explicitly says "show me the last 3 months" (priority 1), that overrides the Time Period Confirmation Rule at priority 6 that would otherwise require asking. If two rules at the same priority level seem to conflict, that is a documentation gap — flag it rather than guessing.

> ⚠ **Absolute PII rules — outside this precedence order.** The rules below are not ranked and are never overridden by any rule above, **including an explicit user request (priority 1)**:
> - The "Never query" tables and columns in Section 3.1.
> - **`R-PII-DIMORDERS-01` (Section 1.20):** never `SELECT *` from `dim_orders`, and never reference its `note`, `comments`, or `tags` columns; never join `dim_orders` onward to `dim_customer` or `dim_address`.
>
> If a user asks for order notes, comments, or tags, decline — say these fields are not available — and do not query them.

---

## 1. General Rules & Client-Specific Configuration

### 1.0 Conversational Context Rule `[R-CONTEXT-01]`

> **Global rule — takes precedence over all individual confirmation rules** (priority 2 in Section 0's precedence order).

Any filter, dimension, or context explicitly confirmed earlier in the conversation — channel, acquisition type, cohort month, time period, or any other dimension — carries forward automatically for all subsequent queries in the same conversation. Do not re-ask for anything already established.

Only re-confirm a filter if the user explicitly signals a change (e.g. "now show me Subscription only", "switch to Amazon", "actually for Q1 2025").

---

### 1.1 Calendar System & Time Period Rule `[R-DATE-01]`

Equip Foods uses the **standard Gregorian calendar (Jan 1 – Dec 31)**. There is no fiscal or non-standard calendar in use. All cohort analysis is at monthly granularity.

| Property | Value |
|---|---|
| Calendar Type | Standard (Jan–Dec) |
| Default Granularity | Monthly |
| Primary Date Column (order-level) | `date` in `LineItemMaster`; `customer_acq_date` for acquisition date |
| Cohort Date Column | `acq_month` (DATE, first of month) in cohort tables |
| Cohort Period Column | `month_diff` (integer, months elapsed since acquisition) in cohort tables |
| Fiscal Calendar Table | None |

> **`R-DATE-01` — Time Period Confirmation Rule (authoritative).** If the user does not specify a time period, always stop and confirm before generating SQL. **There is no automatic default time period.** Never silently apply "last 12 months" or any other window when the user hasn't stated one — the patterns in Section 1.5 (e.g. "last 12 acquisition months") are only used when the user explicitly asks for them.

**Date range syntax (`R-DATE-01`):**
- Always use `>= start_date AND < end_date`. Never use `BETWEEN`, and never use `<= end_date`, for any date-range filter anywhere in this file — this is the single date-boundary convention across all tables and metrics.
- Current partial months are included in cohort data. Always flag partial cohort months in output.

> **Timezone:** All date columns are stored in UTC (BigQuery default). No timezone conversion is applied.

---

### 1.2 Default Term Definitions (Disambiguation)

| Term Used by User | Default Interpretation | Column / Formula | Source |
|---|---|---|---|
| Gross Sales | Gross item revenue before discounts and returns — the top line, before any deduction | `item_gross_sales` | `LineItemMaster`, cohort tables |
| Net Sales | Gross Sales − discounts − returns | See Section 2.1 | Cohort tables or `LineItemMaster` |
| Net Shipping Charges | Total Shipping Charges − Shipping Taxes | See Section 2.1 | Cohort tables or `LineItemMaster` |
| Total Revenue | Net Sales + Net Shipping Charges | See Section 2.1 | Cohort tables or `LineItemMaster` |
| **Revenue** (bare/generic term, no qualifier) | **Defaults to Total Revenue** — the primary Equip Foods revenue metric. Do not treat a bare "Revenue" as a synonym for Gross Sales. If the user says "gross revenue" or "top-line revenue", that means Gross Sales instead. **Always flag this interpretation in the response** — e.g. *"Interpreting 'revenue' as Total Revenue (Net Sales + Net Shipping Charges)."* | See Section 2.1 | Cohort tables or `LineItemMaster` |
| Discounts | Item-level discounts | `item_discount_total` (cohort tables) / `item_discounts` (LineItemMaster) | — |
| Discount Code | An individual code applied to an order (promo code, coupon). Only used when the question is about codes — a plain "discounts" or "discount rate" stays on the Discounts / Discount Rate metrics with no code join. | `discount_codes`, split into individual codes | `dim_orders` joined to `LineItemMaster` — Section 1.20. ⚠ CRITICAL: never `SELECT *`, `note`, `comments`, or `tags` from `dim_orders` (`R-PII-DIMORDERS-01`) |
| Returns | Return value deducted | `item_returns_total` (cohort tables) / `item_returns` (LineItemMaster) | — |
| LTR / Lifetime Revenue | Running cumulative Total Revenue since acquisition | `running_total_revenue` window function | `simplified_customer_cohorts_v2` |
| LTRPC / LTR Per Customer | LTR ÷ Customers Acquired | `running_total_revenue / customers_acquired` | `simplified_customer_cohorts_v2` |
| LTV / Lifetime Value | Running cumulative Total Revenue minus actual COGS since acquisition; falls back to a fixed Gross Margin % per channel only when COGS is `NULL` (rare — 0% null observed across 24 months, see EF-012) | `RUNNING_SUM(Total Revenue − COALESCE(COGS, Total Revenue × (1 − channel Gross Margin %)))` | `simplified_customer_cohorts_v2` |
| LTVPC / LTV Per Customer | LTV ÷ Customers Acquired | `LTV / customers_acquired` | `simplified_customer_cohorts_v2` |
| CAC / Customer Acquisition Cost | Ad spend at acquisition month ÷ Customers Acquired | `adspend / customer_count` at `month_diff = 0` | Cohort tables |
| LTV/CAC | LTV ÷ CAC | `LTV / CAC` | `simplified_customer_cohorts_v2` |
| AOV | Total Revenue ÷ Order Count | `Total Revenue / order_count` | Cohort tables |
| OPC / Orders Per Customer | Cumulative orders ÷ Customers Acquired (running) | `RUNNING_SUM(order_count) / customers_acquired` | Cohort tables |
| UPO / Units Per Order | Total units ÷ Total orders | `item_quantity / order_count` | Cohort tables |
| Customers Acquired | Count at `month_diff = 0` — fixed denominator for all cohort ratios | `SUM(customer_count) WHERE month_diff = 0` | Cohort tables |
| Repurchase Rate | Customers active in period ÷ Customers Acquired | `customer_count / customers_acquired` | Cohort tables |
| Revenue Retention | Total Revenue in period ÷ Total Revenue at `month_diff = 0` | `Total Revenue / Revenue Acquired` | `simplified_customer_cohorts_v2` |
| Churn Rate | Customers churned in `month_diff` ÷ Customers Acquired | `customer_count / total_customers_acquired` | `simplified_churn_customers` |
| Cumulative Churn Rate | Running churned ÷ Customers Acquired | `RUNNING_SUM(customer_count) / total_customers_acquired` | `simplified_churn_customers` |
| Retention Rate | 1 − Cumulative Churn Rate | Derived | `simplified_churn_customers` |
| **Retention** (bare/generic term, no qualifier) | **Defaults to Retention Rate** — customer-level retention (`1 − Cumulative Churn Rate`). Do not treat a bare "Retention" as Revenue Retention, Subscriber Retention Rate, or Subscription Revenue Retained. Only use one of those when the user explicitly says "revenue retention," "subscriber retention," or "subscription revenue retained." **Always flag this interpretation in the response** — e.g. *"Interpreting 'retention' as Retention Rate (1 − Cumulative Churn Rate)."* | Derived | `simplified_churn_customers` |
| Discount Rate | Discounts ÷ Total Revenue | `item_discount_total / Total Revenue` | Cohort tables |
| Gross Margin | (Total Revenue − actual COGS) ÷ Total Revenue; falls back to a fixed % per channel — `55.0%` DTC/Shopify, `49.5%` Amazon — only when COGS is `NULL` (rare, see EF-012). Blended queries: compute each row's own profit (actual or fallback) first, then combine — never a blended fixed %. | `SUM(Total Revenue − COALESCE(COGS, Total Revenue × (1 − channel %))) / SUM(Total Revenue)` | `LineItemMaster` (also feeds LTV on cohort tables — see Section 2.4) |
| Subscriber Take Rate | Subscription-acquired ÷ Total customers | `COUNT(acq_type='Subscription') / COUNT(customer_id)` | `LineItemMaster` |
| OTP to Subscriber Conversion | OTP customers who later subscribed ÷ All OTP customers | `COUNT(acq_type≠'Subscription' AND subscriber_status='Subscriber') / COUNT(acq_type≠'Subscription')` | `LineItemMaster` |
| Channel | Sales channel at acquisition | `acq_channel` (cohort tables) / `channel` (LineItemMaster) | — |
| Acquisition Type | OTP vs Subscription at first purchase | `acq_type` (cohort tables) / `customer_acq_type` (LineItemMaster) | — |
| Purchasing Pattern | Lifetime order behaviour | `purchasing_pattern` (cohort tables) / `customer_purchasing_pattern` (LineItemMaster) | — |
| Revenue Bucket | Order-level channel/subscription/new-vs-returning segment, pre-computed upstream. Can vary order-to-order for the same customer. | `revenue_bucket` | `LineItemMaster`, `simplified_order_cohorts_v2` |
| Revenue Bucket at Acquisition | Same 7-segment taxonomy, fixed to the customer's first-order bucket. Never changes for a given customer. | `revenue_bucket_at_acquisition` | `simplified_customer_cohorts_v2`, `simplified_churn_customers` |

> **Column name divergence — critical:** `LineItemMaster` uses `item_discounts` and `item_returns` (no `_total` suffix). All cohort tables use `item_discount_total` and `item_returns_total`. Never mix these across tables in the same formula.

 **`[R-PERIOD-01]` Net Sales — cohort-qualified question (e.g. "Net Sales for customers acquired in 2025"):** This is the **cohort-level** ask — see Section 1.17 / `R-TABLE-01`.
> When the user asks for Net Sales **for a specific acquisition cohort** (a year, month, or other acquisition-based grouping), always return **two numbers**, clearly labelled:
> 1. **Lifetime Net Sales** — `RUNNING_SUM(Net Sales)` summed to the latest available `month_diff` for that cohort (i.e. all revenue generated by that cohort to date, regardless of when each transaction happened).
> 2. **Net Sales within the acquisition year only** — Net Sales restricted to transactions that occurred within the cohort's acquisition calendar year (e.g. only `month_diff` values whose transaction date falls in 2025, for a 2025 cohort).
> Label both clearly in the response — do not return a single ambiguous number for a cohort-qualified Net Sales question.

> **Net Sales / Revenue — no cohort mentioned (e.g. "overall Net Sales in 2025"):** This is the **business-level (transactional)** ask — see Section 1.17 for full table-selection guidance.
> When the user asks for Net Sales or Revenue for a calendar year or period **without** specifying an acquisition cohort, default to **all transactions that occurred in that period**, regardless of when the customer was originally acquired (i.e. query by transaction date, not acquisition date). Use `LineItemMaster` filtered by `date`, or `simplified_customer_cohorts_v2` filtered/grouped by `order_month` (never `acq_month`/`month_diff`) if an acquisition-level dimension slice is also needed — never `simplified_order_cohorts_v2` for this (Section 5.4, EF-015). **Always state this assumption explicitly in the response** — e.g. *"Assuming this means all Net Sales transactions in 2025, regardless of when the customer was acquired."*

> **Customers Acquired — period-qualified question (e.g. "customers acquired in 2025"):**
> When the user specifies a period (a year, quarter, etc.) for Customers Acquired, always return **one single aggregated number** for that entire period — never a month-by-month breakdown unless the user explicitly asks for a trend, monthly view, or breakdown by month. Sum `customer_count` at `month_diff = 0` across all `acq_month` values within the specified period into one total.

---

### 1.2.1 Net Sales — Query Pattern Reference

**Lifetime Net Sales for a cohort (Fix 2, part 1):**
```sql
-- For a 2025 acquisition cohort, all transactions to date
SELECT
  ROUND(SUM(COALESCE(item_gross_sales,0)) - SUM(COALESCE(item_discount_total,0)) - SUM(COALESCE(item_returns_total,0)), 0) AS lifetime_net_sales
FROM `insightsprod.equipfoods_5642_prod_presentation.simplified_customer_cohorts_v2`
WHERE EXTRACT(YEAR FROM acq_month) = 2025;
```

**Net Sales within acquisition year only (Fix 2, part 2):**
```sql
-- For a 2025 acquisition cohort, restricted to transactions that occurred in 2025
-- month_diff months falling within the same calendar year as acq_month
SELECT
  ROUND(SUM(COALESCE(item_gross_sales,0)) - SUM(COALESCE(item_discount_total,0)) - SUM(COALESCE(item_returns_total,0)), 0) AS net_sales_within_acq_year
FROM `insightsprod.equipfoods_5642_prod_presentation.simplified_customer_cohorts_v2`
WHERE EXTRACT(YEAR FROM acq_month) = 2025
  AND EXTRACT(YEAR FROM DATE_ADD(acq_month, INTERVAL month_diff MONTH)) = 2025;
```

**Overall Net Sales, no cohort specified (Fix 3):**
```sql
-- "Net Sales in 2025" with no acquisition cohort mentioned — all transactions in 2025
-- regardless of customer acquisition date. State this assumption in the response.
SELECT
  ROUND(SUM(COALESCE(item_gross_sales,0)) - SUM(COALESCE(item_discounts,0)) - SUM(COALESCE(item_returns,0)), 0) AS net_sales_2025_all_transactions
FROM `insightsprod.equipfoods_5642_prod_presentation.LineItemMaster`
WHERE EXTRACT(YEAR FROM date) = 2025;
```

**Plain business-level Total Revenue for a period, no dimension breakdown — e.g. "revenue for 2025-01":**
```sql
-- Business-level (transactional): represents all Total Revenue transactions occurring in
-- January 2025, regardless of when the customer was acquired. Filter/group by order_month,
-- NOT acq_month/month_diff.
SELECT
  ROUND(
    SUM(COALESCE(item_gross_sales,0)) - SUM(COALESCE(item_discount_total,0)) - SUM(COALESCE(item_returns_total,0))
    + SUM(COALESCE(shipping_price_total,0)) - SUM(COALESCE(shipping_tax_total,0))
  , 0) AS total_revenue_2025_01_all_transactions
FROM `insightsprod.equipfoods_5642_prod_presentation.simplified_customer_cohorts_v2`
WHERE order_month = DATE '2025-01-01';
```

**Business-level Net Sales sliced by an acquisition-level dimension (Section 1.17) — e.g. "revenue in March 2026 by acquisition channel":**
```sql
-- Business-level ask (transactional, not cohort-qualified) that also needs an acquisition-level
-- dimension slice (acq_channel here). Group by order_month, NOT acq_month/month_diff.
-- Never use simplified_order_cohorts_v2 for this — see Section 5.4, EF-015.
SELECT
  acq_channel,
  ROUND(SUM(COALESCE(item_gross_sales,0)) - SUM(COALESCE(item_discount_total,0)) - SUM(COALESCE(item_returns_total,0)), 0) AS net_sales
FROM `insightsprod.equipfoods_5642_prod_presentation.simplified_customer_cohorts_v2`
WHERE order_month = DATE '2026-03-01'
GROUP BY acq_channel;
```

**Customers Acquired, period as single total (Fix 4):**
```sql
-- "Customers acquired in 2025" — one aggregated number, not month-by-month
SELECT
  SUM(CASE WHEN month_diff = 0 THEN COALESCE(customer_count,0) ELSE 0 END) AS customers_acquired_2025
FROM `insightsprod.equipfoods_5642_prod_presentation.simplified_customer_cohorts_v2`
WHERE EXTRACT(YEAR FROM acq_month) = 2025;
-- Only switch to a GROUP BY acq_month breakdown if the user explicitly asks for a monthly trend.
```

---

### 1.3 Channel & Attribution Terminology

| User Term | Column | Filter Value |
|---|---|---|
| Shopify | `acq_channel` / `channel` | `'Shopify'` |
| DTC | `acq_channel` / `channel` | `'Shopify'` — "DTC" is the client's term for the Shopify channel; map it directly, do not ask for clarification |
| Amazon / Amazon Seller Central | `acq_channel` / `channel` | `'Amazon Seller Central'` — this is the exact value everywhere; never shorten to `'Amazon'` |
| All channels | No filter | — |

**Attribution dimensions available on all tables:**

| Dimension | Column | Default |
|---|---|---|
| Acquisition channel | `acq_channel` / `channel` | ✅ Default — use this unless user specifies otherwise |
| Marketing channel | `marketing_channel` | Only if user asks for marketing attribution |
| Last click channel | `last_click_channel` | Only if user asks for last-click attribution |
| IDDA channel | `idda_channel` | Only if user asks for IDDA attribution |
| Clicks-only Northbeam channel | `clicks_only_northbeam_channel` | Only if user asks for this attribution model. Available on `LineItemMaster`, `simplified_customer_cohorts_v2`, `simplified_order_cohorts_v2`, `simplified_churn_customers`, `SubscriptionMaster`, `SubscriberCohort` |
| Unified Marketing Channel | `unified_marketing_channel` (raw column; always apply the cleaning CASE in Section 2.8 before grouping or joining on it) | Only if user asks for marketing-channel-level LTV/CAC (Section 2.8). Available on `LineItemMaster`, `simplified_customer_cohorts_v2`, `simplified_order_cohorts_v2`, `simplified_churn_customers`, `SubscriptionMaster`, `SubscriberCohort`. Blends the cohort side with ad spend from `AdvertisingMaster` — see Section 2.8 for the join |
| Channel Grouping 1 | `channel_grouping_1_source` | Rollup of Unified Marketing Channel to source/platform (e.g. "Facebook Ads" and "Facebook Organic" both roll up to "Facebook"). Only if user asks for this grouping level. Available on the same six tables as Unified Marketing Channel above |
| Channel Grouping 2 | `channel_grouping_2_channel` | Rollup of Channel Grouping 1 to a broad channel type (e.g. "Facebook" rolls up to "Paid Social"). Only if user asks for this grouping level. Available on the same six tables as Unified Marketing Channel above |

---

### 1.4 Region & Geography

Equip Foods operates in a single market — United States. No `store_name` or geography filter is needed.

---

### 1.5 Date Filtering Patterns

> These patterns apply only once a time period is known — either the user stated one, or explicitly asked for a named window like "last 12 months" (`R-DATE-01`, Section 1.1). None of these is a silent default.

#### Cohort tables (use `acq_month`)

| Term | BigQuery SQL |
|---|---|
| Last 12 acquisition months (only if explicitly requested) | `acq_month >= DATE_SUB(DATE_TRUNC((SELECT MAX(acq_month) FROM \`table\`), MONTH), INTERVAL 11 MONTH)` |
| Last 24 acquisition months (only if explicitly requested) | `acq_month >= DATE_SUB(DATE_TRUNC((SELECT MAX(acq_month) FROM \`table\`), MONTH), INTERVAL 23 MONTH)` |
| Specific acquisition month | `acq_month = DATE('[YYYY-MM-01]')` |
| Custom range (e.g. Jan–Mar 2025 inclusive) | `acq_month >= DATE '[YYYY-MM-01]' AND acq_month < DATE_ADD(DATE '[YYYY-MM-01]', INTERVAL 1 MONTH)` — the second date is the last month of the range; add 1 month to make it an exclusive upper bound per `R-DATE-01` |

#### LineItemMaster (use `date`)

| Term | BigQuery SQL |
|---|---|
| Last 12 order months (only if explicitly requested) | `date >= DATE_SUB(DATE_TRUNC((SELECT MAX(DATE_TRUNC(date, MONTH)) FROM \`LineItemMaster\`), MONTH), INTERVAL 11 MONTH)` |
| Specific order month | `DATE_TRUNC(date, MONTH) = DATE '[YYYY-MM-01]'` |
| Date range | `date >= DATE '[YYYY-MM-DD]' AND date < DATE '[YYYY-MM-DD]'` |

> For acquisition-based filtering in `LineItemMaster`: use `customer_acq_date`. Derive acquisition month as `DATE_TRUNC(customer_acq_date, MONTH)`.

---

### 1.6 Product Hierarchy

| Level | Column | Available In |
|---|---|---|
| SKU code | `sku` | `LineItemMaster` |
| SKU Product Name | `sku_product_name` | `LineItemMaster` |
| SKU Sub-Category | `sku_sub_category` | `LineItemMaster` |
| SKU Category | `sku_category` | `LineItemMaster` |
| Entry SKU Product Name | `entry_sku_product_name` | `LineItemMaster`, cohort tables |
| Entry SKU Sub-Category | `entry_sku_sub_category` | `LineItemMaster`, cohort tables |
| Entry SKU Category | `entry_sku_category` | `LineItemMaster`, cohort tables |

**SKU** = the actual product on any given order (may differ from the customer's entry product). Used for sales mix, repeat-purchase, and lifecycle analysis. Only carried on `LineItemMaster` — cohort tables have no `sku`/`sku_product_name`/`sku_sub_category`/`sku_category` columns.
**Entry SKU** = the product on the customer's very first-ever order — fixed per customer, broadcast across every later row. Used for acquisition/cohort analysis. Available on `LineItemMaster` and all cohort tables.

---

### 1.7 Product Level Default `[R-PRODUCT-01]`

> **Critical global default — apply before generating any product-level SQL. Default and state the assumption; do not ask.**

Two perspectives exist and produce different numbers:

- **SKU level (default)** — the product on the actual order/line item: `sku`, `sku_product_name`, `sku_sub_category`, `sku_category`. Used for sales mix, repeat-purchase, and lifecycle analysis: "which products are selling," "revenue by product."
- **Entry SKU level** — the product a customer's first-ever order contained: `entry_sku_product_name`, `entry_sku_sub_category`, `entry_sku_category`. Used for acquisition/cohort analysis: "which products drive the best long-term customers?"

**Rule:** Default to **SKU level (actual purchased product)** for any product-level question. Only use Entry SKU level when the question explicitly signals acquisition/entry context. Never ask which level is meant — infer per this default and **state the assumption** whenever defaulting to SKU: e.g. *"Based on the purchased SKU, not Entry SKU."* No need to restate the assumption when the user already said "entry"/"acquisition" explicitly.

| Signal in the question | Use |
|---|---|
| "entry product", "entry SKU", "first product", "what they bought first", "acquisition product", "product customers were acquired through" | Entry SKU level |
| Everything else — including vague asks like "by product", "product mix", "revenue by product" | SKU level (default) |

**Table/grain override (Section 0, priority 4 — outranks this default):** `simplified_customer_cohorts_v2`, `simplified_order_cohorts_v2`, and `simplified_churn_customers` carry no actual-SKU columns at all (Section 1.6) — only `entry_sku*`. A cohort metric requested by product (e.g. Repurchase Rate, LTR, LTV, CAC by product) can therefore only ever use Entry SKU, regardless of this default. This is a physical grain constraint, not a preference — state it as such: e.g. *"Cohort tables only carry each customer's entry (first-purchase) product — showing this grouped by entry product."* `LineItemMaster` is the only table on which the SKU-level default above can be honored.

---

### 1.8 Product Level — Granularity Default & Required Columns

**Granularity default (`R-PRODUCT-01` continued):** For a vague product-level ask — "by product", "product mix", "revenue by product" — with no specific SKU, product name, category, or sub-category named, start at **Category + Sub-Category**: group by `sku_category` + `sku_sub_category` (or `entry_sku_category` + `entry_sku_sub_category` at Entry SKU level per the table/grain override above). Do not drill to product name / SKU by default. After presenting that view, offer to drill down further — e.g. *"Want this broken out further by product name or SKU?"*

**Explicit-level override:** If the user names or references a specific SKU, product, product name, category, or sub-category, use exactly that level directly — do not force the broader Category + Sub-Category default, and do not add levels the user didn't ask for.

**Column reference by table:**

| Level | Column | Available In |
|---|---|---|
| Entry SKU Category | `entry_sku_category` | `LineItemMaster`, all cohort tables |
| Entry SKU Sub-Category | `entry_sku_sub_category` | `LineItemMaster`, all cohort tables |
| Entry SKU Product Name | `entry_sku_product_name` | `LineItemMaster`, all cohort tables |
| SKU Category | `sku_category` | `LineItemMaster` |
| SKU Sub-Category | `sku_sub_category` | `LineItemMaster` |
| SKU Product Name | `sku_product_name` | `LineItemMaster` |

---

### 1.9 Unique Identifier Fields

| Entity | Column | Table(s) |
|---|---|---|
| Customer | `customer_id` | `LineItemMaster`, `SubscriptionMaster`, `SubscriberCohort` |
| Order | `order_id` | `LineItemMaster`; `dim_orders` (join key for discount code analysis only — Section 1.20) |
| Subscription Contract | `subscription_id` | `SubscriptionMaster` |
| Subscription Line | `subscription_line_id` | `SubscriptionMaster` |
| Acquisition Month | `acq_month` | All cohort tables |
| Cohort Period (monthly) | `month_diff` | `simplified_customer_cohorts_v2`, `simplified_churn_customers` |
| Cohort Period (order-based) | `order_number` | `simplified_order_cohorts_v2` |

---

### 1.10 NULL Handling & Division Safety

**Global rule:** Always wrap numeric columns in `COALESCE(..., 0)`. Always use `SAFE_DIVIDE` for any division.

```sql
-- Aggregation
SUM(COALESCE(column_name, 0))

-- Division
SAFE_DIVIDE(
  SUM(COALESCE(numerator_col, 0)),
  SUM(COALESCE(denominator_col, 0))
)
```

---

### 1.11 Mandatory Filter Rules

**All customer-level queries against `LineItemMaster`:**
- Always apply `WHERE customer_id IS NOT NULL`
- Always apply `WHERE COALESCE(quantity, 0) > 0` when counting orders or customers
- For order counts: `COUNT(DISTINCT CASE WHEN transaction_type = 'Order' THEN order_id END)`

**All queries against `dim_orders` — ⚠ CRITICAL (`R-PII-DIMORDERS-01`, full rule in Section 1.20):**
- Never `SELECT *` (including `do.*` and `SELECT * EXCEPT(...)`) — always list columns explicitly.
- Never reference `note`, `comments`, or `tags` anywhere in the query — not in `SELECT`, `WHERE`, `GROUP BY`, joins, CTEs, or subqueries.
- Never join `dim_orders` onward to `dim_customer` or `dim_address`.
- `LineItemMaster` is line-level, so a joined `discount_codes` value repeats on every line of its order — order counts must use `COUNT(DISTINCT order_id)`, never `COUNT(*)` or `COUNT(order_id)`.

**Aggregate alias safety:**
- Never alias an aggregate with the same name as the source column. `SUM(item_gross_sales)` → alias as `total_gross_sales`, not `item_gross_sales`.

---

### 1.12 Transaction Type Filter Rule (LineItemMaster) `[R-TRANSACTION-01]`

> **Critical — apply before every `LineItemMaster` query.**

`LineItemMaster` contains both `'Order'` and `'Return'` rows. Filter conditionally based on the metric:

| Metric | Rule |
|---|---|
| Order counts / Customer counts | `WHERE transaction_type = 'Order'` — Return rows inflate counts |
| Net Sales | **No `transaction_type` filter** — include both row types. `item_returns` is only non-zero on Return rows; filtering to Orders silently drops all return deductions |
| Shipping charges / shipping tax (Net Shipping Charges, Total Revenue) | `WHERE transaction_type = 'Order'` — `item_shipping_price` is non-zero and unreduced on Return rows (verified: `simplified_customer_cohorts_v2.shipping_price_total` matches the LineItemMaster Order-only total exactly); summing without this filter double-counts shipping revenue on returned lines. **⚠ Backlog — flagged for stakeholder review, not fully settled. See Section 5.4 EF-013.** |
| Units purchased (Return Rate denominator) | `CASE WHEN transaction_type <> 'Return' THEN ABS(COALESCE(quantity, 0)) ELSE 0 END` |
| Units returned (Return Rate numerator) | `CASE WHEN transaction_type = 'Return' THEN ABS(COALESCE(quantity, 0)) ELSE 0 END` |
| Return analysis only | `WHERE transaction_type = 'Return'` |

---

### 1.13 Returns Attribution

Returns in all cohort tables (`item_returns_total`) are attributed to the **refund date**, not the order creation date. This is pre-applied by the data model — no SQL adjustment needed for cohort queries.

In `LineItemMaster`, Return rows carry the refund date in the `date` column. The `Order Date Return Rates` view re-attributes returns back to the original order date — this is a separate analytical view for SKU-level return analysis only (Section 2.7).

---

### 1.14 Rounding & Formatting Rules

| Metric Type | Rounding | Format | Examples |
|---|---|---|---|
| Monetary values | 0 decimal places | USD — prefix `$`, comma thousands separator | `$1,250` / `$48,300` / `$1,200,000` |
| Count / numeric values | 0 decimal places | US numeric format, comma thousands separator | `1,250` / `48,300` |
| Percentages / rates | 2 decimal places | Append `%` | `42.50%` / `8.25%` |
| Ratios (non-%) | 2 decimal places | Plain number | `3.45` / `12.80` |

**Period-over-period change conventions:**
- Percentage / rate metrics → change in **percentage points (ppt)**. Example: `42.50% → 38.25%` = `−4.25 ppt`
- Monetary / count metrics → absolute delta + relative %. Example: `$120,000 → $132,000` = `+$12,000 (+10.00%)`
- Ratio metrics (LTV/CAC, OPC, UPO) → absolute delta only

---

### 1.15 Exact Column Value Reference

Always use these exact string values when filtering. Case and spacing must match exactly.

| Field | Exact Values |
|---|---|
| `acq_type` / `customer_acq_type` | `'One-Time Purchase'`, `'Subscription'` |
| `purchasing_pattern` / `customer_purchasing_pattern` | `'One-Time Purchaser'`, `'Repeat Purchaser'` |
| `transaction_type` | `'Order'`, `'Return'` |
| `order_type` | `'Subscription'`, `'Order'` |
| `subscriber_status` | `'Subscriber'` (active) |
| `acq_channel` / `channel` | `'Shopify'`, `'Amazon Seller Central'` |
| `revenue_bucket` / `revenue_bucket_at_acquisition` | `'TT Returning'`, `'TT New'`, `'SKIO (Recurring)'`, `'Recurring Day Of'`, `'Returning (OTP)'`, `'NC Subs'`, `'New OTP'` — `NULL` for Amazon and Global-Filters-excluded Shopify orders, see Section 1.16 |
| Discount code label for orders with no code | `'No Discount Code'` — derived label, not a stored value; see Section 1.20 |
| Active subscription (`SubscriptionMaster`) | `subscription_status = 'ACTIVE'` — **never** `subscription_cancel_date IS NULL` (also true for `PAUSED`/`FAILED` rows — inflates active count by ~1,657 customers on Equip Foods data) or a `'9999-12-31'` sentinel check (dead code — no row uses that value). See Section 1.19. |

---

### 1.16 Revenue Bucket

> **Scope lock:** Revenue Bucket is documented and queryable only on the 6 tables already covered by this file. Do not extend Revenue Bucket analysis to any other table, regardless of what other tables in the warehouse may also carry a `revenue_bucket` column.

**Pre-computed — never re-derive.** Revenue Bucket is computed upstream in the `_main` layer from `fact_order_lines` + `dim_orders` (channel, subscription tags, new-vs-returning flag), after a set of Global Filters removes non-Shopify, cancelled, wholesale-channel, TikTok-sample, and seeding/gifting/exchange-credit orders. IQ always uses the pre-computed `revenue_bucket` / `revenue_bucket_at_acquisition` columns as-is — never attempts to reconstruct a bucket from `channel`, `order_type`, or tag data.

**The 7 buckets** (mutually exclusive, evaluated in priority order — a TikTok order is always TT New/TT Returning even if it also carries a subscription tag):

| Priority | Bucket | Definition |
|---|---|---|
| 1 | TT Returning | Returning customer, purchased via TikTok Shop |
| 2 | TT New | New customer, purchased via TikTok Shop |
| 3 | SKIO (Recurring) | Returning customer, subscription renewal order |
| 4 | Recurring Day Of | Returning customer, placing their first subscription order |
| 5 | Returning (OTP) | Returning customer, one-time purchase, no subscription tag |
| 6 | NC Subs | New customer, first-ever order is a subscription |
| 7 | New OTP | New customer, one-time purchase, no subscription tag |

**Column reference:**

| Column | Grain | Tables |
|---|---|---|
| `revenue_bucket` | Order-level — can differ across a single customer's orders | `LineItemMaster`, `simplified_order_cohorts_v2` |
| `revenue_bucket_at_acquisition` | Customer-level — fixed to the bucket of the customer's first order | `simplified_customer_cohorts_v2`, `simplified_churn_customers` |

#### Revenue Bucket Level Clarification Rule `[R-BUCKET-01]`

> **Apply before generating any Revenue Bucket SQL.** Order-level and acquisition-level bucket answer different questions and can produce different numbers for the same bucket name — structurally the same disambiguation axis as SKU vs. Entry SKU (Section 1.7), though that rule now defaults-and-states rather than asking.

- **Order-level (`revenue_bucket`)** — "how did the business perform in a period, broken out by bucket": transactional questions about a period's activity regardless of when each customer was acquired.
- **Acquisition-level (`revenue_bucket_at_acquisition`)** — "how are customers acquired into a given bucket performing over their lifetime": cohort questions about customers grouped by their original acquisition bucket.

Unless the question explicitly signals one level or the context makes it unambiguous, ask before proceeding.

| Signal in the question | Default to |
|---|---|
| "this month", "in [period]", "orders placed", "how did we perform", period-based revenue/order questions | Order-level (`revenue_bucket`) |
| "customers acquired as/via", "lifetime", "LTR/LTV by bucket", cohort or retention questions | Acquisition-level (`revenue_bucket_at_acquisition`) |

#### NULL Handling & Amazon

`revenue_bucket` / `revenue_bucket_at_acquisition` is `NULL` for: (1) Amazon-channel activity — Revenue Bucket is a **Shopify-only** dimension; (2) Shopify orders excluded by Global Filters (cancelled orders, wholesale channels, TikTok-sample-tagged orders, seeding/gifting/exchange-credit discount codes) — these are intentionally out of scope of both bucket and Amazon reporting.

**Rule:** When a user requests a Revenue Bucket breakdown:
1. Return the 7 Shopify buckets and explicitly state that Revenue Bucket is a Shopify-only dimension.
2. Separately and additionally, surface one extra line — the same requested metric computed for Amazon (`channel` / `acq_channel` = `'Amazon Seller Central'`), not broken into buckets.
3. Do not add a line for the remaining `NULL` population (cancelled/wholesale/sample/seeding-gifting Shopify orders) — those are intentionally excluded from both DTC and Amazon reporting and have no place in a bucket breakdown.

#### Default Exclusion — TikTok Buckets `[R-BUCKET-02]`

> **Mandatory default filter — applies to every query against the 4 tables below, not only Revenue Bucket breakdowns.** Same status as the `customer_id IS NOT NULL` rule (Section 1.11) and the `transaction_type` rules (Section 1.12): declared once here, applied everywhere, never repeated inside individual metric SQL blocks.

Even though TikTok orders pass Global Filters as valid Shopify-channel activity (see `Global Filters.md` — TikTok is explicitly kept, not excluded upstream), `TT New` and `TT Returning` are excluded from Equip Foods' default reporting on the 4 bucket-carrying tables. The level determines which bucket(s) drop:

| Bucketing level | Tables | Exclude |
|---|---|---|
| Order-level (`revenue_bucket`) | `LineItemMaster`, `simplified_order_cohorts_v2` | Both `TT New` and `TT Returning` |
| Acquisition-level (`revenue_bucket_at_acquisition`) | `simplified_customer_cohorts_v2`, `simplified_churn_customers` | `TT New` only |

**NULL-safe filter SQL** — a bare `NOT IN` would also silently drop the Amazon/excluded-order `NULL` population (Section 1.16 above), which must stay handled by its own rule. Always use:

```sql
-- Order-level tables (LineItemMaster, simplified_order_cohorts_v2)
WHERE (revenue_bucket IS NULL OR revenue_bucket NOT IN ('TT New', 'TT Returning'))

-- Acquisition-level tables (simplified_customer_cohorts_v2, simplified_churn_customers)
WHERE (revenue_bucket_at_acquisition IS NULL OR revenue_bucket_at_acquisition != 'TT New')
```

**Scope:** This is a blanket default across all metrics on these 4 tables — Net Sales, Total Revenue, Net Shipping Charges, Revenue Acquired, Discount Rate, Revenue Retention, LTR, LTRPC, LTV, LTVPC, LTV/CAC, AOV, Repurchase Rate, OPC, UPO, Customers Acquired, CAC, Churn Rate, Cumulative Churn Rate, Retention Rate — regardless of whether the query touches Revenue Bucket at all. It applies whether or not the query filters to a specific channel — TikTok is a Shopify-channel subset, so "all channels" and "Shopify" queries both exclude it under this rule. Does not apply to `SubscriptionMaster` / `SubscriberCohort` — neither table carries a channel or bucket column to filter on.

**Lift condition:** Only skip this filter when the user explicitly asks about TikTok, TT New, or TT Returning by name.

**Disclosure:** Do not state this exclusion in responses by default — treat it as part of the standing definition of these tables' population, the same way the Global Filters exclusions aren't restated every time. If the user asks whether TikTok is included, confirm that TikTok orders were excluded.

---

### 1.17 Cohort-Level vs. Business-Level (Transactional) Questions `[R-TABLE-01]`

> **Global disambiguation — apply to every metric, not only Net Sales.** The same table and the same calendar period can answer two fundamentally different questions, and they can produce very different numbers for the same period.

- **Cohort-level ask** — "how are customers acquired in [period] performing" — anchored to the customer's acquisition month. The answer is scoped to a specific acquisition cohort's activity, whenever that activity occurs. Native to `acq_month` (+ `month_diff` / `order_number`).
- **Business-level ask** — "how did the business perform in [period]" — anchored to when the transaction happened, regardless of when the customer was acquired. This is the "no-cohort" case already established for Net Sales (Section 1.2), generalized here to every metric.

**Default to inferring, not asking.** Infer the most natural interpretation from the user's wording and any conversation context already established (`R-CONTEXT-01`), proceed with it, and state the assumption in the response using one of these exact phrasings:
- Cohort: *"Interpreting this as customers acquired in [period]."*
- Business-level: *"Interpreting this as transactions occurring in [period], regardless of acquisition date."*

Treat the phrases below as signals toward one interpretation, not rigid trigger words requiring an exact match — judge the overall wording and context. Only stop to ask when both interpretations are genuinely plausible for what was asked *and* picking the wrong one would materially change the answer.

| Signal in the question | Leans toward |
|---|---|
| "customers acquired in [period]", "cohort", "cohort from [period]" | Cohort-level — `acq_month` |
| "sales in", "orders in", "revenue in", "this month", "how did we perform", or a period reference with no acquisition language | Business-level — `order_month` (cohort tables) or `date` (`LineItemMaster`) |

**Why `simplified_customer_cohorts_v2` also works for business-level asks:** its grain is `acq_month × order_month × [dims]`, and the measures (`item_gross_sales`, `order_count`, `item_quantity`, `cogs`, `adspend`, etc.) are real per-`order_month` facts, not retention/cohort-decay counts. Filtering to a single `order_month` and summing across every `acq_month` row reconstitutes that month's true transactional total. Verified against BigQuery for May 2026: `simplified_customer_cohorts_v2` grouped by `order_month` alone matches `LineItemMaster` filtered by `date` exactly — Net Sales $7,512,446, orders 92,877, both sources, to the dollar.

**The caveat that matters:** every acquisition-level dimension on cohort tables (`acq_channel`, `acq_type`, `purchasing_pattern`, `entry_sku` / `entry_sku_category` / `entry_sku_sub_category` / `entry_sku_product_name`, `subscriber_status`, and `revenue_bucket_at_acquisition` per `R-BUCKET-01`) is frozen at the customer's acquisition and broadcast across every later `order_month` row — it does not reflect anything about the activity in that later month. This is correct for "this month's revenue by the channel/SKU that *acquired* the customer" — wrong for "this month's revenue by the channel/SKU *this order* actually came through." For contemporaneous, order-level dimensions (`channel`, `sku` / `sku_category` / `sku_sub_category` / `sku_product_name`, `revenue_bucket`, `order_type`, `transaction_type`), use `LineItemMaster` — the only table with per-order-date-grain dimensions.

**Table selection for business-level (transactional) questions:**

| Need | Table | Key |
|---|---|---|
| Total, or a slice by an acquisition-level dimension (e.g. "revenue in March by acq_channel / entry SKU") | `simplified_customer_cohorts_v2` | Filter/group by `order_month` — never `acq_month` / `month_diff` for this ask type |
| A slice by an order-level / contemporaneous dimension (e.g. "revenue in March by this order's channel / SKU"), or anything needing `transaction_type` handling | `LineItemMaster` | Filter by `date` |

`simplified_order_cohorts_v2` is **excluded from business-level questions entirely** — see Section 5.4, EF-015. It remains valid only for its native cohort-level, order-sequence questions ("how do 2nd orders behave"), unchanged from today.

`simplified_churn_customers` has no `order_month` column — it is inherently cohort-only; this distinction does not apply to it.

The Default Exclusion — TikTok Buckets rule (Section 1.16) and the DTC = Shopify mapping (Section 1.3) apply identically to business-level queries — they are not cohort-specific rules.

---

### 1.18 Month-Based vs. Order-Sequence Cohort Anchoring `[R-COHORT-ANCHOR-01]`

> Applies only once a question is already established as **cohort-level** (Section 1.17). A cohort-level question can still be anchored two different ways, and several metrics — Repurchase Rate, AOV, OPC, UPO — are sourced from tables using either anchor, with the same metric name and formula shape but a different number depending which one applies.

- **Month-based anchor** — "how did the cohort perform N months after acquisition" — anchored to `month_diff`, on `simplified_customer_cohorts_v2`.
- **Order-sequence anchor** — "how did the cohort perform by their Nth order" — anchored to `order_number`, on `simplified_order_cohorts_v2`.

**Default to month-based** unless the question uses order-sequence language ("2nd order," "Nth order," "by order number," "order sequence") — infer from wording and state the assumption, same posture as Section 1.17 (`R-TABLE-01`): *"Interpreting this by month since acquisition"* / *"Interpreting this by order sequence (order number), not calendar time."* Only ask when the question is genuinely ambiguous between the two and the answer would differ materially.

**A second, related distinction — aggregate vs. per-order detail:** `order_number` also exists on `LineItemMaster`, which is a different thing entirely from `simplified_order_cohorts_v2`:
- An order-sequence **aggregate** metric (a count, rate, or revenue total across the cohort at a given order number) → `simplified_order_cohorts_v2`.
- An order-sequence **detail/dimensional** question (e.g. "what products do customers buy on their 2nd order," "what channel are 3rd orders coming through") → `LineItemMaster WHERE order_number = N`. `simplified_order_cohorts_v2` cannot answer this — it has no per-order `sku`/`channel`/`revenue_bucket` column, only `entry_sku*`, which is frozen at acquisition regardless of `order_number`.

---

### 1.19 `SubscriptionMaster` Active-Subscriber Logic `[R-SUBACTIVE-01]`

> **Critical — apply to every "is this subscription/customer currently active" check on `SubscriptionMaster`, not only a dedicated Active Subscribers metric.** This includes churn gating, retention checks, and cohort status derivations that touch this table.

**Rule:** Use `subscription_status = 'ACTIVE'`. **Never** infer active status from `subscription_cancel_date IS NULL` (or a `'9999-12-31'` sentinel check on that column).

**Why:** `subscription_cancel_date` is only populated for `CANCELLED` rows — `PAUSED` and `FAILED` rows also carry a `NULL` cancel date, so a null-based check silently counts them as active too. On Equip Foods data this inflated active subscribers by ~1,657 customers (60,334 vs. the true 58,685).

**Also dead code — do not carry forward:** `subscription_start_date` / `subscription_cancel_date` sentinel checks against `DATE '9999-12-31'` never match any row in this table. Drop any `COALESCE(subscription_cancel_date, DATE '9999-12-31')`-style pattern; use `subscription_status` directly.

This supersedes the "Active subscription" row previously in Section 1.15 and any `subscription_cancel_date IS NULL` filter or derivation elsewhere in this file that touches `SubscriptionMaster`.

---

### 1.20 Discount Code Analysis — `dim_orders` `[R-DISCOUNTCODE-01]` `[R-PII-DIMORDERS-01]`

> ⚠ **CRITICAL — `R-PII-DIMORDERS-01`: never `SELECT *` from `dim_orders`, and never reference its `note`, `comments`, or `tags` columns.** Applies to every query that touches `dim_orders` — the `LineItemMaster` discount-code join or anything else — including CTEs, subqueries, and intermediate steps. This is an absolute rule, outside Section 0's precedence order: no user request overrides it.

**Table:** `insightsprod.equipfoods_5642_prod_main.dim_orders`. It lives in the **`_prod_main`** dataset, unlike every other table in this file (`_prod_presentation`) — always reference it by this full path. One row per `order_id` (verified 1:1, despite its SCD Type 2 columns).

**When to use — discount code analysis only.** `dim_orders` is used for exactly one purpose: breaking metrics out by discount code. Never use it as a general source of order attributes.

| Signal in the question | Use |
|---|---|
| "by discount code", "promo code", "coupon code", "which codes", a named code (e.g. "orders using SAVE10") | `LineItemMaster` joined to `dim_orders` (this section) |
| "discounts", "discount rate", "how much did we discount" — with no mention of codes | Existing Discounts / Discount Rate metrics (Sections 1.2, 2.1) — no `dim_orders` join |

#### Column rule `[R-PII-DIMORDERS-01]` — ⚠ CRITICAL

`dim_orders` is otherwise PII-free: customers and addresses appear only as surrogate keys (`customer_key`, `ship_address_key`, `bill_address_key`), with no raw email or address. But three free-text columns are banned:

| Column | Status | Why |
|---|---|---|
| `note` | ⛔ Never reference | Confirmed PII in sampled rows: customer names, personal emails, a wholesale buyer's business email (13 of 25,612 rows) |
| `comments` | ⛔ Never reference | Confirmed PII in sampled rows: full name + city/state from an Amazon refund complaint (1 of 27 rows) |
| `tags` | ⛔ Never reference | No PII found in the scan — banned because it is the same free-text category and unaudited going forward |

**Rule:**
1. **Always list `dim_orders` columns explicitly.** Never `SELECT *`, `do.*`, or `SELECT * EXCEPT(...)` — a `*` would also pick up any free-text column added to the table later.
2. **Never reference `note`, `comments`, or `tags`** anywhere in a query — not in `SELECT`, `WHERE`, `GROUP BY`, `ORDER BY`, joins, CTEs, or subqueries, not even incidentally.
3. **Allowed columns:** `order_id` and `discount_codes` by default. Other structured/key columns — `order_key`, `platform_name`, `type`, `order_date`, `order_datetime`, `payment_mode`, `payment_gateway`, `digital_wallet`, `credit_card_type`, `order_channel`, `order_name`, `product_basket`, `category_basket`, `rating`, `feedback_type`, `customer_key`, `ship_address_key`, `bill_address_key`, `effective_start_date`, `effective_end_date`, `last_updated`, `_run_id` — only when a discount-code question actually needs them.
4. **Never join `dim_orders` onward** to `dim_customer` or `dim_address` through `customer_key`, `ship_address_key`, or `bill_address_key`. The keys may be selected; following them may not.
5. **If the user asks for order notes, comments, or tags,** decline — say these fields are not available — and do not query them.

#### Join condition

```sql
-- ⚠ CRITICAL (R-PII-DIMORDERS-01): only structured/key columns from dim_orders — never *, note, comments, tags.
select
  lim.*,
  do.discount_codes
from `insightsprod.equipfoods_5642_prod_presentation.LineItemMaster` lim
left join `insightsprod.equipfoods_5642_prod_main.dim_orders` do
  on lim.order_id = do.order_id
```

- `LineItemMaster` is always the left (driving) table; `dim_orders` is never the `FROM` table for metrics.
- Join on `order_id` only, exactly as above.
- Every `LineItemMaster` rule still applies after the join: `transaction_type` handling (Section 1.12, `R-TRANSACTION-01`), mandatory filters (Section 1.11), the TikTok exclusion (Section 1.16, `R-BUCKET-02`), and the time period rule on `lim.date` (Section 1.1, `R-DATE-01`).

#### Line level → distinct order counts

`LineItemMaster` is line-level, so an order's `discount_codes` value repeats on every line of that order. When rolling up:
- **Order counts:** `COUNT(DISTINCT order_id)` — never `COUNT(*)` or `COUNT(order_id)`, which count lines, not orders.
- **Customer counts:** `COUNT(DISTINCT customer_id)`.
- **Monetary values** (Gross Sales, Discounts, Net Sales, Total Revenue): summing across lines is correct — the amounts are line-level and are not repeated; only the code label repeats.

#### Orders with multiple codes — split into individual codes

`discount_codes` holds every code on the order in one string (e.g. `"SAVE10, FREESHIP"`).
- Split it into individual codes; an order counts once under **each** code it carries. The same code appearing twice on one order counts once.
- **Per-code rows therefore do not add up to the overall total.** Example: order #1 (SAVE10, $100), #2 (SAVE10 + FREESHIP, $80), #3 (FREESHIP, $50) → SAVE10 = 2 orders / $180, FREESHIP = 2 orders / $130; rows sum to 4 orders / $310, but the true total is 3 orders / $230.
- Every per-code breakdown must state: *"Orders with multiple discount codes are counted under each code, so the rows don't add up to the overall total."*
- If an overall total is needed, compute it separately from the unsplit join — never by summing the per-code rows.
- For an order with multiple codes, its full line-level amounts (including its full discount amount) sit under each of its codes — the amounts are not apportioned between codes.

#### Orders with no code

Orders whose `discount_codes` is `NULL` or blank are shown as a separate **`'No Discount Code'`** line, included by default. This also covers any `LineItemMaster` order with no matching `dim_orders` row.

#### Query pattern

```sql
-- ⚠ CRITICAL (R-PII-DIMORDERS-01): only order_id and discount_codes are read from dim_orders.
-- Never SELECT *, never reference note / comments / tags, never join onward to dim_customer / dim_address.
WITH order_codes AS (
  -- One row per order × individual code; the same code twice on one order is kept once
  SELECT DISTINCT
    do.order_id,
    TRIM(code) AS discount_code
  FROM `insightsprod.equipfoods_5642_prod_main.dim_orders` do,
    UNNEST(SPLIT(do.discount_codes, ',')) AS code
  WHERE TRIM(code) != ''
),
lim_codes AS (
  SELECT
    COALESCE(oc.discount_code, 'No Discount Code') AS discount_code,
    lim.order_id,
    lim.customer_id,
    lim.transaction_type,
    lim.quantity,
    lim.item_gross_sales,
    lim.item_discounts,
    lim.item_returns,
    lim.item_shipping_price,
    lim.item_shipping_tax
  FROM `insightsprod.equipfoods_5642_prod_presentation.LineItemMaster` lim
  LEFT JOIN order_codes oc
    ON lim.order_id = oc.order_id
  WHERE lim.date >= DATE '[YYYY-MM-DD]' AND lim.date < DATE '[YYYY-MM-DD]'
  -- plus the standing LineItemMaster default filters (TikTok exclusion, Section 1.16 R-BUCKET-02)
)
SELECT
  discount_code,
  -- metrics from Section 2.9
FROM lim_codes
GROUP BY discount_code
```

`order_codes` is the same `lim.order_id = do.order_id` join shown above, with `discount_codes` split first. The metrics that go in the final `SELECT` are defined in Section 2.9.

---

## 2. Metric Definitions, Formulas & Edge Cases

### 2.1 Revenue Metrics

---

#### Metric: Net Sales

- **Definition:** Gross sales minus item discounts minus item returns — item-level revenue only, excludes shipping. Remains directly queryable on its own; **Total Revenue** (below) is now the primary revenue metric and feeds every downstream composite metric (Revenue Acquired, Discount Rate, Revenue Retention, LTR, LTRPC, LTV, LTVPC, LTV/CAC, AOV, Gross Margin).
- **Formula:** `SUM(item_gross_sales) - SUM(item_discount_total) - SUM(item_returns_total)` (cohort tables) / `SUM(item_gross_sales) - SUM(item_discounts) - SUM(item_returns)` (LineItemMaster)
- **Source:** `simplified_customer_cohorts_v2`, `simplified_order_cohorts_v2`, `LineItemMaster`
- **Formatting:** USD — `$1,250`
- **Rounding:** 0 decimal places
- **SQL (cohort tables):**
```sql
ROUND(
  SUM(COALESCE(item_gross_sales, 0))
  - SUM(COALESCE(item_discount_total, 0))
  - SUM(COALESCE(item_returns_total, 0))
, 0) AS net_sales
```
- **SQL (LineItemMaster — do NOT filter by `transaction_type`):**
```sql
ROUND(
  SUM(COALESCE(item_gross_sales, 0))
  - SUM(COALESCE(item_discounts, 0))
  - SUM(COALESCE(item_returns, 0))
, 0) AS net_sales
```
- **Cohort-level vs. business-level question rule:** Apply Section 1.2 — `R-PERIOD-01` (exact query patterns in Section 1.2.1) and Section 1.17 — `R-TABLE-01`.
- **Order-sequence cohort question** (e.g. "Net Sales at order #3"): apply Section 1.18 — `R-COHORT-ANCHOR-01`. Filter `simplified_order_cohorts_v2` by `order_number`, using the same cohort-table SQL above.

---

#### Metric: Net Shipping Charges

- **Definition:** Total shipping charges collected minus shipping taxes. Available on all three revenue tables.
- **Formula:** `Total Shipping Charges - Shipping Taxes`
- **Source:** `simplified_customer_cohorts_v2`, `simplified_order_cohorts_v2`, `LineItemMaster`
- **Formatting:** USD — `$1,250`
- **Rounding:** 0 decimal places
- **SQL (cohort tables):**
```sql
ROUND(
  SUM(COALESCE(shipping_price_total, 0))
  - SUM(COALESCE(shipping_tax_total, 0))
, 0) AS net_shipping_charges
```
- **SQL (LineItemMaster — `transaction_type = 'Order'` filter; ⚠ backlog, see Section 5.4 EF-013):**
```sql
ROUND(
  SUM(CASE WHEN transaction_type = 'Order' THEN COALESCE(item_shipping_price, 0) ELSE 0 END)
  - SUM(CASE WHEN transaction_type = 'Order' THEN COALESCE(item_shipping_tax, 0) ELSE 0 END)
, 0) AS net_shipping_charges
```
- **Order-sequence cohort question** (e.g. "Net Shipping Charges at order #3"): apply Section 1.18 — `R-COHORT-ANCHOR-01`. Filter `simplified_order_cohorts_v2` by `order_number`, using the cohort-table SQL above.

---

#### Metric: Total Revenue

- **Definition:** Net Sales plus Net Shipping Charges. The primary revenue metric across all Equip Foods analysis — feeds Revenue Acquired, Discount Rate, Revenue Retention, LTR, LTRPC, LTV, LTVPC, LTV/CAC, AOV, and Gross Margin.
- **Formula:** `Net Sales + Net Shipping Charges`
- **Source:** `simplified_customer_cohorts_v2`, `simplified_order_cohorts_v2`, `LineItemMaster`
- **Formatting:** USD — `$1,250`
- **Rounding:** 0 decimal places
- **SQL (cohort tables):**
```sql
ROUND(
  SUM(COALESCE(item_gross_sales, 0))
  - SUM(COALESCE(item_discount_total, 0))
  - SUM(COALESCE(item_returns_total, 0))
  + SUM(COALESCE(shipping_price_total, 0))
  - SUM(COALESCE(shipping_tax_total, 0))
, 0) AS total_revenue
```
- **SQL (LineItemMaster — do NOT filter `item_gross_sales`/`item_discounts`/`item_returns` by `transaction_type`; the shipping terms require `transaction_type = 'Order'` — ⚠ backlog, see Section 5.4 EF-013):**
```sql
ROUND(
  SUM(COALESCE(item_gross_sales, 0))
  - SUM(COALESCE(item_discounts, 0))
  - SUM(COALESCE(item_returns, 0))
  + SUM(CASE WHEN transaction_type = 'Order' THEN COALESCE(item_shipping_price, 0) ELSE 0 END)
  - SUM(CASE WHEN transaction_type = 'Order' THEN COALESCE(item_shipping_tax, 0) ELSE 0 END)
, 0) AS total_revenue
```
- **Cohort-level vs. business-level question rule:** Total Revenue inherits Net Sales' disambiguation rule. Apply Section 1.2 — `R-PERIOD-01` and Section 1.17 — `R-TABLE-01` (EF-015 governs why `simplified_order_cohorts_v2` must not be used).
- **Order-sequence cohort question** (e.g. "Total Revenue at order #3"): apply Section 1.18 — `R-COHORT-ANCHOR-01`. Filter `simplified_order_cohorts_v2` by `order_number`, using the same cohort-table SQL above (identical column names on that table).

---

#### Metric: Revenue Acquired

- **Definition:** Total Revenue at `month_diff = 0` for the cohort. This is the fixed denominator for Revenue Retention — it never changes for a given cohort. **Not the same concept as "Customers Acquired"** (a headcount, Section 2.2) or ad-spend-based acquisition cost metrics — "Revenue Acquired" means the revenue generated in the acquisition month itself, not revenue attributable to acquisition marketing spend.
- **Formula:** `SUM(item_gross_sales - item_discount_total - item_returns_total + shipping_price_total - shipping_tax_total) WHERE month_diff = 0`, held constant over the window partition.
- **Source:** `simplified_customer_cohorts_v2` (month-based, default); `simplified_order_cohorts_v2` (order-sequence anchor — apply Section 1.18, `R-COHORT-ANCHOR-01`; `⚠ Needs validation`, Section 3.7)
- **Formatting:** USD — `$1,250`
- **Rounding:** 0 decimal places
- **SQL (month-based):**
```sql
SUM(CASE WHEN month_diff = 0
  THEN COALESCE(item_gross_sales, 0) - COALESCE(item_discount_total, 0) - COALESCE(item_returns_total, 0)
       + COALESCE(shipping_price_total, 0) - COALESCE(shipping_tax_total, 0)
  ELSE 0
END) OVER (PARTITION BY acq_month, acq_channel, acq_type, purchasing_pattern,
           entry_sku, entry_sku_category, entry_sku_sub_category,
           entry_sku_product_name, subscriber_status, _run_id)
AS revenue_acquired
```
- **SQL (order-sequence, `simplified_order_cohorts_v2` — use `revenue_acquired_by_order` from the Order Cohorts CTE, Section 3.7):**
```sql
-- Use order_cohorts CTE from Section 3.7
SELECT revenue_acquired_by_order AS revenue_acquired
FROM order_cohorts
```

---

#### Metric: Discount Rate

- **Definition:** Total item discounts as a percentage of Total Revenue.
- **Formula:** `SUM(item_discount_total) / Total Revenue`
- **Source:** `simplified_customer_cohorts_v2` (month-based, default) or `simplified_order_cohorts_v2` (order-sequence anchor — apply Section 1.18, `R-COHORT-ANCHOR-01`; `⚠ Needs validation`, no independent reconciliation performed for the order-based case). No window function is needed either way — this is a plain aggregate ratio, so the same SQL works on both tables, just changing the `WHERE`/`GROUP BY` from `month_diff` to `order_number`.
- **Formatting:** `%` — `8.25%`
- **Rounding:** 2 decimal places
- **SQL:**
```sql
ROUND(
  SAFE_DIVIDE(
    SUM(COALESCE(item_discount_total, 0)),
    SUM(COALESCE(item_gross_sales, 0)) - SUM(COALESCE(item_discount_total, 0)) - SUM(COALESCE(item_returns_total, 0))
      + SUM(COALESCE(shipping_price_total, 0)) - SUM(COALESCE(shipping_tax_total, 0))
  ) * 100
, 2) AS discount_rate_pct
```
- **By discount code:** when the question breaks Discount Rate out by discount code, use the `LineItemMaster` + `dim_orders` version in Section 2.9, not this cohort-table SQL.

---

### 2.2 Acquisition & CAC Metrics

---

#### Metric: Customers Acquired

- **Definition:** Count of customers in the acquisition month (`month_diff = 0`). This is the **fixed denominator** for all cohort ratio metrics and never changes for a given cohort.
- **Formula:** `SUM(customer_count) WHERE month_diff = 0` — held fixed per cohort partition
- **Source:** `simplified_customer_cohorts_v2` (uses `customer_count`), `simplified_order_cohorts_v2` (uses `customer_count` at `order_number = 1`), `simplified_churn_customers` (uses `total_customers_acquired` — different column name, see Section 3.5)
- **Formatting:** US numeric — `1,250`
- **Rounding:** 0 decimal places
- **Period aggregation rule:** When the user specifies a period longer than one month (e.g. "customers acquired in 2025", "customers acquired in Q1"), return **one single total** for the entire period by summing across all `acq_month` values within it. Do not break this out by month unless the user explicitly asks for a trend or monthly breakdown.
- **SQL (single period total — default):**
```sql
SUM(CASE WHEN month_diff = 0 THEN COALESCE(customer_count, 0) ELSE 0 END) AS customers_acquired
-- WHERE EXTRACT(YEAR FROM acq_month) = [year] -- or other period filter
-- No GROUP BY acq_month unless a monthly breakdown was explicitly requested
```
- **SQL (monthly cohorts, fixed per cohort — for cohort-level ratio denominators):**
```sql
SUM(CASE WHEN month_diff = 0 THEN COALESCE(customer_count, 0) ELSE 0 END)
OVER (PARTITION BY acq_month, acq_channel, acq_type, purchasing_pattern,
     entry_sku, entry_sku_category, entry_sku_sub_category,
     entry_sku_product_name, subscriber_status, _run_id)
AS customers_acquired
```

---

#### Metric: Total Ad Spend

- **Definition:** Ad spend allocated to the acquisition month — the spend that acquired the cohort. Fixed at `month_diff = 0` (month-based) or `order_number = 1` (order-sequence anchor — apply Section 1.18, `R-COHORT-ANCHOR-01`); non-zero only at acquisition either way.
- **Formula:** `SUM(adspend) WHERE month_diff = 0` — held fixed per cohort partition
- **Source:** `simplified_customer_cohorts_v2` (month-based, default); `simplified_order_cohorts_v2` (order-sequence anchor; `⚠ Needs validation`, Section 3.7)
- **Formatting:** USD — `$1,250`
- **Rounding:** 0 decimal places
- **SQL (month-based):**
```sql
SUM(CASE WHEN month_diff = 0 THEN COALESCE(adspend, 0) ELSE 0 END)
OVER (PARTITION BY acq_month, acq_channel, acq_type, purchasing_pattern,
     entry_sku, entry_sku_category, entry_sku_sub_category,
     entry_sku_product_name, subscriber_status, _run_id)
AS total_ad_spend
```
- **SQL (order-sequence, `simplified_order_cohorts_v2` — use `total_ad_spend` from the Order Cohorts CTE, Section 3.7):**
```sql
-- Use order_cohorts CTE from Section 3.7
SELECT total_ad_spend
FROM order_cohorts
```

---

#### Metric: Customer Acquisition Cost (CAC)

- **Definition:** Total ad spend at acquisition month ÷ Customers Acquired.
- **Formula:** `Total Ad Spend / Customers Acquired`
- **Source:** `simplified_customer_cohorts_v2` (month-based, default) or `simplified_order_cohorts_v2` (order-sequence anchor — apply Section 1.18, `R-COHORT-ANCHOR-01`; `⚠ Needs validation`, no independent reconciliation performed for the order-based case)
- **Formatting:** USD — `$48`
- **Rounding:** 0 decimal places
- **SQL (month-based):**
```sql
ROUND(
  SAFE_DIVIDE(
    SUM(CASE WHEN month_diff = 0 THEN COALESCE(adspend, 0) ELSE 0 END)
      OVER (PARTITION BY acq_month, acq_channel, acq_type, purchasing_pattern,
            entry_sku, entry_sku_category, entry_sku_sub_category,
            entry_sku_product_name, subscriber_status, _run_id),
    SUM(CASE WHEN month_diff = 0 THEN COALESCE(customer_count, 0) ELSE 0 END)
      OVER (PARTITION BY acq_month, acq_channel, acq_type, purchasing_pattern,
            entry_sku, entry_sku_category, entry_sku_sub_category,
            entry_sku_product_name, subscriber_status, _run_id)
  )
, 0) AS cac
```
- **SQL (order-sequence, `simplified_order_cohorts_v2` — use `total_ad_spend`/`customers_acquired` from the Order Cohorts CTE, Section 3.7):**
```sql
-- Use order_cohorts CTE from Section 3.7
SELECT ROUND(SAFE_DIVIDE(total_ad_spend, customers_acquired), 0) AS cac
FROM order_cohorts
```

---

### 2.3 Retention & Repurchase Metrics

---

#### Metric: Repurchase Rate

- **Definition:** Customers who transacted in a given `month_diff` ÷ Customers Acquired at `month_diff = 0`. Measures month-over-month cohort reactivation — a customer counts every month they transact, not just the first repeat. **Distinct from Repurchase Rate (Lifecycle)** (Section 2.7), which is a single lifetime yes/no figure (reached a 2nd order, ever) — the two are not comparable and can differ substantially for the same cohort.
- **Formula:** `SUM(customer_count) / Customers Acquired`
- **Source:** `simplified_customer_cohorts_v2` (month_diff-anchored, default) or `simplified_order_cohorts_v2` (order_number-anchored) — apply Section 1.18, `R-COHORT-ANCHOR-01`, to choose. Same formula, different anchor column, different number.
- **Formatting:** `%` — `42.50%`
- **Rounding:** 2 decimal places
- **SQL:**
```sql
ROUND(
  SAFE_DIVIDE(
    SUM(COALESCE(customer_count, 0)),
    SUM(CASE WHEN month_diff = 0 THEN COALESCE(customer_count, 0) ELSE 0 END)
      OVER (PARTITION BY acq_month, acq_channel, acq_type, purchasing_pattern,
            entry_sku, entry_sku_category, entry_sku_sub_category,
            entry_sku_product_name, subscriber_status, _run_id)
  ) * 100
, 2) AS repurchase_rate_pct
```

---

#### Metric: Revenue Retention

> **Not the bare-"Retention" default** (Section 1.2) — only use this metric when the user explicitly says "revenue retention." A plain "Retention" defaults to Retention Rate instead.

- **Definition:** Total Revenue in a given `month_diff` ÷ Total Revenue at `month_diff = 0` for the same cohort.
- **Formula:** `Total Revenue / Revenue Acquired`
- **Source:** `simplified_customer_cohorts_v2` (month-based, default); `simplified_order_cohorts_v2` (order-sequence anchor, using `revenue_acquired_by_order` in place of the `month_diff = 0` window — apply Section 1.18, `R-COHORT-ANCHOR-01`; `⚠ Needs validation`, Section 3.7)
- **Formatting:** `%` — `35.00%`
- **Rounding:** 2 decimal places
- **SQL (month-based):**
```sql
ROUND(
  SAFE_DIVIDE(
    SUM(COALESCE(item_gross_sales, 0)) - SUM(COALESCE(item_discount_total, 0)) - SUM(COALESCE(item_returns_total, 0))
      + SUM(COALESCE(shipping_price_total, 0)) - SUM(COALESCE(shipping_tax_total, 0)),
    SUM(CASE WHEN month_diff = 0
      THEN COALESCE(item_gross_sales, 0) - COALESCE(item_discount_total, 0) - COALESCE(item_returns_total, 0)
           + COALESCE(shipping_price_total, 0) - COALESCE(shipping_tax_total, 0)
      ELSE 0 END)
      OVER (PARTITION BY acq_month, acq_channel, acq_type, purchasing_pattern,
            entry_sku, entry_sku_category, entry_sku_sub_category,
            entry_sku_product_name, subscriber_status, _run_id)
  ) * 100
, 2) AS revenue_retention_pct
```
- **SQL (order-sequence, `simplified_order_cohorts_v2` — use the Order Cohorts CTE, Section 3.7):**
```sql
-- Use order_cohorts CTE from Section 3.7
SELECT
  ROUND(SAFE_DIVIDE(
    COALESCE(item_gross_sales, 0) - COALESCE(item_discount_total, 0) - COALESCE(item_returns_total, 0)
      + COALESCE(shipping_price_total, 0) - COALESCE(shipping_tax_total, 0),
    revenue_acquired_by_order
  ) * 100, 2) AS revenue_retention_pct
FROM order_cohorts
```

---

#### Metric: Churn Rate

- **Definition:** Customers who churned in a given `month_diff` ÷ Customers Acquired.
- **Formula:** `SUM(customer_count) / SUM(total_customers_acquired) WHERE month_diff = 0`
- **Source:** `simplified_churn_customers`
- **Formatting:** `%` — `5.25%`
- **Rounding:** 2 decimal places
- **Important:** This table uses `total_customers_acquired` as the fixed denominator column, not `customer_count`. See Section 3.5.
- **SQL:**
```sql
ROUND(
  SAFE_DIVIDE(
    SUM(COALESCE(customer_count, 0)),
    SUM(CASE WHEN month_diff = 0 THEN COALESCE(total_customers_acquired, 0) ELSE 0 END)
      OVER (PARTITION BY acq_month, acq_channel, acq_type, purchasing_pattern)
  ) * 100
, 2) AS churn_rate_pct
```

---

#### Metric: Cumulative Churn Rate

- **Definition:** Running total of churned customers to date ÷ Customers Acquired.
- **Formula:** `RUNNING_SUM(customer_count) / total_customers_acquired`
- **Source:** `simplified_churn_customers`
- **Formatting:** `%` — `22.50%`
- **Rounding:** 2 decimal places
- **SQL:**
```sql
ROUND(
  SAFE_DIVIDE(
    SUM(SUM(COALESCE(customer_count, 0)))
      OVER (PARTITION BY acq_month, acq_channel, acq_type, purchasing_pattern
            ORDER BY month_diff
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
    SUM(CASE WHEN month_diff = 0 THEN COALESCE(total_customers_acquired, 0) ELSE 0 END)
      OVER (PARTITION BY acq_month, acq_channel, acq_type, purchasing_pattern)
  ) * 100
, 2) AS cumulative_churn_rate_pct
```

---

#### Metric: Retention Rate

> **Default for bare "Retention"** (Section 1.2) — unless the user says "revenue retention," "subscriber retention," or "subscription revenue retained," a plain "Retention" question resolves to this metric. State the assumption.

- **Definition:** Percentage of original cohort that has not yet churned, per the churn definition in Section 4.3. **Not the same as Repurchase Rate** (Section 2.3) and can diverge from it materially: a customer is "retained" as long as they have an active subscription or ordered within the last 30 days, even if they placed no order at all in a given `month_diff` — so Retention Rate can stay high in a month where Repurchase Rate (which requires a transaction in that specific `month_diff`) is comparatively low.
- **Formula:** `1 - Cumulative Churn Rate`
- **Source:** `simplified_churn_customers`
- **Formatting:** `%` — `77.50%`
- **Rounding:** 2 decimal places
- **SQL:**
```sql
ROUND(
  (1 - SAFE_DIVIDE(
    SUM(SUM(COALESCE(customer_count, 0)))
      OVER (PARTITION BY acq_month, acq_channel, acq_type, purchasing_pattern
            ORDER BY month_diff
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
    SUM(CASE WHEN month_diff = 0 THEN COALESCE(total_customers_acquired, 0) ELSE 0 END)
      OVER (PARTITION BY acq_month, acq_channel, acq_type, purchasing_pattern)
  )) * 100
, 2) AS retention_rate_pct
```

---

### 2.4 LTR / LTV Metrics

> **Architecture note:** `running_total_revenue` (and `running_net_sales`) are not raw columns in `simplified_customer_cohorts_v2`. They are added by a window function query that must be run as a CTE or subquery before these metrics can be computed. See Section 3.6 for the full SQL. Each of these metrics can also be computed order-sequence-anchored on `simplified_order_cohorts_v2` (Section 1.18, `R-COHORT-ANCHOR-01`) using the equivalent Order Cohorts CTE (Section 3.7) — `⚠ Needs validation` for that variant, see Section 3.7.

---

#### Metric: Lifetime Revenue (LTR)

- **Definition:** Running cumulative Total Revenue per cohort, ordered by `month_diff` (default) or, order-sequence-anchored, by `order_number` (Section 1.18, `R-COHORT-ANCHOR-01`). Represents total revenue generated by the cohort from acquisition to a given period or order.
- **Formula:** `SUM(Total Revenue) OVER (PARTITION BY [cohort grain] ORDER BY month_diff ROWS UNBOUNDED PRECEDING)`
- **Source:** `simplified_customer_cohorts_v2` — requires Monthly Cohorts CTE (Section 3.6); or `simplified_order_cohorts_v2` — requires Order Cohorts CTE (Section 3.7, `⚠ Needs validation`)
- **Formatting:** USD — `$120,000`
- **Rounding:** 0 decimal places
- **SQL (month-based):**
```sql
-- Use monthly_cohorts CTE from Section 3.6
SELECT
  acq_month,
  month_diff,
  ROUND(running_total_revenue, 0) AS ltr
FROM monthly_cohorts
```
- **SQL (order-sequence):**
```sql
-- Use order_cohorts CTE from Section 3.7
SELECT
  acq_month,
  order_number,
  ROUND(running_total_revenue_by_order, 0) AS ltr
FROM order_cohorts
```

---

#### Metric: LTR Per Customer (LTRPC)

- **Definition:** Lifetime Revenue ÷ Customers Acquired.
- **Formula:** `running_total_revenue / customers_acquired`
- **Source:** `simplified_customer_cohorts_v2` — requires Monthly Cohorts CTE; or `simplified_order_cohorts_v2` — requires Order Cohorts CTE (Section 3.7, `⚠ Needs validation`), order-sequence-anchored per Section 1.18
- **Formatting:** USD — `$48`
- **Rounding:** 0 decimal places
- **SQL (month-based):**
```sql
ROUND(
  SAFE_DIVIDE(running_total_revenue, customers_acquired)
, 0) AS ltrpc
```
- **SQL (order-sequence):**
```sql
-- Use order_cohorts CTE from Section 3.7
ROUND(SAFE_DIVIDE(running_total_revenue_by_order, customers_acquired), 0) AS ltrpc
```

---

#### Metric: Lifetime Value (LTV)

**COGS is back in use for LTV, reverted from the fixed-%-only formula (EF-012).** LTV is Running cumulative (Total Revenue − actual COGS) since acquisition. The fixed Gross Margin % per channel is now a fallback only, used exclusively when `cogs` is `NULL` for a row — verified against BigQuery as of 2026-09 to be 0% null across every acquisition month from January 2024 through June 2026, so the fallback should almost never fire in practice, but must stay in the formula defensively.

- **Definition:** Running cumulative (Total Revenue − COGS) since acquisition, `month_diff`-anchored (default) or order-sequence-anchored by `order_number` (Section 1.18, `R-COHORT-ANCHOR-01`). Falls back to Total Revenue × channel Gross Margin % only when `cogs` is `NULL` for that row. **Every response using this metric must disclose that actual COGS is in use and offer the fixed-% alternative — Section 5.2, `R-COGS-DISCLOSURE-01`.**
- **Fallback Gross Margin % by channel (Section 2.7):** `55.0%` for DTC/Shopify (`acq_channel = 'Shopify'`), `49.5%` for Amazon (`acq_channel = 'Amazon Seller Central'`) — applied row-by-row only when `cogs IS NULL`, not as a blended channel-level rate.
- **Formula:** `SUM(Total Revenue - COALESCE(cogs, Total Revenue * (1 - CASE WHEN acq_channel = 'Shopify' THEN 0.55 WHEN acq_channel = 'Amazon Seller Central' THEN 0.495 END))) OVER (PARTITION BY [cohort grain] ORDER BY month_diff ROWS UNBOUNDED PRECEDING)`
- **Source:** `simplified_customer_cohorts_v2` — requires Monthly Cohorts CTE (Section 3.6); or `simplified_order_cohorts_v2` — requires Order Cohorts CTE (Section 3.7, `⚠ Needs validation`)
- **Formatting:** USD — `$84,000`
- **Rounding:** 0 decimal places
- **SQL (month-based):**
```sql
-- Use monthly_cohorts CTE from Section 3.6
ROUND(running_ltv, 0) AS ltv
-- running_ltv = RUNNING_SUM(total_revenue - COALESCE(cogs, total_revenue * (1 - CASE WHEN acq_channel = 'Shopify' THEN 0.55 WHEN acq_channel = 'Amazon Seller Central' THEN 0.495 END)))
```
- **SQL (order-sequence):**
```sql
-- Use order_cohorts CTE from Section 3.7
ROUND(running_ltv_by_order, 0) AS ltv
-- running_ltv_by_order = RUNNING_SUM(total_revenue - COALESCE(cogs, total_revenue * (1 - channel Gross Margin %))), ordered by order_number
```

---

#### Metric: LTV Per Customer (LTVPC)

- **Definition:** Lifetime Value ÷ Customers Acquired. **Inherits the COGS disclosure requirement from LTV — Section 5.2, `R-COGS-DISCLOSURE-01`.**
- **Formula:** `running_ltv / customers_acquired`
- **Source:** `simplified_customer_cohorts_v2` — requires Monthly Cohorts CTE; or `simplified_order_cohorts_v2` — requires Order Cohorts CTE (Section 3.7, `⚠ Needs validation`), order-sequence-anchored per Section 1.18
- **Formatting:** USD — `$84`
- **Rounding:** 0 decimal places
- **SQL (month-based):**
```sql
ROUND(SAFE_DIVIDE(running_ltv, customers_acquired), 0) AS ltvpc
```
- **SQL (order-sequence):**
```sql
-- Use order_cohorts CTE from Section 3.7
ROUND(SAFE_DIVIDE(running_ltv_by_order, customers_acquired), 0) AS ltvpc
```

---

#### Metric: LTV / CAC

- **Definition:** Lifetime Value ÷ Customer Acquisition Cost. Measures return on acquisition investment. **Inherits the COGS disclosure requirement from the LTV metric it divides — Section 5.2, `R-COGS-DISCLOSURE-01`.**
- **Formula:** `LTV / CAC`
- **Source:** `simplified_customer_cohorts_v2` (month-based, default) or `simplified_order_cohorts_v2` (order-sequence anchor, using `running_ltv_by_order` — apply Section 1.18, `R-COHORT-ANCHOR-01`; `⚠ Needs validation`, Section 3.7)
- **Formatting:** Plain ratio — `3.45`
- **Rounding:** 2 decimal places
- **SQL (month-based):**
```sql
ROUND(SAFE_DIVIDE(running_ltv, cac), 2) AS ltv_cac_ratio
```
- **SQL (order-sequence, `simplified_order_cohorts_v2` — use `running_ltv_by_order` and the order-based CAC, Section 3.7):**
```sql
ROUND(SAFE_DIVIDE(running_ltv_by_order, cac), 2) AS ltv_cac_ratio
```

---

### 2.5 Volume Metrics

---

#### Metric: AOV (Average Order Value)

- **Definition:** Total Revenue ÷ Total Orders in the period.
- **Formula:** `Total Revenue / SUM(order_count)`
- **Source:** `simplified_customer_cohorts_v2` (month_diff-anchored, default) or `simplified_order_cohorts_v2` (order_number-anchored) — apply Section 1.18, `R-COHORT-ANCHOR-01`, to choose. No window function needed either way; only the `WHERE`/`GROUP BY` key changes.
- **Formatting:** USD — `$85`
- **Rounding:** 0 decimal places
- **SQL:**
```sql
ROUND(
  SAFE_DIVIDE(
    SUM(COALESCE(item_gross_sales, 0)) - SUM(COALESCE(item_discount_total, 0)) - SUM(COALESCE(item_returns_total, 0))
      + SUM(COALESCE(shipping_price_total, 0)) - SUM(COALESCE(shipping_tax_total, 0)),
    SUM(COALESCE(order_count, 0))
  )
, 0) AS aov
```

---

#### Metric: Orders Per Customer (OPC)

- **Definition:** Cumulative orders placed per customer acquired — running total across `month_diff` (default) or, order-sequence-anchored, across `order_number` (Section 1.18, `R-COHORT-ANCHOR-01`).
- **Formula:** `RUNNING_SUM(SUM(order_count)) / Customers Acquired`
- **Source:** `simplified_customer_cohorts_v2`, `simplified_order_cohorts_v2` (`⚠ Needs validation` for the order-sequence variant — no independent reconciliation performed)
- **Formatting:** Plain ratio — `3.45`
- **Rounding:** 2 decimal places
- **SQL (month-based):**
```sql
ROUND(
  SAFE_DIVIDE(
    SUM(SUM(COALESCE(order_count, 0)))
      OVER (PARTITION BY acq_month, acq_channel, acq_type, purchasing_pattern,
            entry_sku, entry_sku_category, entry_sku_sub_category,
            entry_sku_product_name, subscriber_status, _run_id
            ORDER BY month_diff
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
    SUM(CASE WHEN month_diff = 0 THEN COALESCE(customer_count, 0) ELSE 0 END)
      OVER (PARTITION BY acq_month, acq_channel, acq_type, purchasing_pattern,
            entry_sku, entry_sku_category, entry_sku_sub_category,
            entry_sku_product_name, subscriber_status, _run_id)
  )
, 2) AS orders_per_customer
```
- **SQL (order-sequence, `simplified_order_cohorts_v2`):**
```sql
ROUND(
  SAFE_DIVIDE(
    SUM(SUM(COALESCE(order_count, 0)))
      OVER (PARTITION BY acq_month, acq_channel, acq_type, purchasing_pattern,
            entry_sku, entry_sku_category, entry_sku_sub_category,
            entry_sku_product_name, subscriber_status, _run_id
            ORDER BY order_number
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
    SUM(CASE WHEN order_number = 1 THEN COALESCE(customer_count, 0) ELSE 0 END)
      OVER (PARTITION BY acq_month, acq_channel, acq_type, purchasing_pattern,
            entry_sku, entry_sku_category, entry_sku_sub_category,
            entry_sku_product_name, subscriber_status, _run_id)
  )
, 2) AS orders_per_customer
```

---

#### Metric: Units Per Order (UPO)

- **Definition:** Total units ordered ÷ Total orders in the period.
- **Formula:** `SUM(item_quantity) / SUM(order_count)`
- **Source:** `simplified_customer_cohorts_v2` (month_diff-anchored, default) or `simplified_order_cohorts_v2` (order_number-anchored) — apply Section 1.18, `R-COHORT-ANCHOR-01`, to choose. No window function needed either way; only the `WHERE`/`GROUP BY` key changes.
- **Formatting:** Plain ratio — `2.50`
- **Rounding:** 2 decimal places
- **SQL:**
```sql
ROUND(
  SAFE_DIVIDE(
    SUM(COALESCE(item_quantity, 0)),
    SUM(COALESCE(order_count, 0))
  )
, 2) AS units_per_order
```

---

### 2.6 Subscription Metrics

All subscription metrics source from `SubscriptionMaster` and `SubscriberCohort`.

**Key derivations used across subscription metrics:**

```sql
-- Subscriber acquisition date (earliest subscription start per customer)
MIN(subscription_start_date) OVER (PARTITION BY customer_id) AS subscriber_acq_date

-- Subscriber churn date (latest cancel date; NULL if the customer currently has any ACTIVE row)
-- Section 1.19 (R-SUBACTIVE-01): "active" must come from subscription_status, never a cancel-date-null check
-- (PAUSED/FAILED rows also carry a NULL subscription_cancel_date).
CASE
  WHEN MAX(CASE WHEN subscription_status = 'ACTIVE' THEN 1 ELSE 0 END)
         OVER (PARTITION BY customer_id) = 1 THEN NULL
  ELSE MAX(subscription_cancel_date) OVER (PARTITION BY customer_id)
END AS subscriber_churn_date

-- Active subscription filter
WHERE subscription_status = 'ACTIVE'
```

---

#### Metric: Subscriber Churn Rate

- **Definition:** Customers who churned in a given month since their subscriber acquisition ÷ Subscribers acquired in that cohort month. Measured at customer level.
- **Formula:** `COUNT(DISTINCT customer_id [churned in month]) / COUNT(DISTINCT customer_id [acquired in acq_month])`
- **Source:** `SubscriptionMaster`
- **Formatting:** `%` — `3.25%`
- **Rounding:** 2 decimal places
- **SQL:**
```sql
WITH subscriber_base AS (
  SELECT
    customer_id,
    DATE_TRUNC(MIN(subscription_start_date), MONTH) AS subscriber_acq_month,
    CASE
      WHEN MAX(CASE WHEN subscription_status = 'ACTIVE' THEN 1 ELSE 0 END) = 1 THEN NULL
      ELSE MAX(subscription_cancel_date)
    END AS subscriber_churn_date
  FROM `insightsprod.equipfoods_5642_prod_presentation.SubscriptionMaster`
  GROUP BY customer_id
),
cohort_base AS (
  SELECT
    subscriber_acq_month,
    COUNT(DISTINCT customer_id) AS subscribers_acquired
  FROM subscriber_base
  GROUP BY subscriber_acq_month
),
churn_events AS (
  SELECT
    sb.subscriber_acq_month,
    DATE_TRUNC(sb.subscriber_churn_date, MONTH) AS churn_month,
    DATE_DIFF(sb.subscriber_churn_date, sb.subscriber_acq_month, MONTH) AS months_since_acq,
    COUNT(DISTINCT sb.customer_id) AS churned_customers
  FROM subscriber_base sb
  WHERE sb.subscriber_churn_date IS NOT NULL
  GROUP BY 1, 2, 3
)
SELECT
  ce.subscriber_acq_month AS acq_month,
  ce.months_since_acq,
  ROUND(SAFE_DIVIDE(ce.churned_customers, cb.subscribers_acquired) * 100, 2) AS subscriber_churn_rate_pct
FROM churn_events ce
JOIN cohort_base cb ON ce.subscriber_acq_month = cb.subscriber_acq_month
ORDER BY acq_month, months_since_acq
```

---

#### Metric: Subscriber Cumulative Churn Rate

- **Definition:** Running total of churned subscribers to date ÷ Subscribers Acquired.
- **Formula:** `RUNNING_SUM(churned_customers) / subscribers_acquired`
- **Source:** `SubscriptionMaster`
- **Formatting:** `%` — `18.50%`
- **Rounding:** 2 decimal places
- **SQL:**
```sql
-- Extend churn_events CTE above:
ROUND(
  SAFE_DIVIDE(
    SUM(churned_customers)
      OVER (PARTITION BY subscriber_acq_month ORDER BY months_since_acq
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
    subscribers_acquired
  ) * 100
, 2) AS subscriber_cumulative_churn_rate_pct
```

---

#### Metric: Subscriber Retention Rate

> **Not the bare-"Retention" default** (Section 1.2) — only use this metric when the user explicitly asks about subscribers/subscriptions. A plain "Retention" defaults to the customer-level Retention Rate (Section 2.3) instead.

- **Definition:** Percentage of original subscriber cohort that has not yet churned.
- **Formula:** `1 - Subscriber Cumulative Churn Rate`
- **Source:** `SubscriptionMaster`
- **Formatting:** `%` — `81.50%`
- **Rounding:** 2 decimal places
- **SQL:**
```sql
ROUND((1 - subscriber_cumulative_churn_rate_pct / 100.0) * 100, 2) AS subscriber_retention_rate_pct
```

---

#### Metric: Subscription Cancellation Rate

- **Definition:** Subscriptions cancelled in a given month ÷ Subscriptions acquired in the cohort month. Measured at subscription contract level (`subscription_id`), not customer level.
- **Formula:** `COUNT(DISTINCT subscription_id [cancelled]) / COUNT(DISTINCT subscription_id [acquired])`
- **Source:** `SubscriptionMaster`
- **Formatting:** `%` — `4.10%`
- **Rounding:** 2 decimal places
- **SQL:**
```sql
WITH sub_base AS (
  SELECT
    subscription_id,
    customer_id,
    DATE_TRUNC(MIN(subscription_start_date) OVER (PARTITION BY customer_id, subscription_id), MONTH) AS sub_acq_month,
    CASE
      WHEN MAX(CASE WHEN subscription_status = 'ACTIVE' THEN 1 ELSE 0 END)
             OVER (PARTITION BY customer_id, subscription_id) = 1 THEN NULL
      ELSE MAX(subscription_cancel_date) OVER (PARTITION BY customer_id, subscription_id)
    END AS sub_cancel_date
  FROM `insightsprod.equipfoods_5642_prod_presentation.SubscriptionMaster`
),
acquired AS (
  SELECT sub_acq_month, COUNT(DISTINCT subscription_id) AS subscriptions_acquired
  FROM sub_base GROUP BY 1
),
cancelled AS (
  SELECT
    sub_acq_month,
    DATE_DIFF(sub_cancel_date, sub_acq_month, MONTH) AS months_since_acq,
    COUNT(DISTINCT subscription_id) AS subscriptions_cancelled
  FROM sub_base WHERE sub_cancel_date IS NOT NULL
  GROUP BY 1, 2
)
SELECT
  c.sub_acq_month AS acq_month,
  c.months_since_acq,
  ROUND(SAFE_DIVIDE(c.subscriptions_cancelled, a.subscriptions_acquired) * 100, 2) AS subscription_cancellation_rate_pct
FROM cancelled c
JOIN acquired a ON c.sub_acq_month = a.sub_acq_month
ORDER BY acq_month, months_since_acq
```

---

#### Metric: Subscription Line Cancellation Rate

- **Definition:** Subscription lines cancelled ÷ Subscription lines acquired. Most granular level — one subscription contract can have multiple lines.
- **Formula:** `COUNT(DISTINCT subscription_line_id [cancelled]) / COUNT(DISTINCT subscription_line_id [acquired])`
- **Source:** `SubscriptionMaster`
- **Formatting:** `%` — `5.00%`
- **Rounding:** 2 decimal places
- **Critical:** Use `MIN(subscription_start_date)` to derive the cohort acquisition month — never the raw `subscription_start_date` value directly. A subscription line can have multiple `subscription_start_date` rows (renewals, frequency changes); using the raw column without `MIN()` will create duplicate or incorrect cohort months for the same line.
- **SQL:** Same pattern as Subscription Cancellation Rate above, substituting `subscription_line_id` for `subscription_id`, and using `MIN(subscription_start_date) OVER (PARTITION BY customer_id, subscription_line_id)` for the line-level acquisition date — never the raw `subscription_start_date` column.

---

#### Metric: Skip Rate

- **Definition:** Orders skipped ÷ Total possible orders (skipped + placed) in the period.
- **Formula:** `SUM(orders_skipped) / SUM(orders_skipped + subscription_orders_placed)`
- **Source:** `SubscriberCohort`
- **Formatting:** `%` — `12.50%`
- **Rounding:** 2 decimal places
- **SQL:**
```sql
SELECT
  acq_month,
  month_diff,
  ROUND(
    SAFE_DIVIDE(
      SUM(COALESCE(orders_skipped, 0)),
      SUM(COALESCE(orders_skipped, 0)) + SUM(COALESCE(subscription_orders_placed, 0))
    ) * 100
  , 2) AS skip_rate_pct
FROM `insightsprod.equipfoods_5642_prod_presentation.SubscriberCohort`
GROUP BY acq_month, month_diff
ORDER BY acq_month, month_diff
```

---

#### Metric: Subscription Revenue Retained

> **Not the bare-"Retention" default** (Section 1.2) — only use this metric when the user explicitly says "subscription revenue retained" (or asks about skipped vs. realized subscription revenue). A plain "Retention" defaults to Retention Rate (Section 2.3) instead.

- **Definition:** Realized revenue ÷ Total potential revenue (skipped + realized). Measures how much of a subscriber cohort's potential revenue was actually retained/realized, not lost to skips.
- **⚠ Corrected formula.** The previous formula, `skipped_revenue / (skipped_revenue + realized_revenue)`, computes the share of potential revenue that was *lost* to skips — the inverse of what "Revenue Retained" means. "Retained" revenue is what was realized, not what was skipped.
- **Formula:** `SUM(realized_revenue) / SUM(skipped_revenue + realized_revenue)`
- **Source:** `SubscriberCohort`
- **Formatting:** `%` — `8.75%`
- **Rounding:** 2 decimal places
- **SQL:**
```sql
ROUND(
  SAFE_DIVIDE(
    SUM(COALESCE(realized_revenue, 0)),
    SUM(COALESCE(skipped_revenue, 0)) + SUM(COALESCE(realized_revenue, 0))
  ) * 100
, 2) AS subscription_revenue_retained_pct
```

---

#### Metric: Reactivation Rate

- **Definition:** Subscribers reactivated in a given period ÷ Subscribers Acquired (fixed at acquisition month).
- **Formula:** `SUM(subscribers_reactivated) / SUM(subscribers_acquired WHERE month_diff = 0)`
- **Source:** `SubscriberCohort`
- **Formatting:** `%` — `2.10%`
- **Rounding:** 2 decimal places
- **SQL:**
```sql
ROUND(
  SAFE_DIVIDE(
    SUM(COALESCE(subscribers_reactivated, 0)),
    SUM(CASE WHEN month_diff = 0 THEN COALESCE(subscribers_acquired, 0) ELSE 0 END)
      OVER (PARTITION BY acq_month)
  ) * 100
, 2) AS reactivation_rate_pct
```

---

#### Metric: Subscriber Type

- **Definition:** Classifies a subscriber by how they were originally acquired.
- **Formula:** `CASE WHEN customer_acq_type = 'Subscription' THEN 'Acquired on Subscription' ELSE 'OTP to Subscriber' END`
- **Source:** `SubscriptionMaster`
- **Formatting:** Text label — display as-is
- **Rounding:** N/A — categorical value

---

### 2.7 Lifecycle & SKU Metrics (LineItemMaster)

---

#### Metric: Repurchase Rate (Lifecycle)

- **Definition:** Customers who reached a 2nd order ÷ Customers acquired at their 1st order. Distinct from Repurchase Rate (Section 2.3), which measures month-over-month cohort reactivation, not lifetime repeat purchase — see the disambiguation note there.
- **⚠ Corrected formula.** The previous formula, `SUM(customer_count WHERE order_number > 1) / SUM(customer_count)`, summed `customer_count` across every `order_number > 1` row (2nd, 3rd, 4th... orders) in both the numerator and the denominator. Since `customer_count` at a given `order_number` already counts every customer who reached at least that far, summing across multiple `order_number` values double- and triple-counts the same customers in both the numerator and denominator, producing a number that isn't a clean percentage of the acquired cohort.
- **Formula:** `customer_count WHERE order_number = 2` ÷ `customer_count WHERE order_number = 1` — numerator is customers who reached a 2nd order (i.e. repurchased at least once); denominator is customers acquired (identical to the `order_number = 1` row, per the Customers Acquired metric, Section 2.2).
- **Source:** `simplified_order_cohorts_v2` — the order cohort table (not LineItemMaster, which lacks the `order_number` dimension)
- **Formatting:** `%` — `45.25%`
- **Rounding:** 2 decimal places
- **SQL:**
```sql
SELECT
  ROUND(SAFE_DIVIDE(
    SUM(CASE WHEN order_number = 2 THEN COALESCE(customer_count, 0) ELSE 0 END),
    SUM(CASE WHEN order_number = 1 THEN COALESCE(customer_count, 0) ELSE 0 END)
  ) * 100, 2) AS repurchase_rate_lifecycle_pct
FROM `insightsprod.equipfoods_5642_prod_presentation.simplified_order_cohorts_v2`
WHERE EXTRACT(YEAR FROM acq_month) = [YEAR];
```

---

#### Metric: OTP to Subscriber Conversion Rate

- **Definition:** OTP-acquired customers who later became subscribers ÷ All OTP-acquired customers.
- **Formula:** `COUNT(DISTINCT customer_id WHERE customer_acq_type != 'Subscription' AND subscriber_status = 'Subscriber') / COUNT(DISTINCT customer_id WHERE customer_acq_type != 'Subscription')`
- **Source:** `LineItemMaster`
- **Formatting:** `%` — `18.75%`
- **Rounding:** 2 decimal places
- **SQL:**
```sql
SELECT
  ROUND(
    SAFE_DIVIDE(
      COUNT(DISTINCT CASE WHEN customer_acq_type != 'Subscription' AND subscriber_status = 'Subscriber' THEN customer_id END),
      COUNT(DISTINCT CASE WHEN customer_acq_type != 'Subscription' THEN customer_id END)
    ) * 100
  , 2) AS otp_to_subscriber_conversion_rate_pct
FROM `insightsprod.equipfoods_5642_prod_presentation.LineItemMaster`
WHERE customer_id IS NOT NULL
```

---

#### Metric: Subscribers Acquired

- **Definition:** Count of unique customers who **started a subscription** in a given period, using the earliest subscription start date per customer. This includes both customers acquired directly as a subscription AND OTP customers who later converted.
- **Formula:** `COUNT(DISTINCT customer_id)` where `DATE_TRUNC(MIN(subscription_start_date), MONTH)` falls in the period
- **Source:** `SubscriptionMaster` — uses `MIN(subscription_start_date)` per `customer_id` to derive the cohort acquisition month
- **Formatting:** US numeric — `1,250`
- **Rounding:** 0 decimal places
- **SQL:** `MIN(subscription_start_date)` must be derived per customer in a CTE first — a raw `SELECT ... GROUP BY DATE_TRUNC(MIN(subscription_start_date), MONTH)` is invalid (BigQuery cannot `GROUP BY` an expression built on an aggregate over the whole table with no prior per-customer grouping):
```sql
WITH customer_first_sub AS (
  SELECT
    customer_id,
    MIN(subscription_start_date) AS first_sub_date
  FROM `insightsprod.equipfoods_5642_prod_presentation.SubscriptionMaster`
  GROUP BY customer_id
)
SELECT
  DATE_TRUNC(first_sub_date, MONTH) AS subscription_acq_month,
  COUNT(DISTINCT customer_id) AS subscribers_acquired
FROM customer_first_sub
GROUP BY subscription_acq_month
ORDER BY subscription_acq_month DESC;
```

- **Note:** This metric includes both "direct subscription" customers AND "OTP→Subscriber converters" (customers whose first purchase was OTP but who later subscribed). To isolate direct subscription acquisitions only, filter to `customer_acq_type = 'Subscription'` in the source or use the "Subscription Take Rate" metric below.

---

#### Metric: Subscription Take Rate (Customers Acquired as Subscription)

- **Definition:** Percentage of customers whose **first purchase was a subscription** (customer_acq_type = 'Subscription') out of all customers acquired. This is narrower than "Subscribers Acquired" — it excludes OTP→Subscriber converters.
- **Formula:** `COUNT(DISTINCT customer_id WHERE customer_acq_type = 'Subscription') / COUNT(DISTINCT customer_id)`
- **Source:** `LineItemMaster` — filters to first purchase per customer, checking if that first purchase was a subscription
- **Formatting:** `%` — `32.00%`
- **Rounding:** 2 decimal places
- **SQL:**
```sql
SELECT
  ROUND(SAFE_DIVIDE(
    COUNT(DISTINCT CASE WHEN customer_acq_type = 'Subscription' THEN customer_id END),
    COUNT(DISTINCT customer_id)
  ) * 100, 2) AS subscription_take_rate_pct
FROM `insightsprod.equipfoods_5642_prod_presentation.LineItemMaster`
WHERE customer_id IS NOT NULL;
```

- **Comparison to Subscribers Acquired:**
  - **Subscribers Acquired** = all customers with a subscription start date in the period (includes converters)
  - **Subscription Take Rate** = % of all customers whose first-ever purchase was a subscription (excludes converters)
  
---

#### Metric: Gross Margin

**COGS is back in use for Gross Margin, reverted from the fixed-%-only formula (EF-012).** Gross Margin is a computed ratio using actual per-line COGS (`cost_of_single_unit × quantity`); the fixed percentage per channel is now a fallback only, used exclusively when `cost_of_single_unit` is `NULL` for a row.

- **Definition:** (Total Revenue − actual COGS) ÷ Total Revenue. Falls back to a fixed % per channel — `55.0%` for DTC/Shopify, `49.5%` for Amazon — only when `cost_of_single_unit` is `NULL` for that row (rare — verified 0% null on the equivalent cohort-table `cogs` column across 24 months of data; not independently re-verified on `cost_of_single_unit` specifically). **Every response using this metric must disclose that actual COGS is in use and offer the fixed-% alternative — Section 5.2, `R-COGS-DISCLOSURE-01`.**
- **Formula:** `SUM(total_revenue - COALESCE(cost_of_single_unit * ABS(quantity), total_revenue * (1 - CASE WHEN channel = 'Shopify' THEN 0.55 WHEN channel = 'Amazon Seller Central' THEN 0.495 END))) / SUM(total_revenue)` — `quantity` is negative on Return rows (Section 3.5); always wrap in `ABS()` here or COGS is understated on any row involving returns.
- **Row-level, not a blended fixed %:** compute each row's own profit (actual COGS-based, or fallback where COGS is missing) before summing and dividing — never apply a single blended percentage across mixed channels.
- **Source:** `LineItemMaster`
- **Formatting:** `%` — `55.00%`
- **Rounding:** 2 decimal places
- **SQL (blended):**
```sql
ROUND(
  SAFE_DIVIDE(
    SUM(total_revenue - COALESCE(
      cost_of_single_unit * ABS(quantity),
      total_revenue * (1 - CASE WHEN channel = 'Shopify' THEN 0.55 WHEN channel = 'Amazon Seller Central' THEN 0.495 END)
    )),
    SUM(total_revenue)
  ) * 100
, 2) AS gross_margin_pct
-- total_revenue = Net Sales + Net Shipping Charges (Section 2.1) computed per row/channel
```

---

#### Metric: SKU Repurchase Rate

- **Definition:** Percentage of customers who made a repeat purchase of the same product, sub-category, or category within 12 months of acquisition (12M) or within their full customer lifetime (Lifetime). Only customers with a completed 90-day observation window are included in the 12M denominator (mature cohort).
- **Formula:**
  - 12M: `COUNT(customers who repurchased same [level] within 1 year AND mature_cohort = 1) / COUNT(customers WHERE mature_cohort = 1)`
  - Lifetime: `COUNT(customers who repurchased same [level] ever) / COUNT(DISTINCT customer_id)`
- **Source:** `LineItemMaster` — built via the CTE below
- **Formatting:** `%` — `38.50%`
- **Rounding:** 2 decimal places
- **Available levels:** Product (`sku_product_name`), Sub-Category (`sku_sub_category`), Category (`sku_category`)
- **SQL:**
```sql
WITH lim AS (
  SELECT
    customer_id,
    customer_acq_date,
    entry_sku_product_name,
    entry_sku_sub_category,
    entry_sku_category,
    channel,
    customer_acq_type,
    customer_purchasing_pattern,
    subscriber_status,
    MAX(date) OVER () AS max_date
  FROM `insightsprod.equipfoods_5642_prod_presentation.LineItemMaster`
),
cohort AS (
  SELECT DISTINCT
    customer_id,
    customer_acq_date,
    entry_sku_product_name,
    entry_sku_sub_category,
    entry_sku_category,
    max_date,
    CASE
      WHEN DATE_ADD(customer_acq_date, INTERVAL 90 DAY) <= max_date THEN 1
      ELSE 0
    END AS mature_cohort
  FROM lim
),
future_orders AS (
  SELECT
    customer_id,
    date,
    sku_product_name,
    sku_sub_category,
    sku_category
  FROM `insightsprod.equipfoods_5642_prod_presentation.LineItemMaster`
  WHERE transaction_type = 'Order'
    AND COALESCE(quantity, 0) > 0
),
repurchases AS (
  SELECT
    c.customer_id,
    c.customer_acq_date,
    c.entry_sku_product_name,
    c.entry_sku_sub_category,
    c.entry_sku_category,
    c.mature_cohort,
    MAX(CASE WHEN f.sku_product_name = c.entry_sku_product_name
                  AND c.entry_sku_product_name != ''
                  AND f.date > c.customer_acq_date
                  AND f.date <= DATE_ADD(c.customer_acq_date, INTERVAL 365 DAY)
             THEN 1 ELSE 0 END) AS repurchased_1yr_product,
    MAX(CASE WHEN f.sku_product_name = c.entry_sku_product_name
                  AND c.entry_sku_product_name != ''
                  AND f.date > c.customer_acq_date
             THEN 1 ELSE 0 END) AS repurchased_lifetime_product,
    MAX(CASE WHEN f.sku_sub_category = c.entry_sku_sub_category
                  AND c.entry_sku_sub_category != ''
                  AND f.date > c.customer_acq_date
                  AND f.date <= DATE_ADD(c.customer_acq_date, INTERVAL 365 DAY)
             THEN 1 ELSE 0 END) AS repurchased_1yr_subcategory,
    MAX(CASE WHEN f.sku_sub_category = c.entry_sku_sub_category
                  AND c.entry_sku_sub_category != ''
                  AND f.date > c.customer_acq_date
             THEN 1 ELSE 0 END) AS repurchased_lifetime_subcategory,
    MAX(CASE WHEN f.sku_category = c.entry_sku_category
                  AND c.entry_sku_category != ''
                  AND f.date > c.customer_acq_date
                  AND f.date <= DATE_ADD(c.customer_acq_date, INTERVAL 365 DAY)
             THEN 1 ELSE 0 END) AS repurchased_1yr_category,
    MAX(CASE WHEN f.sku_category = c.entry_sku_category
                  AND c.entry_sku_category != ''
                  AND f.date > c.customer_acq_date
             THEN 1 ELSE 0 END) AS repurchased_lifetime_category
  FROM cohort c
  LEFT JOIN future_orders f ON c.customer_id = f.customer_id
  GROUP BY 1, 2, 3, 4, 5, 6
)
-- Final aggregation — example at Product level:
SELECT
  entry_sku_product_name,
  ROUND(SAFE_DIVIDE(
    SUM(CASE WHEN mature_cohort = 1 THEN repurchased_1yr_product ELSE 0 END),
    NULLIF(SUM(CASE WHEN mature_cohort = 1 THEN 1 ELSE 0 END), 0)
  ) * 100, 2) AS repurchase_rate_12m_pct,
  ROUND(SAFE_DIVIDE(
    SUM(repurchased_lifetime_product),
    COUNT(DISTINCT customer_id)
  ) * 100, 2) AS repurchase_rate_lifetime_pct
FROM repurchases
GROUP BY entry_sku_product_name
ORDER BY repurchase_rate_lifetime_pct DESC
```

---

#### Metric: Median Gap Days

- **Definition:** Median days between a customer's first purchase and their first repurchase of the same product, sub-category, or category. Computed only for customers who did repurchase.
- **Formula:** `MEDIAN(DATE_DIFF(first_repurchase_date, customer_acq_date, DAY))` — over repurchasing customers only, at the chosen product hierarchy level
- **Source:** `LineItemMaster` — derived via the repurchase CTE above
- **Formatting:** Integer with `d` suffix — `42d`
- **Rounding:** 0 decimal places (ceiling)
- **SQL:**
```sql
-- Add to repurchases CTE: capture the first repurchase date
MIN(CASE WHEN f.sku_product_name = c.entry_sku_product_name
              AND f.date > c.customer_acq_date
         THEN f.date END) AS first_repurchase_date_product,

-- Then in final aggregation:
CAST(CEILING(PERCENTILE_CONT(
  DATE_DIFF(first_repurchase_date_product, customer_acq_date, DAY),
  0.5
) OVER ()) AS INT64) AS median_gap_days_product
```

---

#### Metric: Return Rate (by Order Date)

- **Definition:** Units returned ÷ Units purchased, attributed to the original order date (not refund date). Available at product, sub-category, and category level.
- **Formula:** `SUM(units_returned) / SUM(units_purchased)`
  - `units_purchased`: `CASE WHEN transaction_type <> 'Return' THEN ABS(COALESCE(quantity, 0)) ELSE 0 END`
  - `units_returned`: `CASE WHEN transaction_type = 'Return' THEN ABS(COALESCE(quantity, 0)) ELSE 0 END`
- **Source:** `LineItemMaster`
- **Formatting:** `%` — `4.25%`
- **Rounding:** 2 decimal places
- **SQL:**
```sql
SELECT
  DATE_TRUNC(date, MONTH) AS transaction_month, -- LineItemMaster has no real order_month column; do not reuse that name here, see Section 1.17
  sku_category,
  sku_sub_category,
  sku_product_name,
  channel,
  customer_acq_type,
  customer_purchasing_pattern,
  subscriber_status,
  CAST(SUM(CASE WHEN transaction_type <> 'Return' THEN ABS(COALESCE(quantity, 0)) ELSE 0 END) AS INT64) AS units_purchased,
  CAST(SUM(CASE WHEN transaction_type = 'Return' THEN ABS(COALESCE(quantity, 0)) ELSE 0 END) AS INT64) AS units_returned,
  ROUND(
    SAFE_DIVIDE(
      SUM(CASE WHEN transaction_type = 'Return' THEN ABS(COALESCE(quantity, 0)) ELSE 0 END),
      NULLIF(SUM(CASE WHEN transaction_type <> 'Return' THEN ABS(COALESCE(quantity, 0)) ELSE 0 END), 0)
    ) * 100
  , 2) AS return_rate_pct
FROM `insightsprod.equipfoods_5642_prod_presentation.LineItemMaster`
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8
ORDER BY transaction_month, sku_category
```

---

### 2.8 Marketing Channel LTV & CAC Metrics

> **Dashboard reference:** these metrics back the worksheet `17.Channel CAC, LTV` (dashboard-internal caption: "17. LTV and CAC by marketing channel") in the **Month Cohort View** dashboard. Grain is `acq_month × Unified Marketing Channel` — there is no `month_diff` breakout on this view; each LTV horizon is its own filtered aggregate, not a running series.
>
> **This section documents the target logic for IQ, not a literal transcription of the Tableau worksheet.** The live Tableau worksheet implements this same business intent through a Tableau data blend (not a SQL join) and currently diverges from the rules below in several respects — see EF-017. Where the two disagree, **this section is the source of truth for IQ**; EF-017 exists so dashboard numbers and IQ answers can be reconciled rather than silently mismatched.
>
> **Architecture note:** Ad spend for this view comes from a different table than every other CAC metric in this file (Section 2.2's `Total Ad Spend`/`CAC` read a pre-joined `adspend` column already sitting on the cohort tables, scoped by `acq_channel`). Here, ad spend is sourced fresh from `AdvertisingMaster` and joined in by IQ, scoped by `Unified Marketing Channel` instead. The two CAC metrics answer different questions (acquisition channel vs. marketing channel) and are not interchangeable.

---

#### Metric: Unified Marketing Channel (Join Key)

- **Definition:** Cleaned version of the raw `unified_marketing_channel` column, used to group cohort/customer data and to join it to ad spend from `AdvertisingMaster`. Fixes two known data-entry inconsistencies in the raw value, and maps customers with no attributed channel (`NULL`) to `'Unattributed- Amazon'` — in practice this is expected to be almost entirely Amazon Seller Central-acquired customers, since Amazon orders don't carry marketing-channel attribution the way Shopify orders do. Always apply this CASE before grouping or joining on channel anywhere in this section — never group on the raw `unified_marketing_channel` value directly.
- **Formula:**
```sql
CASE
  WHEN unified_marketing_channel = 'ChatGpt'         THEN 'ChatGPT'
  WHEN unified_marketing_channel = 'YouTude Organic'  THEN 'YouTube Organic'
  WHEN unified_marketing_channel IS NULL              THEN 'Unattributed- Amazon'
  ELSE unified_marketing_channel
END
```
- **Source:** `unified_marketing_channel`, `channel_grouping_1_source`, and `channel_grouping_2_channel` are confirmed present on all six cohort/order/lifecycle tables (Section 3.5) — `simplified_customer_cohorts_v2`, `simplified_order_cohorts_v2`, `simplified_churn_customers`, `LineItemMaster`, `SubscriptionMaster`, `SubscriberCohort`. This section's SQL uses `simplified_customer_cohorts_v2`, matching every other metric in Section 2.4/2.2.

---

#### Metric: Marketing Channel Ad Spend

- **Definition:** Ad spend from `AdvertisingMaster`, mapped to Unified Marketing Channel and restricted to the ad month matching the cohort's acquisition month — spend in the same calendar month the cohort was acquired, same "fixed at acquisition" pattern as Section 2.2's `Total Ad Spend`, just grouped by Unified Marketing Channel instead of `acq_channel`. Changes whenever the selected acquisition period/cohort window changes.
- **Channel mapping (`AdvertisingMaster.ad_channel` → Unified Marketing Channel):** `'GOOGLE'` → `'Google Ads'`, `'FACEBOOK'` → `'Facebook Ads'`, `'AMAZON'` → `'Unattributed- Amazon'`, anything else — **including `'TIKTOK'`** — → `'NA'` (no spend data — see "Which channels can show CAC" below). **TikTok ad spend is blocked for now, by client instruction (not yet ready to be included).** Mapping `'TIKTOK'` to `'NA'` instead of `'TikTok Shops'` means it never matches a `TikTok Shops` row on the cohort side, so that channel shows LTV normally but CAC/LTV·CAC as `-`, exactly like any other channel with no ad spend — no separate exclusion logic needed. This happens to now match the live Tableau worksheet's own TikTok exclusion (EF-017), though for a different, unconditional reason — revisit and re-include when the client is ready.
- **Formula:** `SUM(adspend) WHERE ad_month = acq_month` — join condition below.
- **Source:** `insightsprod.equipfoods_5642_prod_presentation.AdvertisingMaster`, joined to `simplified_customer_cohorts_v2` on acquisition month and Unified Marketing Channel.
- **Formatting:** USD — `$1,250`
- **Rounding:** 0 decimal places
- **SQL:**
```sql
WITH channel_adspend AS (
  SELECT
    DATE_TRUNC(ad_date, MONTH) AS ad_month,
    CASE
      WHEN UPPER(ad_channel) = 'GOOGLE'   THEN 'Google Ads'
      WHEN UPPER(ad_channel) = 'FACEBOOK' THEN 'Facebook Ads'
      WHEN UPPER(ad_channel) = 'AMAZON'   THEN 'Unattributed- Amazon'
      ELSE 'NA'  -- includes TikTok — blocked for now, by client instruction; see the Definition above
    END AS unified_marketing_channel,
    SUM(spend) AS adspend
  FROM `insightsprod.equipfoods_5642_prod_presentation.AdvertisingMaster`
  GROUP BY 1, 2
),
cohort_channel AS (
  SELECT
    acq_month,
    month_diff,
    customer_count,
    item_gross_sales, item_discount_total, item_returns_total,
    shipping_price_total, shipping_tax_total,
    cogs,
    CASE
      WHEN unified_marketing_channel = 'ChatGpt'        THEN 'ChatGPT'
      WHEN unified_marketing_channel = 'YouTude Organic' THEN 'YouTube Organic'
      WHEN unified_marketing_channel IS NULL             THEN 'Unattributed- Amazon'
      ELSE unified_marketing_channel
    END AS unified_marketing_channel
  FROM `insightsprod.equipfoods_5642_prod_presentation.simplified_customer_cohorts_v2`
  -- apply acq_channel / acq_type / subscriber_status / acq_month-window filters here
)
SELECT
  cc.unified_marketing_channel,
  SUM(CASE WHEN cc.month_diff = 0 THEN ca.adspend END) AS marketing_channel_ad_spend
FROM cohort_channel cc
LEFT JOIN channel_adspend ca
  ON  ca.ad_month = cc.acq_month
  AND ca.unified_marketing_channel = cc.unified_marketing_channel
GROUP BY 1
```
Note the `CASE` has no `ELSE` branch (defaults to `NULL`, not `0`) — wrapping the join's non-matches in `COALESCE(ca.adspend, 0)` would silently turn "no ad spend exists for this channel" into a real `$0`, which then divides cleanly instead of showing `-`. Only genuinely non-matching `month_diff = 0` rows should stay `NULL` so `SUM` correctly returns `NULL` (not `0`) for a channel with no ad spend at all.

---

#### Metric: Customers Acquired (by Unified Marketing Channel)

- **Definition:** Same underlying metric as Section 2.2's `Customers Acquired`, grouped by Unified Marketing Channel instead of the default cohort grain.
- **Formula:** `SUM(customer_count) WHERE month_diff = 0`, grouped by Unified Marketing Channel.
- **Source:** `simplified_customer_cohorts_v2`
- **Formatting:** US numeric — `1,250`
- **Rounding:** 0 decimal places
- **SQL:**
```sql
SELECT
  cc.unified_marketing_channel,
  SUM(CASE WHEN cc.month_diff = 0 THEN COALESCE(cc.customer_count, 0) ELSE 0 END) AS customers_acquired
FROM cohort_channel cc  -- cohort_channel CTE from "Marketing Channel Ad Spend" above
GROUP BY 1
```

---

#### Metric: Marketing Channel CAC

- **Definition:** Marketing Channel Ad Spend ÷ Customers Acquired (by Unified Marketing Channel). Distinct from Section 2.2's `CAC` (acquisition-channel-based, different ad-spend source) — see the architecture note above.
- **Formula:** `Marketing Channel Ad Spend / Customers Acquired (by Unified Marketing Channel)`
- **Which channels can show a value:** only channels with real spend mapped in from `AdvertisingMaster` — currently **Google Ads**, **Facebook Ads**, and **Unattributed- Amazon**. TikTok is blocked for now (see "Marketing Channel Ad Spend" above) and shows `-` like any other unmapped channel. Every other Unified Marketing Channel value (organic, email, affiliate/Superfiliate, influencer, direct, etc.) displays as a literal `-`, per the display rule below — there is no ad spend to divide, not a calculation error.
- **Source:** `simplified_customer_cohorts_v2` joined to `AdvertisingMaster` (see "Marketing Channel Ad Spend" above)
- **Formatting:** USD — `$48`; displayed as `-` when no ad spend exists for that channel (see "Query trigger, defaults, and horizon maturity" below) — apply the `-` conversion at display/presentation time, not inside the metric's own SQL, since `LTV/CAC` below divides by this metric numerically and would break against a string.
- **Rounding:** 0 decimal places
- **SQL:**
```sql
SELECT
  cc.unified_marketing_channel,
  ROUND(SAFE_DIVIDE(
    SUM(CASE WHEN cc.month_diff = 0 THEN ca.adspend END),
    SUM(CASE WHEN cc.month_diff = 0 THEN COALESCE(cc.customer_count, 0) ELSE 0 END)
  ), 0) AS marketing_channel_cac
FROM cohort_channel cc  -- cohort_channel CTE from "Marketing Channel Ad Spend" above
LEFT JOIN channel_adspend ca  -- channel_adspend CTE from "Marketing Channel Ad Spend" above
  ON  ca.ad_month = cc.acq_month
  AND ca.unified_marketing_channel = cc.unified_marketing_channel
GROUP BY 1
```
The numerator must stay `NULL` (not `0`) for a true non-match — same `COALESCE` caveat as Marketing Channel Ad Spend above — or `SAFE_DIVIDE` returns `0` instead of `NULL`, and the channel would wrongly look like it has a real (zero) CAC instead of no ad spend at all. Keep this result numeric (`NULL`, not `'-'`) so `LTV/CAC` below can divide by it directly; convert `NULL` to `-` only in the final, user-facing output.

---

#### Metric: Marketing Channel LTV per Customer (3M / 6M / 9M / 12M / Lifetime)

**COGS is back in use here too, reverted from the flat-55%-only formula.** Uses actual per-row COGS (Total Revenue − COGS) through the horizon; falls back to a flat 55% margin on Total Revenue only when `cogs` is `NULL` for a row. The flat 55% (rather than Section 2.4's channel-differentiated 55%/49.5%) is kept as the fallback specifically because the acquisition-channel split doesn't map cleanly onto a marketing-channel axis (a single marketing channel can span both Shopify- and Amazon-acquired customers) — that reasoning still applies to the fallback, it just no longer applies to the primary calculation.

- **Definition:** (Total Revenue − COGS) accrued through month N since acquisition (or, for Lifetime, with no month cutoff), divided by Customers Acquired, grouped by Unified Marketing Channel. Falls back to Total Revenue × 55% for any row where `cogs` is `NULL`. **Every response using this metric must disclose that actual COGS is in use and offer the fixed-% alternative — Section 5.2, `R-COGS-DISCLOSURE-01`.**
- **Formula:** `SUM((Total Revenue - COALESCE(cogs, Total Revenue * 0.45)) WHERE month_diff <= N) / Customers Acquired` — no cutoff for Lifetime.
- **Source:** `simplified_customer_cohorts_v2`
- **Formatting:** USD — `$84`
- **Rounding:** 0 decimal places
- **SQL (3M shown; substitute 6/9/12 for the `month_diff` cutoff, drop the `CASE` cutoff entirely for Lifetime; requires `cogs` selected in the `cohort_channel` CTE — see "Marketing Channel Ad Spend" above):**
```sql
SELECT
  cc.unified_marketing_channel,
  ROUND(SAFE_DIVIDE(
    SUM(CASE WHEN cc.month_diff <= 3 THEN
      (COALESCE(cc.item_gross_sales, 0) - COALESCE(cc.item_discount_total, 0) - COALESCE(cc.item_returns_total, 0)
      + COALESCE(cc.shipping_price_total, 0) - COALESCE(cc.shipping_tax_total, 0))
      - COALESCE(cc.cogs, (COALESCE(cc.item_gross_sales, 0) - COALESCE(cc.item_discount_total, 0) - COALESCE(cc.item_returns_total, 0)
      + COALESCE(cc.shipping_price_total, 0) - COALESCE(cc.shipping_tax_total, 0)) * 0.45)
    ELSE 0 END),
    SUM(CASE WHEN cc.month_diff = 0 THEN COALESCE(cc.customer_count, 0) ELSE 0 END)
  ), 0) AS channel_ltvpc_3m
FROM cohort_channel cc  -- cohort_channel CTE from "Marketing Channel Ad Spend" above — must select cogs
GROUP BY 1
```

---

#### Metric: Marketing Channel LTV / CAC (3M / 6M / 9M / 12M)

- **Definition:** Marketing Channel LTV per Customer at a given horizon ÷ Marketing Channel CAC. No Lifetime variant — CAC is a fixed acquisition-month cost, so a "Lifetime LTV/CAC" is not evaluated on this view. **Inherits the COGS disclosure requirement from the LTV metric it divides — Section 5.2, `R-COGS-DISCLOSURE-01`.**
- **Formula:** `Marketing Channel LTV per Customer (N) / Marketing Channel CAC`
- **Source:** `simplified_customer_cohorts_v2` joined to `AdvertisingMaster`
- **Formatting:** Plain ratio — `3.45`; displayed as `-` when `marketing_channel_cac` is `NULL` (no ad spend for that channel) — same display-time conversion as Marketing Channel CAC above, not baked into the SQL below.
- **Rounding:** 2 decimal places
- **SQL:**
```sql
ROUND(SAFE_DIVIDE(channel_ltvpc_3m, marketing_channel_cac), 2) AS channel_ltvpc_cac_3m
-- repeat for 6m / 9m / 12m; SAFE_DIVIDE(x, NULL) correctly returns NULL when marketing_channel_cac has no ad spend
```

---

#### Cohort period and filter behavior

- **Acquisition period / cohort window:** changes both sides — it restricts `cohort_channel` (Customers Acquired, LTV numerator) *and*, through the `ad_month = acq_month` join condition, Marketing Channel Ad Spend. This is a deliberate join design, confirmed by the client, and is the main way this section's logic differs from the live Tableau worksheet (EF-017), which has no date join at all.
- **Acquisition Channel, Acquisition Type, Subscriber Status filters:** apply as ordinary `WHERE` clauses on `cohort_channel` — they restrict Customers Acquired and the LTV numerator, but have no matching column on `AdvertisingMaster`, so they don't restrict Marketing Channel Ad Spend. This mirrors how Section 2.2's channel-level CAC already works — ad spend is a channel/month-level fact, not a per-customer one.
- **Channel Grouping 1 / Channel Grouping 2:** should restrict Marketing Channel Ad Spend too, unlike on the Tableau worksheet where this is a visual/blend limitation (EF-017). IQ can do this correctly because it isn't bound by Tableau's blend mechanics — and no mapping logic needs to be derived or invented to do it. `channel_grouping_1_source` and `channel_grouping_2_channel` are pre-computed columns already sitting on `cohort_channel` (the same cohort-side row that `channel_adspend` is joined to via `ad_month = acq_month` / `unified_marketing_channel`) — once that join is made, grouping/filtering by Channel Grouping 1 or 2 is simply a `GROUP BY`/`WHERE` swap onto those columns instead of `unified_marketing_channel`, using the exact same join. `AdvertisingMaster` itself carries no `channel_grouping_1_source`/`channel_grouping_2_channel` columns, but it doesn't need to — the grouping value comes from the cohort side of the join, not from Advert Master.

---

#### Query trigger, defaults, and horizon maturity

- **Trigger:** apply this section's logic (grouping by Unified Marketing Channel, joining to `AdvertisingMaster`) whenever the question asks to break LTV, CAC, or Ad Spend out "by Marketing Channel," "by Ad Channel," "by Advert Channel," or any equivalent phrasing that signals grouping by the Unified Marketing Channel field — not only the literal phrase "Marketing Channel." A bare "LTV by channel" with no such signal stays on `acq_channel` (Section 2.2/2.4) as usual.
- **Default horizons:** when this view is invoked without the user naming a specific horizon, default to showing LTV at 3M, 6M, 9M, and 12M — **not** Lifetime; Lifetime is only shown if explicitly asked for. Show the corresponding LTV/CAC at each of those same four horizons alongside it, wherever ad spend exists for that channel (no Lifetime LTV/CAC either way — see the LTV/CAC metric definition above).
- **Missing CAC display:** for any Unified Marketing Channel with no ad spend mapped in from `AdvertisingMaster` (i.e., not Google Ads / Facebook Ads / Unattributed- Amazon — TikTok is blocked for now and falls into this bucket too), display CAC and every LTV/CAC horizon as a literal `-` for that channel's row. Do not compute, return NULL, or explain the absence inline — LTV itself is still shown normally for that channel.
- **Horizon maturity — do not compute an immature horizon.** Before calculating LTV or LTV/CAC at 6M, 9M, or 12M for the selected acquisition window, confirm the window's cohorts have actually reached that many months since acquisition (`DATE_ADD(acq_month, INTERVAL N MONTH) <= [latest complete acq_month in the data]`) — the same mature-cohort gate already used for SKU Repurchase Rate (Section 2.7). If the selected window's cohorts have not reached a given horizon, do not calculate that horizon at all; state plainly that it isn't available yet (e.g. "12M LTV isn't available yet for this period — those cohorts haven't reached 12 months") rather than compute it on an incomplete basis.
- **Ad Spend asked on its own, with no LTV/CAC:** a bare "Ad spend for [month]" question never needs an acquisition-month-vs-transactional-month disambiguation — `AdvertisingMaster` has exactly one date dimension (`ad_month`, the month the spend was incurred), unlike Net Sales/Total Revenue (Section 1.17), which genuinely has two. Always answer directly against `ad_month`.
- **"LTV/CAC" as a combined ask:** the acquisition period drives LTV and Customers Acquired as always; the matching ad period for Ad Spend follows automatically through the `ad_month = acq_month` join — never ask the user which period they mean.

---

### 2.9 Discount Code Metrics

> **Applies only to discount code questions** (Section 1.20, `R-DISCOUNTCODE-01`). All metrics run on the `lim_codes` CTE from Section 1.20 — `LineItemMaster` left-joined to `dim_orders` on `order_id`, with `discount_codes` split into individual codes — grouped by `discount_code`.
>
> ⚠ **CRITICAL (`R-PII-DIMORDERS-01`):** every query here reads only `order_id` and `discount_codes` from `dim_orders` — never `SELECT *`, never `note`, `comments`, or `tags`.

**How each metric is rolled up:**

| Metric | Roll-up | Rule applied |
|---|---|---|
| Orders | `COUNT(DISTINCT order_id)` on Order rows with `quantity > 0` | Distinct `order_id` because codes repeat on every line (Section 1.20); Order rows only per Section 1.12 |
| Customers | `COUNT(DISTINCT customer_id)` on Order rows with `quantity > 0`, `customer_id IS NOT NULL` | Section 1.11 customer-level filters |
| Gross Sales | `SUM(item_gross_sales)` across lines | Line-level amounts — no dedup needed; no `transaction_type` filter (same as Net Sales) |
| Discounts | `SUM(item_discounts)` across lines | Line-level; no `transaction_type` filter |
| Net Sales | Net Sales formula, `LineItemMaster` version (Section 2.1) | No `transaction_type` filter — Return rows keep their order's code and reduce that code's Net Sales |
| Total Revenue | Total Revenue formula, `LineItemMaster` version (Section 2.1) | Shipping terms on Order rows only (⚠ backlog, EF-013) |
| AOV | Total Revenue ÷ Orders (distinct) | Denominator is the distinct order count above, never a line count |
| Discount Rate | Discounts ÷ Total Revenue | Same definition as Section 2.1 |

- **Formatting / rounding:** as Section 1.14 — Orders and Customers as counts; Gross Sales, Discounts, Net Sales, Total Revenue, AOV in USD with 0 decimals; Discount Rate as `%` with 2 decimals.
- **Multi-code caveat:** per-code rows do not add up to the overall total — always state this in the response (Section 1.20). For an overall total, compute the same metrics from the unsplit join.
- **`'No Discount Code'`** is shown as its own row by default (Section 1.20).

**SQL (final `SELECT` over `lim_codes`, Section 1.20):**
```sql
SELECT
  discount_code,
  COUNT(DISTINCT CASE WHEN transaction_type = 'Order' AND COALESCE(quantity, 0) > 0
                      THEN order_id END) AS orders,
  COUNT(DISTINCT CASE WHEN transaction_type = 'Order' AND COALESCE(quantity, 0) > 0
                       AND customer_id IS NOT NULL
                      THEN customer_id END) AS customers,
  ROUND(SUM(COALESCE(item_gross_sales, 0)), 0) AS total_gross_sales,
  ROUND(SUM(COALESCE(item_discounts, 0)), 0) AS total_discounts,
  ROUND(
    SUM(COALESCE(item_gross_sales, 0))
    - SUM(COALESCE(item_discounts, 0))
    - SUM(COALESCE(item_returns, 0))
  , 0) AS net_sales,
  ROUND(
    SUM(COALESCE(item_gross_sales, 0))
    - SUM(COALESCE(item_discounts, 0))
    - SUM(COALESCE(item_returns, 0))
    + SUM(CASE WHEN transaction_type = 'Order' THEN COALESCE(item_shipping_price, 0) ELSE 0 END)
    - SUM(CASE WHEN transaction_type = 'Order' THEN COALESCE(item_shipping_tax, 0) ELSE 0 END)
  , 0) AS total_revenue,
  ROUND(SAFE_DIVIDE(
    SUM(COALESCE(item_gross_sales, 0))
    - SUM(COALESCE(item_discounts, 0))
    - SUM(COALESCE(item_returns, 0))
    + SUM(CASE WHEN transaction_type = 'Order' THEN COALESCE(item_shipping_price, 0) ELSE 0 END)
    - SUM(CASE WHEN transaction_type = 'Order' THEN COALESCE(item_shipping_tax, 0) ELSE 0 END),
    COUNT(DISTINCT CASE WHEN transaction_type = 'Order' AND COALESCE(quantity, 0) > 0
                        THEN order_id END)
  ), 0) AS aov,
  ROUND(SAFE_DIVIDE(
    SUM(COALESCE(item_discounts, 0)),
    SUM(COALESCE(item_gross_sales, 0))
    - SUM(COALESCE(item_discounts, 0))
    - SUM(COALESCE(item_returns, 0))
    + SUM(CASE WHEN transaction_type = 'Order' THEN COALESCE(item_shipping_price, 0) ELSE 0 END)
    - SUM(CASE WHEN transaction_type = 'Order' THEN COALESCE(item_shipping_tax, 0) ELSE 0 END)
  ) * 100, 2) AS discount_rate_pct
FROM lim_codes
GROUP BY discount_code
ORDER BY orders DESC
```

The `quantity > 0` and `customer_id IS NOT NULL` conditions sit inside the `CASE` expressions rather than in a `WHERE` clause: a `WHERE` would drop Return rows (negative `quantity`) and break Net Sales, Total Revenue, and Discount Rate in the same query.

---

## 3. Table Selection & Conflict Resolution

### 3.1 Table Overview

| BQ Table | Full Path | Granularity | Primary Metrics |
|---|---|---|---|
| `simplified_customer_cohorts_v2` | `insightsprod.equipfoods_5642_prod_presentation.simplified_customer_cohorts_v2` | `acq_month × order_month × acq_channel × acq_type × purchasing_pattern × entry_sku_* × subscriber_status × month_diff × _run_id` | Repurchase Rate, Net Sales, Net Shipping Charges, Total Revenue, LTR, LTV, AOV, OPC, UPO, CAC, LTV/CAC, Revenue Retention, Discount Rate. Also valid for business-level (transactional) questions when filtered/grouped by `order_month` instead of `acq_month`/`month_diff` — see Section 1.17. |
| `simplified_churn_customers` | `insightsprod.equipfoods_5642_prod_presentation.simplified_churn_customers` | `acq_month × month_diff × acq_channel × acq_type × purchasing_pattern` | Churn Rate, Cumulative Churn Rate, Retention Rate. No `order_month` column — cohort-level only. |
| `simplified_order_cohorts_v2` | `insightsprod.equipfoods_5642_prod_presentation.simplified_order_cohorts_v2` | `acq_month × order_month × order_number × acq_type × purchasing_pattern × acq_channel` | Same metric suite as Monthly Cohorts, indexed by order number. Cohort-level (order-sequence) only — never use for business-level questions, see Section 5.4 EF-015. |
| `LineItemMaster` | `insightsprod.equipfoods_5642_prod_presentation.LineItemMaster` | One row per order line item per customer | Lifecycle, SKU Mix, Purchase Funnel, OTP→Subscriber, Gross Margin, Return Rate, SKU Repurchase Rate |
| `SubscriptionMaster` | `insightsprod.equipfoods_5642_prod_presentation.SubscriptionMaster` | One row per subscription contract | Subscriber Churn, Cancellation Rates (customer / subscription / line) |
| `SubscriberCohort` | `insightsprod.equipfoods_5642_prod_presentation.SubscriberCohort` | `acq_month × subscriber dimensions × month_diff` | Skip Rate, Subscription Revenue Retained, Reactivation Rate |
| `AdvertisingMaster` | `insightsprod.equipfoods_5642_prod_presentation.AdvertisingMaster` | One row per ad per campaign per day (daily ad performance, ~499K rows) — far finer than needed; always aggregate to `ad_month × ad_channel` via `DATE_TRUNC(ad_date, MONTH)` first | Marketing Channel Ad Spend, Marketing Channel CAC, Marketing Channel LTV/CAC (Section 2.8), using only `ad_date`/`ad_channel`/`spend`. Never used for any other metric in this file — see the dedicated `AdvertisingMaster_table_yaml.yaml` for its full real schema (58 columns; a physical BigQuery table, time-partitioned by `ad_date`). |
| `dim_orders` | `insightsprod.equipfoods_5642_prod_main.dim_orders` — ⚠ `_prod_main` dataset, not `_prod_presentation` | One row per `order_id` (verified 1:1 despite SCD Type 2 columns) | **Discount code analysis only** (Sections 1.20, 2.9), always as `LineItemMaster` LEFT JOIN `dim_orders` on `order_id`. ⚠ **CRITICAL (`R-PII-DIMORDERS-01`):** never `SELECT *`, never `note` / `comments` / `tags`. See the dedicated `dim_orders.yaml` for its full schema. |

**Never query:**

| Table / Column | Reason |
|---|---|
| `customer_360` | PII — never reference |
| `shopify_conversion_path` | PII — never reference |
| `dim_orders.note`, `dim_orders.comments`, `dim_orders.tags` | ⚠ **CRITICAL — PII in free text** (`R-PII-DIMORDERS-01`, Section 1.20). Columns only — the rest of `dim_orders` is queryable for discount code analysis. Never `SELECT *` from `dim_orders`, since it would include these. |
| `dim_customer`, `dim_address` (via `dim_orders` keys) | Never join `dim_orders` onward through `customer_key`, `ship_address_key`, or `bill_address_key` (`R-PII-DIMORDERS-01`) |

---

### 3.2 Table Selection Decision Tree

```
User question about...
|
+-- Cohort-level ask: month-based (Section 1.18, R-COHORT-ANCHOR-01, default anchor)?
|   Repurchase Rate, LTR, LTV, CAC, AOV, OPC, Revenue Retention, Discount Rate, by month_diff?
|   YES --> simplified_customer_cohorts_v2 (with Monthly Cohorts CTE, Section 3.6, for running metrics)
|
+-- Churn Rate, Cumulative Churn, Retention Rate?
|   YES --> simplified_churn_customers
|
+-- Cohort-level ask: order-sequence anchor (Section 1.18) — "2nd/3rd/Nth order"?
|   YES, and it's an aggregate (count, rate, revenue total) --> simplified_order_cohorts_v2
|        (with Order Cohorts CTE, Section 3.7, for running metrics)
|   YES, but it's a per-order detail/dimension (SKU, channel, this order's own attributes)
|        --> LineItemMaster WHERE order_number = N (simplified_order_cohorts_v2 has no
|            per-order SKU/channel column, only entry_sku* frozen at acquisition)
|
+-- Business-level (transactional): "how did the business perform in [period]"
|   regardless of acquisition date (Section 1.17)?
|   YES, and slicing by an acquisition-level dimension (acq_channel, entry SKU, etc.)
|        --> simplified_customer_cohorts_v2, filter/group by order_month (not acq_month/month_diff)
|   YES, and slicing by an order-level/contemporaneous dimension (channel, SKU, revenue_bucket, order_type)
|        --> LineItemMaster, filter by date
|   (Never simplified_order_cohorts_v2 for this — see Section 5.4 EF-015)
|
+-- Discount codes — by code, promo/coupon code, a named code (Section 1.20)?
|   YES --> LineItemMaster LEFT JOIN dim_orders ON order_id, codes split (Sections 1.20, 2.9)
|           ⚠ CRITICAL: never SELECT * / note / comments / tags from dim_orders (R-PII-DIMORDERS-01)
|   (Plain "discounts" / "discount rate" with no code mention --> existing metrics, no dim_orders)
|
+-- Lifecycle, purchase funnel, days between orders, OTP→Subscriber conversion,
|   SKU mix, Gross Margin, Return Rate (by order date), SKU Repurchase Rate?
|   YES --> LineItemMaster
|
+-- Subscriber churn, cancellation rate at customer / subscription / line level?
|   YES --> SubscriptionMaster
|
+-- Skip Rate, Subscription Revenue Retained, Reactivation Rate?
    YES --> SubscriberCohort
```

---

### 3.3 "Do NOT Use" Rules

| Table | Do NOT Use When... |
|---|---|
| `simplified_customer_cohorts_v2` | User asks for Churn Rate or Retention Rate → use `simplified_churn_customers` |
| `simplified_customer_cohorts_v2` | User asks for order-number cohort → use `simplified_order_cohorts_v2` |
| `simplified_churn_customers` | User asks for Repurchase Rate, LTR, or any revenue metric → use `simplified_customer_cohorts_v2` |
| `simplified_churn_customers` | Never use `customer_count` as the fixed denominator — use `total_customers_acquired` |
| `simplified_order_cohorts_v2` | Any business-level (transactional) question → apply Section 1.17 / `R-TABLE-01` (EF-015) |
| `simplified_order_cohorts_v2` | Per-order SKU/channel/dimensional detail question (not an aggregate) → apply Section 1.18 / `R-COHORT-ANCHOR-01` (use `LineItemMaster WHERE order_number = N` instead — no per-order SKU/channel column here, only `entry_sku*` frozen at acquisition) |
| `simplified_customer_cohorts_v2` | Business-level question needing an order-level/contemporaneous dimension → apply Section 1.17 / `R-TABLE-01` (use `LineItemMaster` instead) |
| `LineItemMaster` (Net Sales) | Never apply `WHERE transaction_type = 'Order'` — include both row types |
| `LineItemMaster` (Order/Customer counts) | Must apply `WHERE transaction_type = 'Order'` |
| `SubscriberCohort` | Customer-level subscriber churn → use `SubscriptionMaster` |
| `SubscriptionMaster` | Skip Rate or Subscription Revenue Retained → use `SubscriberCohort` |
| `dim_orders` | ⚠ **CRITICAL:** Never `SELECT *` and never reference `note`, `comments`, or `tags` — in any query, for any purpose (`R-PII-DIMORDERS-01`, Section 1.20) |
| `dim_orders` | Anything other than discount code analysis — it is not a general source of order attributes |
| `dim_orders` | As the driving (`FROM`) table for metrics → always `LineItemMaster` LEFT JOIN `dim_orders` |
| `dim_orders` | Joining onward to `dim_customer` / `dim_address` → never (`R-PII-DIMORDERS-01`) |
| `dim_orders` | Plain "discounts" / "discount rate" with no mention of codes → use the existing Discounts / Discount Rate metrics, no join |

---

### 3.4 Join Keys

#### `simplified_customer_cohorts_v2` ↔ `simplified_churn_customers`

```sql
ON  a.acq_month          = b.acq_month
AND a.month_diff         = b.month_diff
AND a.acq_channel        = b.acq_channel
AND a.acq_type           = b.acq_type
AND a.purchasing_pattern = b.purchasing_pattern
```

#### `simplified_customer_cohorts_v2` ↔ `simplified_order_cohorts_v2`

Different period keys (`month_diff` vs `order_number`) — join at `acq_month` level only:

```sql
ON  a.acq_month   = b.acq_month
AND a.acq_channel = b.acq_channel
AND a.acq_type    = b.acq_type
-- Do not join on month_diff / order_number
```

#### Cohort Tables ↔ `LineItemMaster`

**Join key:** `customer_acq_date` (LineItemMaster) = cohort acquisition month derived from `acq_month` (cohort tables).

No direct `acq_month` exists in LineItemMaster — derive it from `customer_acq_date`:

```sql
ON  DATE_TRUNC(a.customer_acq_date, MONTH) = b.acq_month
AND a.channel                              = b.acq_channel
AND a.customer_acq_type                    = b.acq_type
AND a.customer_purchasing_pattern          = b.purchasing_pattern
```

**Caveat:** LineItemMaster uses different column names than cohort tables for the same concepts:
- `customer_acq_date` (LineItemMaster) vs `acq_month` (cohort tables)
- `channel` vs `acq_channel`
- `customer_acq_type` vs `acq_type`
- `customer_purchasing_pattern` vs `purchasing_pattern`

Never mix column names across tables — map explicitly.

#### Cohort Tables ↔ `SubscriberCohort`

**Join key:** Subscriber acquisition month (from SubscriberCohort) to cohort acquisition month.

SubscriberCohort uses `acq_month` and `month_diff` as primary period keys, same as cohort tables. Join on `acq_month` for a given cohort, then optionally filter by `month_diff` for a specific period:

```sql
ON  a.acq_month         = b.acq_month
AND a.subscriber_status = 'Subscriber'  -- Only subscribers in acq cohort
-- Optional: AND b.month_diff = N  (for a specific period snapshot)
```

**Note:** `SubscriberCohort` contains only subscribers (by definition). When joining to customer cohort tables, filter the customer cohort to `subscriber_status = 'Subscriber'` to ensure you're comparing equivalent populations.

#### `LineItemMaster` ↔ `SubscriptionMaster`

**Join key:** `customer_id`

```sql
ON a.customer_id = b.customer_id
```

**No date join needed** unless filtering to a specific subscription start date window — use `subscription_start_date` or `MIN(subscription_start_date)` per customer depending on grain.

#### `LineItemMaster` ↔ `dim_orders`

**Join key:** `order_id`. Discount code analysis only (Section 1.20).

```sql
-- ⚠ CRITICAL (R-PII-DIMORDERS-01): only structured/key columns from dim_orders — never *, note, comments, tags.
select
  lim.*,
  do.discount_codes
from `insightsprod.equipfoods_5642_prod_presentation.LineItemMaster` lim
left join `insightsprod.equipfoods_5642_prod_main.dim_orders` do
  on lim.order_id = do.order_id
```

- `LineItemMaster` is always the left (driving) table.
- `LineItemMaster` is line-level, so `discount_codes` repeats on every line of an order — use `COUNT(DISTINCT order_id)` for order counts (Section 1.20).
- `dim_orders` lives in `_prod_main`, not `_prod_presentation` — always use its full path.

---


### 3.5 Table Schemas

#### `simplified_customer_cohorts_v2`

| Column | Description | Aggregation / Notes |
|---|---|---|
| `_run_id` | Pipeline run ID | Include in all PARTITION BY clauses |
| `acq_month` | Acquisition month (DATE, first of month) | Primary cohort key |
| `month_diff` | Months since acquisition (0 = acquisition month) | Period key |
| `order_month` | Calendar month this row's activity actually occurred | Business-level (transactional) key — filter/group by this instead of `acq_month`/`month_diff` for "how did the business perform in [period]" questions; see Section 1.17 |
| `acq_channel` | Acquisition channel | `'Shopify'`, `'Amazon Seller Central'` |
| `acq_type` | Acquisition type | `'One-Time Purchase'`, `'Subscription'` |
| `purchasing_pattern` | Lifetime order pattern | `'One-Time Purchaser'`, `'Repeat Purchaser'` |
| `subscriber_status` | Subscription status | Filter dimension |
| `marketing_channel`, `last_click_channel`, `idda_channel`, `clicks_only_northbeam_channel` | Attribution channels | Filter dimensions |
| `unified_marketing_channel` | Unified attribution channel (Superfiliate → IDDA/Northbeam priority, mapped to a single channel) | Used by Section 2.8. Always apply the cleaning CASE in Section 2.8 before use |
| `channel_grouping_1_source`, `channel_grouping_2_channel` | Rollups of `unified_marketing_channel` — source/platform, then broad channel type | Used by Section 2.8. Mapping logic (Unified Marketing Channel → grouping values) not yet documented in this file, `⚠ Needs validation` |
| `entry_sku`, `entry_sku_category`, `entry_sku_sub_category`, `entry_sku_product_name` | Entry product dimensions | Filter / group by |
| `customer_count` | Customers active in this `month_diff` | SUM |
| `order_count` | Orders placed in this `month_diff` | SUM |
| `item_quantity` | Units ordered in this `month_diff` | SUM |
| `item_gross_sales` | Gross revenue in this `month_diff` | SUM |
| `item_discount_total` | Discounts in this `month_diff` | SUM |
| `item_returns_total` | Returns in this `month_diff` (attributed to refund date) | SUM |
| `shipping_price_total` | Total shipping charges in this `month_diff` | SUM — used in Net Shipping Charges, Total Revenue |
| `shipping_tax_total` | Total shipping tax in this `month_diff` | SUM — used in Net Shipping Charges, Total Revenue |
| `revenue_bucket_at_acquisition` | Customer's bucket at their first order — fixed, see Section 1.16 | Filter / group by; `NULL` for Amazon and Global-Filters-excluded orders |
| `adspend` | Ad spend — non-zero only at `month_diff = 0` | SUM at `month_diff = 0` only |
| `cogs` | Cost of goods | Used for LTV (Section 2.4) — Total Revenue minus this column, cumulative. Fixed Gross Margin % per channel is a fallback only when this is NULL (rare, 0% null observed) |

#### `simplified_churn_customers`

| Column | Description | Aggregation / Notes |
|---|---|---|
| `acq_month` | Acquisition month | Cohort key |
| `month_diff` | Months since acquisition | Period key |
| `customer_count` | Customers who **churned** in this `month_diff` | SUM — numerator for Churn Rate |
| `total_customers_acquired` | Total customers acquired in `acq_month` | Fixed denominator — this is NOT the same as `customer_count` |
| `acq_channel`, `acq_type`, `purchasing_pattern` | Cohort dimensions | Filter / group by |
| `marketing_channel`, `last_click_channel`, `idda_channel`, `clicks_only_northbeam_channel` | Attribution dimensions | Filter dimensions. Note: this table has no `subscriber_status` column, unlike `simplified_customer_cohorts_v2` — corrected doc error |
| `unified_marketing_channel`, `channel_grouping_1_source`, `channel_grouping_2_channel` | Unified attribution channel and its two rollups — see Section 2.8 | Same definitions as `simplified_customer_cohorts_v2` |
| `revenue_bucket_at_acquisition` | Customer's bucket at their first order — fixed, see Section 1.16 | Filter / group by; `NULL` for Amazon and Global-Filters-excluded orders |

#### `simplified_order_cohorts_v2`

| Column | Description | Aggregation / Notes |
|---|---|---|
| `acq_month` | Acquisition month | Cohort key |
| `order_number` | Sequential order number per customer (1 = first order) | Period key — replaces `month_diff` |
| `order_month` | Calendar month the specific order number was placed | ⚠ Do NOT use for business-level (transactional) questions — Returns figure is ~21% low when grouped by `order_month` alone. See Section 5.4, EF-015. |
| `acq_type`, `acq_channel`, `purchasing_pattern` | Cohort dimensions | Filter / group by |
| `customer_count` | Customers at this `order_number` | SUM |
| `order_count` | Orders at this `order_number` | SUM |
| `item_quantity`, `item_gross_sales`, `item_discount_total`, `item_returns_total` | Same as Monthly Cohorts | SUM |
| `shipping_price_total`, `shipping_tax_total` | Same as Monthly Cohorts — used in Net Shipping Charges, Total Revenue | SUM |
| `revenue_bucket` | This order's bucket — order-level, can differ from the customer's other orders, see Section 1.16 | Filter / group by; `NULL` for Amazon and Global-Filters-excluded orders |
| `adspend` | Ad spend — non-zero at `order_number = 1` only | SUM at order_number = 1 only |
| `cogs` | Cost of goods | Used for LTV (Section 2.4) — Total Revenue minus this column, cumulative. Fixed Gross Margin % per channel is a fallback only when this is NULL (rare, 0% null observed) |
| `marketing_channel`, `last_click_channel`, `idda_channel`, `clicks_only_northbeam_channel` | Attribution dimensions | Filter dimensions |
| `unified_marketing_channel`, `channel_grouping_1_source`, `channel_grouping_2_channel` | Unified attribution channel and its two rollups — see Section 2.8 | Same definitions as `simplified_customer_cohorts_v2` |

#### `LineItemMaster`

| Column | Description | Notes |
|---|---|---|
| `date` | Transaction date — order date for Orders; refund date for Returns | Primary date filter |
| `transaction_type` | `'Order'` or `'Return'` | Apply conditional filter per Section 1.10 |
| `customer_id` | Customer identifier | Always filter `IS NOT NULL` for customer analysis |
| `order_id` | Order identifier | Count with `transaction_type = 'Order'` filter |
| `order_number` | Customer's sequential order number (1 = first order) | — |
| `order_type` | `'Subscription'` or `'Order'` | Used for OTP→Subscriber conversion date |
| `customer_acq_date` | Customer's first order date | Use for cohort derivation |
| `customer_acq_type` | Acquisition type | `'Subscription'`, `'One-Time Purchase'` |
| `customer_purchasing_pattern` | Lifetime order pattern | `'One-Time Purchaser'`, `'Repeat Purchaser'` |
| `subscriber_status` | Subscription status | `'Subscriber'` for active subscribers |
| `channel` | Sales channel | Equivalent to `acq_channel` in cohort tables |
| `marketing_channel`, `last_click_channel`, `idda_channel`, `clicks_only_northbeam_channel` | Attribution channels | — |
| `unified_marketing_channel`, `channel_grouping_1_source`, `channel_grouping_2_channel` | Unified attribution channel and its two rollups — see Section 2.8 | Same definitions as cohort tables |
| `sku`, `sku_product_name`, `sku_sub_category`, `sku_category` | SKU dimensions | — |
| `entry_sku_product_name`, `entry_sku_sub_category`, `entry_sku_category` | Entry SKU dimensions | — |
| `revenue_bucket` | This order's bucket — order-level, can differ from the customer's other orders, see Section 1.16 | Filter / group by; `NULL` for Amazon and Global-Filters-excluded orders |
| `item_gross_sales` | Gross revenue for line | SUM |
| `item_discounts` | Discounts (**no `_total` suffix** — differs from cohort tables) | SUM |
| `item_returns` | Return value (**no `_total` suffix**) | SUM |
| `item_shipping_price`, `item_shipping_tax` | Shipping charge / shipping tax on this line | SUM — used in Net Shipping Charges, Total Revenue. `item_shipping_price` is non-zero on Return rows — filter `transaction_type = 'Order'` (⚠ backlog, see Section 5.4 EF-013) |
| `quantity` | Units — negative on Return rows; always use `ABS(quantity)` | SUM with ABS |
| `cost_of_single_unit` | Unit-level COGS | Used for Gross Margin (Section 2.7) — multiply by `quantity` for line-level COGS. Fixed % per channel is a fallback only when this is NULL |
| `time_since_last_order` | Days since previous order | Used for days-between-orders bucketing |

#### `SubscriptionMaster`

| Column | Description | Notes |
|---|---|---|
| `customer_id` | Customer identifier | Join key |
| `subscription_id` | Subscription contract ID | Subscription-level grain |
| `subscription_line_id` | Subscription line ID | Line-level grain (most granular) |
| `subscription_start_date` | Subscription start date | **Always use `MIN(subscription_start_date)`** (per `customer_id`, `subscription_id`, or `subscription_line_id` depending on grain) to derive the acquisition month. Never use the raw column directly — a contract/line can have multiple start_date rows from renewals or frequency changes, and using the raw value will produce duplicate or incorrect cohort months. |
| `subscription_status` | Current subscription status | `'ACTIVE'`, `'CANCELLED'`, `'FAILED'`, `'PAUSED'`. **This is the only valid way to determine active status** — see Section 1.19 (`R-SUBACTIVE-01`) |
| `subscription_cancel_date` | Cancellation date | Only populated for `'CANCELLED'` rows — `NULL` on `'PAUSED'`/`'FAILED'` rows too, not just `'ACTIVE'` ones. **Never use `IS NULL` to infer active status** — use `subscription_status = 'ACTIVE'` instead (Section 1.19). No row uses a `'9999-12-31'` sentinel value — that check is dead code. |
| `customer_acq_type` | Original acquisition type | `'Subscription'` vs OTP |
| `sku_category` | SKU category | Dimension |
| `number_of_orders_completed` | Orders completed on this subscription | — |
| `last_click_channel`, `idda_channel`, `marketing_channel`, `clicks_only_northbeam_channel` | Attribution channels | — |
| `unified_marketing_channel`, `channel_grouping_1_source`, `channel_grouping_2_channel` | Unified attribution channel and its two rollups — see Section 2.8 | Same definitions as cohort tables |
| `revenue_per_cycle` | Revenue per billing cycle | NULL on ~15% of active records — not used in any KPI |

#### `SubscriberCohort`

| Column | Description | Notes |
|---|---|---|
| `acq_month` | Subscriber acquisition month | Cohort key |
| `month_diff` | Months since subscriber acquisition | Period key |
| `subscribers_acquired` | Subscribers in acquisition month (fixed denominator) | — |
| `orders_skipped` | Orders skipped in period | Skip Rate numerator |
| `subscription_orders_placed` | Subscription orders placed in period | Skip Rate denominator component |
| `skipped_revenue` | Revenue value of skipped orders | Revenue Retained numerator |
| `realized_revenue` | Revenue value of placed orders | Revenue Retained denominator component |
| `subscribers_reactivated` | Reactivated subscribers in period | Reactivation Rate numerator |
| `last_click_channel`, `idda_channel`, `marketing_channel`, `clicks_only_northbeam_channel` | Attribution channels | — |
| `unified_marketing_channel`, `channel_grouping_1_source`, `channel_grouping_2_channel` | Unified attribution channel and its two rollups — see Section 2.8 | Same definitions as cohort tables |

#### `AdvertisingMaster`

| Column | Description | Notes |
|---|---|---|
| `ad_date` | Date the spend was recorded | Truncate to month (`ad_month`) before use — see Section 2.8 |
| `ad_channel` | Raw ad platform | `'GOOGLE'`, `'FACEBOOK'`, `'TIKTOK'`, `'AMAZON'`, or other — map to Unified Marketing Channel per Section 2.8 before joining to cohort data; never use `ad_channel` directly against cohort-side channel columns |
| `spend` | Ad spend | SUM, aggregated to `ad_month × unified_marketing_channel` before joining — see Section 2.8 |
| `sku`, `category`, `sub_category`, `product_name` | Product dimensions on the ad | Not used by any metric in this file — Section 2.8 only uses `ad_date`/`ad_channel`/`spend` |

#### `dim_orders`

Full path `insightsprod.equipfoods_5642_prod_main.dim_orders` (`_prod_main` dataset). Discount code analysis only — Section 1.20.

> ⚠ **CRITICAL (`R-PII-DIMORDERS-01`):** never `SELECT *`; never reference `note`, `comments`, or `tags`; never join onward to `dim_customer` / `dim_address`.

| Column | Description | Notes |
|---|---|---|
| `order_id` | Order identifier | ✅ Join key to `LineItemMaster.order_id` |
| `discount_codes` | All discount codes on the order, in one string | ✅ Default column — split into individual codes (Section 1.20) |
| `order_key`, `platform_name`, `type`, `order_date`, `order_datetime`, `order_name`, `order_channel` | Order attributes | ✅ Allowed only when a discount-code question needs them |
| `payment_mode`, `payment_gateway`, `digital_wallet`, `credit_card_type` | Payment attributes (`payment_gateway`, `digital_wallet`, `credit_card_type` are Shopify-only) | ✅ Allowed only when a discount-code question needs them |
| `product_basket`, `category_basket` | Products / categories in the order | ✅ Allowed only when a discount-code question needs them |
| `rating`, `feedback_type` | Customer rating (1–5) and its category | ✅ Allowed only when a discount-code question needs them |
| `customer_key`, `ship_address_key`, `bill_address_key` | Surrogate keys to `dim_customer` / `dim_address` | ✅ May be selected — ⛔ never joined onward |
| `effective_start_date`, `effective_end_date`, `last_updated`, `_run_id` | SCD Type 2 / pipeline tracking | ✅ Allowed; not needed for the discount join (grain is 1:1) |
| `note` | Free-text order note | ⛔ **Never reference** — confirmed PII (names, personal/business emails) |
| `comments` | Free-text customer feedback | ⛔ **Never reference** — confirmed PII (full name + city/state) |
| `tags` | Free-text order tags | ⛔ **Never reference** — same free-text category, unaudited |

---

### 3.6 Monthly Cohorts CTE

IQ must prepend this CTE when computing LTR, LTRPC, LTV, LTVPC, or LTV/CAC. These columns do not exist in the raw `simplified_customer_cohorts_v2` BQ table — they are derived. `running_total_revenue` (Total Revenue basis) feeds LTR, LTRPC, LTV, LTVPC, and LTV/CAC. `running_net_sales` is retained only for standalone Net Sales lifetime queries — it no longer feeds LTR/LTV. OPC is a running metric too, but its own SQL (Section 2.5) is self-contained and does not use this CTE — it computes its running window directly.

```sql
WITH monthly_cohorts AS (
  SELECT
    *,
    -- Customers Acquired (fixed at month_diff = 0)
    SUM(CASE WHEN month_diff = 0 THEN COALESCE(customer_count, 0) ELSE 0 END)
      OVER (PARTITION BY _run_id, acq_month, acq_channel, acq_type, purchasing_pattern,
                         entry_sku, entry_sku_category, entry_sku_sub_category,
                         entry_sku_product_name, subscriber_status)
      AS customers_acquired,
    -- Total Ad Spend (fixed at month_diff = 0)
    SUM(CASE WHEN month_diff = 0 THEN COALESCE(adspend, 0) ELSE 0 END)
      OVER (PARTITION BY _run_id, acq_month, acq_channel, acq_type, purchasing_pattern,
                         entry_sku, entry_sku_category, entry_sku_sub_category,
                         entry_sku_product_name, subscriber_status)
      AS total_ad_spend,
    -- Running Net Sales — retained for standalone Net Sales lifetime queries only.
    -- Not used by LTR/LTV/LTRPC/LTVPC/LTV-CAC below — those now run on running_total_revenue.
    SUM(COALESCE(item_gross_sales, 0) - COALESCE(item_discount_total, 0) - COALESCE(item_returns_total, 0))
      OVER (PARTITION BY _run_id, acq_month, acq_channel, acq_type, purchasing_pattern,
                         entry_sku, entry_sku_category, entry_sku_sub_category,
                         entry_sku_product_name, subscriber_status
            ORDER BY month_diff
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
      AS running_net_sales,
    -- Running Total Revenue (LTR) — Net Sales + Net Shipping Charges, cumulative
    SUM(
      COALESCE(item_gross_sales, 0) - COALESCE(item_discount_total, 0) - COALESCE(item_returns_total, 0)
      + COALESCE(shipping_price_total, 0) - COALESCE(shipping_tax_total, 0)
    )
      OVER (PARTITION BY _run_id, acq_month, acq_channel, acq_type, purchasing_pattern,
                         entry_sku, entry_sku_category, entry_sku_sub_category,
                         entry_sku_product_name, subscriber_status
            ORDER BY month_diff
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
      AS running_total_revenue,
    -- Running LTV (Total Revenue minus actual COGS, cumulative; fixed Gross Margin % per channel is a fallback only when cogs IS NULL — reverted, see EF-012)
    SUM(
      (COALESCE(item_gross_sales, 0) - COALESCE(item_discount_total, 0) - COALESCE(item_returns_total, 0)
       + COALESCE(shipping_price_total, 0) - COALESCE(shipping_tax_total, 0))
      - COALESCE(
          cogs,
          (COALESCE(item_gross_sales, 0) - COALESCE(item_discount_total, 0) - COALESCE(item_returns_total, 0)
           + COALESCE(shipping_price_total, 0) - COALESCE(shipping_tax_total, 0))
          * (1 - CASE WHEN acq_channel = 'Shopify' THEN 0.55
                      WHEN acq_channel = 'Amazon Seller Central' THEN 0.495
                      ELSE NULL END)
        )
    )
      OVER (PARTITION BY _run_id, acq_month, acq_channel, acq_type, purchasing_pattern,
                         entry_sku, entry_sku_category, entry_sku_sub_category,
                         entry_sku_product_name, subscriber_status
            ORDER BY month_diff
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
      AS running_ltv
  FROM `insightsprod.equipfoods_5642_prod_presentation.simplified_customer_cohorts_v2`
)
```

---

### 3.7 Order Cohorts CTE

Order-sequence equivalent of the Monthly Cohorts CTE (Section 3.6) — same pattern, with `order_number` as the progression field instead of `month_diff`. IQ must prepend this CTE when computing any running metric (LTR, LTRPC, LTV, LTVPC, LTV/CAC) indexed by order number rather than month_diff. `⚠ Needs validation` — see Section 5.4, EF-016: the structure is mechanically mirrored from Section 3.6 and reconciles correctly on `customers_acquired`/`adspend` behavior (verified against BigQuery — `customers_acquired` at `order_number = 1` matches `simplified_customer_cohorts_v2`'s `month_diff = 0` exactly for a sample cohort, and revenue decays proportionally across `order_number` the same way it does across `month_diff`), but the running revenue/LTV totals this CTE produces have not been independently reconciled against a dashboard or other source of truth the way Section 3.6's have — treat as structurally sound but not yet stakeholder-confirmed.

```sql
WITH order_cohorts AS (
  SELECT
    *,
    -- Customers Acquired (fixed at order_number = 1)
    SUM(CASE WHEN order_number = 1 THEN COALESCE(customer_count, 0) ELSE 0 END)
      OVER (PARTITION BY _run_id, acq_month, acq_channel, acq_type, purchasing_pattern,
                         entry_sku, entry_sku_category, entry_sku_sub_category,
                         entry_sku_product_name, subscriber_status)
      AS customers_acquired,
    -- Total Ad Spend (fixed at order_number = 1)
    SUM(CASE WHEN order_number = 1 THEN COALESCE(adspend, 0) ELSE 0 END)
      OVER (PARTITION BY _run_id, acq_month, acq_channel, acq_type, purchasing_pattern,
                         entry_sku, entry_sku_category, entry_sku_sub_category,
                         entry_sku_product_name, subscriber_status)
      AS total_ad_spend,
    -- Revenue Acquired, order-based (fixed at order_number = 1) — denominator for order-based Revenue Retention
    SUM(CASE WHEN order_number = 1
      THEN COALESCE(item_gross_sales, 0) - COALESCE(item_discount_total, 0) - COALESCE(item_returns_total, 0)
           + COALESCE(shipping_price_total, 0) - COALESCE(shipping_tax_total, 0)
      ELSE 0 END)
      OVER (PARTITION BY _run_id, acq_month, acq_channel, acq_type, purchasing_pattern,
                         entry_sku, entry_sku_category, entry_sku_sub_category,
                         entry_sku_product_name, subscriber_status)
      AS revenue_acquired_by_order,
    -- Running Total Revenue by order sequence (order-based LTR) — Net Sales + Net Shipping Charges, cumulative through order_number
    SUM(
      COALESCE(item_gross_sales, 0) - COALESCE(item_discount_total, 0) - COALESCE(item_returns_total, 0)
      + COALESCE(shipping_price_total, 0) - COALESCE(shipping_tax_total, 0)
    )
      OVER (PARTITION BY _run_id, acq_month, acq_channel, acq_type, purchasing_pattern,
                         entry_sku, entry_sku_category, entry_sku_sub_category,
                         entry_sku_product_name, subscriber_status
            ORDER BY order_number
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
      AS running_total_revenue_by_order,
    -- Running LTV by order sequence (Total Revenue minus actual COGS, cumulative through order_number; fixed Gross Margin % per channel is a fallback only when cogs IS NULL — reverted, see EF-012)
    SUM(
      (COALESCE(item_gross_sales, 0) - COALESCE(item_discount_total, 0) - COALESCE(item_returns_total, 0)
       + COALESCE(shipping_price_total, 0) - COALESCE(shipping_tax_total, 0))
      - COALESCE(
          cogs,
          (COALESCE(item_gross_sales, 0) - COALESCE(item_discount_total, 0) - COALESCE(item_returns_total, 0)
           + COALESCE(shipping_price_total, 0) - COALESCE(shipping_tax_total, 0))
          * (1 - CASE WHEN acq_channel = 'Shopify' THEN 0.55
                      WHEN acq_channel = 'Amazon Seller Central' THEN 0.495
                      ELSE NULL END)
        )
    )
      OVER (PARTITION BY _run_id, acq_month, acq_channel, acq_type, purchasing_pattern,
                         entry_sku, entry_sku_category, entry_sku_sub_category,
                         entry_sku_product_name, subscriber_status
            ORDER BY order_number
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
      AS running_ltv_by_order
  FROM `insightsprod.equipfoods_5642_prod_presentation.simplified_order_cohorts_v2`
)
```

---

## 4. Domains & Sub-Domains

### 4.1 Cohort Analytics (Monthly)

- All ratio metrics use the fixed denominator at `month_diff = 0`.
- Running metrics (LTR, LTRPC, LTV, LTVPC, LTV/CAC) require the Monthly Cohorts CTE (Section 3.6) — never attempt window functions on a raw aggregation. OPC is also a running metric but its SQL is self-contained and does not use this CTE.
- No automatic default period — apply `R-DATE-01` (Section 1.1): ask if the user hasn't specified a time period.
- When a user asks for a cohort metric "overall" without specifying dimensions, remove all dimension filters but keep `month_diff` as the row dimension.
- Default anchor for cohort-level questions per `R-COHORT-ANCHOR-01` (Section 1.18) — see Section 4.2 for the order-sequence alternative.

### 4.2 Cohort Analytics (Order-Based)

- Period key is `order_number`, not `month_diff`. Customers Acquired is fixed at `order_number = 1`. Apply `R-COHORT-ANCHOR-01` (Section 1.18) to decide when this anchor applies instead of month-based.
- Supports the same metric suite as Monthly Cohorts: Repurchase Rate, Net Sales, Net Shipping Charges, Total Revenue, LTR, LTRPC, LTV, LTVPC, AOV, OPC, CAC, LTV/CAC, Revenue Retention, Discount Rate, UPO. Running metrics (LTR, LTRPC, LTV, LTVPC, LTV/CAC) require the Order Cohorts CTE (Section 3.7) — `⚠ Needs validation`, see that section.
- Use when the user asks how customers behave on their 2nd, 3rd, or Nth order — not how they behave 2 or 3 months after acquisition. For per-order SKU/channel *detail* rather than an aggregate, use `LineItemMaster WHERE order_number = N` instead (Section 1.18).

### 4.3 Churn & Retention

- The fixed denominator column in `simplified_churn_customers` is `total_customers_acquired` — not `customer_count`. This is the only table with a differently named denominator.
- **Churn definition (customer-level, evaluated per customer regardless of original acquisition type):**
  - **OTP logic** (customer has no active subscription): `NOT CHURNED` if their last OTP purchase was within the last 30 days; `CHURNED` otherwise.
  - **Subscriber logic**: `NOT CHURNED` if the customer has at least one active subscription; else `NOT CHURNED` if their last OTP purchase was within the last 30 days; else `CHURNED`.
  - **Churn Date** = the earlier of (a) the date all of the customer's active subscriptions were cancelled, or (b) their last OTP order date + 30 days.
  - `customer_count` / `churn_month` in `simplified_churn_customers` reflect this pre-computed churn date, rolled up to the calendar month. IQ never recomputes churn from raw order/subscription data — it consumes `customer_count` and `total_customers_acquired` as-is.

### 4.4 Subscription Analytics

Three levels of analysis from `SubscriptionMaster`:

| Level | Grain | Key Metric |
|---|---|---|
| Customer | `customer_id` | Subscriber Churn Rate, Subscriber Retention Rate |
| Subscription contract | `subscription_id` | Subscription Cancellation Rate |
| Subscription line | `subscription_line_id` | Subscription Line Cancellation Rate |

Skip Rate and Subscription Revenue Retained come from `SubscriberCohort`, not `SubscriptionMaster`.

### 4.5 Lifecycle & SKU Analytics

- SKU Mix: group `LineItemMaster` by `sku_category`, `sku_sub_category`, `sku_product_name`.
- Entry SKU analysis: group by `entry_sku_category`, `entry_sku_sub_category`, `entry_sku_product_name`.
- Days since last order: bucketed from `time_since_last_order` in 30-day intervals.
- OTP→Subscriber conversion date derived as: `MIN(CASE WHEN order_type = 'Subscription' THEN date END)` per `customer_id`.

---

## 5. Client Expectations & Contextual Knowledge

### 5.1 Standard Period Terminology

| Term | Meaning |
|---|---|
| Cohort Month | `acq_month` — calendar month of first purchase |
| month_diff | Months elapsed since acquisition (0 = acquisition month) |
| order_number | Sequential order count per customer (1 = first, 2 = second, etc.) |
| MTD | Month-to-date: from 1st of current month to yesterday |
| YTD | Year-to-date: from Jan 1 to yesterday |
| Last 12M | Last 12 completed acquisition months |
| LTR / LTRPC | Lifetime Revenue / LTR Per Customer |
| LTV / LTVPC | Lifetime Value / LTV Per Customer |
| CAC | Customer Acquisition Cost |
| OPC | Orders Per Customer (cumulative, running) |
| UPO | Units Per Order |

### 5.2 Response Format Rules

**Always lead with a plain-language summary before any data table.** 2–3 sentences maximum. State what the data shows, what is notable, and the direction key metrics are moving. Never return a table without a summary.
> Example: *"Equip Foods' July 2025 Shopify cohort has a 6-month repurchase rate of 38.50%, above the trailing 12-month average of 34.20%. LTR per customer at month 6 is $142, up from $128 for the June cohort. CAC for this cohort was $52."*

**Never surface raw column names in output.** Always use the display name from Section 1.2. Example: `item_gross_sales` → Gross Sales, `customer_count` → Customers, `acq_month` → Cohort Month.

**Never surface internal table names in output.** Table selection (Section 3, `R-TABLE-01`) is internal reasoning only — do not include lines like "Table used: `simplified_customer_cohorts_v2`" or otherwise name a BigQuery table in a user-facing response. State assumptions about scope/period/level as required by other rules, but never the table that produced them.

**Custom date or period math:** If the user describes a period in relative terms not covered by the standard patterns in Section 1.5 (e.g. "the last 3 cohorts", "cohorts from last summer"), translate to explicit dates, state the translation, and confirm before generating SQL.
> Example: *"I've interpreted 'last 3 cohorts' as the acquisition months Apr 2026, May 2026, and Jun 2026. Is that correct?"*

**COGS Disclosure Rule `[R-COGS-DISCLOSURE-01]`** — mandatory whenever a response includes LTV, LTVPC, Gross Margin, LTV/CAC, or the Marketing Channel LTV/CAC family (Sections 2.4, 2.7, 2.8): explicitly state that the figures use actual COGS (not an assumed margin), and close the response by offering the fixed-%-approximation alternative. Do this every time, not only on the first mention in a conversation.
> Example: *"These LTV figures use actual COGS. If you'd rather see them using the 55% (Amazon: 49.5%) approximation instead, just let me know."*

### 5.3 Dashboard Reference

| Dashboard | Primary BQ Tables |
|---|---|
| Summary | `simplified_customer_cohorts_v2` (Monthly Cohorts CTE) |
| Month Cohort View | `simplified_customer_cohorts_v2`, `simplified_churn_customers`; `AdvertisingMaster` additionally backs the `17.Channel CAC, LTV` worksheet only (Section 2.8) |
| Order Cohort View | `simplified_order_cohorts_v2` |
| Subscription | `SubscriptionMaster`, `SubscriberCohort` |
| Lifecycle | `LineItemMaster` |
| SKU Mix | `LineItemMaster` |
| Repurchase Rate View | `LineItemMaster` (SKU Repurchase Rate CTE, Return Rate query) |

### 5.4 Data Limitations

| ID | Description |
|---|---|
| EF-010 | `running_net_sales`, `running_total_revenue`, and `running_ltv` are not raw columns in `simplified_customer_cohorts_v2`. IQ must always prepend the Monthly Cohorts CTE (Section 3.6) before computing LTR, LTRPC, LTV, LTVPC, or LTV/CAC (OPC's SQL is self-contained and does not need this CTE). `running_ltv` and LTR are now built on `running_total_revenue`, not `running_net_sales`. |
| EF-011 | Column naming divergence: `item_discounts` / `item_returns` in `LineItemMaster` vs `item_discount_total` / `item_returns_total` in all cohort tables. Never mix these in the same formula. |
| EF-012 | **Reinstated 2026-09.** The original concern (`cogs` unreliable if a Product Master file has not been received) no longer holds: verified against BigQuery, `cogs` is 0% `NULL` across every acquisition month from January 2024 through June 2026. Actual COGS is also materially different from the flat-55%-margin assumption — implied gross margin from real COGS ran 70–78% in a sample April 2026 cohort check (COGS at 22–30% of net sales), well above the assumed 55%/45% split, meaning the fixed-%-only formula was understating LTV, Gross Margin, and LTV/CAC. LTV and Gross Margin (Sections 2.4, 2.7, 2.8) now use actual COGS as the primary calculation again, with the fixed Gross Margin % per channel (55.0% DTC/Shopify, 49.5% Amazon; flat 55% on the Marketing Channel view, Section 2.8) retained only as a fallback for a `NULL` `cogs`/`cost_of_single_unit` row — which current data suggests will almost never fire. *Prior state, for history:* between the original retirement and this reinstatement, both metrics ran on the fixed % exclusively, with COGS unused. |
| EF-013 | ⚠ **Backlog — not fully settled, pending stakeholder review.** `LineItemMaster.item_shipping_price` is non-zero and unreduced on Return rows (verified against BigQuery: `simplified_customer_cohorts_v2.shipping_price_total` matches the LineItemMaster Order-rows-only total exactly, $5,501,243.41, excluding the ~$61.6K carried on Return rows). Net Shipping Charges and Total Revenue currently filter `LineItemMaster` shipping terms to `transaction_type = 'Order'` to avoid double-counting. This diverges from the Net Sales no-filter convention (§1.12) and should be revisited. |
| EF-015 | `simplified_order_cohorts_v2` must never be used for business-level (transactional) questions (Section 1.17) — verified via BigQuery for May 2026: grouping by `order_month` alone matches `LineItemMaster` / `simplified_customer_cohorts_v2` exactly on gross sales ($9,066,388) and discounts ($1,380,359), but Returns comes in ~21% low ($136,424 vs. the true $173,584) — Net Sales computed this way is therefore overstated by ~$37K for that month. Shipping fields (`shipping_price_total`, `shipping_tax_total`) matched exactly, so the gap is isolated to Returns attribution across `order_number`. Use `LineItemMaster` (order-level dimensions) or `simplified_customer_cohorts_v2` via `order_month` (acquisition-level dimensions) instead; `simplified_order_cohorts_v2` remains valid only for its native cohort-level, order-sequence questions. |
| EF-016 | ⚠ **Needs validation.** The Order Cohorts CTE (Section 3.7) and the order-sequence-anchored variants of Revenue Acquired, Discount Rate, Revenue Retention, CAC, LTR, LTRPC, LTV, LTVPC, LTV/CAC, and OPC are mechanically mirrored from the equivalent, stakeholder-validated `month_diff` versions, substituting `order_number` as the progression field. Verified against BigQuery: `customers_acquired` at `order_number = 1` matches `month_diff = 0` exactly for a sample cohort (17,893 = 17,893), `adspend` is confirmed non-zero only at `order_number = 1`, and revenue decays proportionally across `order_number` the same way it does across `month_diff`. Not yet verified: the resulting running-revenue/LTV totals have not been independently reconciled against a dashboard or other source of truth. Added per explicit user confirmation that `simplified_order_cohorts_v2` backs these metrics in the Order View dashboard. |
| EF-017 | ⚠ **Needs validation** (3 of the original 5 divergences remain — the 1st is resolved by EF-012's reinstatement, and the 3rd is now largely resolved by Section 2.8 also blocking TikTok, see below). Section 2.8 (Marketing Channel LTV & CAC) documents the *target* logic for IQ, confirmed directly by the client — the live Tableau worksheet (`17.Channel CAC, LTV`) still implements it differently in three ways, found by inspecting the .twb directly: ~~(1) its LTV-per-customer fields subtract actual per-line `cogs` rather than using the flat 55% Total Revenue formula in Section 2.8~~ — **resolved**: Section 2.8 now also uses actual `cogs` as primary (EF-012), so this is no longer a divergence; (2) its ad-spend blend has no date key at all (no field on either shelf ties `ad_month` to `acq_month`), so the worksheet's Ad Spend/CAC reflects Advert Master's all-time total per channel regardless of the selected acquisition period, unlike Section 2.8's explicit `ad_month = acq_month` join; ~~(3) its Ad Spend formula (`Total Ad Spend fin`) explicitly nulls any row where the attribution-mapped channel equals literal `"TikTok Shops"` — but only when Attribution Type = "Northbeam Channel" (the default); switching to "IDDA Channel" or "Last Click Channel" silently stops the exclusion, since those models spell TikTok as `"ads - tiktokgmvmax"`. Section 2.8 does not exclude TikTok at all, by client instruction~~ — **largely resolved**: Section 2.8 now also blocks TikTok ad spend (by client instruction, current as of this edit), so both sides exclude it — the remaining difference is mechanism only: the Tableau worksheet's exclusion is conditional on Attribution Type (only fires under "Northbeam Channel"), while Section 2.8's is unconditional (TikTok always maps to `'NA'`, regardless of any attribution setting, since this view has no such parameter); (4) its Channel Grouping 1/2 filters exist only on the cohort side (Advert Master has no matching columns), so they narrow which channel rows are visible but never restrict ad spend — a visual/blend limitation the client has confirmed is acceptable for the dashboard, unlike IQ (Section 2.8), which should apply the cascade; (5) the SQL embedded in the .twb for the `Advert Master` data source has no `'AMAZON'` branch in its `unified_marketing_channel` CASE (3 branches: Google/Facebook/TikTok + `ELSE 'NA'`) — the client confirmed the Amazon branch (mapping to `'Unattributed- Amazon'`) has since been added at the source, so Section 2.8 documents the 4-branch version as current. Expect IQ's answers on this metric to disagree with the live dashboard until the dashboard is rebuilt to match; that is expected, not a bug in either. |
| EF-018 | ⚠ **Needs validation.** `dim_orders.discount_codes` is documented as a `STRING_AGG` of all codes on the order, but the separator is not confirmed. The Section 1.20 query pattern splits on `,` and trims spaces, which handles both `","` and `", "`; if the real separator differs, the split must be updated. Also: the `'No Discount Code'` line includes both orders with no code and any `LineItemMaster` order with no matching `dim_orders` row — the two are not distinguished. |

### 5.5 Out-of-Scope Metrics

| Metric | Reason |
|---|---|
| CVR / ROAS / ACoS / CTR / CPC | No session or impression data in the presentation layer |
| Customer PII (email, address, phone) | `customer_360` or any other customer data is never queryable |
| Conversion path attribution | `shopify_conversion_path` is never queryable |
| Order notes, comments, tags | `dim_orders.note` / `comments` / `tags` are free text with confirmed PII — never queryable (⚠ CRITICAL, `R-PII-DIMORDERS-01`, Section 1.20) |

---

