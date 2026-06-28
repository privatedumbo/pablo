# Bootstrap scripts — the canonical runbook

Idempotent step-scripts that rebuild Pablo from zero on a fresh Hetzner VPS.
**The scripts are the source of truth** for *how* to stand the system up; the
*why* lives in [ADR](../docs/adr/README.md), the *vocabulary* in
[CONTEXT.md](../CONTEXT.md). Recovery is **stateless** (ADR-0005): a rebuilt
Pablo is config-identical but starts with empty memory.

## Quick start

```bash
cp .env.example .env && $EDITOR .env   # fill secrets (source of truth, ADR-0005)
git config core.hooksPath .githooks    # enable the secret-blocking pre-commit hook
scripts/bootstrap.sh                    # 00→30 automated, then guides you
scripts/40-authenticate.sh             # Nous + 2× Google + Linear logins (needs a TTY)
scripts/50-gateway.sh                  # Telegram gateway as a boot service
```

Run a subrange (e.g. skip provisioning against the live box):
`VPS_IP=<vps-ip> scripts/bootstrap.sh 10 30`. The live host IP is kept out of
this repo — resolve it with `hcloud server ip hermes` or pass `VPS_IP=…`.

## What runs, in order

| Script | Does | Automated? |
|---|---|---|
| `00-provision.sh` | Create the Hetzner VPS (`cpx22`, `ubuntu-24.04`, `nbg1`, name `hermes`); upload SSH key; wait for SSH. | ✅ |
| `10-install-agent.sh` | Install Hermes on the box. | ✅ |
| `20-workspace-mcp.sh` | Install `uv` + the self-hosted Google Workspace MCP `systemd` unit (localhost:8000 only). | ✅ |
| `30-install-profile.sh` | Install this profile; push Telegram secrets. | ✅ |
| `40-authenticate.sh` | **Interactive** paste-back logins: Nous Account + both Google accounts + Linear. | ❌ TTY |
| `50-gateway.sh` | Install the Telegram gateway as a boot-time system service. | ✅ |
| `bootstrap.sh` | Orchestrator for `00`→`30`. | — |
| `lib.sh` | Shared helpers (sourced, not run). Server spec knobs live here. | — |

Every step is idempotent: safe to re-run after a mid-bootstrap failure. Config
knobs (`SERVER_TYPE`, `SERVER_LOCATION`, …) are overridable via env; see
`lib.sh`.

## Prerequisites

