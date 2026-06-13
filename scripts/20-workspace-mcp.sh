#!/usr/bin/env bash
# Step 20 — Self-hosted Google Workspace MCP server (systemd, localhost-only).
# Mirrors docs/setup/google-workspace.md › 2.  See ADR-0002, ADR-0004.
# Idempotent: reuses the existing JWT signing key so re-runs don't break logins.
set -euo pipefail
. "$(dirname "$0")/lib.sh"

load_env
require_vars GOOGLE_OAUTH_CLIENT_ID GOOGLE_OAUTH_CLIENT_SECRET

# install uv runtime (idempotent installer)
ssh_do 'command -v uv >/dev/null 2>&1 || curl -LsSf https://astral.sh/uv/install.sh | sh' >/dev/null
log "uv runtime present"

# reuse an existing JWT signing key if one is already on the box, else mint one
jwt="$(ssh_do 'sed -n "s/^FASTMCP_SERVER_AUTH_GOOGLE_JWT_SIGNING_KEY=//p" /root/.workspace-mcp.env 2>/dev/null' || true)"
if [ -z "$jwt" ]; then
  jwt="$(ssh_do 'openssl rand -hex 32')"
  log "minted a new JWT signing key"
else
  log "reusing existing JWT signing key"
fi

# push the env file (over stdin; secrets never hit argv or the terminal)
printf '%s\n' \
  "MCP_ENABLE_OAUTH21=true" \
  "WORKSPACE_MCP_PORT=8000" \
  "WORKSPACE_MCP_HOST=127.0.0.1" \
  "GOOGLE_OAUTH_REDIRECT_URI=http://localhost:8000/oauth2callback" \
  "OAUTHLIB_INSECURE_TRANSPORT=1" \
  "GOOGLE_MCP_CREDENTIALS_DIR=/root/.google_workspace_mcp/credentials" \
  "FASTMCP_SERVER_AUTH_GOOGLE_JWT_SIGNING_KEY=$jwt" \
  "GOOGLE_OAUTH_CLIENT_ID=$GOOGLE_OAUTH_CLIENT_ID" \
  "GOOGLE_OAUTH_CLIENT_SECRET=$GOOGLE_OAUTH_CLIENT_SECRET" \
  | put_remote /root/.workspace-mcp.env 600

# systemd unit
printf '%s\n' \
  "[Unit]" \
  "Description=Google Workspace MCP (Gmail + Calendar)" \
  "After=network-online.target" \
  "Wants=network-online.target" \
  "" \
  "[Service]" \
  "EnvironmentFile=/root/.workspace-mcp.env" \
  "ExecStart=/root/.local/bin/uvx workspace-mcp --transport streamable-http --tools gmail calendar" \
  "Restart=on-failure" \
  "RestartSec=3" \
  "" \
  "[Install]" \
  "WantedBy=multi-user.target" \
  | put_remote /etc/systemd/system/workspace-mcp.service 644

ssh_do 'systemctl daemon-reload && systemctl enable --now workspace-mcp'
sleep 3
ssh_do 'systemctl restart workspace-mcp'   # clears any transient :8000 bind conflict (gotcha)
if ssh_do 'systemctl is-active --quiet workspace-mcp'; then
  log "workspace-mcp is active on 127.0.0.1:8000"
else
  die "workspace-mcp failed to start — check: ssh root@$(vps_ip) journalctl -u workspace-mcp -n 50"
fi
