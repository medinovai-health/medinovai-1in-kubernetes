# MedinovAI Deploy

Autonomous deployment, instantiation, CI/CD, and monitoring system for the entire MedinovAI platform.

**medinovai-Deploy** can take a brand-new bare cloud account and stand up a fully operational MedinovAI environment end-to-end -- every service, every database, every secret, every monitoring hook, every governance control -- with zero manual steps. It then owns the ongoing lifecycle: continuous deployment, health monitoring, drift detection, auto-remediation, scaling, cost optimization, compliance enforcement, and disaster recovery.

## Architecture

```
┌───────────────────────────────────────────────────────────────────────────────┐
│                        MedinovAI Deploy System                                │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │                      Orchestration Layer                                │  │
│  │  ┌──────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │ GitHub   │  │ Atlas        │  │ Approval     │  │ Cron         │   │  │
│  │  │ Actions  │  │ Gateway      │  │ Pipelines    │  │ Scheduler    │   │  │
│  │  │ (CI/CD)  │  │ (Agents)     │  │ (Lobster)    │  │              │   │  │
│  │  └────┬─────┘  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘   │  │
│  └───────┼────────────────┼─────────────────┼─────────────────┼───────────┘  │
│          │                │                 │                 │               │
│  ┌───────┼────────────────┼─────────────────┼─────────────────┼───────────┐  │
│  │       ▼           Agent Layer            ▼                 ▼           │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐              │  │
│  │  │ Platform │  │ Eng/CICD │  │ Security │  │  AI/ML   │              │  │
│  │  │ Agent    │  │ Agent    │  │ Agent    │  │  Agent   │              │  │
│  │  │          │  │          │  │          │  │          │              │  │
│  │  │ IaC      │  │ Pipeline │  │ Secrets  │  │ Model    │              │  │
│  │  │ Deploy   │  │ PR/CI    │  │ Vuln     │  │ Deploy   │              │  │
│  │  │ Monitor  │  │ Release  │  │ Comply   │  │ Registry │              │  │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘              │  │
│  │       │              │             │             │                     │  │
│  │  ┌──────────┐  ┌──────────┐                                           │  │
│  │  │   Data   │  │Supervisor│  ← monitors all agents                   │  │
│  │  │  Agent   │  │ Guardian │  ← validates all actions                  │  │
│  │  └──────────┘  └──────────┘                                           │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │                    Infrastructure Layer                                  │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────┐ │  │
│  │  │Terraform │  │Kubernetes│  │  Docker   │  │Monitoring│  │ Secrets │ │  │
│  │  │ Modules  │  │Manifests │  │  Images   │  │  Stack   │  │ Mgmt    │ │  │
│  │  │          │  │          │  │          │  │          │  │         │ │  │
│  │  │ network  │  │ base     │  │ python   │  │ prom     │  │ KMS     │ │  │
│  │  │ compute  │  │ services │  │ node     │  │ grafana  │  │ vault   │ │  │
│  │  │ database │  │ overlays │  │ ml       │  │ alert    │  │ rotate  │ │  │
│  │  │ storage  │  │ monitor  │  │          │  │ loki     │  │         │ │  │
│  │  │ dns/iam  │  │ ingress  │  │          │  │ jaeger   │  │         │ │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └─────────┘ │  │
│  └─────────────────────────────────────────────────────────────────────────┘  │
│                                                                               │
│  ┌─────────────────────────────────────────────────────────────────────────┐  │
│  │                      Cloud Resources                                    │  │
│  │  VPC  │  EKS/GKE  │  RDS/CloudSQL  │  Redis  │  S3/GCS  │  CDN/LB   │  │
│  └─────────────────────────────────────────────────────────────────────────┘  │
└───────────────────────────────────────────────────────────────────────────────┘
```

## What's in This Repo

