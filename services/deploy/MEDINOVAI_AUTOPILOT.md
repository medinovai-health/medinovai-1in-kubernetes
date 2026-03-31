# medinovai-Deploy — Autopilot Protocol

## Repo Classification
- **Tier**: 0
- **Grade**: D
- **Domain**: platform
- **Risk**: low

## Agent Operating Protocol
1. Read CLAUDE.md and this file before ANY action
2. Run existing tests to verify current state
3. Follow SDD workflow: SPECIFY → VALIDATE → TESTS → IMPLEMENT
4. Classify changes: GREEN (auto) / YELLOW (plan) / RED (human approval)
5. Produce evidence bundle for every change

## GREEN Actions (Auto-approved)
- Documentation updates
- Test additions
- Manifest fixes
- Scorecard updates
- Logging format standardization

## YELLOW Actions (Plan first)
- API changes (backward-compatible only)
- Middleware modifications
- Schema migrations (additive only)
- Workflow node additions

## RED Actions (Human approval required)
- Auth/policy changes
- Destructive migrations
- Cross-tenant logic
- Secrets rotation
- Audit schema changes
- PHI handling modifications
