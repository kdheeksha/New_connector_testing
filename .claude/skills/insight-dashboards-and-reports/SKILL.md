---
name: insight-dashboards-and-reports
description: Turn BigQuery findings into client-ready deliverables — self-contained HTML insight dashboards ("hooks"), short numbers-first Word reports, Excel use-case maps, and Q&A/handoff docs. Use when asked to build, rebuild, shorten or restructure a report or dashboard.
---

# Insight dashboards & reports

## Deliverable types done so far
- **HTML hook dashboards** (TSM Data Insights): Hook 2 "Where the Renewals Go", Hook 3 "Four Launches, Two Scoreboards".
- **Word reports** (TSM Flavour Launch Analysis .docx — cut ~1,900 → ~910 words, validated paragraph/table structure).
- **Excel workbooks**: Overview / Metric Detail / Rules & Notes (Adverio use-case map, v4).
- **Client Q&A doc** with BQ validation + technical handoff DOCX (cohort feedback).
- **Report formatting** passes for daily/periodic reports (30 Sep report; asked to extend to TrueSeaMoss).

## Rules that kept being requested
1. **Numbers first.** "Bottom line" with 3–4 quantified statements before any method. A reader of page 1 gets the answer.
2. **Method in ≤3 sentences**; keep control/placebo logic compressed so "$0 redistribution" survives challenge.
3. **One chart, one scale.** Split sections that must not share a scale (product lines vs flavours = Part A / Part B).
4. **Plain labels, expanded jargon.** No acronyms the client has not used.
5. **Show corrections explicitly** in the page and in FINDINGS, with old vs new.
6. **Drop what the audience cannot act on** (population/join section, shift-share chart → plain table, acquisition-channel when
   Shopify is the store not a traffic source).
7. **Recompute and cross-check counts across tabs** before saying done (254 metrics / 123 / 100 dataset rows / 12 use cases).
8. **Validate the file** (paragraph counts, table shapes) and deliver via file attach; push the branch.
9. When asked "3–4 lines each", give exactly that.

## Dashboard build checklist
- Live data vs embedded snapshot: say which, and the snapshot end date (an early-August snapshot had no Equip Foods rows).
- Decisions the user did not answer → apply recommendation, state it on the page, make it easy to flip.
- For BigQuery-backed HTML dashboards: decide path (run toolbox locally / host it / paste results) and ask the 4 blocking questions
  (sign-in email domain, who can deploy, retention, attribution, Product tab).

## Pairing
Use `dataviz` / `artifact-design` skills for chart styling when publishing as an Artifact.
