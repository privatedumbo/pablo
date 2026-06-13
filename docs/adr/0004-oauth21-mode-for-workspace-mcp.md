# 0004 — OAuth 2.1 mode for the self-hosted Google Workspace MCP

- **Status:** accepted
- **Date:** 2026-06-13

## Context

`workspace-mcp` exposes three mutually exclusive authentication modes:

- **OAuth 2.1** (`MCP_ENABLE_OAUTH21=true`) — multi-user, bearer-token auth over
  HTTP transport; the modern MCP-client path.
- **Single-user** — one Google account per server instance, email passed in
  tool calls; a legacy path.
- **Service account** — domain-wide delegation for headless server-to-server use.

We need two accounts reached through two Hermes entries that authenticate
independently (see ADR-0003). Hermes' native MCP client uses `auth: oauth`, and
the server maintainer recommends OAuth 2.1 for deployments.

## Decision

Run the server in **OAuth 2.1 mode** with streamable-HTTP transport, so each
Hermes entry's `auth: oauth` flow maps to a distinct Google account on a single
shared server instance.

## Consequences

- Aligns with Hermes' per-entry OAuth token isolation, giving the two-account
  separation of ADR-0003 on **one** server instance.
- Spec-compliant and the maintainer's recommended deployment mode.
- Requires a **confidential** Google OAuth client (a client *secret*): a
  public/PKCE Desktop client alone failed the Google token exchange with
  `invalid_request: client_secret is missing`. The secret is now supplied.
- The OAuth **resource indicator must match exactly** between Hermes' configured
  server URL and the server's self-identified base URI. `127.0.0.1` ≠ `localhost`
  produced an opaque `server_error` until both sides used `localhost`.
- Headless login requires OAuth-over-SSH: an `ssh -L` port-forward (so Google's
  redirect reaches the VPS) plus Hermes' paste-back of the final callback URL.

## Alternatives considered

- **Single-user mode**: simpler and no bearer auth, but one account per instance
  — it would force **two** server instances, and it cannot be combined with
  OAuth 2.1. Rejected because OAuth 2.1 serves both accounts from one server and
  matches Hermes' native per-entry OAuth.
- **Service account / domain-wide delegation**: for server-to-server use inside a
  Workspace org. Rejected — overkill, and inapplicable to a personal Gmail
  account.