- **`hcloud` CLI** — `brew install hcloud` (macOS) or from
  [releases](https://github.com/hetznercloud/cli/releases).
- A local **SSH key** at `~/.ssh/id_ed25519` (`ssh-keygen -t ed25519` if missing).
- A filled **`.env`** (see Secrets below).

## Secrets

The local **`.env`** (repo root, copied from
[`.env.example`](../.env.example)) is the single source of truth. It is
**gitignored and never committed** — verify with
`git status --porcelain | grep .env` (must print nothing). The scripts push
secrets to the VPS **over SSH stdin**, never echoed. **Verify a secret before
relying on it** — most rebuild failures are bad credentials, not bad config.

| Key | Source | Lives on VPS in | Verify |
|---|---|---|---|
| `HCLOUD_TOKEN` | Hetzner console → Security → API Tokens (**Read & Write**) | — (local only) | `hcloud server list` |
| `TELEGRAM_BOT_TOKEN` | @BotFather → `/newbot` or `/token` | `~/.hermes/.env` | `getMe` (below) |
| `TELEGRAM_ALLOWED_USERS` | @userinfobot (your numeric id) | `~/.hermes/.env` | message the bot |
| `GOOGLE_OAUTH_CLIENT_ID` | Google Cloud → Credentials → OAuth client | `/root/.workspace-mcp.env` | server starts |
| `GOOGLE_OAUTH_CLIENT_SECRET` | same OAuth client (**confidential**, ADR-0004) | `/root/.workspace-mcp.env` | login completes |

Plus the **Nous Account** OAuth refresh token — created interactively by
`40-authenticate.sh`, stored only on the VPS at `~/.hermes/auth.json`, never in
`.env`.

**Verify a Telegram token without printing it:**

```bash
set -a; . ./.env; set +a
curl -s -o /tmp/tg.json "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getMe"
python3 -c 'import json;d=json.load(open("/tmp/tg.json"));print(d.get("ok"), d.get("result",{}).get("username") or d.get("description"))'
```

**Rotation:** regenerating a token (Telegram `/token`, Hetzner re-issue, Google
secret) invalidates the old one immediately. Update `.env`, re-push, restart the
affected service (`hermes-gateway` or `workspace-mcp`). On-disk secret files
(`~/.hermes/.env`, `/root/.workspace-mcp.env`) are `chmod 600`.

## Manual steps the scripts can't do

**Google Cloud OAuth client (once)** — clickops in `console.cloud.google.com`.
One client authorizes *both* Google accounts; separation happens at login.

1. Create a project.
2. **APIs & Services → Library** → enable **Gmail API** and **Google Calendar API**.
3. **OAuth consent screen** → External → add **both** Google addresses as **test
   users** (unlisted accounts are blocked in testing mode).
4. **Credentials → Create OAuth client ID** → a **confidential** client with a
   **secret** (required, ADR-0004) and redirect URI
   `http://localhost:8000/oauth2callback`.
5. Put `GOOGLE_OAUTH_CLIENT_ID` + `GOOGLE_OAUTH_CLIENT_SECRET` in `.env`.

> If the **Work Google Account** is company-managed, an admin may block the app.

**Interactive logins** (driven by `40-authenticate.sh`, needs a TTY):

- **Nous** — `hermes auth add nous … --no-browser --manual-paste`: open the
  printed URL, sign in, paste the redirect URL back.
- **Google** — open an SSH tunnel (`ssh -L 8000:localhost:8000 root@<VPS_IP>`),
  then `hermes mcp login google_personal` / `google_work` (sign work in via
  incognito). For each: open the `localhost:8000/authorize` URL → sign in → copy
  the final `127.0.0.1:<port>/callback?code=…` URL (it errors — expected) →
  paste it back **within ~1 min** (the code is single-use). Then
  `systemctl restart hermes-gateway`; `hermes mcp list` should show
  `google_personal` = all, `google_work` = `11 selected` (read-only allowlist).
- **Linear** — `hermes mcp login linear`: official remote MCP at
  `https://mcp.linear.app/mcp`. Public OAuth endpoint, so **no SSH tunnel** is
  needed. Open the printed authorize URL, sign in to the `privatedumbo`
  workspace, paste the callback URL back, then `systemctl restart
  hermes-gateway`. `hermes mcp list` should show `linear` connected.

## Gotchas

- **`hcloud: … unauthorized`** — token invalid, expired, or **Read-only**. Mint a
  fresh **Read & Write** token; verify with `hcloud server list` *first*.
- **`exit code 1` in `journalctl` on restart is normal** — Hermes exits on
  SIGTERM and `systemd`'s `Restart=on-failure` revives it. Trust
  `~/.hermes/logs/agent.log` over journald.
- **System service refuses to run as root** without `--run-as-user root` — present
  by design (single-operator box).
- **Telegram bot ignores `/start`** — message it with **real text** to test.
- **Google `server_error` at `/authorize`** → URL/base-URI mismatch; use
  `localhost` (not `127.0.0.1`) on both sides (ADR-0004).
- **Google `client_secret is missing`** at token exchange → the OAuth client must
  be confidential (ADR-0004).
- **`workspace-mcp` `exit code 1` loop right after start** → transient `:8000`
  bind conflict; `systemctl restart` once it settles.
- `hermes mcp test <name>` lists *raw* server tools and ignores per-entry
  filters; check the agent-facing view with `hermes mcp list`.

## Guardrails

This repo is public, so secrets must never land in a commit. Two layers:

- **GitHub push protection** (secret scanning) — server-side, blocks pushes
  containing known secret formats.
- **Local pre-commit hook** — enable once: `git config core.hooksPath .githooks`.
  Blocks staged `.env`/`auth.json`/`mcp-tokens`, secret-looking values, and
  public host IPs.

> **Not yet validated end-to-end.** Authored from the original runbooks for the
> named `pablo` profile. Lines tagged `NOTE (verify at test-install)` —
> named-profile flag scoping (`--profile pablo`), `profile update` syntax, and the
> gateway service name — get confirmed on the first real rebuild.
