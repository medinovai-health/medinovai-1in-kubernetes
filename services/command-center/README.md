# MedinovAI Command Center
## `medinovai-infrastructure/services/command-center/`
**(c) 2026 Copyright MedinovAI. All Rights Reserved.**
**Version: 3.0.0 | Build: 20260414**

---

## Overview

The MedinovAI Command Center is the **unified control plane** for the entire MedinovAI platform. It provides total observability, autonomous remediation, and AI-powered operations across all environments (Dev/QA/Staging/Production).

> **Migrated from:** `medinovai-2pl-atlas-os/ui/` → `medinovai-infrastructure/services/command-center/`
> **Migration date:** 2026-04-14
> **Reason:** Architectural separation — the Command Center observes AtlasOS; observer must be separate from the observed.

---

## Quick Start

```bash
# Development
cd ui && npm install && npm run dev
# → http://localhost:9443

# Production (Docker)
docker build -t command-center . && docker run -p 9443:9443 command-center

# Kubernetes (Helm)
helm install command-center ./helm --namespace medinovai
```

---

## Architecture

```
services/command-center/
├── ui/                     # Next.js 15 + React 19 frontend
│   ├── app/
│   │   ├── api/
│   │   │   ├── health/     # Deep health check endpoint
│   │   │   ├── agent/      # Nexus AI Agent API
│   │   │   ├── sync/       # Brain + Deploy + AtlasOS sync
│   │   │   ├── metrics/    # Prometheus metrics endpoint
│   │   │   ├── modules/    # Platform module status
│   │   │   ├── alerts/     # Alert management
│   │   │   ├── deployments/ # Deployment lifecycle
│   │   │   └── environments/ # Environment health
│   │   ├── dashboard/      # Main control plane view
│   │   ├── login/          # Authentication
│   │   └── layout.tsx      # Root layout
│   ├── lib/
│   │   └── agent/
│   │       └── nexus-singleton.ts  # Nexus agent singleton
│   └── middleware.ts        # Security hardening middleware
├── agent/
│   └── src/
│       └── nexus-agent.ts  # Nexus AI Agent (self-learning)
├── helm/                   # Kubernetes Helm chart
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── .github/
│   └── workflows/
│       └── deploy-command-center.yml
├── Dockerfile              # Multi-stage hardened build
├── module-manifest.yaml    # MedinovAI platform registration
├── CHARTER.md              # 50 blind spots + 50 hardening points
└── MIGRATION.md            # Migration guide from atlas-os
```

---

## Ports

| Service | Port | Protocol |
|---------|------|----------|
| Command Center UI | 9443 | HTTPS |
| Health Check | 9444 | HTTP |
| Prometheus Metrics | 9445 | HTTP |
| WebSocket (Nexus) | 9446 | WSS |
| Nexus Agent REST | 9447 | HTTPS |

---

## Nexus AI Agent

Nexus is the dedicated self-learning AI agent for the Command Center. It:
- Syncs knowledge from `medinovai-platform-brain` every 5 minutes
- Detects and triages incidents autonomously
- Recommends deployments and rollbacks (requires human approval for prod)
- Continuously improves from operational data
- Maintains a persistent memory of all platform events

**Model:** Ollama (llama3.2) primary, GPT-4.1-mini fallback

---

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GITHUB_TOKEN` | Yes | GitHub API access for Brain sync |
| `OPENAI_API_KEY` | Yes | GPT-4.1-mini fallback for Nexus |
| `ATLASOS_GATEWAY_URL` | Yes | AtlasOS gateway for environment health |
| `OLLAMA_HOST` | Yes | Ollama server for Nexus primary model |
| `GITHUB_WEBHOOK_SECRET` | Yes | Webhook signature verification |
| `NEXT_PUBLIC_ENVIRONMENT` | Yes | Current environment name |
| `NEXT_PUBLIC_BUILD_ID` | Yes | Git SHA for build tracking |

---

## Compliance

- **HIPAA:** PHI never flows through Command Center; all access logged
- **GDPR:** Data minimization; no PII in operational logs
- **Audit:** All control actions logged to immutable audit chain
- **Access:** Company employees only; MFA required for admin actions

---

## License

UNLICENSED — (c) 2026 MedinovAI. All Rights Reserved.
Unauthorized access, reproduction, or distribution is strictly prohibited.
