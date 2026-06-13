#!/usr/bin/env bash
# Step 50 — Install the Telegram messaging gateway as a boot-time service.
# Mirrors docs/setup/agent.md › Telegram Gateway.
# Idempotent: the gateway installer is safe to re-run.
#
# Verified: profile flag is `-p pablo`. Still unverified: gateway install under
# `-p` + the resulting service name (hermes-gateway vs profile-specific) —
# confirm at the gateway cutover (roadmap step 2.3).
set -euo pipefail
. "$(dirname "$0")/lib.sh"

# Telegram transport dependency (quiet, idempotent)
ssh_do '/usr/local/lib/hermes-agent/venv/bin/python -m pip install -q python-telegram-bot'

# install + start as a system service (feeds the two y/n prompts)
ssh_do "printf 'y\\ny\\n' | hermes -p '$PROFILE' gateway install --system --run-as-user root"

log "waiting for the gateway to connect…"
sleep 5
if ssh_do 'grep -aq "telegram connected\|Gateway running with" ~/.hermes/logs/agent.log'; then
  log "gateway connected. Message the bot with REAL text (not /start) to test."
else
  warn "no 'connected' line yet — tail it: ssh root@$(vps_ip) 'tail -f ~/.hermes/logs/agent.log'"
fi
