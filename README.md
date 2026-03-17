# MedinovAI Deploy

**Autonomous deployment for the entire MedinovAI platform and AtlasOS four-layer agent fabric — on-prem first.**

Single repo to deploy 109 services across a K3s cluster spanning Mac Studio, MacBook Pro, and DGX GPU servers. HashiCorp Vault for secrets. AtlasOS runs as a four-layer agent platform across the company: `Named Assistants`, `Functional Agents`, `Entity Agents`, and `Squad Agents`, with humans retained for approval gates and regulated actions.

## Architecture

```
                    medinovai-Deploy
                           │
                           ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                    Tailscale Mesh (100.x.x.x)                             │
│                                                                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │ Mac Studio  │  │ MacBook Pro │  │   DGX-1     │  │   DGX-2     │      │
│  │ K3s Server  │  │ K3s Agent   │  │ K3s Agent   │  │ K3s Agent   │      │
│  │ OrbStack    │  │ OrbStack    │  │ Bare Metal  │  │ Bare Metal  │      │
│  │             │  │             │  │ 4x A100 GPU │  │ 4x A100 GPU │      │
│  └─────┬───────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘      │
│        │                 │                 │                │             │
│  ┌─────┴─────────────────┴─────────────────┴────────────────┴─────┐      │
│  │                    K3s Cluster (4 nodes)                        │      │
│  │  Longhorn │ Vault │ ESO │ Prometheus+Grafana │ 109 Services    │      │
│  │  AtlasOS Cluster Brain │ Node Agents (DaemonSet)                │      │
│  └────────────────────────────────────────────────────────────────┘      │
│                                    │                                       │
│                                    ▼                                       │
│              AtlasOS embedded across MedinovAI repos + runtimes            │
└──────────────────────────────────────────────────────────────────────────┘
```

## What'''s in This Repo

```
medinovai-Deploy/
├── config/
│   ├── fleet.json5              # Physical node inventory
│   ├── dependency-graph.json    # 109-service deployment order
│   └── repo_registry.json5      # ~162 repos with categories
├── infra/kubernetes/
│   ├── base/                    # Namespaces, RBAC
│   ├── services/
│   │   ├── tier0/               # PostgreSQL, Redis, Kafka, MongoDB, ES, etc.
│   │   ├── tier1/               # Security (Keycloak, SSO, RBAC)
│   │   ├── tier2/               # Platform core
│   │   ├── atlasos/             # AtlasOS gateway, UI, orchestrator, invocation, entity runtime
│   │   ├── atlasos-node-agent/  # DaemonSet on every node
│   │   ├── atlasos-cluster-brain/
│   │   └── tier3-6/             # AI/ML, domain, integration, UI
│   ├── vault/                   # Vault Helm values + policies
│   ├── external-secrets/        # ESO + ExternalSecret per namespace
│   ├── monitoring/              # Prometheus, Grafana, Loki, DCGM
│   └── overlays/
│       ├── onprem-dev/          # Mac Studio only, 12 services
│       └── onprem-prod/         # Full 4-node fleet, all tiers
├── scripts/
│   ├── bootstrap/
│   │   ├── prerequisites.sh     # Tool checks (kubectl, helm, tailscale, orb)
│   │   ├── init-network.sh      # Tailscale mesh setup
│   │   ├── init-orbstack.sh     # OrbStack VM + K3s (server or agent)
│   │   ├── init-dgx.sh          # DGX bare metal K3s + NVIDIA toolkit
│   │   ├── init-storage.sh      # Longhorn distributed storage
│   │   ├── init-vault.sh        # Vault deploy + init + seed secrets
│   │   └── instantiate.sh       # 25-step full platform from blank
│   ├── deploy/
│   │   ├── deploy_tier.sh       # Deploy specific tier or all
│   │   └── deploy_service.sh   # Deploy single service
│   ├── agents/
│   │   ├── embed_atlasos.sh     # Distribute agent kits to all ~162 repos
│   │   ├── create_agents.sh     # Register named, functional, entity, and squad agents
│   │   └── register_crons.sh   # Agent cron jobs
│   ├── maintenance/             # drift_check, db_backup, rotate_secrets
│   ├── validation/              # validate_setup, smoke_test
│   └── monitoring/              # Health checks
├── templates/repo-agents/       # Agent kits per category (clinical, ai-ml, etc.)
└── Makefile                    # All operations: make help
```

