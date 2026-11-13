---
name: bigquery-mcp-and-toolbox-setup
description: Connect Claude to client BigQuery (MCP server / MCP Toolbox / service account), debug auth and permission walls, and keep credentials out of git. Use when a session starts with "connect BigQuery", "MCP server configuration", or "file too huge".
---

# BigQuery MCP / toolbox setup

## Seen repeatedly (Aug–Oct 2026)
Eight sessions opened as "BigQuery connection / MCP BigQuery server configuration / Daton project connection /
TSM connection / Trueseamoss connection". Typical state reached: "BigQuery connected to `daton-project`; 7 datasets visible
(analytics, trueseamoss staging/prod shares)".

## Steps
1. Choose the path: Google's MCP Toolbox for Databases on the user's PC (needed when the sandbox cannot reach BigQuery or a
   result file is too large), or a hosted toolbox, or user-pasted query results.
2. Service account JSON + MCP config stay **local and git-ignored** (this repo's `.gitignore` exists for that reason).
   Never print keys; the config path may be off-limits to scripts — run comparisons inside BigQuery via the connector.
3. Verify with `SELECT 1`, list datasets, then inspect one table's schema. Remember schema listings can truncate (see
   `bq-validation-and-reconciliation`).
4. Permission walls: `bigquery.jobs.listAll` missing → cannot read `INFORMATION_SCHEMA.JOBS_BY_PROJECT`; say so and ask.
5. Large results: write to a file and slice, or aggregate in SQL; don't paste 100k rows.
6. Tool-environment limits learned: corporate laptop security (Sophos) blocks sites like TikTok — VPN won't help; use a
   personal device or request an IT allowlist.

## Project/dataset paths to remember
- Equip Foods: `insightsprod.equipfoods_5642_prod_main.dim_orders`
- TSM: `insightsprod.trueseamoss_5363_prod_raw.*`, `insightsprod.trueseamoss_daton.*`, prod DAG `trueseamoss_5363_prod`
- Adverio: `adveriodatondw.daton_raw_data.*`
- Shared: `daton-project`, `solutionsdw` (dev tables), `dev_edm` (test schema)

## Cloud sessions
$100 credit applies to cloud sessions only; regular chat uses the plan's standard allocation.
