#!/usr/bin/env bash
# Step 50 — Install the Telegram messaging gateway as a boot-time service.
# Mirrors docs/setup/agent.md › Telegram Gateway.
# Idempotent: the gateway installer is safe to re-run.
#
# Verified at cutover: gateway installs under `-p` as a profile-specific unit
# `hermes-gateway-<profile>` (NOT the shared hermes-gateway), and a named profile
# logs to ~/.hermes/profiles/<profile>/logs/agent.log.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

# Telegram transport dependency (quiet, idempotent)
ssh_do '/usr/local/lib/hermes-agent/venv/bin/python -m pip install -q python-telegram-bot'

# install + start as a system service (feeds the two y/n prompts)
ssh_do "printf 'y\\ny\\n' | hermes -p '$PROFILE' gateway install --system --run-as-user root"

log "waiting for the gateway to connect…"
sleep 6
svc="hermes-gateway-$PROFILE"
plog="/root/.hermes/profiles/$PROFILE/logs/agent.log"
if ssh_do "systemctl is-active --quiet '$svc' && grep -aq 'telegram connected\|Gateway running with' '$plog'"; then
  log "gateway connected ($svc). Message the bot with REAL text (not /start) to test."
else
  warn "not confirmed yet — check: ssh root@$(vps_ip) 'journalctl -u $svc -n 30 --no-pager; tail $plog'"
fi