## Blank Host Quickstart (4 Steps)

Minimum path from a fresh machine to a running platform:

```bash
# 1. Check prerequisites (Docker, kubectl, helm, etc.)
make prerequisites

# 2. Bootstrap infrastructure (Docker Compose, Vault, namespaces, storage)
make bootstrap

# 3. Deploy all services in tiered order
make deploy-all

# 4. Verify everything is healthy
make smoke-test
```

**Requirements**: Docker Desktop (or OrbStack) running, SSH key added to GitHub, `.env` file configured from `infra/docker/.env.example`.

For the full 25-step instantiation including Tailscale mesh, DGX GPU nodes, and AtlasOS embedding, see below.

## Keycloak Ownership Policy

Only one Keycloak owner is allowed per environment/runtime.

- `k8s + platform` (enforced): `medinovai-Deploy` tier0 owns Keycloak and is the canonical platform owner.
- `compose + standalone` (allowed): `medinovai-security-service` may own Keycloak for local development.
- `compose + platform` (informational/advisory): reference topology only, not a default blocker for standalone local workflows.

Validation is built into deploy entrypoints:

```bash
# Kubernetes preflight is enforced by default in deploy_tier
bash scripts/deploy/deploy_tier.sh 1

# Compose validation stays advisory by default for local standalone
bash scripts/deploy/deploy_platform.sh --keycloak-mode standalone --keycloak-ownership-mode warn
```

## Greenfield Instantiation

Full setup from blank to running platform in 25 steps (~70 min). Critical path only: 15 steps (~25 min).

| Step | Description | Est. Time |
|------|-------------|-----------|
| 1 | Prerequisites check | 1 min |
| 2 | Tailscale mesh network | 2 min |
| 3 | K3s server (Mac Studio via OrbStack) | 5 min |
| 4 | K3s agent (MacBook Pro via OrbStack) | 3 min |
| 5 | DGX GPU nodes | 10 min |
| 6 | Longhorn distributed storage | 5 min |
| 7 | Kubernetes namespaces and RBAC | 1 min |
| 8 | HashiCorp Vault | 5 min |
| 9 | Seed secrets into Vault | 2 min |
| 10 | External Secrets Operator | 3 min |
| 11 | Monitoring stack | 3 min |
| 12 | Tier 0: Databases + infrastructure | 5 min |
| 13 | Tier 1: Security services | 2 min |
| 14 | Tier 2: Platform core | 3 min |
| 15 | AtlasOS services | 3 min |
| 16 | Tier 3: AI/ML + clinical foundation | 5 min |
| 17 | GPU inference (Ollama, AIFactory) | 3 min |
| 18 | Tier 4: Domain services | 4 min |
| 19 | Tier 5: Integration services | 2 min |
| 20 | Tier 6: UI shell | 2 min |
| 21 | Ingress | 1 min |
| 22 | AtlasOS node agents (DaemonSet) | 2 min |
| 23 | AtlasOS cluster brain | 2 min |
| 24 | Atlas four-layer agent registration + crons | 2 min |
| 25 | Smoke tests | 2 min |

```bash
# Full instantiation
make instantiate

# Critical path only (~25 min)
make instantiate-critical

# Manual step-by-step
make prerequisites
make init-network
make init-k3s
make init-k3s-agent    # optional
make init-dgx          # optional, for GPU
make init-storage
make init-vault
make instantiate       # or resume from checkpoint
```

## Quick Reference

