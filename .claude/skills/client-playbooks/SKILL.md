---
name: client-playbooks
description: Client-specific facts, definitions, table paths and gotchas for TrueSeaMoss (TSM), Equip Foods, Adverio, Simply Sales and Commerce Labs. Load alongside any other job skill whenever a client name is mentioned.
---

# Client playbooks

> Employer: **Saras Analytics** (GitHub org `sarasanalytics-com`). Repos seen: `equipfoods_5642_prod`, TSM prod repo (PR #186).

## TrueSeaMoss (TSM) — D2C supplements on Shopify + Amazon + TikTok + Walmart + Target
- Products: Gels, Electrolytes, Gummies, Fruit Chews, Sparkling Hydration, Lemonade (TikTok). Flavour launches are core.
- Heavy subscription (97.8–99.2% of launch revenue) with OTP minority; dunning/failed-charge issues.
- Stack: Triple Whale, Meta, Shopify, Daton, dbt on `insightsprod`; prod DAG `trueseamoss_5363_prod`.
- Models: `fact_order_lines_shopify → fact_order_lines → OrderLinesMaster → account_overview_sales → sku_cohort_base`;
  `Product_Affinity_Cumul`, journey table (`daysToConversion`), `sku_cohort_base.is_cancelled` etc.
- Flags delivered (PR #186): is_cancelled, is_fully_refunded, is_partially_refunded, is_replacement_order.
- Gotchas: forked `fact_order_lines.sql` missing `cost_price`; Upsert-key bloat on Shopify test tables; Gels NCP in the
  Google Sheet source is wrong (~20×); Peach & Pear launched 15 Mar; Sparkling is TikTok-only; GCS FUSE mount race on prod runs.
- Client contacts: Gega (marketing lead), Pavel, Mark Anthony. Saras: Koundinya, Vishnu, Sai.
- Work done: flavour cohort, expansion LTV, cross-sell, consideration time, launch analysis 30/60/90, Lemonade post-mortem,
  gel returns, Hook 2/3 dashboards, Triple Whale BRD & validation, Shopify traffic reconciliation, Gummies-tab attribution,
  cohort feedback Q&A + technical handoff, iQ adoption analytics (13 total / 3 in last 30d).

## Equip Foods — consumer products; Shopify + Amazon + TikTok Shop + Faire (wholesale)
- Key table: `insightsprod.equipfoods_5642_prod_main.dim_orders`; models `OrderLinesMaster`, `ReturnLinesMaster`, `LineItemMaster`,
  `RevenueDetailBase`, cohort models (`simplified_customer_cohorts_v2`, `simplified_order_cohorts_v2`, `simplified_churn_customers`).
- `AllTables.yaml` lists table docs for the Equip Foods iQ/semantic layer (note: `table name:` key vs `table_name:` in the dim_orders entry; CRLF vs LF line endings).
- Done: dim_orders appended to AllTables.yaml; `discount_codes` added to LineItemMaster (PR #123, `max()` in return group-by,
  2,986,473 rows matched prod); Subs & OTP cohort vs client reconciliation; Faire RCA (Feb 10, 2026 launch; exclusion PR #82, 2026-08-17);
  campaign+date uniqueness check (1,304 rows = 1,304 unique); cancelled orders included check; iQ adoption analysis (MCP vs Web, Sep 8–Oct 5).
- Gotchas: discount NULL on Shopify/TikTok, '' on Amazon; no LineItemMaster.yml before this work; TikTok Shop customers
  (`@scs.tiktok`) present in ours (829) but zero in client list; Faire retailers `@relay.faire.com`.
- Contact: de-agent-saras authors agent PRs; client Slack uses `@Dheeksha`.

## Adverio — Amazon (+Walmart/Target/DSP) brand portfolio
See `amazon-dashboard-metric-catalog`. Project `adveriodatondw`; Luzmo dashboards; brands incl. RainEyeDropsUS, Cater Pax.

## Simply Sales — NOT FOUND in any session
No evidence available. Template to fill:
- What the client sells / channels:
- Stack & project IDs:
- Your role & deliverables:
- Recurring tasks:
- Gotchas:

## Commerce Labs — NOT FOUND in any session
Same template as above. Likely a separate employer or earlier role — tell me and I will add a dedicated skill.
