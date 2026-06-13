# 0001 — Use Nous Portal as the model and tool provider

- **Status:** accepted
- **Date:** 2026-06-13

## Context

Hermes needs an inference provider (a model) and, to be genuinely useful, tool
backends — web search, image generation, browser automation, text-to-speech.
There are two ways to supply both:

- **Nous Portal subscription** — one OAuth login grants 300+ models (routed via
  OpenRouter under the hood) plus the **Tool Gateway** (Firecrawl search, FAL
  images, OpenAI TTS, Browser Use), billed as a single subscription.
- **Bring-your-own API keys** — per-token model billing direct from a provider,
  plus a separate account, key, and bill for each tool backend.

The agent runs headless on an internet-facing VPS and is reached from Telegram.
We wanted it capable out of the box (web search at minimum) while keeping as few
long-lived secrets on the box as possible.

## Decision

Use Nous Portal as **both** the inference provider and the tool gateway:
authenticate once (`hermes auth add nous --type oauth`), set `model.provider:
nous` with default `anthropic/claude-sonnet-4.6`, and route web search through
the gateway (`web.backend: firecrawl`, `web.use_gateway: true`).

## Consequences

- One subscription covers the model and every gateway tool — no Firecrawl, FAL,
  Browser Use, or OpenAI accounts to manage.
- Only one long-lived credential sits on disk (the Portal refresh token);
  per-request JWTs are short-lived — a good posture for a public VPS.
- Models are hot-swappable mid-session via `/model` across the catalog.
- Cost is a flat subscription regardless of usage; a model-only, light user
  could pay less with a metered BYO key.
- We take a dependency on Nous as an intermediary (routing, availability) and on
  the subscription remaining active.

## Alternatives considered

- **Bring-your-own provider key** (OpenRouter / OpenAI / Anthropic): pure
  pay-per-token, a direct provider relationship, and access to any model — but
  inference *only*. Each tool would be its own signup, key, and bill, and more
  secrets would live on the box. Rejected because the assistant needed tools
  immediately and we wanted minimal credential sprawl on an internet-facing host.
