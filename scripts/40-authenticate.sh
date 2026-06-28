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
  Four logins, into profile '$PROFILE':
    1) Nous Account   — paste-back, no tunnel
    2) google_personal — full access
    3) google_work     — read-only (11 tools)
    4) linear          — task manager (remote MCP, no tunnel)
  ─────────────────────────────────────────────────────────────────────

EOF

# 1) Nous — open the printed URL, sign in, paste the redirect URL back.
read -r -p "Authenticate the Nous Account now? [y/N] " a
[[ $a == [Yy] ]] && \
  sshi "hermes -p '$PROFILE' auth add nous --type oauth --no-browser --manual-paste"

# 2+3) Google — needs a tunnel so Google's redirect reaches the VPS:8000.
read -r -p "Log in the two Google accounts now? [y/N] " a
if [[ $a == [Yy] ]]; then
  log "opening SSH tunnel localhost:8000 → VPS:8000 (background)…"
  # background with the shell's & (not ssh -f) so $! captures the PID under set -u
  ssh -NL 8000:localhost:8000 -o ExitOnForwardFailure=yes "root@$ip" &
  tunnel_pid=$!
  trap '[ -n "${tunnel_pid:-}" ] && kill "$tunnel_pid" 2>/dev/null || true' EXIT
  sleep 2   # let the forward establish before the login hits :8000

  echo; log "PERSONAL account — open the localhost:8000/authorize URL, sign in, paste the callback URL back:"
  sshi "hermes -p '$PROFILE' mcp login google_personal"

  echo; log "WORK account — use an incognito window, sign in with the WORK address:"
  sshi "hermes -p '$PROFILE' mcp login google_work"

  kill "$tunnel_pid" 2>/dev/null || true; trap - EXIT
  log "logins done; restarting gateway to pick up tokens"
  ssh_do "systemctl restart hermes-gateway || true"
fi

# 4) Linear — official remote MCP at https://mcp.linear.app/mcp.
# Public OAuth endpoint, so no SSH tunnel is needed (unlike the Google MCP).
read -r -p "Authenticate Linear now? [y/N] " a
if [[ $a == [Yy] ]]; then
  log "LINEAR — open the printed authorize URL, sign in to the privatedumbo workspace, paste the callback URL back:"
  sshi "hermes -p '$PROFILE' mcp login linear"
  log "restarting gateway to pick up the Linear token"
  ssh_do "systemctl restart hermes-gateway || true"
fi

echo; log "verify: ssh root@$ip 'hermes -p $PROFILE mcp list'  → google_work = 11 selected, linear connected"
