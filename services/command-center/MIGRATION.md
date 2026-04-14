# Command Center Migration Guide
## From `medinovai-2pl-atlas-os/ui/` → `medinovai-infrastructure/services/command-center/`
**(c) 2026 Copyright MedinovAI. All Rights Reserved.**

---

## Why This Migration

The Command Center is the **observer** of the MedinovAI platform. AtlasOS is the **operating system**.
Mixing the observer with the observed creates circular dependencies and deployment coupling.

The `medinovai-infrastructure` monorepo is the correct home because:
1. Infrastructure tools (Helm, Terraform, deploy scripts) live here
2. The Command Center deploys alongside infrastructure, not alongside AtlasOS agents
3. Shared `libs/` and `.cursor/rules` in the monorepo enable the Nexus agent to self-improve globally

---

## Migration Steps

### Step 1: Copy source files
```bash
# In medinovai-2pl-atlas-os repo
cp -r ui/ ../medinovai-infrastructure/services/command-center/ui/
cp -r agent/ ../medinovai-infrastructure/services/command-center/agent/
```

### Step 2: Update imports
All imports from `@/` remain unchanged (Next.js alias).
Update any hardcoded references to `medinovai-2pl-atlas-os` → `medinovai-infrastructure`.

### Step 3: Add new files
The following new files are added (not present in original):
- `agent/src/nexus-agent.ts` — Nexus AI Agent
- `ui/app/api/agent/route.ts` — Nexus API endpoint
- `ui/app/api/health/route.ts` — Deep health check
- `ui/app/api/sync/route.ts` — Brain sync webhook
- `helm/` — Helm chart for Kubernetes deployment
- `Dockerfile` — Hardened multi-stage build
- `.github/workflows/deploy-command-center.yml` — CI/CD pipeline
- `module-manifest.yaml` — MedinovAI module registration
- `CHARTER.md` — Enhanced charter with 50 blind spots + 50 hardening points

### Step 4: Update medinovai-2pl-atlas-os
Add a deprecation notice to `medinovai-2pl-atlas-os/ui/README.md`:
```markdown
> ⚠️ **DEPRECATED**: The Command Center UI has been migrated to
> `medinovai-infrastructure/services/command-center/`. This directory
> will be removed in v4.0.0. Please update all references.
```

### Step 5: Update medinovai-Deploy
Add `command-center` to `docker-compose.yml` and `port-registry.json`:
- Port `9443` — Command Center UI
- Port `9444` — Nexus Agent WebSocket
- Port `9445` — Prometheus metrics

### Step 6: Update medinovai-platform-brain
The Brain already has `agent-knowledge/COMMAND_CENTER_STRATEGIC_PLAN.md`.
Update `JCODEMUNCH_INDEX.json` to point to the new repo location.

---

## Port Registry

| Service | Port | Protocol |
|---------|------|----------|
| Command Center UI | 9443 | HTTPS |
| Nexus Agent WebSocket | 9444 | WSS |
| Prometheus Metrics | 9445 | HTTP |
| Nexus Agent REST | 9447 | HTTPS |

---

## Environment Variables Required

| Variable | Source | Required |
|----------|--------|----------|
| `GITHUB_TOKEN` | Vault | Yes |
| `OPENAI_API_KEY` | Vault | Yes (Nexus fallback) |
| `ATLASOS_GATEWAY_URL` | Vault | Yes |
| `OLLAMA_HOST` | Vault | Yes (Nexus primary) |
| `GITHUB_WEBHOOK_SECRET` | Vault | Yes |
| `NEXT_PUBLIC_ENVIRONMENT` | Build arg | Yes |
| `NEXT_PUBLIC_BUILD_ID` | Build arg | Yes |

---

## Rollback Plan

If the migration causes issues:
1. Revert the `medinovai-infrastructure` commit
2. Re-enable the old `medinovai-2pl-atlas-os` deployment
3. The old deployment runs on port `9443` — no port conflict

---

*Migration completed: 2026-04-14*
*Migrated by: Manus AI Agent*
*Approved by: MedinovAI Platform Infrastructure Squad*
