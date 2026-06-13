# Provisioning

Stand up the Hetzner VPS that hosts the Agent, the Gateway, and the Google
Workspace MCP.

## Prerequisites

- The `hcloud` CLI — `brew install hcloud` (macOS) or from the
  [releases](https://github.com/hetznercloud/cli/releases).
- A **Hetzner Account** API token with **Read & Write** scope
  (`console.hetzner.cloud` → project → Security → API Tokens), stored as
  `HCLOUD_TOKEN` — see [credentials](credentials.md).
- A local SSH key at `~/.ssh/id_ed25519` (`ssh-keygen -t ed25519` if missing).

## Spec

| Setting | Value |
|---|---|
| Type | `cpx22` (2 vCPU / 4 GB) — CPU-only; the model runs via Nous Portal, not locally |
| Image | `ubuntu-24.04` |
| Location | `nbg1` (Nuremberg) |
| Name | `hermes` |

## Steps

```bash
export HCLOUD_TOKEN=…            # from .env; verify it works first:
hcloud server list               # must succeed (not "unauthorized")

# upload the public key (idempotent)
hcloud ssh-key create --name pablo --public-key-from-file ~/.ssh/id_ed25519.pub

# create the server
hcloud server create \
  --name hermes --image ubuntu-24.04 --type cpx22 \
  --location nbg1 --ssh-key pablo

# get the public IP
hcloud server ip hermes
```

Then confirm SSH:

```bash
ssh root@<VPS_IP> echo ok
```

> The live host IP is intentionally kept out of this repo. Resolve it with
> `hcloud server ip hermes`, or pass it explicitly as `VPS_IP=… scripts/…`.

## Gotchas

- **`hcloud: ... unauthorized`** — the token is invalid, expired, or
  **Read-only**. Mint a fresh **Read & Write** token; verify with
  `hcloud server list` *before* anything else.
- The VPS is CPU-only. This is fine because inference is remote (Nous Portal); a
  local LLM would need a GPU host, which Hetzner Cloud does not provide.

## Next

→ [Credentials](credentials.md)
