# 0006 — Bootstrap scripts are the canonical runbook

Status: Accepted
Supersedes: part of [0005](0005-package-pablo-as-profile-distribution.md) (the
spec↔script mirror)

## Context

ADR-0005 introduced `scripts/` as the executable form of `docs/setup/*` and
declared the runbook the spec and the script its 1:1 mirror. In practice the two
trees drifted (e.g. `provisioning.md` told you to `export HCLOUD_TOKEN` by hand
while `00-provision.sh` reads it from `.env` via `load_env`), and the duplication
made the setup unclear: a reader couldn't tell which tree was authoritative. The
command blocks in `docs/setup/*` mostly restated what the scripts already run.

## Decision

`scripts/` and `scripts/README.md` are the **single canonical runbook**. The
`docs/setup/` tree is removed. The irreducible, non-automatable knowledge it
carried is folded into `scripts/README.md`:

- prerequisites, the secret inventory, rotation, and verify-without-printing;
- the one-time Google Cloud OAuth client clickops (no script can do it);
- the interactive paste-back logins (Nous + both Google accounts);
- the consolidated gotchas.

`docs/adr/` (the *why*) and `CONTEXT.md` (the *vocabulary*) are unchanged.

## Consequences

- One place to read and one place to maintain; no spec↔script drift surface.
- `scripts/README.md` is heavier, but it is the thing you run, so the knowledge
  sits next to the executable form.
- Links in `README.md`, `docs/README.md`, and `CLAUDE.md` now point at
  `scripts/README.md` instead of `docs/setup/`.
- This narrows ADR-0005 but does not reverse it: Pablo is still a single named
  profile distribution rebuilt by idempotent bootstrap scripts.

## Alternatives considered

- **Keep the mirror, thin the duplicated command blocks to pointers.** Removes
  drift but leaves two trees and the "which is canonical?" ambiguity.
- **Delete `docs/setup/` outright.** Rejected — it would silently lose the
  OAuth-client clickops, rotation, and gotchas that no script captures.
