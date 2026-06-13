# pablo

## Agent skills

This repo is configured for the Beyond Data engineering skills.
Configuration lives in `docs/agents/`:

- `issue-tracker.md` — tracker, team, project (personal Linear via `PABLO_LINEAR_API_KEY`)
- `labels.md` — type and workflow labels
- `ways-of-working.md` — Epic/Issue model, domain docs

Reporting (`/to-briefing`) is not configured — the personal workspace has no Initiatives.

Skills that read this configuration:
- `/to-epic` — create Epics
- `/to-prd` — create PRDs
- `/to-issues` — break down into vertical-slice issues
- `/to-briefing` — generate stakeholder status updates

---

_This is a Hermes profile-distribution repo (shell scripts + runbooks + YAML),
not a Python application. The setup runbook is [`scripts/README.md`](scripts/README.md)
and the rationale lives in [`docs/adr/`](docs/adr/README.md)._
