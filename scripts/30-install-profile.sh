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
  # --force-config: config.yaml ships in the distribution and is the source of
  # truth (ADR-0006), so overwrite it on update. User data (memory, sessions,
  # auth, .env) is NOT touched by profile update regardless of this flag —
  # without it, shipped config changes (e.g. new MCP entries) would never deploy.
  ssh_do "hermes profile update '$PROFILE' --force-config"
else
  log "installing profile '$PROFILE' from $DISTRIBUTION"
  ssh_do "hermes profile install '$DISTRIBUTION' --name '$PROFILE' --alias -y"
fi

# make pablo the sticky default so `hermes` (no -p) targets it, not the empty
# root profile. (The root 'default' profile cannot be deleted; this demotes it.)
ssh_do "hermes profile use '$PROFILE'"

# push Telegram secrets into the profile .env (env_requires in distribution.yaml)
printf '%s\n' \
  "TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN" \
  "TELEGRAM_ALLOWED_USERS=$TELEGRAM_ALLOWED_USERS" \
  | put_remote "/root/.hermes/profiles/$PROFILE/.env" 600

log "profile '$PROFILE' installed/updated; Telegram secrets in place"
log "config check: ssh root@$(vps_ip) hermes -p $PROFILE config show"
