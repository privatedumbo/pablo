# Pablo

A personal [Hermes](https://hermes-agent.nousresearch.com) agent, packaged as a
**profile distribution**. The root of this repo *is* Pablo's profile: persona
([`SOUL.md`](SOUL.md)), config ([`config.yaml`](config.yaml)), and the
[manifest](distribution.yaml). Secrets and runtime state are excluded by design.

Pablo runs headless on a Hetzner VPS, reachable from Telegram, with web search
and personal + work Gmail/Calendar (work is read-only) via a self-hosted Google
Workspace MCP.

## Rebuild Pablo

A lost VPS is not fatal. Recovery is **stateless** — a rebuilt Pablo is
config-identical but starts with empty memory (see
[ADR-0005](docs/adr/0005-package-pablo-as-profile-distribution.md)).

1. Provision the box and install Hermes — `scripts/` (mirror of
   [`docs/setup/`](docs/setup/README.md)).
2. Install this profile:
   ```bash
   hermes profile install github.com/privatedumbo/pablo --name pablo --alias
   ```
3. Restore secrets (`.env`) and complete the interactive logins (Nous + both
   Google accounts). See [`docs/setup/credentials.md`](docs/setup/credentials.md).

## Documentation

- **[Setup](docs/setup/README.md)** — stand the system up from zero, in order.
- **[Decisions (ADRs)](docs/adr/README.md)** — *why* it is built this way.
- **[Glossary](CONTEXT.md)** — the canonical domain terms.
