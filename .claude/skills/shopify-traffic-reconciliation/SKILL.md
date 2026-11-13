---
name: shopify-traffic-reconciliation
description: Reconcile Shopify traffic/funnel data between Daton ShopifyQL tables and the RPA-based raw table (and BigQuery vs Shopify), diagnose Upsert-key row bloat, and sanity-check funnel stages. Use for TSM traffic tables and sessions/visitors/ATC/checkout discrepancies.
---

# Shopify traffic reconciliation (TSM)

## Tables seen
- `insightsprod.trueseamoss_daton.Trueseamoss_Shopify_Test_Query_1` (landing-page level)
- `insightsprod.trueseamoss_daton.Shopify_RPA_Test_Query_1` (account level)
- RPA raw: `insightsprod.trueseamoss_5363_prod_raw.trueseamoss_us_shopify_detailed_account_rpa_ext`
- Production staging dedups with `QUALIFY ROW_NUMBER() OVER (PARTITION BY Day ... ORDER BY Replication_date DESC)=1`.

## Diagnose bloat
- Symptom: ~90 rows for one day (expected ~1.5 rows/day over 1,463 days) with a sequence like 1,087 → 8,275 → … → 114,546 repeated.
  That is every intraday snapshot retained = **Upsert key missing/reset** (should be `day`, or `day + landing_page_path`).
- It is a storage/cost problem, not a correctness one, provided the latest snapshot per day is right.

## Correctness check
Dedup ShopifyQL to latest snapshot per day, dedup RPA, join on day, exclude last 2 days.
Result recorded: exact digit-for-digit match for sessions, visitors, ATC, checkout across 13 days (Aug 5–17).
`sessions_that_completed_checkout` has no RPA equivalent (new metric) — expected, not a gap.

## Known explainers
- Landing-page-summed Visitors ≠ account-level Visitors (non-additive across pages).
- RPA raw has duplicate and partial early-in-day rows of its own.
- `checkout_exceeds_atc` ~37.5% of rows is expected (accelerated checkout).
- `completed_exceeds_checkout` ~1.1% (1,939 rows) is the one worth a query.

## Action list
1. Confirm/fix the Upsert key on **both** Test_Query tables before handoff.
2. Run the 20-row `completed > reached` investigation query.
3. Re-check storage after fix.

Also see the BigQuery/Shopify traffic reconciliation session (Sept) — offer a shareable report or validate an older month + Query_2.
