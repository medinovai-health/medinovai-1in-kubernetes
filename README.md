# MedinovAI Deploy

**The single repo for deploying the entire MedinovAI platform from blank.**

On-prem K3s cluster spanning Mac Studio, MacBook Pro, and DGX GPU servers. HashiCorp Vault for secrets. AtlasOS agents embedded in every repo for fully autonomous AI-run operations with humans only for final approvals.

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                    Tailscale Mesh (100.x.x.x)                       │
│                                                                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐│
│  │ Mac Studio  │  │ MacBook Pro │  │   DGX-1     │  │   DGX-2     ││
│  │ K3s Server  │  │ K3s Agent   │  │ K3s Agent   │  │ K3s Agent   ││
│  │ OrbStack    │  │ OrbStack    │  │ Bare Metal  │  │ Bare Metal  ││
│  │             │  │             │  │ 4x A100 GPU │  │ 4x A100 GPU ││
│  └─────┬───────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘│
│        │                 │                 │                │       │
│  ┌─────┴─────────────────┴─────────────────┴────────────────┴─────┐ │
│  │                    K3s Cluster                                  │ │
│  │  Longhorn Storage │ Vault Secrets │ ESO │ Prometheus+Grafana   │ │
│  │  109 Services across 7 Tiers │ AtlasOS Cluster Brain          │ │
│  └────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────┘
```

## Quick Start

```bash
# 1. Check prerequisites
make prerequisites

# 2. Full platform instantiation (~70 min for all 109 services)
make instantiate

# 3. Critical path only (~25 min for 12 essential services)
make instantiate-critical

# 4. Health check
make health

