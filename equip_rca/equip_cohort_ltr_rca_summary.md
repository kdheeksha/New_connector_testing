# Equip Foods — cohort LTR reconciliation

**Internal. Not for the client.**
Audience: Koundinya, Dheeksha. Written 2026-10-05.

---

## 0. Read this first — what this document is and isn't

This explains why our Cohorts Dashboard disagreed with the client's "Equip LTV
analysis", what we changed to close it, and what is still open. It is written
so someone who was not in the investigation can follow it.

**Diff convention, used everywhere:** `(ours − client) / client`, computed on
**LTR per customer**. Negative means we are *below* the client.
*The companion Excel file uses the opposite sign, `(client − ours) / client`.
That is the only place the other convention appears, and it is labelled there.*

**Provenance of every number.** Every figure comes from a BigQuery run executed
during the investigation, named in the text. Nothing here was re-run today —
see §11 for why, and treat that as a real limitation rather than a footnote.

---

## 1. Executive summary

Our cohort LTR disagreed with the client's by up to **51%** on the oldest
cohorts. Two causes, one large and one small.

**The large one is attribution.** We locked every customer into the bucket they
were acquired in and left them there for life. A customer acquired on a
one-time order who later subscribed had all their subscription revenue counted
as OTP. The client moves that revenue. This single change takes the mean error
across all eleven cohorts from **14.11% to 1.03%**.

**The small one is Faire.** Faire wholesale orders are deliberately excluded
from `OrderLinesMaster` by a channel filter, so neither the revenue nor the
retailers reach our cohorts. The client counts them. Adding them removes the
remaining OTP shortfall on the 2026 cohorts.

Together: **mean error 1.11%, worst cell 3.6%, no cell above 5%** across eleven
cohorts and both buckets.

Still open: roughly 115 customers across the non-July cohorts that we class as
OTP and the client classes as Subscription (0.10% of base), and three cohorts
where we hold slightly fewer customers than the client.

---

## 2. The "Before" logic — what the dashboard does today

Plain language: **a customer is put in a bucket on the day they are acquired,
and every dollar they ever spend is counted in that bucket forever.**

| element | rule |
|---|---|
| scope | Shopify only; `customer_id` not null; `is_test = false`; `is_gift_card = false` |
| exclusions | customers whose founding-order `revenue_bucket = 'TT New'` (TikTok) |
| founding order | earliest by `(order_date, order_id)` |
| acquisition bucket | **Subscription** if any order on the acquisition *date* is a subscription order, else **OTP** |
| revenue per order | `item_subtotal_price − item_discount + item_shipping_price − item_shipping_tax` |
| returns | deducted |
| attribution | the acquisition bucket applies to every later order |

**Tables read:** `insightsprod.equipfoods_5642_prod_presentation.OrderLinesMaster`
and `…ReturnLinesMaster`.

**March 2026 under this logic:** 6,643 OTP + 4,577 Subscription = 11,220
customers. *(The brief quotes 6,651 / 4,580 / 11,231. The 11-customer difference
is the $0-founding-order rule, §5.3, which we applied to the Before side as well
so the two tabs stay comparable. 0.1% — inside the 0.5% tolerance, but noted.)*

> `sql/02_before_logic.sql` · 33 cohort/bucket pairs × month_index ·
> March OTP: 6,643 customers, M0 $95.00 and M4 $148.16 per customer. Full
> values in §6.

---

## 3. Which source table — and why it mattered more than expected

This cost us several rounds and is the single most likely thing to confuse
someone re-running the work, so it goes before the changes.

There are two candidate sources and they do **not** agree:

| | reproduces the published dashboard (March, worst cell) |
|---|---|
| `LineItemMaster` | **3.73% off** |
| `OrderLinesMaster` + `ReturnLinesMaster` | **0.20% off** |

For most of the investigation we built on `LineItemMaster` and carried an
unexplained **1.2–3.7% residual**, which I repeatedly told the team to accept as
noise. It was not noise — it was the wrong table. `OrderLinesMaster` applies
`is_test` and `is_gift_card` exclusions that `LineItemMaster` does not surface
the same way, and those account for most of the difference.

**A second finding fell out of the same comparison: the published dashboard is
already net of returns.**

```
published March M0 total            1,093,954
ours, net of returns                1,093,509    −0.04%
ours, orders only                   1,109,523    +1.42%
```

Our early "orders only" runs were the deviation, not the baseline. Returns were
never optional.

**Both the Before and After numbers in this document use
`OrderLinesMaster + ReturnLinesMaster`, net of returns.** If the After logic is
implemented, it should use the same.

