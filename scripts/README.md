# Bootstrap scripts

Idempotent step-scripts that rebuild Pablo from zero. Each mirrors one of the
[setup runbooks](../docs/setup/README.md) 1:1 — the runbook is the spec, the
script is the executable form. Recovery is **stateless** (ADR-0005): a rebuilt
Pablo is config-identical but starts with empty memory.

| Script | Mirrors | Automated? |
|---|---|---|
| `00-provision.sh` | `provisioning.md` | ✅ |
| `10-install-agent.sh` | `agent.md › Install` | ✅ |
| `20-workspace-mcp.sh` | `google-workspace.md › 2` | ✅ |
| `30-install-profile.sh` | `agent.md` + `credentials.md` (Telegram) | ✅ |
| `40-authenticate.sh` | `agent.md › Nous` + `google-workspace.md › 4` | ❌ interactive (paste-back) |
| `50-gateway.sh` | `agent.md › Telegram Gateway` | ✅ |
| `bootstrap.sh` | orchestrator | — |

```bash
cp .env.example .env && $EDITOR .env     # fill secrets (source of truth, ADR-0005)
scripts/bootstrap.sh                       # 00→30 automated, then guides you
scripts/40-authenticate.sh                 # Nous + 2× Google logins (needs a TTY)
scripts/50-gateway.sh                      # Telegram gateway as a boot service
```

Run a subrange (e.g. skip provisioning against the live box):
`VPS_IP=<vps-ip> scripts/bootstrap.sh 10 30`

## Guardrails

This repo is public, so secrets must never land in a commit. Two layers:

- **GitHub push protection** (secret scanning) — server-side, blocks pushes
  containing known secret formats.
- **Local pre-commit hook** — enable once: `git config core.hooksPath .githooks`.
  Blocks staged `.env`/`auth.json`/`mcp-tokens`, secret-looking values, and
  public host IPs.

> **Not yet validated end-to-end.** These were authored from the runbooks for the
> *named `pablo` profile*. Lines tagged `NOTE (verify at test-install)` —
> named-profile flag scoping (`--profile pablo`), `profile update` syntax, and the
> gateway service name — get confirmed on the first real run (roadmap step 2) and
> back-ported into `docs/setup/*` (step 3).
