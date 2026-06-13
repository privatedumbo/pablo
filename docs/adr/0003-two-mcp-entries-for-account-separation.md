# 0003 — Two MCP entries for personal/work separation

- **Status:** accepted
- **Date:** 2026-06-13

## Context

The agent must reach **two** Google accounts — personal and professional — and
keep them separate, while remaining a single assistant in one Telegram chat.
Hermes offers two separation boundaries:

- **Two MCP entries** — register the same self-hosted server twice under
  distinct names (`google_personal`, `google_work`). Hermes keys MCP servers by
  name, so each entry gets its own OAuth token (`mcp-tokens/<name>.json`) and its
  tools are namespaced (`google_work:get_events`).
- **Hermes profiles** — fully separate configurations (own `config.yaml`,
  sessions, and memory), with the Portal login shared across them.

## Decision

Use **two MCP entries** pointing at the one self-hosted server. Separation is
enforced at the credential/tool level: two token files, two namespaces, one
conversation. The work entry is additionally constrained read-only via a
`tools.include` allowlist.

## Consequences

- Separate, independently revocable credentials per account; the model cannot
  confuse which account a tool call hits (tools are namespaced).
- Both accounts live in the same assistant and the same Telegram chat — natural
  "check my **work** calendar" vs "**personal** inbox" routing.
- Personal and work **share one conversation context and memory** — separation is
  at the account/tool level, not the "brain" level.
- Restructuring later (e.g. to profiles) means re-auth and splitting memory.

## Alternatives considered

- **Hermes profiles**: a hard wall — separate memory, sessions, and config per
  account, Portal login shared automatically. Rejected as overkill: it would mean
  effectively two assistants (usually two bots) when the requirement was *one*
  assistant with two accounts. The memory wall wasn't needed; enforced credential
  separation was.
