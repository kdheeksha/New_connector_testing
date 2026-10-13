#!/usr/bin/env bash
# Usage: PROJECT=my-gcp-project DATASET=cohorts_dashboard LOCATION=US ./deploy.sh [--dry-run]
# Creates the dataset if missing, then deploys every .sql in folder / numeric order (BigQuery validates view
# references at creation, so order matters). --dry-run validates syntax + references without creating anything
# (references to upstream views only resolve once those exist, so dry-run the staging layer first against real sources).
set -euo pipefail
: "${PROJECT:?}"; : "${DATASET:?}"; LOCATION="${LOCATION:-US}"
DRY=""; [[ "${1:-}" == "--dry-run" ]] && DRY="--dry_run"
cd "$(dirname "$0")"
[[ -z "$DRY" ]] && bq --project_id="$PROJECT" --location="$LOCATION" mk -f -d "$DATASET" || true
for f in 01_staging/*.sql 02_intermediate/*.sql 03_marts/*.sql 04_reporting/*.sql; do
  echo ">> $f"
  envsubst '${PROJECT} ${DATASET}' < "$f" | bq --project_id="$PROJECT" --location="$LOCATION" query --use_legacy_sql=false $DRY
done
