# Glossary

Domain terms for the agent system. This file is a **glossary only** — no setup
steps, no implementation, no decisions. Definitions are canonical: use these
words consistently across all docs.

## Account

Never used unqualified — always name the system it belongs to:

- **Google Account** — an inbox/calendar the Agent operates on behalf of; further
  qualified as **Personal Google Account** or **Work Google Account**.
- **Telegram Account** — the allow-listed identity that messages the bot.
- **Hetzner Account** — the cloud project that owns and bills the VPS.
- **Nous Account** — the Nous Portal subscription identity providing models and
  the Tool Gateway.

## Agent

The Hermes process that reasons, calls tools, and persists memory — the
assistant itself.

## Bootstrap

The act of reconstructing a working [VPS](#vps) from zero: provisioning the
server, installing the [Agent](#agent), applying the [Profile
Distribution](#profile-distribution), restoring secrets, and completing the
interactive logins. The recovery path when a VPS is lost.

## Gateway

The Hermes process that connects the Agent to messaging platforms (Telegram) and
runs scheduled work. Runs as the `hermes-gateway` service. "Gateway" always means
this **messaging** gateway — never the [Tool Gateway](#tool-gateway). Write
"Messaging Gateway" when ambiguity is possible.

## Google Workspace MCP

The self-hosted [MCP server](#mcp-server) exposing Gmail and Calendar tools to
the Agent. Runs from the `workspace-mcp` package.

## MCP entry

A named server registration in Hermes config (`mcp_servers.<name>`). Each entry
has its own credentials and namespaces its tools (e.g. `google_work:get_events`).

## MCP server

The external tool server an [MCP entry](#mcp-entry) connects to (e.g. the Google
Workspace MCP).

## Nous Portal

Nous's subscription gateway that supplies both the [Provider](#provider) and the
[Tool Gateway](#tool-gateway) through one OAuth login.

## Profile

A self-contained Hermes configuration — its own config, MCP entries, persona,
sessions, and memory — sharing the Nous Portal login. Pablo runs as a single
named profile, and that profile is the unit that gets packaged. Running
*multiple* profiles to separate the Personal and Work Google Accounts was
considered and rejected — see ADR-0003.

## Profile Distribution

A [Profile](#profile) packaged as a git repository — persona, config, and MCP
entries — with secrets, sessions, and memory excluded by design. The canonical
package of Pablo-the-Agent, installed onto a fresh [VPS](#vps) with
`hermes profile install`.

## Provider

The inference backend serving the model (here, Nous).

## Tool Gateway

The Nous-managed tool backends — web search, image generation, text-to-speech,
browser automation — that the Agent's tool calls route through, included with a
Nous Portal subscription. Always written in full; never shortened to "gateway."

## VPS

The Hetzner virtual server hosting the Agent, the Gateway, and the Google
Workspace MCP.