# 5. Embed AtlasOS in all repos
make embed-atlasos
```

## Fleet

| Node | Role | Hardware | K3s Role |
|------|------|----------|----------|
| Mac Studio | Control plane | M2 Ultra, 192GB RAM, 2TB | Server |
| MacBook Pro | Overflow worker | M3 Pro, 36GB RAM | Agent |
| DGX-1 | GPU inference | AMD EPYC, 512GB, 4x A100 80GB | Agent |
| DGX-2 | GPU inference | AMD EPYC, 512GB, 4x A100 80GB | Agent |

## Service Tiers (109 services)

| Tier | Name | Services | K8s Namespace |
|------|------|----------|---------------|
| 0 | Infrastructure | PostgreSQL, Redis, Kafka, MongoDB, ES, Vault, Keycloak | `infra` |
| 1 | Security | SSO, RBAC, encryption, HIPAA/GDPR guard | `security` |
| 2 | Platform Core | Registry, API gateway, notifications, AtlasOS | `platform`, `atlasos` |
| 3 | AI/ML | AIFactory, Ollama, model orchestrator, scribe | `ai-ml` |
| 4 | Domain | CTMS, EDC, LIS, eConsent, CRM, sales tools | `clinical`, `business` |
| 5 | Integrations | Email, fax, CRM connectors, webhooks | `integrations` |
| 6 | UI | MedinovAI OS shell, dashboards | `ui` |

## Repo Structure

```
medinovai-Deploy/
├── config/
│   ├── fleet.json5              # Physical node inventory
│   ├── dependency-graph.json    # 109-service deployment order
│   └── repo_registry.json5     # ~162 repos with categories
├── infra/kubernetes/
│   ├── services/
│   │   ├── tier0/               # PostgreSQL, Redis, Kafka, etc.
│   │   ├── tier1/               # Security services
│   │   ├── tier2/               # Platform core
│   │   ├── atlasos/             # AtlasOS (gateway, UI, orchestrator, etc.)
│   │   ├── atlasos-node-agent/  # DaemonSet on every node
│   │   ├── atlasos-cluster-brain/ # CEO+Supervisor+Guardian
│   │   └── tier3-6/             # Domain, integration, UI services
│   ├── vault/                   # Vault Helm values + policies
│   ├── external-secrets/        # ESO + ExternalSecret per namespace
│   ├── monitoring/              # Prometheus, Grafana, Loki, DCGM
│   └── overlays/
│       ├── onprem-dev/          # Mac Studio only, 12 services
│       └── onprem-prod/         # Full 4-node fleet, all tiers
├── scripts/
│   ├── bootstrap/
│   │   ├── prerequisites.sh     # Tool checks (kubectl, helm, tailscale, vault, orb)
│   │   ├── init-network.sh      # Tailscale mesh setup
│   │   ├── init-orbstack.sh     # OrbStack VM + K3s (server or agent)
│   │   ├── init-dgx.sh          # DGX bare metal K3s + NVIDIA toolkit
│   │   ├── init-storage.sh      # Longhorn distributed storage
│   │   ├── init-vault.sh        # Vault deploy + init + seed secrets
│   │   └── instantiate.sh       # 25-step full platform from blank
│   ├── deploy/
│   │   └── deploy_tier.sh       # Deploy specific tier or all
│   └── agents/
│       └── embed_atlasos.sh     # Distribute agent kits to all ~162 repos
├── templates/
│   └── repo-agents/             # Agent kits per category
│       ├── clinical/            # AGENTS.md, HEARTBEAT.md, .cursor/rules/
│       ├── backend-service/
│       ├── frontend-app/
│       ├── ai-ml/
│       ├── platform/
│       ├── security/
│       ├── data/
│       ├── sales-crm/
│       ├── docs-standards/
│       └── library/
└── Makefile                     # All operations: make help
```

## Secrets Management

All secrets are stored in **HashiCorp Vault** (deployed in the K3s cluster) and synced to Kubernetes Secrets via **External Secrets Operator (ESO)**.

| Vault Path | Namespace | Description |
|------------|-----------|-------------|
| `medinovai-secrets/atlasos/*` | atlasos | AtlasOS API keys, tokens, integrations |
| `medinovai-secrets/infra/*` | infra | Database passwords, connection strings |
| `medinovai-secrets/security/*` | security | Keycloak, JWT, encryption keys |
| `medinovai-secrets/platform/*` | platform | API gateway, registry tokens |
| `medinovai-secrets/clinical/*` | clinical | FHIR, CTMS database credentials |
| `medinovai-secrets/ai-ml/*` | ai-ml | AIFactory, model API keys |

```bash
# Seed from existing .env file
make seed-secrets

# Interactive seeding
make seed-secrets-interactive

# Vault UI
kubectl port-forward -n vault svc/vault-ui 8200:8200
```

## AtlasOS Everywhere

AtlasOS is embedded at every level:

1. **Node-level**: DaemonSet on every K3s node — monitors CPU, memory, disk, GPU health
2. **Service-level**: Sidecar agents for all platform services — health, latency, circuit breaking
3. **Cluster-level**: Cluster brain (CEO + Supervisor + Guardian) with K8s API access — scaling, remediation, governance
4. **Repo-level**: Agent kits in all ~162 repos — code quality, CI/CD, dependency management, autonomous PRs

```bash
# Embed in all repos
make embed-atlasos

# Embed in a single repo
make embed-atlasos-repo REPO=medinovai-CTMS

# Embed by category
make embed-atlasos-category CATEGORY=clinical

# Preview (dry run)
make embed-atlasos-dry-run
```

## Monitoring

| Tool | Port | Purpose |
|------|------|---------|
| Prometheus | 9090 | Metrics collection |
| Grafana | 3000 | Dashboards |
| Loki | 3100 | Log aggregation |
| DCGM Exporter | 9400 | NVIDIA GPU metrics |
| AtlasOS Brain | 8100 | Cluster health + agent status |
| Vault | 8200 | Secret management UI |

```bash
make dashboards  # Shows port-forward commands
make health      # Full stack health check
make gpu-status  # DGX GPU status
make agent-status # AtlasOS agent heartbeats
```

## Commands Reference

Run `make help` for the full list. Key commands:

| Command | Description |
|---------|-------------|
| `make setup` | Full setup from blank to running |
| `make instantiate` | 25-step greenfield deployment (~70 min) |
| `make instantiate-critical` | Critical path only (~25 min) |
| `make deploy-all` | Deploy all services in tier order |
| `make deploy-tier TIER=0` | Deploy specific tier |
| `make deploy-atlasos` | Deploy AtlasOS services |
| `make deploy-agents` | Deploy node agents + cluster brain |
| `make embed-atlasos` | Embed agents in all ~162 repos |
| `make health` | Full-stack health audit |
| `make gpu-status` | DGX GPU health |
| `make seed-secrets` | Seed Vault from .env |
| `make validate-k8s` | Dry-run validate all manifests |
