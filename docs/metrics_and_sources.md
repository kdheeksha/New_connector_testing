# Equip Foods Cohorts Dashboard — metrics, definitions & data sources

Derived from `Cohorts_dashboard_mockup_v2_2.html` (mock data, 5 tabs). SQL lives in `sql/`.

> **Status — read first.** There was no BigQuery access while this was written. The **metric logic, grains and
> definitions below are taken from the mock's formulas and Glossary and are firm.** The **raw BigQuery tables/columns are
> ASSUMED** (Fivetran-style naming) and each is tagged *to confirm*. Every assumption is isolated in `sql/01_staging/`;
> run `sql/00_discovery/discover_sources.sql`, send back the output, and only those 7 files change.

## 1. Global rules (apply to every tab)

| Rule | Definition | Where implemented |
|---|---|---|
| Cohort | Customers whose first purchase is in the same calendar month | `int_customer_first_order.cohort_month` |
| Month since acquisition (M*h*) | Months elapsed since first purchase; M0 = acquisition month | `int_customer_month.month_since` |
| Complete months only | Only complete calendar months are used; header shows "data through t−1, cohorts complete through <last month>" | `int_params.last_complete_month`, `mart_dashboard_meta` |
| Cohort window | UI toggle: last 12 or 24 cohorts **and** 12 / 24 months of age | app param → `cohort_month > last_complete_month − N months` |
| Mature cohort | Old enough to have reached the horizon (12-month figures need cohorts ≥12 months old). Immature cells show "—" | cells absent from `mart_*_month`; `repurchased_12m` NULL |
| Net sales | Gross sales − discounts − returns, excl. tax. Refunds count in the month they occur | `int_order_lines.net_sales`, `int_customer_events` |
| COGS | SKU unit cost × qty where available, otherwise 45% of net sales (55% margin fallback) | `int_order_lines.cogs`, `int_params.fallback_margin` |
| Filters | Channel (Shopify/Amazon), Acquisition type (One-time `OTP` / Subscription `Sub`), Purchasing pattern (Repeat / One-time) | segment columns in `mart_cohort_segment_month` |
| Quick takeaways | Rule-based call-outs recomputed client-side from the same data. Thresholds (LTV/CAC floor 1.5×, ±5% band) are **placeholders pending Equip** | app logic, no SQL |

## 2. Source inventory (what must exist in BigQuery)

| # | Input | Used for | Assumed BQ source (**to confirm**) | Staging view | Key risk |
|---|---|---|---|---|---|
| S1 | Shopify orders + lines | cohorts, sales, entry product, sub vs one-time | `shopify.order`, `shopify.order_line` | `stg_orders` | Subscription flag location (selling plan vs Recharge) |
| S2 | Amazon orders + items | Amazon channel | `amazon_selling_partner.orders`, `.order_item` | `stg_orders` | **Customer identity**: Amazon rarely exposes a stable buyer id → cohorts/repeat may be impossible |
| S3 | Refunds / returns | net sales, return rate | `shopify.refund`, `.order_line_refund`; Amazon refunds | `stg_refunds` | Amazon return data source |
| S4 | Product unit cost | COGS / LTV | `finance.product_cost` | `stg_product_cost` | Where cost lives; cost history over time |
| S5 | Product hierarchy | Category → Sub-category → Product | `reference.product_hierarchy` | `stg_product_dim` | Hierarchy likely a business mapping sheet |
| S6 | Ad spend (Meta, Google, TikTok, Amazon Ads, Superfiliate) | CAC, LTV/CAC | `facebook_ads.*`, `google_ads.*`, `tiktok_ads.*`, `amazon_ads.*`, `superfiliate.payouts` | `stg_ad_spend` | Platform-native vs Northbeam/WorkMagic blended spend |
| S7 | Attribution: WorkMagic (last paid click, IDDA), Northbeam (clicks-only, CO+DV) | Marketing tab channel credit | `workmagic.order_attribution`, `northbeam.orders_attribution` | `stg_attribution` | IDDA / CO+DV may be modelled aggregates, not per-order |
| S8 | Superfiliate referrals | "Last Paid Click + Superfiliate" view | `superfiliate.referrals` | `stg_attribution` | Referral-code field on order |

## 3. Lineage

