#!/usr/bin/env bash
# Pablo bootstrap orchestrator — rebuild the whole system from zero.
# Runs the step scripts in order. Stops at the interactive wall (step 40) unless
# you opt in, because Nous + Google logins need a human at the keyboard.
#
# Usage:
#   scripts/bootstrap.sh            # 00→30 automated, then guide you to 40/50
#   scripts/bootstrap.sh --all      # also run 40 (interactive) and 50
#   VPS_IP=<vps-ip> scripts/bootstrap.sh 30 50   # run a subrange (skip provision)
#
# Every step is idempotent — safe to re-run after a mid-bootstrap failure.
set -euo pipefail
cd "$(dirname "$0")"

AUTOMATED=(00-provision 10-install-agent 20-workspace-mcp 30-install-profile)
INTERACTIVE=(40-authenticate 50-gateway)

run() { echo; echo "════ $1 ════"; "./$1.sh"; }

case "${1:-}" in
  --all) for s in "${AUTOMATED[@]}" "${INTERACTIVE[@]}"; do run "$s"; done ;;
  "")
    for s in "${AUTOMATED[@]}"; do run "$s"; done
    cat <<'EOF'

  ── Automated steps done. Two interactive steps remain (human paste-back) ──
    scripts/40-authenticate.sh   # Nous + both Google logins (needs a TTY)
    scripts/50-gateway.sh        # Telegram gateway as a boot service
  Or re-run with:  scripts/bootstrap.sh --all
EOF
    ;;
  *) # explicit list of step name-prefixes, e.g. `bootstrap.sh 30 50`
    for arg in "$@"; do
      match="$(printf '%s\n' "${AUTOMATED[@]}" "${INTERACTIVE[@]}" | grep "^$arg" || true)"
      [ -n "$match" ] || { echo "no step matches '$arg'" >&2; exit 1; }
      run "$match"
    done ;;
esac