| Command | Description |
|---------|-------------|
| `make help` | Show all targets |
| `make setup` | Full setup from blank |
| `make prerequisites` | Check required tools |
| `make init-network` | Tailscale mesh |
| `make init-k3s` | K3s server (Mac Studio) |
| `make init-k3s-agent` | K3s worker (MacBook Pro) |
| `make init-dgx` | DGX GPU nodes |
| `make init-storage` | Longhorn storage |
| `make init-vault` | Vault deploy + init |
| `make instantiate` | Full platform (25 steps, ~70 min) |
| `make instantiate-critical` | Critical path only (~25 min) |
| `make deploy-all` | Deploy all services |
| `make deploy-tier TIER=0` | Deploy specific tier |
| `make deploy-service SVC=name` | Deploy single service |
| `make deploy-atlasos` | AtlasOS services |
| `make deploy-gpu` | GPU inference services |
| `make embed-atlasos` | Embed in all ~162 repos |
| `make health` | Full-stack health check |
| `make gpu-status` | DGX GPU status |
| `make seed-secrets` | Seed Vault |
| `make vault-status` | Vault status |
| `make validate-k8s` | Validate K8s manifests |

## Fleet Configuration

| Node | Role | Hardware | K3s Role |
|------|------|----------|----------|
| Mac Studio | Control plane | M2 Ultra, 192GB RAM, 2TB | Server |
| MacBook Pro | Overflow worker | M3 Pro, 36GB RAM | Agent |
| DGX-1 | GPU inference | AMD EPYC, 512GB, 4x A100 80GB | Agent |
| DGX-2 | GPU inference | AMD EPYC, 512GB, 4x A100 80GB | Agent |

Fleet config: `config/fleet.json5`

## AtlasOS Embedding

AtlasOS is embedded at every level, and every environment should preserve the same four-layer topology:

1. **Node-level**: DaemonSet on every K3s node — monitors CPU, memory, disk, GPU health
2. **Service-level**: Sidecar agents for platform services — health, latency, circuit breaking
3. **Cluster-level**: Shared AtlasOS runtime for the canonical agent layers
4. **Repo-level**: Agent kits in all MedinovAI repos — code quality, CI/CD, dependency management, autonomous PRs

Within the shared AtlasOS runtime, the canonical agent layers are:

1. **Named Assistants**: one assistant per employee or executive persona such as `ceo`/Arjun
2. **Functional Agents**: reusable shared-domain agents such as finance, compliance, recruiting, procurement, and security
3. **Entity Agents**: one runtime per governed entity class such as employees, SOPs, protocols, regulations, customers, clinics, and patients
4. **Squad Agents**: specialist workers that execute delegated tasks, evaluations, and approvals inside a domain

```bash
# Embed in all repos
make embed-atlasos

# Embed in a single repo
make embed-atlasos-repo REPO=medinovai-CTMS

# Embed by category
make embed-atlasos-category CAT=clinical
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
make seed-secrets           # Seed from ~/.atlas/.env or interactively
make vault-status          # Check Vault status
make rotate-secrets        # Rotate expiring secrets

# Vault UI
kubectl port-forward -n vault svc/vault-ui 8200:8200
```

## Governance Controls

The platform enforces 10 mandatory AI governance controls (GOV-01 through GOV-10):

| ID | Control | Description |
|----|---------|-------------|
| GOV-01 | Model Risk Register | Every AI model registered with risk class, impact, mitigation plan |
| GOV-02 | Pre-Deployment Validation | Full validation pipeline before production |
| GOV-03 | Bias Testing | Demographic fairness audits for patient-affecting models |
| GOV-04 | Human Override Pathways | Clinician override with audit logging, no punitive metrics |
| GOV-05 | Explainability Standards | AI outputs labeled with confidence, factors, reasoning |
| GOV-06 | Performance Monitoring | Accuracy drift, alert fatigue, clinical outcome tracking |
| GOV-07 | Data Lineage Tracking | Source-to-model lineage, PHI handling documented |
| GOV-08 | Vendor Accountability | Vendor AI contracts with accountability terms |
| GOV-09 | Incident Response | Model quarantine, escalation, root cause analysis |
| GOV-10 | Cross-Functional Oversight | Governance board approval for clinical AI deployments |

## License

Proprietary — MedinovAI.