```
raw (S1–S8)
  └─ 01_staging      stg_orders · stg_refunds · stg_product_cost · stg_product_dim · stg_ad_spend · stg_attribution · ref_marketing_channel
       └─ 02_intermediate   int_params · int_order_lines · int_orders · int_customer_first_order · int_customer_events
                            · int_customer_month · int_customer_profile · int_customer_attribution · int_customer_first_year_units
            └─ 03_marts            mart_dashboard_meta · mart_cohort_segment_month · mart_ad_spend_cohort
                                   · mart_marketing_cohort · mart_marketing_cohort_month
                                   · mart_product_cohort · mart_product_cohort_month · dim_product_hierarchy
                 └─ 04_reporting   rpt_ltv_cohort · rpt_retention_cohort · fn_marketing_channel_summary() · fn_product_summary()
```
Dashboard tab → API surface: **LTV** → `rpt_ltv_cohort` · **Retention** → `rpt_retention_cohort` ·
**Marketing** → `fn_marketing_channel_summary(window)` (+ `mart_marketing_cohort_month` for the curve) ·
**Product** → `fn_product_summary(window, type)` (+ `mart_product_cohort_month` for curve / mix) · **Header** → `mart_dashboard_meta`.

## 4. Metric dictionary

### 4.1 LTV Cohorts tab  (`rpt_ltv_cohort`; filters: channel, acquisition type)
| Metric | Definition | Formula | Column | Sources |
|---|---|---|---|---|
| Customers acquired | Unique customers whose first order is in the cohort month; denominator of every per-customer figure | count of customers by cohort | `customers_acquired` | S1, S2 |
| Lifetime Revenue (LTR) | Cumulative net sales from acquisition through month *h* | Σ net_sales, M0..Mh | `ltr` | S1–S3 |
| LTR per customer | LTR ÷ customers acquired | `ltr / customers_acquired` | `ltr_per_customer` | S1–S3 |
| Lifetime Value (LTV) | Cumulative net sales − COGS (SKU cost, else 55% margin) | Σ(net_sales − cogs) | `ltv` | S1–S4 |
| LTV per customer | LTV ÷ customers acquired | `ltv / customers_acquired` | `ltv_per_customer` | S1–S4 |
| % of M0 | Cell as a multiple of the same cohort's month 0 | `value_h / value_0` | `*_pct_of_m0` | derived |
| CAC | Cohort-month ad spend ÷ customers acquired that month; allocated to segments by customer share (same CAC for every type). Amazon spend exists only from Nov 2025 | `ad_spend / customers_acquired` | `cac` | S6, S1/S2 |
| LTV / CAC | LTV per customer ÷ CAC; >1 = acquisition cost paid back | `ltv_per_customer / cac` | `ltv_cac` | S1–S6 |
| LTR/customer curve | LTR per customer for the last six cohorts by month | — | `ltr_per_customer` | S1–S3 |

### 4.2 Retention tab  (`rpt_retention_cohort`; filters: channel, type, purchasing pattern)
| Metric | Definition | Formula | Column | Sources |
|---|---|---|---|---|
| Repurchase rate | Share of cohort that ordered **in** that month (M0 ≈ 100%) | `customers_active / customers_acquired` | `repurchase_rate` | S1, S2 |
| Retention rate | Share that ordered **at or after** that month; mirror of cumulative churn; only falls | `customers_retained / customers_acquired` | `retention_rate` | S1, S2 |
| Revenue retention | Net sales in month *h* ÷ net sales at month 0; >100% = spending more than at acquisition | `net_sales_h / net_sales_0` | `revenue_retention` | S1–S3 |
| Purchasing pattern | One-time = single lifetime order; Repeat = more than one | `lifetime_orders > 1` | `purchasing_pattern` | S1, S2 |
| Retention curve | Retention rate, last six cohorts | — | `retention_rate` | S1, S2 |

### 4.3 Marketing Channel LTV tab  (`fn_marketing_channel_summary`; views: Last Paid Click / Incrementality / Last Paid Click + Superfiliate)
| Metric | Definition | Formula | Column | Sources |
|---|---|---|---|---|
| Attribution view | **Last Paid Click**: WorkMagic LPC, Northbeam clicks-only · **Incrementality**: WorkMagic IDDA, Northbeam CO+DV · **+ Superfiliate**: a Superfiliate referral code on the first order supersedes the click | — | `attribution_view` (`lpc`/`inc`/`lpcsf`) | S7, S8 |
| Channel | Meta, Google, TikTok, Amazon Ads, Email & SMS, Organic, Unattributed (+ Superfiliate – Affiliate / – Paid in the 3rd view) | — | `marketing_channel`, `is_paid` | S7 |
| Customers / Share | Customers credited to the channel (window) and share of the view total | `Σ credit`, `customers / Σ customers` | `customers`, `customer_share` | S7, S1 |
| Ad spend | Channel spend in the window; none for unpaid channels | Σ spend | `ad_spend` | S6 |
| CAC | Channel spend ÷ customers credited to the channel | `ad_spend / customers` | `cac` | S6, S7 |
| LTV per customer, N mo | Gross profit per credited customer at N months (3/6/9/12; 18/24 on the 24-mo window); uses **only cohorts that reached month N** so columns compare | `Σ(net_sales_cum − cogs_cum) / Σ customers` (mature) | `ltv_per_customer`, `horizon_months` | S1–S4, S7 |
| LTV / CAC, N mo | LTV per customer at N ÷ CAC (paid channels only) | — | `ltv_cac` | S1–S7 |

