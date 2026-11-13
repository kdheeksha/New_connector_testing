---
name: cohort-ltv-and-launch-analysis
description: Run cohort, LTV, retention, subscription-vs-OTP, flavour/product launch and incrementality analyses on D2C data in BigQuery (TrueSeaMoss, Equip Foods). Use for launch performance, cannibalization, cross-sell, time-to-second-order, dunning/failed-charge and churn questions.
---

# Cohort / LTV / launch analysis

## Definitions to pin down first (state them on the page)
- **Launch date** (e.g. Peach & Pear = 15 Mar, not 20 Mar; Sparkling Hydration is TikTok-only, never on Amazon).
- **Seeded / $0 orders** — show separately rather than silently excluding (Fruit Chews 20% at $0, Sparkling 43%).
- **New customer** — acquisition date logic; watch customers "acquired on 0" still counted as new (July zero-value issue).
- **LTR/LTV** = gross − discounts − returns + shipping − shipping_tax (Equip Foods cohort work).
- **Bundles**: count where the source resolves them; caveat where it does not (8.5% in one table).
- **Returns** compared against each product's *own platform* baseline (TikTok refunds 10.71% vs Shopify 4.53%).

## Launch report recipe (TSM flavour launches)
1. 30 / 60 / 90-day revenue table with growth multiple — first thing on page.
2. Where revenue came from: new customers vs pre-existing, share each.
3. Incrementality of the pre-existing slice: control group + **placebo calibration** (subtract e.g. $9.68/customer),
   adjusted lift, redistributed = $0.
4. Payback: revenue per new customer ÷ CAC and ÷ NCPA (1.55–1.91× CAC in 60 days; profit not settled at 1.11–1.39× NCPA).
5. Conclusions quantified, not advisory. Headline example: Raspberry/Watermelon beat Cranberry by $975,985 at T+90
   with per-customer value within 4% → "reach, not flavour".
6. Caveats ≤5 bullets (revenue ≠ margin).

## Analysis menu (built or queued)
Flavour cohort · Expansion/"add to subscription" LTV · cross-sell path (`Product_Affinity_Cumul`) · consideration time
(`daysToConversion`) · OTP→subscription conversion curve (30/60/90/120d by entry flavour) · flavour-level Jaccard ·
gateway flavour → LTV · time-to-second-order · Lemonade 10-flavour natural experiment (15 Oct 2025) ·
gel vs electrolyte head-to-head (equal age) · gel return-rate investigation (7.4–7.5% vs 4.6–5.0%).

## Cannibalization — test three ways
Product-line share, time-series dip vs control, then customer-level (ceiling <1%). Report price-vs-cause ambiguity honestly.

## Dunning / failed-charge work (TSM "Hook 2")
Failure rate, retry collapse, recovery by decline type, monthly $ loss decomposition. Key finding: a third of failed
charges are never retried (33%). **Include corrections** when a prior version was wrong (proxy method had the direction wrong).

## Equip Foods specifics
- Faire wholesale excluded from `OrderLinesMaster` by design (exclusion landed 2026-08-17, PR #82); Faire launched 2026-02-10 and
  matches the OTP break from Feb 2026 — customers and revenue must be added together or not at all.
- Subscription vs OTP monthly comparison vs client sheet; March 2026 is the only month with the client's customer list.
- Brief the DE agent with: facts, numbered questions, "what we are NOT asking for", why it matters now.

## Hygiene
Cite counts with denominators; show launch-date definition up front; state recommendations used when the user does not
answer ("moved on without answering, so I used my recommendation and stated it on the page").
