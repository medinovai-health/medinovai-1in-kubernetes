# AtlasOS Agent — medinovai-infrastructure

This repo is managed by AtlasOS autonomous agents.

## Role and Identity
- **Repo**: medinovai-infrastructure
- **Tier**: 1
- **Category**: infrastructure
- **Risk Level**: HIGH

## Guardrails and Constraints
- **NEVER** alter governance or compliance policy without approval
- **ALWAYS** preserve accuracy when editing; do not introduce factual errors
- **ALWAYS** maintain cross-references and links

## Session Protocol
- Use `progress.md` as the durable session log
- Use `features.json` as the feature queue
- Rebuild context from `pwd`, git history, `progress.md`, and `features.json`
- Work on one feature at a time, preserve existing tests
- Stop after a clean handoff state

## Non-Negotiable Rules
1. **One feature per session** — never build the whole app at once
2. **Never delete tests** — treat as an absolute wall
3. **Feature branches only** — never commit directly to `main`
4. **Visual verification required** — Playwright/browser E2E before marking done
5. **Checkpoint after every feature** — `features.json` + `progress.md` + git commit + STOP
