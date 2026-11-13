---
name: bq-validation-and-reconciliation
description: Verify numbers in BigQuery — dev vs prod, source sheet vs warehouse, connector vs source, client file vs our cohort. Use when asked to "verify", "check", "reconcile", or when metrics do not tie. Encodes the triangulation and false-alarm checks used across TSM, Equip Foods and Adverio work.
---

# BigQuery validation & reconciliation

## Principles that recurred
1. **Triangulate — never trust one source.** Three independent routes converging beats one clean query.
   Example: Gels NCP stated 83/day vs connector ~1,800 vs implied (Meta spend ÷ CAC) 1,779 → the sheet was wrong.
2. **Consistency test using the source's own identities.** If CAC = spend ÷ NCP then NCP must = spend ÷ CAC.
   Run it on a control segment first (Electrolytes reconciled 113 vs 111 → method valid) then on the suspect one.
3. **Dedup before you compare or join.** Raw feeds carry intraday snapshots and exact duplicates; a FULL OUTER JOIN on
   an un-deduped side fans out and creates fake mismatches. Use
   `QUALIFY ROW_NUMBER() OVER (PARTITION BY day ORDER BY _daton_batch_runtime DESC)=1`.
4. **Exclude unsettled days** (last ~2) from comparisons on both sides.
5. **Check schema queries are not truncated.** A 270-column table silently returned only 200; re-search all
   `INFORMATION_SCHEMA.COLUMNS` rows (`LIKE '%click%'`) before claiming a column does not exist.
6. **Separate correctness from hygiene.** Values exact-match but storage bloats = a cost issue, not a data-quality one.
7. **Classify NULLs and exceedances before calling them bugs.** `checkout > add-to-cart` is expected with Shopify
   accelerated checkout; `completed > reached` (~1%) is the one worth a look.
8. **Say what you could not verify** (no Luzmo access, no `bigquery.jobs.listAll`, no ad-manager access).
   Offer the exact permission / check that would settle it.

## Standard dev-vs-prod checklist
- Row counts equal
- Five key metrics equal (revenue, orders, units, discounts, returns — whatever the model owns)
- Distinct key counts and rows-per-key (e.g. return rows per `order_id`: 35,581 orders, 0 differ)
- New column: distinct values, NULL vs '' by platform, single-valuedness inside any GROUP BY
- Note which dataset the dev table lives in (e.g. `solutionsdw`) so a reviewer can re-run it

## Reconciling to a client file
- Do not "fit" by excluding named IDs — that moved Subscription from -1.17% to -1.46%. Find the **mechanism**.
- Profile dimensions never profiled before (e.g. `source_name` vs `channel`; `transaction_type`).
- Check customer *and* revenue sides together: adding revenue without customers inflates per-customer LTR.
- Confirm export dates of any "dashboard export" against model-change dates (restatement risk).

## Answer format
Table of check → result → verdict, then "what I'd do next" and the one decision needed.
Admit when an earlier verdict was wrong (e.g. "7 of 8 'unique KPIs' were false positives; CTR is the real gap").