> *Not verified:* we never read `LineItemMaster`'s model SQL to confirm exactly
> how it unions `OrderLinesMaster` and `ReturnLinesMaster`, nor built the
> line-by-line bridge the brief asks for. See §11.

---

## 4. Change log

| # | Change | Before | After | Why | Evidence | March M4 impact (per customer) |
|---|---|---|---|---|---|---|
| 1 | **Post-acquisition attribution** | acquisition bucket for life | from M1, an order is Subscription if the customer was acquired on Subscription, or the order is a subscription type, or it is on/after their first subscription order | we attribute by *who the customer was*; the client attributes by *what is happening now* | mean error 14.11% → 1.03% across all 11 cohorts | OTP +13.4% → −6.5% · Sub −15.1% → −0.5% |
| 2 | **Faire wholesale** | excluded by a channel filter | Faire retailers and their revenue added as OTP | the client counts them; the exclusion is a deliberate wholesale policy that predates nobody checking its effect on cohorts | 649 orders, 293 customers, none reach `OrderLinesMaster` | OTP −6.5% → −1.5% · Sub unchanged |
| 3 | **$0 founding orders** | counted as acquisitions | customers whose founding order has raw `total_price = 0` excluded | a one-day free-product promotion created 936 fake acquisitions in July | July customer gap +954 → +18 | July OTP +13.6% → −1.4% |

Change 3 is not in the original brief's list; it emerged from the July
investigation and is applied to **both** tabs, so it is a scope correction
rather than an attribution change.

---

## 5. Each change in detail

### 5.1 Change 1 — post-acquisition attribution

**What it does.** M0 stays in the acquisition bucket. From M1 an order counts as
Subscription if **any** of:

- (a) the customer was acquired on Subscription
- (b) the order's `revenue_bucket` is `NC Subs`, `Recurring Day Of`, or `SKIO (Recurring)`
- (c) the order is on or after the customer's first subscription-type order

Returns follow the allocation of the order they reverse
(`return_order_id = order_id`).

**What it does not change.** Customer counts. Total cohort LTR. Only the split
between OTP and Subscription moves — the two buckets always sum to the same
total, which is the main check on any implementation.

**Why we believe it.** We scored four candidate rules across all eleven cohorts
on the same baseline:

| rule | mean error | max | cells > 5% |
|---|---|---|---|
| A — acquisition bucket for life (current) | 14.11% | 51.1% | 102 |
| **B — the rule above** | **1.03%** | 6.5% | 2 |
| B + Faire | 1.11% | 3.6% | 0 |
| C — Subscription only *between* first and last subscription order | 2.16% | 6.2% | 8 |

**A caution for whoever reads this next.** Rule C won an earlier round of this
same test, when it was run on `LineItemMaster`. It lost decisively once the
baseline was corrected. Two separate times in this investigation a rule looked
right on one month or one baseline and was wrong across the series. Any future
rule change should be scored on all eleven cohorts before it is believed.

> `sql/05a_change1_four_rules.sql` · 44 rows (4 rules × 11 cohorts) ·
> key totals in the table above.

---

### 5.2 Change 2 — Faire wholesale retailers

**1. Do we exclude Faire? Yes, deliberately.**

