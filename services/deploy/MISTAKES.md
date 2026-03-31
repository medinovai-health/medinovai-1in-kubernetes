# MISTAKES

Use this file as a short repo-local log of repeat failures and the fix that prevented them from
coming back. Keep entries concise and action-oriented.

## Entry Format

```md
### YYYY-MM-DD — short title
- Symptom:
- Root cause:
- Prevention:
- Owner:
```

## Common MedinovAI Failure Patterns

### Example — Hardcoded secret slipped into config
- Symptom: credentials appeared in a committed config or compose file
- Root cause: runtime secret was stored directly in tracked source
- Prevention: move the value to Vault or environment injection and leave only placeholders in `.env.example`
- Owner: infrastructure-squad

### Example — Port drift between compose and manifest
- Symptom: service container started but readiness checks failed or traffic routed to the wrong port
- Root cause: compose, Dockerfile, and manifest used different exposed ports
- Prevention: source the port from the registry/manifest and validate it in CI
- Owner: infrastructure-squad
