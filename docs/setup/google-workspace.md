# Google Workspace

Give the Agent Gmail + Calendar for **two** Google Accounts (personal + work),
kept separate, via the self-hosted Google Workspace MCP. Background:
ADR-0002 (self-host), ADR-0003 (two entries), ADR-0004 (OAuth 2.1).

## 1. Google Cloud OAuth client (once)

Done once — one client authorizes *both* accounts (separation happens at login).

1. `console.cloud.google.com` → create a project.
2. **APIs & Services → Library** → enable **Gmail API** and **Google Calendar
   API**.
3. **OAuth consent screen** → External → **add both** Google addresses as **test
   users** (unlisted accounts are blocked in testing mode).
4. **Credentials → Create OAuth client ID** → a **confidential** client with a
   **secret** (required — see ADR-0004) and redirect URI
   `http://localhost:8000/oauth2callback`.
5. Put `GOOGLE_OAUTH_CLIENT_ID` + `GOOGLE_OAUTH_CLIENT_SECRET` in `.env`.

> If the **Work Google Account** is company-managed, an admin may block the app.

## 2. The server (systemd, localhost-only)

```bash
# install the runtime
ssh root@<VPS_IP> 'curl -LsSf https://astral.sh/uv/install.sh | sh'

# /root/.workspace-mcp.env  (client id+secret pushed via stdin; see credentials.md)
MCP_ENABLE_OAUTH21=true
WORKSPACE_MCP_PORT=8000
WORKSPACE_MCP_HOST=127.0.0.1
GOOGLE_OAUTH_REDIRECT_URI=http://localhost:8000/oauth2callback
OAUTHLIB_INSECURE_TRANSPORT=1
GOOGLE_MCP_CREDENTIALS_DIR=/root/.google_workspace_mcp/credentials
FASTMCP_SERVER_AUTH_GOOGLE_JWT_SIGNING_KEY=<openssl rand -hex 32>
GOOGLE_OAUTH_CLIENT_ID=…
GOOGLE_OAUTH_CLIENT_SECRET=…
```

systemd unit `workspace-mcp.service` runs:
`/root/.local/bin/uvx workspace-mcp --transport streamable-http --tools gmail calendar`
(`EnvironmentFile=/root/.workspace-mcp.env`, `Restart=on-failure`). Then
`systemctl enable --now workspace-mcp`. It must listen on `127.0.0.1:8000` only.

## 3. Two MCP entries

Append to `~/.hermes/config.yaml` — note **`localhost`**, not `127.0.0.1` (ADR-0004):

```yaml
mcp_servers:
  google_personal:
    url: "http://localhost:8000/mcp"
    auth: oauth
  google_work:
    url: "http://localhost:8000/mcp"
    auth: oauth
    tools:
      include: [get_events, get_gmail_attachment_content, get_gmail_message_content,
                get_gmail_messages_content_batch, get_gmail_thread_content,
                get_gmail_threads_content_batch, list_calendars, list_gmail_filters,
                list_gmail_labels, query_freebusy, search_gmail_messages]
```

The `tools.include` allowlist makes the **Work Google Account read-only** (read
tools only; no send/modify/delete). Drop the block to grant full access.

## 4. Log in each account (headless)

```bash
# terminal 1 — tunnel so Google's redirect reaches the VPS:
ssh -L 8000:localhost:8000 root@<VPS_IP>

# terminal 2 — once per account:
ssh root@<VPS_IP> -t 'hermes mcp login google_personal'   # sign in PERSONAL
ssh root@<VPS_IP> -t 'hermes mcp login google_work'       # sign in WORK (incognito)
```

For each: open the `localhost:8000/authorize` URL → sign in → copy the final
`127.0.0.1:<port>/callback?code=…` URL (it errors — expected) → paste it back at
the prompt **within ~1 min** (the code is single-use).

Then `systemctl restart hermes-gateway`. Verify: `hermes mcp list` shows
`google_personal` = all, `google_work` = `11 selected`.

## Gotchas

- **`server_error` at `/authorize`** → resource mismatch: the entry URL and the
  server's base URI must match exactly. Use `localhost` on both sides.
- **`client_secret is missing`** at token exchange → the OAuth client must be
  confidential (have a secret). See ADR-0004.
- **`exit code 1` loop right after start** → a transient `:8000` bind conflict
  from the restart loop; `systemctl restart` once it settles.
- `hermes mcp test <name>` lists *raw* server tools and ignores the per-entry
  filter; check the agent-facing view with `hermes mcp list`.
