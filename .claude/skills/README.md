# Job Skill Set — Dheeksha (Saras Analytics)

Built from 28 chat sessions (Aug 13 – Nov 13, 2026) and the code sessions in this repo's branches.
Every skill below is grounded in work that actually appears in those sessions.

## Role in one line
Analytics engineer / data analyst at **Saras Analytics**: builds and validates BigQuery + dbt models,
connector pipelines (Daton, Triple Whale, ShopifyQL), cohort / LTV / launch analyses and client dashboards
for D2C and Amazon brands, then turns the findings into client-ready messages, reports and BRDs.

## Skills

| # | Skill | When it triggers | Clients seen |
|---|---|---|---|
| 1 | `dbt-model-change-and-pr` | Add/alter a dbt column or model, open/review a PR, document YAML | Equip Foods, TSM, Adverio |
| 2 | `bq-validation-and-reconciliation` | "Verify this", dev-vs-prod, source-vs-warehouse, numbers don't tie | all |
| 3 | `cohort-ltv-and-launch-analysis` | Cohorts, LTV, OTP vs subscription, flavour/product launches, incrementality | TSM, Equip Foods |
| 4 | `insight-dashboards-and-reports` | HTML dashboards, short .docx reports, "hook" decks, findings write-ups | TSM, Equip Foods |
| 5 | `connector-migration-and-brd` | Triple Whale / ShopifyQL / RPA connector work, BRDs, validation handoffs | TSM |
| 6 | `shopify-traffic-reconciliation` | Daton ShopifyQL tables vs RPA, upsert-key bloat, funnel sanity checks | TSM |
| 7 | `amazon-dashboard-metric-catalog` | Use-case maps, metric catalogs, Luzmo datasets, brand onboarding in master sheets | Adverio |
| 8 | `client-and-team-comms` | Draft Slack/client messages, DE-agent briefs, action-item extraction, prompt enhancing | all |
| 9 | `bigquery-mcp-and-toolbox-setup` | Connect BigQuery to Claude (MCP / toolbox), service accounts, permission walls | all |
| 10 | `client-playbooks` | Client-specific facts: table paths, definitions, gotchas | TSM, Equip Foods, Adverio |

## Gaps — please fill in
- **Simply Sales** and **Commerce Labs** do not appear in any session I can read. No work is invented for them.
  Add a section to `client-playbooks` (template at the bottom of that file) or paste/attach the sessions
  and I will extend the skills.
- Sessions whose detail I only saw as one-line summaries (so skills are thinner there):
  Gummies tab attribution, Cancelled orders included, Product categories dbt model,
  EquipFoods iQ adoption analysis, TikTok access.
- Code sessions: this repo only contains a `.gitignore`; the code work lives in other branches
  (e.g. `claude/bigquery-connection-7g40ib`) that are not attached to this session.

## Using them
Each skill is a folder with a `SKILL.md` under `.claude/skills/`. Claude Code loads them automatically
in this repo. To use everywhere, copy the folders to `~/.claude/skills/`.
