# Cohorts dashboard — BigQuery views

Layers (deploy order = folder/number order): `01_staging` (only place with raw table names — ASSUMED, confirm) →
`02_intermediate` (cohort logic) → `03_marts` (app grains) → `04_reporting` (dashboard-shaped views / table functions).

```
PROJECT=my-project DATASET=cohorts_dashboard LOCATION=US ./deploy.sh --dry-run   # validate
PROJECT=my-project DATASET=cohorts_dashboard LOCATION=US ./deploy.sh             # deploy
```
Start with `00_discovery/discover_sources.sql`. Full metric/source documentation: `../docs/metrics_and_sources.md`.
Status: syntax-checked with sqlglot (BigQuery dialect); NOT executed against BigQuery or data.
