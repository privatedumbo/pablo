#!/usr/bin/env bash
# Step 40 — INTERACTIVE logins. These cannot be automated (human paste-back).
# Mirrors agent.md › Model+tools (Nous) and google-workspace.md › 4 (logins).
#
# Run this from your own terminal — it needs a TTY. Each login is single-use and
# time-boxed (~1 min), so do them deliberately, one at a time.
#
# Verified: profile flag is `-p pablo` (mcp/config confirmed on the live box).
# Still unverified here: `auth add nous` + `mcp login` under `-p` (interactive).
set -euo pipefail
. "$(dirname "$0")/lib.sh"

ip="$(vps_ip)"

cat <<EOF

  ── Pablo authentication (interactive) ───────────────────────────────
  Three logins, into profile '$PROFILE':
    1) Nous Account   — paste-back, no tunnel
    2) google_personal — full access
    3) google_work     — read-only (11 tools)
  ─────────────────────────────────────────────────────────────────────

EOF

# 1) Nous — open the printed URL, sign in, paste the redirect URL back.
read -r -p "Authenticate the Nous Account now? [y/N] " a; [ "$a" = y ] && \
  sshi "hermes -p '$PROFILE' auth add nous --type oauth --no-browser --manual-paste"

# 2+3) Google — needs a tunnel so Google's redirect reaches the VPS:8000.
read -r -p "Log in the two Google accounts now? [y/N] " a
if [ "$a" = y ]; then
  log "opening SSH tunnel localhost:8000 → VPS:8000 (background)…"
  ssh -fNL 8000:localhost:8000 -o ExitOnForwardFailure=yes "root@$ip"
  tunnel_pid=$!
  trap '[ -n "${tunnel_pid:-}" ] && kill "$tunnel_pid" 2>/dev/null || true' EXIT

  echo; log "PERSONAL account — open the localhost:8000/authorize URL, sign in, paste the callback URL back:"
  sshi "hermes -p '$PROFILE' mcp login google_personal"

  echo; log "WORK account — use an incognito window, sign in with the WORK address:"
  sshi "hermes -p '$PROFILE' mcp login google_work"

  kill "$tunnel_pid" 2>/dev/null || true; trap - EXIT
  log "logins done; restarting gateway to pick up tokens"
  ssh_do "systemctl restart hermes-gateway || true"
fi

echo; log "verify: ssh root@$ip 'hermes -p $PROFILE mcp list'  → google_work = 11 selected"
