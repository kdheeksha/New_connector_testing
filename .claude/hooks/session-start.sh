#!/bin/bash
set -euo pipefail

# Only do this in Claude Code on the web / remote sessions.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# --- BigQuery access for TrueSeaMoss daton-project -------------------------
#
# Requires an environment secret named TSM_BQ_SA_B64: the service account
# JSON key, base64-encoded (one line). Set it in this environment's
# Environment Variables settings — never commit the key itself, and never
# paste its contents into a session.
#
# To produce the value locally from the key file:
#   base64 -w0 tsm_service_account.json     (Linux)
#   base64 -i tsm_service_account.json      (macOS)

if [ -n "${TSM_BQ_SA_B64:-}" ]; then
  CRED_DIR="$HOME/.config/tsm-bq"
  mkdir -p "$CRED_DIR"
  CRED_PATH="$CRED_DIR/service_account.json"

  echo "$TSM_BQ_SA_B64" | base64 -d > "$CRED_PATH"
  chmod 600 "$CRED_PATH"

  echo "export GOOGLE_APPLICATION_CREDENTIALS=\"$CRED_PATH\"" >> "$CLAUDE_ENV_FILE"
else
  echo "TSM_BQ_SA_B64 not set — skipping BigQuery credential setup. See .claude/hooks/session-start.sh for how to configure it." >&2
fi

# --- Python BigQuery client -------------------------------------------------
# Installed into a dedicated venv (not --user) to avoid colliding with the
# system cryptography/cffi packages already on the image.
VENV_DIR="$HOME/.venvs/tsm-bq"
if [ ! -x "$VENV_DIR/bin/python3" ]; then
  python3 -m venv "$VENV_DIR"
fi
"$VENV_DIR/bin/pip" install --quiet --upgrade pip
"$VENV_DIR/bin/pip" install --quiet google-cloud-bigquery

echo "export TSM_BQ_PYTHON=\"$VENV_DIR/bin/python3\"" >> "$CLAUDE_ENV_FILE"
