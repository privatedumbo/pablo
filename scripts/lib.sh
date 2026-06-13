#!/usr/bin/env bash
# Shared helpers for the Pablo bootstrap scripts.
# Sourced by every step script; not run directly.
#
# Conventions:
#   - The local repo-root .env is the source of truth for secrets (ADR-0005).
#   - Secrets are pushed to the VPS over SSH stdin, never echoed (credentials.md).
#   - Every step is idempotent: safe to re-run after a mid-bootstrap failure.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# --- config knobs (override via env) ---
SERVER_NAME="${SERVER_NAME:-hermes}"
SERVER_TYPE="${SERVER_TYPE:-cpx22}"
SERVER_IMAGE="${SERVER_IMAGE:-ubuntu-24.04}"
SERVER_LOCATION="${SERVER_LOCATION:-nbg1}"
SSH_KEY_NAME="${SSH_KEY_NAME:-pablo}"
SSH_KEY_FILE="${SSH_KEY_FILE:-$HOME/.ssh/id_ed25519}"
PROFILE="${PROFILE:-pablo}"
DISTRIBUTION="${DISTRIBUTION:-github.com/privatedumbo/pablo}"

log()  { printf '\033[1;34m[pablo]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[pablo] WARN:\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m[pablo] ERROR:\033[0m %s\n' "$*" >&2; exit 1; }

# Load the local .env into the environment (secrets stay out of argv).
load_env() {
  [ -f "$REPO_ROOT/.env" ] || die "missing $REPO_ROOT/.env — copy .env.example and fill it in"
  set -a; . "$REPO_ROOT/.env"; set +a
}

require_vars() {
  for v in "$@"; do
    [ -n "${!v:-}" ] || die "required var \$$v is empty (check .env)"
  done
}

# Resolve the VPS IP: explicit $VPS_IP wins, else ask hcloud.
vps_ip() {
  if [ -n "${VPS_IP:-}" ]; then printf '%s' "$VPS_IP"; return; fi
  command -v hcloud >/dev/null || die "hcloud not installed and \$VPS_IP unset"
  hcloud server ip "$SERVER_NAME" 2>/dev/null || die "cannot resolve IP for server '$SERVER_NAME'"
}

# ssh wrappers (non-interactive by default; sshi for interactive/tty steps).
ssh_do()  { ssh -o BatchMode=yes -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "root@$(vps_ip)" "$@"; }
sshi()    { ssh -t -o ConnectTimeout=10 -o StrictHostKeyChecking=accept-new "root@$(vps_ip)" "$@"; }

# Write stdin to a remote file atomically (mode 600). Usage: printf ... | put_remote /path
put_remote() {
  local dest="$1" mode="${2:-600}"
  ssh_do "umask 177; cat > '$dest.tmp' && chmod $mode '$dest.tmp' && mv '$dest.tmp' '$dest'"
  log "wrote $dest (mode $mode) on the VPS"
}
