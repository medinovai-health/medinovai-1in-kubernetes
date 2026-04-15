# medinovai-infrastructure

Central infrastructure-as-code, CI/CD templates, and operational runbooks for the MedinovAI platform.

## Contents

### Reusable Workflows (`.github/workflows/`)
- **`deploy-to-aifactory.yml`** — Reusable workflow called by all 138 repos to deploy to AIFactory MacStudio

### Documentation (`docs/`)
- **`MACSTUDIO_DEPLOYMENT_RUNBOOK.md`** — Complete deployment guide for AIFactory MacStudio (Astra + Deploy App)
- **`wire_results.json`** — Audit of all 138 repos' CI/CD wiring status

### Scripts (`scripts/`)
- **`wire_120_repos.py`** — Auto-wires all org repos to the reusable AIFactory deploy workflow
- **`push_fmea.py`** — Pushes FMEA engine updates to app repos via GitHub API
- **`update_workflows.py`** — Updates CI/CD workflow files across repos via GitHub API
- **`push_all_to_github.py`** — Master script to push all generated files to correct repos

### Knowledge Bases
- **`deploy_kb_fmea.yaml`** — FMEA Knowledge Base v3.0 (128 failure modes, 16 categories)
  Used by MIL (medinovai-intelligence-layer) for autonomous remediation

## Quick Deploy to AIFactory

Any repo in `medinovai-health` can deploy to AIFactory with 3 lines:

```yaml
jobs:
  deploy:
    uses: medinovai-health/medinovai-infrastructure/.github/workflows/deploy-to-aifactory.yml@main
    with:
      service_name: "my-service"
      port: 8080
    secrets: inherit
```

## AIFactory MacStudio

| Service | Port | URL |
|---------|------|-----|
| Astra Universal Agent | 36800 | http://100.106.54.9:36800 |
| Deploy Orchestrator | 36900 | http://100.106.54.9:36900 |
| Command Center | 9443 | http://100.106.54.9:9443 |
| MIL WebSocket | 9876 | ws://100.106.54.9:9876/ws |
| Vidur Event Bus | 9019 | http://vidur-event-bus:9019 |

## Releases

- **Astra v2.0.0**: https://github.com/medinovai-health/medinovai-2ag-astra/releases/tag/v2.0.0
- **Deploy v2.0.0**: https://github.com/medinovai-health/medinovai-2ag-deploy/releases/tag/v2.0.0

---
*© 2026 myOnsite Healthcare — Confidential*
