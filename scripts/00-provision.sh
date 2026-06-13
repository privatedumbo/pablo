#!/usr/bin/env bash
# Step 00 — Provision the Hetzner VPS.  Mirrors docs/setup/provisioning.md.
# Idempotent: skips key upload / server create if they already exist.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

command -v hcloud >/dev/null || die "hcloud CLI not installed (brew install hcloud)"
[ -f "$SSH_KEY_FILE.pub" ] || die "no SSH public key at $SSH_KEY_FILE.pub (ssh-keygen -t ed25519)"

load_env
require_vars HCLOUD_TOKEN
export HCLOUD_TOKEN

hcloud server list >/dev/null 2>&1 || die "hcloud unauthorized — mint a fresh Read & Write token"

# upload public key (idempotent — ignore 'already exists')
hcloud ssh-key create --name "$SSH_KEY_NAME" --public-key-from-file "$SSH_KEY_FILE.pub" 2>/dev/null \
  && log "uploaded SSH key '$SSH_KEY_NAME'" \
  || log "SSH key '$SSH_KEY_NAME' already present"

# create the server only if missing
if hcloud server describe "$SERVER_NAME" >/dev/null 2>&1; then
  log "server '$SERVER_NAME' already exists — skipping create"
else
  log "creating server '$SERVER_NAME' ($SERVER_TYPE / $SERVER_IMAGE / $SERVER_LOCATION)…"
  hcloud server create --name "$SERVER_NAME" --image "$SERVER_IMAGE" \
    --type "$SERVER_TYPE" --location "$SERVER_LOCATION" --ssh-key "$SSH_KEY_NAME"
fi

ip="$(hcloud server ip "$SERVER_NAME")"
log "server IP: $ip"

# wait for SSH to come up
log "waiting for SSH…"
for _ in $(seq 1 30); do
  if ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "root@$ip" echo ok >/dev/null 2>&1; then
    log "SSH ready on $ip"; exit 0
  fi
  sleep 5
done
die "SSH did not become ready on $ip"
