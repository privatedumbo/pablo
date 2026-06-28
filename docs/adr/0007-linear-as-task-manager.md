# 0007 — Linear as Pablo's task manager via the official remote MCP

- **Status:** accepted
- **Date:** 2026-06-28

## Context

Franco wants to capture task-like requests in conversation ("Pablo, I want to do
this tomorrow") as durable, trackable items, and to keep those **separate from
the calendar**: tasks belong in a task manager, the Google Calendar is reserved
for appointments (meetings, calls, time-bound events).

Before this, Pablo's only persistence surfaces were Gmail/Calendar via the
self-hosted Google Workspace MCP. Capturing a task therefore meant either an
awkward calendar event or nothing at all.

Linear is already Franco's tracker for engineering work (workspace
`privatedumbo`, team `FRA`, project `Pablo`) and it ships an official **remote**
MCP server at `https://mcp.linear.app/mcp` (OAuth 2.1, dynamic client
registration), which matches the `auth: oauth` pattern Pablo already uses.

## Decision

Add a third MCP entry, `linear`, pointing at Linear's hosted remote MCP. Pablo
treats it as a **task manager** and routes by intent:

- Task-like requests → create a Linear issue.
- Appointments / events → Google Calendar, unchanged.

Behavioral contract lives in `SOUL.md`. Defaults when creating a task, unless
Franco says otherwise: **project `Pablo`**, **team `FRA`**, **state `Todo`**, and
a **due date** mapped from relative language ("tomorrow" = current date + 1).
Linear due dates are date-only, which reinforces the tasks-vs-appointments split.

Authentication is a fourth interactive login in `scripts/40-authenticate.sh`.
Because the endpoint is a public remote server (not the localhost Google MCP), it
needs **no SSH tunnel** — just `hermes -p pablo mcp login linear` and a
paste-back of the callback URL.

## Consequences

- Pablo gains create/find/update access to Linear issues, projects, and comments.
- Tasks and appointments stay cleanly separated by surface (Linear vs Calendar),
  matching how Franco already works.
- One more credential to manage and re-authenticate on a rebuild; recovery is
  still stateless (ADR-0005) — the login is re-done in step 40.
- Pablo's Linear scope is the whole personal workspace via OAuth; unlike the work
  Google entry it is **not** read-only allowlisted. Tightening later (a
  `tools.include` allowlist) is possible if write scope proves too broad.

## Alternatives considered

- **Calendar-only (status quo)**: rejected — conflates tasks with appointments,
  the exact split Franco wants to preserve.
- **Self-host an MCP for a different task tool**: rejected — Linear is already the
  tracker, and its hosted remote MCP removes the operational burden that ADR-0002
  accepted only because Google offered no suitable hosted option.
- **Reuse the company `LINEAR_API_KEY` / engineering-skills config**: rejected —
  that path is for the repo's engineering skills (`/to-epic`, `/to-issues`), not
  the running agent. Pablo authenticates via OAuth against the personal workspace,
  keeping the agent's credential independent and revocable.