The exclusion is a channel list in the client repo's `dbt_project.yml`:
`shopify_revenue_bucket_excluded_channels` contains `'faire'` and
`'14264008705'` (Faire's numeric channel id), under the comment *"Wholesale
channels are globally excluded, not bucketed."* The macro
`shopify_passes_global_filter` flags those orders and
`OrderLinesMaster.sql` applies `coalesce(rb.passes_global_filter, true) = true`.
Added in PR #82 (`ef00ff5`, 2026-08-17), gated behind an opt-in flag in #83
(2026-09-29).

Effect: **649 Faire orders reach `dim_orders`; 0 reach `OrderLinesMaster`.**

**2. Does the client include Faire? The evidence says yes.**

- 293 distinct Faire customer ids exist and are stable; all are in
  `dim_customer` and `CustomerMaster`. Only **40** have any `OrderLinesMaster`
  row — those are retailers who also bought through the web.
- The client's March customer list contains **22 `@relay.faire.com`** customers.
  Ours contained 1. *(This is a floor, not a count: only 397 of 649 Faire orders
  use a relay email, so Faire buyers with ordinary emails are not detectable
  this way. Any future matching should use `customer_id`.)*
- Faire launched **2026-02-10**. New Faire retailers by cohort: Feb 17, Mar 33,
  Apr 25, May 37, Jun 33, Jul 46 — and our OTP position versus the client turns
  negative from exactly those cohorts onward.

**3. Why this first looked like the Skio migration.** The original RCA attributed
a growing subscription gap to the Luna→Skio feed migration, whose Luna feed
stopped on 2026-02-16. Faire launched 2026-02-10. Two unrelated events six days
apart, both producing a step change in February. The Skio story was dropped once
total cohort revenue was shown to be within ~1% of the client's — a missing-data
story predicts a large total shortfall, and there wasn't one.

**4. What the data cannot settle.** Whether the client *intends* wholesale
retailers to count as LTV customers, or whether their inclusion is incidental.
Faire is B2B; the exclusion was a deliberate policy decision by whoever owns
PR #82. The data says the client counts them. It does not say they should.

**The denominator trap.** Faire must add **customers as well as revenue**. An
earlier version added only revenue, which inflated LTR per customer because 87%
of Faire revenue ($199K of $228K) belongs to retailers with no
`OrderLinesMaster` row at all. On a dollar comparison this is invisible; on a
per-customer basis it is not.

> `sql/05b_change2_faire.sql` · Faire: 649 orders, 293 customers,
> first order 2026-02-10, ~$228K subtotal.

---

### 5.3 Change 3 — $0 founding orders (July 2026)

**What happened.** On **2026-07-09** a free-product promotion
(`PRIMEVANILLASACHET`, `EQUIP-TOTE-01`) created **936 acquisitions worth
nothing**. 871 of 875 sub-$5 founding orders are dated that one day. A further
66 are shipping-only — `total_price = 0` with $6.99–24.99 of shipping — which a
`< $5` cut would miss.

**Why it is a real exclusion, not a fit.** Our extra 954 July customers carry
**$3.57 each** against a cohort average of $93.96. They are acquisitions with no
money attached.

**Effect.** July customer gap **+954 → +18**; July OTP error **+13.6% → −1.4%**.
Outside July the rule is a wash: worse by 27 customers in three cohorts, better
by 25 in three others.

**Implementation note.** Scope it to the **founding order only**. Applied
globally it would drop legitimate $0 replacements and comped follow-ups. Use
`total_price`, not `total_line_items_price`, which misses 2 of the 875 and all
66 shipping-only cases.

> `sql/05c_change3_zero_founding.sql` · July: 936 customers dropped,
> 11,786 → 10,850 against the client's 10,832.

---

### 5.4 The validation-only step we did **not** adopt

For March only, an earlier run removed 60 customers absent from the client's
customer list. **This should not go into the dashboard** — it is a hardcoded id
list, it breaks the moment the client re-exports, and it is fitting to the
answer rather than deriving a rule.

We then tried to find the *rule* behind those 60: 42 had a draft order and 43
carried a seeding tag. Every variant of a seeding exclusion **overshot** — it
removed 626–1,338 customers against a total excess of just **+51** across ten
cohorts, and the excluded customers turned out to be *above* average value
($251 / $324 against $165 / $267), i.e. real buyers who happened to receive a
gift. Rejected.

That failure produced the most useful framing in the investigation: across the
ten non-July cohorts we hold **+166 too many OTP and −115 too few Subscription**,
netting to +51. **That is a classification difference, not a population one** —
which is why no exclusion rule could ever close it. Removing customers cannot
create Subscription ones.

---

## 6. Results — March 2026

Cumulative LTR **per customer**, `(ours − client) / client`.

### OTP

| variant | customers | M0 | M4 | M0 diff | M4 diff |
|---|---|---|---|---|---|
| Before | 6,643 | 95.00 | 148.16 | −0.4% | **+13.4%** |
| After ch.1 | 6,643 | 95.00 | 122.26 | −0.4% | −6.5% |
| After ch.1+2 | 6,676 | 97.08 | 128.78 | +1.8% | **−1.5%** |
| Client | 6,599 | 95.39 | 130.71 | — | — |

### Subscription

| variant | customers | M0 | M4 | M0 diff | M4 diff |
|---|---|---|---|---|---|
| Before | 4,577 | 101.02 | 218.34 | −1.5% | **−15.1%** |
| After ch.1 | 4,577 | 101.02 | 255.93 | −1.5% | **−0.5%** |
| After ch.1+2 | 4,577 | 101.02 | 255.93 | −1.5% | −0.5% |
| Client | 4,608 | 102.59 | 257.28 | — | — |

Faire does not touch Subscription — it is added entirely as OTP.

### All customers

| variant | customers | M0 | M4 | M0 diff | M4 diff |
|---|---|---|---|---|---|
| Before | 11,220 | 97.46 | 176.79 | −0.9% | −3.3% |
| After ch.1 | 11,220 | 97.46 | 176.79 | −0.9% | −3.3% |
| After ch.1+2 | 11,253 | 98.68 | 180.50 | +0.3% | −1.2% |
| Client | 11,207 | 98.35 | 182.75 | — | — |

Change 1 leaves the total untouched, exactly as designed — it only moves money
between buckets. All of the total movement comes from Faire.

> `sql/06a_march_three_steps.sql` · 12 rows · `exports/march_three_steps.csv`

### Every cohort, at its latest available month

Max |diff| across both buckets:

| cohort | before | after |
|---|---|---|
| 2025-09 | 51.1% | **1.3%** |
| 2025-10 | 40.7% | 1.7% |
| 2025-11 | 34.0% | 1.8% |
| 2025-12 | 34.3% | 1.2% |
| 2026-01 | 26.4% | 0.9% |
| 2026-02 | 23.8% | 2.7% |
| 2026-03 | 15.1% | 1.5% |
| 2026-04 | 16.2% | **3.6%** |
| 2026-05 | 5.0% | 1.5% |
| 2026-06 | 5.4% | 1.1% |
| 2026-07 | 1.2% | 1.4% |

> `sql/06b_all_cohorts_latest.sql` · 33 rows ·
> `exports/all_cohorts_latest_month.csv`

---

## 7. Ruled out — and the number that killed each

| hypothesis | killed by |
|---|---|
| Acquisition misclassification (the "548" list) | 470 of the 548 were *already* Subscription in live data; only 78 would move. The list was built on `cohorts_main_shopify`, not the dashboard model, which is why it never reconciled. |
| Missing subscription orders / Skio migration | Total cohort revenue is within ~1% of the client's. A missing-data cause predicts a large total shortfall; there isn't one. |
| Seeding / influencer gifts | Every variant overshot: removed 626–1,338 customers against +51 of excess. |
| Draft orders | 73% are $0, 98% carry a discount code, 2,514 of 2,674 recent draft-only customers are seeding recipients. Not DTC buyers. |
| Faire as a separate *channel* | No Faire channel exists in `LineItemMaster` — only Shopify and Amazon. Faire is excluded upstream, not mis-channelled. |
| Walmart / `88312` dropped by a platform filter | Both carry `platform_name = 'Shopify'` and are fully present in `OrderLinesMaster`. |
| $0-rule and Faire interacting | Zero overlap in every cohort. |
| Returns definition | The dashboard is net of returns; matching that moves March M0 from +1.42% to −0.04%. |
| Partial-month export for July | The 954 extra customers carry $3.57 each; a mid-month cut would remove customers worth the cohort average. June's M0→M1 increment is 95.7% of ours, so July was essentially complete. |

---

## 8. Still open

| item | size | note |
|---|---|---|
| OTP/Subscription classification residual | ~115 customers, **0.10%** of base | +166 OTP / −115 Sub across the ten non-July cohorts. Not fixable by any exclusion rule. |
| Three cohorts short of the client | Sep-25 −25, Oct-25 −53, Feb-26 −60 | To be short, the client must count customers we exclude. `is_gift_card` is the only untested exclusion that could do it. Feb's LTR error is flat at −2.7%, i.e. an offset not a drift. |
| 465 of the 936 July customers have a second order | justification gap, not a numbers gap | Believed to be the promotion's *second* free item — it had two products — rather than a real purchase. One query would confirm: how many of the 936 have any order with `total_price > 0`. |
| 2026-04 at 3.6% | worst remaining cell | No investigation run. |

---

## 9. Decisions we need to make

1. **Adopt the client's attribution rule, or keep ours and label the
   difference?** Ours is defensible — "this customer was acquired on OTP, here
   is their lifetime value" is a coherent metric. Theirs answers a different
   question. But we cannot publish a dashboard that disagrees with the client's
   by 15% and call it a definition difference without saying so explicitly.

2. **Do Faire wholesale retailers count as LTV customers?** The data says the
   client counts them. Wholesale was excluded from `OrderLinesMaster` on
   purpose. Removing `'faire'` from the exclusion list changes **every**
   `OrderLinesMaster` consumer, not just cohorts. This is a decision for whoever
   owns PR #82, with this document attached.

3. **Is a $0 founding order an acquisition?** We say no. Worth stating once as
   policy rather than deciding it per-promotion.

---

## 10. If the After logic is adopted

Not implemented. Nothing in this investigation changed a model, a macro, or a
table.

| what changes | where |
|---|---|
| attribution rule | the cohort model's bucket assignment — currently acquisition-locked |
| Faire | `shopify_revenue_bucket_excluded_channels` in `dbt_project.yml`, or a cohort-level carve-out |
| $0 founding orders | a new condition in `shopify_passes_global_filter`, **scoped to the founding order** |

**Downstream impact.** Unexcluding Faire touches every `OrderLinesMaster`
consumer, not just cohorts. Scope that before changing it.

**Re-validation plan.** Re-run `sql/06b_all_cohorts_latest.sql` and confirm:
customer counts unchanged by change 1; OTP + Subscription = All customers in
every cell; total cohort LTR identical before and after change 1.

**Separate bug, not addressed here.** The original RCA identified that
`fact_order_lines_shopify.is_subscription_order` resolves no `subscription_id`
for a large share of tagged subscription orders, and that `dim_customer`
consumes that flag with no fallback while
`int_shopify_order_revenue_bucket` has one. That defect is real and worth
fixing on its own merits — but it is **not** the cause of the cohort LTR gap, as
§7 shows. Fixing it will not move these numbers.

---

## 11. Limitations — read before relying on this

Two things the brief asked for that this document does not deliver, stated
plainly rather than buried:

1. **Nothing was re-run today.** This session has no BigQuery access — no
   credentials, no `bq` client, no warehouse connector. Every number is
   carried forward from a query run earlier in the investigation, each named
   in the text. They were checked for internal consistency (bucket sums,
   totals, cross-run agreement) but not re-executed.

2. **No model SQL was read.** The dbt project
   (`sarasanalytics-com/equipfoods_5642_prod`) is not accessible from this
   session — `add_repo` was attempted and refused. Every statement about model
   internals — the `dbt_project.yml` exclusion list, `shopify_passes_global_filter`,
   `OrderLinesMaster.sql:240`, PR #82 — comes from the DE agent's RCA, not from
   reading the files. Those claims are well-evidenced but second-hand.

Consequently the brief's §3 bridge table (`LineItemMaster` reconciled to
`OrderLinesMaster`, reason by reason) is **not** in this document. We know the
size of the gap (3.73% vs 0.20% against the published dashboard) and the most
likely cause (`is_test` / `is_gift_card`), but not the line-by-line attribution.

