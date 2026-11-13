---
name: dbt-model-change-and-pr
description: Make a safe change to a Saras/EDM dbt model (add a column, dedupe, add a brand block, thread a flag through layers), validate dev vs prod, and run the PR + review loop. Use for any dbt SQL change on client BigQuery projects (Equip Foods, TrueSeaMoss, Adverio).
---

# dbt model change + PR

## Workflow
1. **Find the real model and its position in the DAG.** Locate the file, its upstream refs and every downstream
   consumer. State where in the file the change goes (e.g. "inside `final` CTE, after the last `UNION ALL` block,
   before the closing paren") — not just "add this".
2. **Match the existing pattern.** Copy the conventions of sibling blocks (same column order, casts, null handling,
   `QUALIFY ROW_NUMBER()` style). In `UNION ALL` branches the new column must sit at the **same position and type**
   in every branch.
3. **Dedup deliberately.** If a model *sums* downstream (e.g. COGS `group by Brand, marketplaceName, asin, SKU`),
   duplicate source rows double-count — add `QUALIFY ROW_NUMBER() OVER (PARTITION BY <natural key>) = 1`.
   Say plainly that no `ORDER BY` means an arbitrary survivor, and offer a deterministic version.
4. **Mirror filters from sibling brands** (e.g. `Child_ASIN <> 'B07CX95VRT' and Child_ASIN <> ''`) and flag when a
   pasted block drops one. When adding a filter you were not asked for (e.g. `Product_Lifecycle <> 'Parent'`), say it
   was a judgment call and give the query that verifies it.
5. **Aggregation changes in a GROUP BY:** if adding a column would split rows, prefer `max()/any_value()` and keep the
   original `group by 1..N`. Prove it is single-valued (e.g. "single-valued in all 64,746 groups, max() loses nothing").
6. **Validate dev vs prod** (see `bq-validation-and-reconciliation`): row counts, 5 key metrics, rows per order/key.
7. **YAML:** description for every new column; for Presentation/l2 models the rules require a
   `cross_model_reconciliation` test. Pattern to copy: `RevenueDetailBase.yml`. Document NULL-vs-empty-string semantics
   per platform (e.g. discount_codes: NULL on Shopify/TikTok, empty string on Amazon → test `IFNULL(x,'')=''`).
8. **PR:** body states change, validation numbers, review record, and what is deliberately out of scope / follow-up.
   Link the ClickUp ticket. Keep ticket out of code-review until CI + bot review are clean.

## Review loop (what worked)
- Use a fresh subagent for static review; limit to 3 rounds. Categorize findings (medium/low), ask the human for the
  scope call (in this PR vs follow-up) rather than deciding silently.
- After each fix re-run the dev-vs-prod comparison and update the PR body.
- Report: "SQL is correct; findings are X, Y; nothing changed on the PR yet" — be explicit about what was NOT run
  (e.g. "static review only, did not run dbt").

## Prod full-refresh validation (flag threading, TSM PR #186 pattern)
- Trigger the client DAG with `dbt run --select <model>+ --full-refresh --exclude DeprecatedModels`.
- Compare order-level flag counts at every layer (`fact_order_lines_shopify` → `fact_order_lines` →
  `OrderLinesMaster` → `account_overview_sales` → `sku_cohort_base`). Explain expected drifts
  (cross-platform union raises `is_cancelled`; ~1-order aggregation drift) and NULL-by-platform breakdowns.
- Note unrelated pre-existing failures separately (e.g. `SalesMaster: cost_price not found` — TSM's forked
  `fact_order_lines.sql` never picked up the EDM base `cost_price` column). Flag, don't fix inside the ticket.

## Output style
Short, plain. Lead with verdict. Tables for counts. Always end with the decision you need from the human.
When asked "short msg — client name and the change", give 2 lines: client, change, validation.
