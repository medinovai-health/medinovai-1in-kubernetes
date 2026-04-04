# MISTAKES.md — `<monorepo-name>`
**Use this file as a short repo-local log of repeat failures and the fix that prevented them.**
**Keep entries concise and action-oriented. Add new entries at the top.**
**(c) 2026 Copyright MedinovAI. All Rights Reserved.**

## Entry Format
```md
### YYYY-MM-DD — short title
- Symptom:
- Root cause:
- Prevention:
- Owner:
```

---

## Known MedinovAI Platform Failure Patterns

### 2026-01-01 — Hardcoded secret slipped into config
- **Symptom:** Credentials appeared in a committed config or compose file.
- **Root cause:** Runtime secret was stored directly in tracked source.
- **Prevention:** Move the value to Vault or environment injection; leave only placeholders in `.env.example`.
- **Owner:** infrastructure-squad

### 2026-01-01 — Port drift between compose and manifest
- **Symptom:** Service container started but readiness checks failed or traffic routed to the wrong port.
- **Root cause:** `docker-compose.yml`, `Dockerfile`, and `module-manifest.yaml` used different exposed ports.
- **Prevention:** Source the port from `port-registry.json` and validate it in CI using `validate-port-compliance.py`.
- **Owner:** infrastructure-squad

### 2026-01-01 — PHI appeared in application logs
- **Symptom:** Patient identifiers (MRN, DOB, name) visible in Elasticsearch logs.
- **Root cause:** Service used `print()` or unstructured logging instead of `structlog` ZTA format.
- **Prevention:** Enforce `phi_safe: true` in `module-manifest.yaml`; block PRs that use `print()` or `logging.info()` directly.
- **Owner:** security-compliance-squad

### 2026-01-01 — `git subtree` used with `--squash` flag
- **Symptom:** FDA audit trail broken; commit history lost after migration.
- **Root cause:** Developer used `git subtree add --squash` for convenience.
- **Prevention:** `--squash` is permanently banned. CI pre-receive hook rejects squash merges. See `MONOREPO_MIGRATION_GUIDE.md`.
- **Owner:** platform-squad

### 2026-01-01 — Service deployed without readiness probe
- **Symptom:** ArgoCD sync hung indefinitely; downstream services timed out.
- **Root cause:** `deployment.yaml` missing `readinessProbe` definition.
- **Prevention:** The 10-gate CI pipeline checks for `/ready` endpoint and `readinessProbe` in all K8s manifests.
- **Owner:** infrastructure-squad

---
*Add new entries above this line.*