### 4.4 Product LTV & Repurchase tab  (`fn_product_summary`; filters: category → sub-category → product, level, acquisition type)
| Metric | Definition | Formula | Column | Sources |
|---|---|---|---|---|
| Entry product | Product in the customer's first order, preferring subscription items, then highest-priced line | rank by `is_subscription DESC, unit_price DESC` | `entry_sku` → `product` | S1, S2, S5 |
| Customers / Share | Customers whose entry product is the row; share of the shown rows | — | `customers`, `customer_share` | S1, S5 |
| LTR per customer, N mo | Net sales per customer at N months (mature cohorts) | `Σ net_sales_cum / Σ customers` | `ltr_pc_3…24` | S1–S3 |
| LTV per customer, 12 mo | Gross profit per customer at 12 months | `Σ(net_sales_cum − cogs_cum) / Σ customers` | `ltv_pc_12` | S1–S4 |
| 12-month repurchase | Share of a **mature** cohort (≥12 mo old) with a 2nd order within M0–M11 | `repurchased_12m / mature customers` | `repurchase_12m_rate` | S1, S2 |
| Lifetime repurchase | Share who have ever placed a 2nd order | `repurchased_ever / customers` | `lifetime_repurchase_rate` | S1, S2 |
| Median days to 2nd order | Typical gap between 1st and 2nd order, repurchasers only | median(`days_to_second_order`) | `median_days_to_second_order` | S1, S2 |
| Return rate (repurchasers / non-repurchasers) | Units returned ÷ units purchased in the first year, split by whether the customer later repurchased | `Σ returned / Σ purchased` | `return_rate_repeat`, `return_rate_one_time` | S1–S3 |
| New-customer mix | Share of each cohort's new customers by entry product | `customers_acquired / Σ` | `mart_product_cohort` | S1, S5 |

## 5. Deliberate deviations from the mock (confirm each)
1. **CAC "Both"**: mock divides Shopify-only spend by Shopify+Amazon customers before Amazon spend exists (understates CAC). SQL divides by customers of channels *with* spend.
2. **Median days to 2nd order** at category / sub-category: mock averages medians weighted by customers; SQL computes an approximate median over customers.
3. **Return rate** roll-ups: mock customer-weights a per-product rate; SQL is unit-weighted (more standard).
4. **COGS on refunds** is *not* reversed (food returns assumed not restocked).
5. **Purchasing pattern** counts orders only through the last complete month.

## 6. Open questions for Equip / data owners
1. Which datasets/tables hold S1–S8 (run the discovery script)? Is there already a modelled orders/customers layer (dbt)?
2. **Amazon customer identity** — is there a stable buyer/customer id (Amazon Marketing Cloud, Brand Analytics, Subscribe & Save)? Without it, Amazon cohorts, repeat and retention can't be built per customer.
3. Are WorkMagic IDDA and Northbeam CO+DV available **per order** or only as modelled/aggregate channel totals? (Drives `credit` and whether `customers` can be fractional.)
4. Is ad spend taken from platforms or from Northbeam/WorkMagic? Does Superfiliate spend = commission payouts?
5. COGS: source of SKU cost, history by effective date, and treatment on returns.
6. How is a *subscription* order identified (Shopify selling plan, Recharge, Amazon Subscribe & Save)?
7. Final LTV/CAC floor and ±band thresholds for the takeaways.
8. Product Category / Sub-category hierarchy — owner and location.

## 7. Next steps
1. Run `sql/00_discovery/discover_sources.sql`; share output → finalise `sql/01_staging/*`.
2. `PROJECT=… DATASET=cohorts_dashboard ./sql/deploy.sh --dry-run`, then deploy.
3. Reconcile `mart_cohort_segment_month` to Shopify/Amazon admin totals (customers and net sales by month) before wiring the app.
4. Web app queries only `rpt_*`, `fn_*` and `mart_dashboard_meta` (never staging).