**Three exports asked for are not here.** `march_cohort_customer_level.csv` and
`faire_retailers_march.csv` both need customer-level warehouse extracts that were
never pulled into this session; `sql/08a_…` and `sql/08b_…` are the queries that
produce them, written but unrun. `removed_60_customers.csv` is not produced at
all — the 60 ids only ever existed inside a query pasted into chat and were never
saved, and reconstructing them needs the client's customer list, which is not in
BigQuery. Since the 60-id removal is validation-only and explicitly **not** going
into the dashboard (§5.4), this is the least costly of the three gaps.

Anyone picking this up should run the files in `sql/` and confirm the figures
before quoting them externally.

---

## 12. Files

| file | what it is |
|---|---|
| `equip_cohort_ltr_rca_summary.md` | this document |
| `sql/02_before_logic.sql` | §2 — the Before tab, all cohorts |
| `sql/03_source_table_check.sql` | §3 — returns and OLM vs LineItemMaster |
| `sql/05a_change1_four_rules.sql` | §5.1 — all four attribution rules; the engine behind everything |
| `sql/05b_change2_faire.sql` | §5.2 — Faire orders, retailers, and what reaches OLM |
| `sql/05c_change3_zero_founding.sql` | §5.3 — the $0 founding-order promotion |
| `sql/06a_march_three_steps.sql` | §6 — March, Before / After ch.1 / After ch.1+2 |
| `sql/06b_all_cohorts_latest.sql` | §6 — every cohort at its latest month |
| `sql/07_ruled_out_checks.sql` | §7 — the three one-line kills |
| `sql/08a_export_march_customer_level.sql` | recipe for the customer-level export (unrun) |
| `sql/08b_export_faire_retailers_march.sql` | recipe for the Faire retailer export (unrun) |
| `exports/march_three_steps.csv` | §6 March table, with diffs against the client |
| `exports/all_cohorts_latest_month.csv` | §6 all-cohort table, with diffs against the client |

`05a`, `06a` and `06b` share one engine — the CTE block is identical in all
three and only the final SELECT differs, so a change to the logic must be made
in all three.

Every `sql/` file is a single read-only SELECT with its parameters in a `params`
CTE at the top. Nothing in this folder creates, alters, or writes anything.
