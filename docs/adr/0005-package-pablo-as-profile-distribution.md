# 0005 — Package Pablo as a profile distribution with bootstrap scripts

- **Status:** accepted (spec↔script mirror superseded by [0006](0006-scripts-as-canonical-runbook.md))
- **Date:** 2026-06-13

---

## Context

Pablo's entire definition — persona, model/web config, and the two Google
Workspace MCP entries — lived only on the VPS under `~/.hermes/`. None of it was
in version control. If the VPS died, there was no way to reconstruct the agent
except from memory and prose runbooks. We want a lost VPS to be a non-event: a
fresh box should come back as a functionally identical Pablo.

## Decision

Package Pablo-the-Agent as a **Hermes profile distribution** at the root of this
repo, and reconstruct everything around it (infrastructure, secrets, interactive
logins) with **idempotent bootstrap scripts that mirror the setup runbooks 1:1**.

- **Recovery target is stateless identity** — a rebuilt Pablo is config-identical
  but starts with empty memory/sessions. Persistent memory is deferred to a
  future application-level feature where Pablo writes to external storage, not a
  file backup of `~/.hermes/memories`.
- The distribution config is **seeded by extracting the live box** and
  sanitizing it (also a free drift audit against ADRs 0001–0004).
- The live box is **migrated to the named `pablo` profile now**, so what runs in
  prod and what the repo packages are the same thing — the distribution is
  continuously dogfooded rather than first executed during an outage.

## Consequences

- Pablo runs as a single **named** profile. This does **not** reverse ADR-0003:
  that rejected running *multiple* profiles for account separation; this adopts
  *one* profile as the packaging unit. Account separation remains two MCP entries
  with a read-only allowlist on the work entry.
- The empty Python scaffold (`pablo/`, `pyproject.toml`, tests, Docker/poe
  toolchain) is deleted — this is a config/scripts/docs repo, not a Python
  project.
- A one-time, deliberate re-auth (Nous Account + both Google Accounts) is
  required to migrate the live box to the named profile.

## Known residual risks (deferred)

- The laptop `.env` is the only durable copy of the non-OAuth secrets; a
  simultaneous laptop + VPS loss is unrecoverable, and rebuilds require that one
  laptop. Hardening (password manager or SOPS-in-repo) is deferred.
- Accumulated memory and conversation history do not survive a rebuild until the
  storage-writing feature exists.

## Alternatives considered

- **Config-as-code applied entirely by scripts** (no profile distribution): the
  bootstrap scripts already do the un-scriptable work (infra, secrets, OAuth), so
  scripting the config too was viable. Rejected because the distribution is the
  Hermes-native unit for capturing a profile as files — and "no config files for
  Pablo" was the actual problem being solved.
- **Two repos** (control repo + separate distribution repo with a clean
  profile-dir root): rejected to keep a single source of truth; the repo root
  becomes the profile directory instead.