```
medinovai-deploy/
├── config/                     # Deployment configuration
│   ├── deploy.json5            # Master deploy config (gateway, agents, health, circuit breakers)
│   ├── environments/           # Per-environment overrides (dev, staging, production)
│   ├── schemas/                # JSON schemas (service manifests, data lineage, model risk)
│   └── .env.example            # Secrets template
│
├── infra/                      # Infrastructure as Code
│   ├── terraform/              # Cloud resource provisioning (9 modules)
│   │   ├── modules/            # networking, compute, database, storage, secrets, monitoring, dns, iam, ai-infra
│   │   ├── environments/       # dev, staging, production compositions
│   │   └── global/             # Shared resources (DNS zones, IAM)
│   ├── kubernetes/             # K8s manifests (Kustomize-based)
│   │   ├── base/               # Namespaces, RBAC, network policies, resource quotas
│   │   ├── services/           # Per-service deployments, HPAs, PDBs
│   │   ├── overlays/           # Environment-specific overlays
│   │   ├── monitoring/         # Prometheus, Grafana, Alertmanager, Loki
│   │   └── ingress/            # Nginx ingress, cert-manager, TLS
│   └── docker/                 # Base images (python-service, node-service, ml-service)
│
├── agents/                     # Autonomous deploy agent workspaces
│   ├── platform/               # Platform Ops — IaC, deploy, monitoring, cost
│   ├── eng/                    # Engineering — CI/CD, PRs, releases, dependencies
│   ├── security/               # Security — secrets, vulns, compliance, incidents
│   ├── data/                   # Data — migrations, backups, lineage
│   ├── ai-ml/                  # AI/ML — model deploy, registry, bias, drift
│   ├── supervisor/             # Meta-agent — monitors all deploy agents
│   └── guardian/               # Meta-agent — validates all deploy actions
│
├── scripts/                    # Executable scripts
│   ├── bootstrap/              # Greenfield instantiation (prerequisites, init-cloud, instantiate)
│   ├── deploy/                 # Service deployment (deploy_service, rollback, promote_canary)
│   ├── agents/                 # Agent registration and cron setup
│   ├── maintenance/            # Ongoing ops (secret rotation, cert renewal, backup, drift check)
│   ├── monitoring/             # Monitoring setup and health audits
│   └── validation/             # Config, infra, manifest, compliance validation
│
├── workflows/                  # Approval-gated pipelines (Lobster format)
│   ├── deploy.lobster.md       # Build → stage → approve → deploy → health check
│   ├── infra-change.lobster.md # Plan → review → approve → apply → verify
│   └── ...                     # AI validation, access provisioning, DR, secret rotation
│
├── services/registry/          # Service deployment manifests (one per MedinovAI service)
│
├── .github/workflows/          # GitHub Actions CI/CD pipelines
│
├── docs/                       # Architecture, runbooks, guides
│
└── tests/                      # Unit, integration, and E2E tests
```

## Greenfield Instantiation

Stand up a complete MedinovAI environment from scratch:

```bash
# 1. Check prerequisites
bash scripts/bootstrap/prerequisites.sh

# 2. Initialize cloud account (state bucket, IAM bootstrap)
bash scripts/bootstrap/init-cloud-account.sh --cloud aws --region us-east-1

# 3. Full instantiation (30-45 minutes)
bash scripts/bootstrap/instantiate.sh \
  --cloud aws \
  --region us-east-1 \
  --environment production \
  --domain medinovai.example.com \
  --org-name "Example Health System"
```

The instantiation script executes 15 checkpointed steps:

