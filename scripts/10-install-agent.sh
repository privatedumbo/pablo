#!/usr/bin/env bash
# Step 10 — Install the Hermes Agent on the VPS.  Mirrors docs/setup/agent.md › Install.
# Idempotent: skips if `hermes` is already on PATH.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

if ssh_do 'command -v hermes >/dev/null 2>&1'; then
  log "Hermes already installed: $(ssh_do 'hermes --version' | head -1)"
  exit 0
fi

log "installing Hermes…"
ssh_do 'curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash'
log "installed: $(ssh_do 'hermes --version' | head -1)"
