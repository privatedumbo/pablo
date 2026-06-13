# 0002 — Self-host the Google Workspace MCP

- **Status:** accepted
- **Date:** 2026-06-13

## Context

Gmail and Calendar are not native to Hermes — there is no catalog entry and no
built-in toolset. They reach the agent only through an MCP server. Two ways to
supply that server:

- **Self-hosted** — run the open-source Google Workspace MCP
  (`workspace-mcp`) on our own VPS, with our own Google Cloud OAuth client; the
  OAuth app and the resulting tokens live on infrastructure we control.
- **Hosted aggregator** — a third-party MCP (Composio / Zapier / Pipedream
  style) that hosts the server and brokers the Google OAuth for us.

The agent has terminal access and operates on **personal and work** mail and
calendar — sensitive data. Where the OAuth app and tokens live matters.

## Decision

Self-host `workspace-mcp` on the VPS (run via `uvx`, managed by systemd), bound
to `127.0.0.1` only, backed by our own Google Cloud OAuth client. Google tokens
are stored on our box.

## Consequences

- Full control and privacy: the OAuth app and the Google tokens are ours; no
  third party sits between the agent and the inbox/calendar.
- We own the setup and upkeep: a Google Cloud project, enabled Gmail/Calendar
  APIs, a consent screen with both accounts as test users, running and patching
  the server, and completing OAuth over SSH because the host is headless.
- The server is localhost-only and never exposed to the internet.
- More moving parts than a hosted option (one more service + a Google Cloud app).

## Alternatives considered

- **Hosted aggregator** (Composio / Zapier / Pipedream): the fastest path — they
  own the OAuth app and you just click "authorize" per account. Rejected because
  a third party would broker tokens to sensitive personal *and* work data, and we
  preferred to keep those credentials on infrastructure we control.
