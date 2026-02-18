# MedinovAI Deploy

Autonomous on-prem deployment system for the entire MedinovAI platform. Takes blank physical servers and stands up 109 services across 7 tiers — databases, security, AI inference, clinical applications, and the AtlasOS AI brain — in a single command.

## Architecture

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                        MedinovAI Deploy System                                │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │                     On-Prem K3s Cluster (4 nodes)                       │  │
│  │                                                                         │  │
│  │  Mac Studio (control plane)     MacBook Pro (worker)                   │  │
│  │  ├── Tier 0: PostgreSQL, Redis  ├── Tier 4: Domain service overflow    │  │
│  │  ├── Tier 0: Kafka, MongoDB     └── Tier 6: medinovaios UI shell      │  │
│  │  ├── Tier 0: Vault, Keycloak                                          │  │
│  │  ├── Tier 1-2: Security, Platform   DGX Server 1 (GPU worker)         │  │
│  │  ├── AtlasOS: Gateway, Orchestrator ├── Ollama (11434)                │  │
│  │  ├── Monitoring: Prometheus, Grafana├── AIFactory (5000)              │  │
│  │  └── Cluster Brain (CEO/Supervisor) └── GPU Operator                  │  │
│  │                                                                         │  │
│  │                                     DGX Server 2 (GPU worker)          │  │
│  │    Tailscale Mesh Network           ├── Ollama (11434)                │  │
│  │    LAN: 192.168.x.x                ├── AIFactory (5000)              │  │
│  │    Tailscale: 100.x.x.x            └── GPU Operator                  │  │
│  └─────────────────────────────────────────────────────────────────────────┘  │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │               AtlasOS Embedded in ~162 Repos                            │  │
│  │  Every repo gets: AGENTS.md, HEARTBEAT.md, SOUL.md, .cursor/rules/     │  │
│  │  AI agents autonomously develop, review, deploy, and maintain code      │  │
│  │  Humans approve: deploys, external comms, financial tx, safety actions  │  │
│  └─────────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# 1. Check prerequisites
make prerequisites

# 2. Full instantiation (blank to running, ~70 min)
make instantiate

# 3. Or critical-path only (~25 min, 12 core services + AtlasOS)
make instantiate-critical

# 4. Embed AtlasOS agents in all repos
make embed-atlasos
```

## What Gets Deployed

| Tier | Services | Deploy Time |
|------|----------|-------------|
| **0** | PostgreSQL (x2), Redis, Kafka, MongoDB, Elasticsearch, Keycloak, MinIO, Vault | 5 min |
| **1** | Secrets bridge, Security, SSO, RBAC, Encryption, HIPAA guard, Consent API | 5 min |
| **2** | Registry, Data services, Stream bus, Notification, AIFactory, API gateway | 5 min |
| **AtlasOS** | Gateway, UI, Orchestrator, AI orchestrator, MCP, Event bus, Audit chain, Voice bridge | 3 min |
| **GPU** | Ollama (DaemonSet on DGX), AIFactory, ChromaDB, NVIDIA GPU Operator | 5 min |
| **3** | CDS, AI Scribe, HealthLLM, Knowledge Graph, Prompt Vault, Model Orchestrator | 5 min |
| **4** | 60+ domain services: CTMS, EDC, LIS, Sales, Telehealth, etc. | 8 min |
| **5-6** | Integration, DevOps, UI shell (medinovaios) | 5 min |
| **AtlasOS Infra** | Node agents (DaemonSet), Cluster brain (CEO+Supervisor+Guardian) | 2 min |

## Fleet

| Node | Role | Hardware | Services |
|------|------|----------|----------|
| Mac Studio | Control plane + worker | M2 Ultra, 192GB, 2TB | Databases, Vault, AtlasOS, Monitoring |
| MacBook Pro | Worker | M3 Pro, 36GB, 500GB | Domain service overflow, UI shell |
| DGX Server 1 | GPU worker | 64 cores, 512GB, 4x A100 | Ollama, AIFactory |
| DGX Server 2 | GPU worker | 64 cores, 512GB, 4x A100 | Ollama, AIFactory |

Networking: Tailscale mesh (100.x.x.x) + LAN (192.168.x.x)

## Secrets Management

All secrets stored in HashiCorp Vault, synced to K8s via External Secrets Operator:

```
medinovai-secrets/
├── infra/          PostgreSQL, Redis, Kafka passwords
├── security/       Keycloak admin, JWT signing keys
├── platform/       Registry, API gateway keys
├── atlasos/        Anthropic, OpenAI, Slack, 3CX, CRM, voice
├── ai-ml/          Model API keys, AIFactory config
├── clinical/       FHIR server creds, clinical DB
└── tenant/{id}/    Per-tenant secrets (SAES compliance)
```

## AtlasOS Everywhere

AtlasOS agents are embedded in every MedinovAI repo (~162 repos):

```bash
make embed-atlasos                              # All repos
make embed-atlasos-repo REPO=medinovai-CTMS     # Single repo
make embed-atlasos-category CATEGORY=clinical   # All clinical repos
```

Each repo receives a category-specific agent kit (clinical, platform, ai-ml, etc.) with AGENTS.md, HEARTBEAT.md, SOUL.md, TOOLS.md, and Cursor rules for autonomous AI operation.

**AI runs everything. Humans approve:**
- Production deployments (canary promotion)
- Node drain/removal, cluster upgrades
- External communications, financial transactions
- Clinical safety actions, regulatory submissions

## Command Reference

```bash
# Bootstrap
make setup                    # Full: prerequisites + instantiate
make init-network             # Tailscale mesh
make init-k3s-server          # K3s on Mac Studio
make init-k3s-worker          # K3s on MacBook Pro
make init-dgx                 # DGX GPU nodes
make init-vault               # HashiCorp Vault
make add-node TYPE=dgx IP=x   # Add new node

# Deploy
make deploy-all               # All 109 services
make deploy-tier TIER=0       # Specific tier
make deploy-atlasos           # AtlasOS services
make deploy-gpu               # GPU workloads
make deploy-node-agents       # Node agent DaemonSet
make deploy-cluster-brain     # Cluster brain

# Health
make health                   # Full-stack health
make status                   # Quick cluster status
make agent-status             # AtlasOS agent status
make gpu-status               # GPU node status

# Secrets
make seed-secrets             # Seed Vault interactively
make rotate-secrets           # Rotate expiring secrets

# Maintenance
make drift-check              # K3s vs Git manifest diff
make backup                   # Longhorn + Vault snapshots
make validate                 # Full validation suite
```

## Governance Controls

All 10 AI governance controls (GOV-01 through GOV-10) enforced at deploy time. See `scripts/validation/validate_compliance.sh`.

## License

Private. Internal use only. MedinovAI / MyOnsite Healthcare.
