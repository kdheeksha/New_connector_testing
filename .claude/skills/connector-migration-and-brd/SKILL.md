---
name: connector-migration-and-brd
description: Plan, validate and document data-connector migrations (Triple Whale to warehouse, ShopifyQL/RPA tables) — BRDs, column mappings, validation handoffs, action-item lists from Slack/ClickUp. Use for Triple Whale and TSM data-warehouse column work.
---

# Connector migration & BRD

## Context
TSM (TrueSeaMoss) migration of Triple Whale metrics into the data warehouse. Client side: Gega, Pavel, Mark Anthony.
Saras side: Koundinya, Dheeksha, Vishnu, Sai (+ others). Work tracked in ClickUp; discussion in Slack.

## BRD workflow ("BRD — Triple Whale")
1. Gather: pasted Slack threads, ClickUp ticket text, screenshots for time estimates.
2. Produce a consolidated action-item list: **Task name · description · owner/side · date raised · status · time estimate**.
   Group completed first, then open; order by date within each.
3. Rules: text in chat only if asked; work strictly from what is pasted; flag ambiguous names rather than guess
   (e.g. "Milima" unclear from dictation); say when screenshots are missing so the estimate column would be empty.
4. When the user asks to "enhance the prompt", return a cleaned prompt plus the 2–3 things to fix before running it.

## Validation handoff
- Source vs connector: for every metric, state the source column, the connector column and the expected delta.
- **Declare known source defects in the BRD's Validation Results**, assigning blame to no one. Example line added:
  "Gels NCP is the one exception — source does not reconcile to Meta spend at stated CAC (implies ~1,779/day vs 83 stated);
  validate Gels NCP against the connector, not the source."
- Offer a long (shows working) and short version; let the user choose.

## Attribution decisions to put to a client (Gummies tab)
"Acquisition page" for returning customers has three candidates: (1) first session ever, (2) first session of the first order,
(3) converting session of the first order. (1) is an artifact (Shopify lookback can stamp a later order's session before the
first order) — do not offer it to a marketer. Put 2 vs 3 to the client with a Monday/Wednesday/Friday example,
state the recommended option, and **flag to the builder (Vishnu) that spec and client message must agree**.
Include a delivery commitment ("implemented by end of this week once confirmed").

## ClickUp / ticketing
Ticket keeps acceptance criteria; PR links back; ticket stays out of code-review status until CI and bot review are clean.
