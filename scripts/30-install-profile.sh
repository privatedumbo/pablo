#!/usr/bin/env bash
# Step 30 — Install the Pablo profile distribution + push the profile's secrets.
# This replaces the old hand-run `hermes config set` / mcp_servers append:
# config.yaml, SOUL.md, and the two MCP entries now ship in the distribution.
# Idempotent: installs if absent, updates in place if present.
#
# Verified on the live box: `--name/--alias/-y` work; profile flag is `-p`.
# `profile update <name>` syntax still unverified (only used on re-install).
set -euo pipefail
. "$(dirname "$0")/lib.sh"

load_env
require_vars TELEGRAM_BOT_TOKEN TELEGRAM_ALLOWED_USERS

if ssh_do "hermes profile list 2>/dev/null | grep -q '\\b$PROFILE\\b'"; then
  log "profile '$PROFILE' exists — updating from $DISTRIBUTION"
  ssh_do "hermes profile update '$PROFILE'"
else
  log "installing profile '$PROFILE' from $DISTRIBUTION"
  ssh_do "hermes profile install '$DISTRIBUTION' --name '$PROFILE' --alias -y"
fi

# push Telegram secrets into the profile .env (env_requires in distribution.yaml)
printf '%s\n' \
  "TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN" \
  "TELEGRAM_ALLOWED_USERS=$TELEGRAM_ALLOWED_USERS" \
  | put_remote "/root/.hermes/profiles/$PROFILE/.env" 600

log "profile '$PROFILE' installed/updated; Telegram secrets in place"
log "config check: ssh root@$(vps_ip) hermes -p $PROFILE config show"
