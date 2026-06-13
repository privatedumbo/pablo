# Agent

Install Hermes, wire the model (Nous Portal), and run the Telegram Gateway as a
boot-time service. Assumes the [VPS](provisioning.md) and
[credentials](credentials.md) are ready.

## Install

```bash
ssh root@<VPS_IP> 'curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash'
```

`hermes` lands in `/usr/local/bin`; config in `~/.hermes/`.

## Model + tools (Nous Portal)

Authenticate the **Nous Account** (headless paste-back flow), then set the
provider and turn on Tool Gateway web search. See ADR-0001 for *why* Portal.

```bash
# interactive — run from your own terminal:
ssh root@<VPS_IP> -t 'hermes auth add nous --type oauth --no-browser --manual-paste'
# open the printed URL, sign in, paste the redirect URL back.

# then set config (non-interactive):
ssh root@<VPS_IP> '
  hermes config set model.provider nous
  hermes config set model.default anthropic/claude-sonnet-4.6
  hermes config set model.base_url https://inference-api.nousresearch.com/v1
  hermes config set web.backend firecrawl
  hermes config set web.use_gateway true
'
```

Verify: `hermes portal info` (provider = Nous, web search ✓) and
`hermes -z "Reply with OK"`.

## Telegram Gateway

```bash
# push the Telegram secrets (see credentials.md), then:
ssh root@<VPS_IP> '/usr/local/lib/hermes-agent/venv/bin/python -m pip install -q python-telegram-bot'

# install + start as a boot-time system service:
ssh root@<VPS_IP> "printf 'y\ny\n' | hermes gateway install --system --run-as-user root"
```

Verify it connected:

```bash
ssh root@<VPS_IP> 'grep -a "telegram connected\|Gateway running with" ~/.hermes/logs/agent.log | tail -2'
```

Then message the bot with **real text** (not `/start`, which Hermes ignores as a
ping).

## Gotchas

- **`exit code 1` in `journalctl` on restart is normal** — Hermes exits on
  SIGTERM so systemd's `Restart=on-failure` revives it. Trust `~/.hermes/logs/
  agent.log` over journald for the real status.
- **System service refuses to run as root** without `--run-as-user root`. That is
  why the flag is present (single-operator box).
- `hermes gateway install` prompts twice ("start now?", "start at boot?") — feed
  `printf 'y\ny\n'` when scripting.
- The model serves only after the Nous OAuth completes; `doctor` may show "API
  key configured" before a model is actually selected.

## Decisions referenced

- Telegram as the channel (easily swappable — not an ADR).
- Gateway runs as a root systemd service (single-operator box).

## Next

→ [Google Workspace](google-workspace.md)