| Step | Action | Duration |
|------|--------|----------|
| 1 | Prerequisites check | 10s |
| 2 | Cloud account bootstrap (state bucket, lock table, IAM) | 1m |
| 3 | Networking (VPC, subnets, NAT, security groups) | 3m |
| 4 | DNS & certificates (hosted zone, ACM/Let's Encrypt) | 2m |
| 5 | Secrets infrastructure (KMS, Secrets Manager) | 1m |
| 6 | Seed initial secrets (DB passwords, API keys, JWT) | 30s |
| 7 | Databases (RDS PostgreSQL, ElastiCache Redis) | 10m |
| 8 | Database migrations (schema, seed data) | 2m |
| 9 | Compute cluster (EKS/GKE + node groups) | 12m |
| 10 | Base K8s resources (namespaces, RBAC, network policies) | 1m |
| 11 | Monitoring stack (Prometheus, Grafana, Alertmanager, Loki) | 3m |
| 12 | MedinovAI services (in dependency order) | 5m |
| 13 | Ingress & TLS termination | 2m |
| 14 | Smoke tests (health, auth, APIs, AI inference) | 2m |
| 15 | Atlas gateway + agent registration + crons | 1m |

Every step is idempotent. If interrupted, re-running resumes from the last checkpoint.

## Ongoing CI/CD

| Trigger | Pipeline | What Happens |
|---------|----------|-------------|
| Push/PR | `ci.yml` | Lint, validate configs, Terraform validate, K8s validate, unit tests, secret scan |
| Merge to `develop` | `deploy-staging.yml` | Build images, push to registry, deploy to staging, smoke test |
| Release tag `v*` | `deploy-production.yml` | Approval gate, canary deploy (5%), monitor 10min, promote or rollback |
| PR touches `infra/` | `infra-plan.yml` | `terraform plan`, post diff as PR comment |
| Merge `infra/` to `main` | `infra-apply.yml` | `terraform apply` with approval gate per environment |
| Daily 03:00 UTC | `drift-detection.yml` | Detect IaC drift, alert on discrepancies |
| Daily 04:00 UTC | `nightly-health.yml` | Full-stack health audit, cert expiry, backup verification |
| Daily + PR | `security-scan.yml` | Container vuln scan, dependency audit, secret scan |

## Monitoring & Observability

Four-layer monitoring with graduated alerting:

| Layer | What | Tools |
|-------|------|-------|
| Infrastructure | CPU, memory, disk, network, IaC drift, cost | CloudWatch, Terraform |
| Platform | Cluster health, node pressure, pod restarts, HPA | Prometheus, Grafana |
| Application | Request latency, error rates, traces, logs | OpenTelemetry, Jaeger, Loki |
| AI/ML | Inference latency, prediction drift, bias, token cost | Custom metrics, model registry |

## Agents

| Agent | Responsibility | Key Skills |
|-------|---------------|------------|
| **Platform** | IaC, deployments, monitoring, cost, certs | infra-provision, service-deploy, health-audit, cost-optimize, drift-remediate |
| **Eng/CICD** | Pipelines, PRs, releases, dependencies | ci-monitor, pr-review, dependency-planner, pipeline-doctor, release-manager |
| **Security** | Secrets, vulnerabilities, compliance, incidents | secret-scan, vuln-scan, compliance-audit, incident-response |
| **Data** | Migrations, backups, lineage | migration-runner, backup-verify, lineage-track |
| **AI/ML** | Model deployment, registry, bias, drift | model-deploy, model-registry, bias-testing, drift-detection |
| **Supervisor** | Monitors all deploy agents | Intervention logging, health verification |
| **Guardian** | Validates all deploy actions | Policy enforcement, approval gating |

## Docker Local Deployment

For full greenfield deployment on a single machine (survives restarts/crashes):

```bash
make docker-instantiate           # Full stack (postgres, redis, prometheus, grafana, etc.)
make docker-backup                # Backup to ~/medinovai-backups/medinovai-Deploy/
make docker-restore               # Restore from latest backup
make docker-seed                  # Fresh environment from zero
```

See **[docs/DOCKER_GREENFIELD_DEPLOYMENT.md](docs/DOCKER_GREENFIELD_DEPLOYMENT.md)** for the full plan and maintenance guide.

## Quick Reference

```bash
# Setup
make prerequisites                # Check required tools
make setup                        # Full setup: install + deploy + validate

# Infrastructure
make plan ENV=staging             # Terraform plan
make apply ENV=staging            # Terraform apply (requires approval)
make drift-check                  # Check for IaC drift

# Deployments
make deploy-service SVC=api-gateway ENV=staging    # Deploy single service
make deploy-all ENV=staging                         # Deploy all services
make rollback SVC=api-gateway ENV=staging           # Rollback service
make promote-canary SVC=api-gateway ENV=production  # Promote canary to full

# Monitoring
make health                       # Full-stack health check
make status                       # Atlas gateway status
make logs                         # Follow deploy logs
make dashboards                   # Open Grafana dashboards

# Maintenance
make rotate-secrets               # Rotate expiring secrets
make cert-check                   # Check certificate expiry
make backup-verify                # Verify backup integrity
make cost-report                  # Generate cost report

# Validation
make validate                     # Full validation suite
make validate-infra               # Terraform validate
make validate-k8s                 # K8s manifest validation
make validate-compliance          # GOV-01 through GOV-10 check
```

## Governance Controls

All 10 AI governance controls (GOV-01 through GOV-10) are enforced at deploy time:

| Control | Enforcement Point |
|---------|-------------------|
| GOV-01: Model Risk Register | Pre-deploy validation requires registry entry |
| GOV-02: Pre-Deployment Validation | AI model validation pipeline (benchmark, bias, shadow) |
| GOV-03: Bias Testing | Automated bias audit in validation pipeline |
| GOV-04: Human Override | Override mechanisms verified in smoke tests |
| GOV-05: Explainability | Schema validation ensures required fields |
| GOV-06: Performance Monitoring | Monitoring stack auto-configured per model risk class |
| GOV-07: Data Lineage | Lineage records verified before pipeline deploy |
| GOV-08: Vendor Accountability | Vendor contract ref required in manifest |
| GOV-09: Incident Response | Quarantine mechanism tested in staging |
| GOV-10: Cross-Functional Oversight | Approval gates enforce board sign-off |

## License

Private. Internal use only. MedinovAI / MyOnsite Healthcare.
