# MedinovAI Platform — Complete Deployment Sequence

Copyright 2025-2026 MedinovAI. All Rights Reserved.

Generated from `config/dependency-graph.json`

---

## Quick Reference

| Phase | Tier Name | # Services | Strategy | Estimated Time |
|-------|-----------|------------|----------|-----------------|
| 0 | Bare Infrastructure | 19 | Parallel (docker-compose / Terraform) | 5–15 min |
| 1 | Security & Secrets Foundation | 8 | Sequential | 20–30 min |
| 2 | Platform Core | 9 | Sequential | 25–40 min |
| 3 | AI/ML & Clinical Foundation | 6 | Parallel (3 groups) | 15–25 min |
| 4 | Domain Services | 54 | Parallel (7 sub-groups) | 60–90 min |
| 5 | Integration & Specialized | 18 | All parallel | 20–35 min |
| 6 | UI Shell & Master Menu | 3 | Sequential | 10–15 min |

**Total:** ~109 services | **Full deployment:** ~3–4 hours

---

## Prerequisites

| Tool | Purpose |
|------|---------|
| **docker** | Container runtime for dev/staging; compose for infra |
| **kubectl** | Kubernetes CLI for production deployments |
| **terraform** | IaC for production infrastructure (AKS, networking) |
| **helm** | Package manager for Kubernetes charts |
| **python3** | Dependency-graph parsing, validation scripts |
| **node 22+** | Node services, npm publish targets |
| **atlas CLI** | Atlas gateway & agent management |

Verify prerequisites:
```bash
docker --version && kubectl version --client && terraform --version && helm version && python3 --version && node --version && atlas --version
```

---

## Phase 0: Bare Infrastructure

19 infrastructure components. Must exist before any MedinovAI services. Deploy via `docker compose` (dev) or Terraform (staging/production).

| # | Component | Port | Health Check |
|---|-----------|------|--------------|
| 1 | postgres-primary | 5432 | `pg_isready` |
| 2 | postgres-clinical | 5433 | `pg_isready` |
| 3 | redis-cache | 6379 | `redis-cli ping` |
| 4 | zookeeper | 2181 | `echo ruok \| nc localhost 2181` |
| 5 | kafka | 9092 | `kafka-topics --bootstrap-server localhost:9092 --list` |
| 6 | mongodb | 27017 | `mongosh --eval db.adminCommand('ping')` |
| 7 | elasticsearch | 9200 | `GET /_cluster/health` |
| 8 | rabbitmq | 5672 | `rabbitmq-diagnostics ping` |
| 9 | vault | 8200 | `GET /v1/sys/health` |
| 10 | keycloak | 9080 | `GET /health/ready` |
| 11 | pgbouncer | 6432 | `psql -h localhost -p 6432 -c 'SELECT 1'` |
| 12 | s3-object-store | — | `aws s3 ls` (or LocalStack endpoint) |
| 13 | prometheus | 9090 | `GET /-/healthy` |
| 14 | grafana | 3000 | `GET /api/health` |
| 15 | loki | 3100 | `GET /ready` |
| 16 | alertmanager | 9093 | `GET /-/healthy` |
| 17 | jaeger | 16686 | `GET /` |
| 18 | mailhog | 8025 | `GET /api/v2/messages` (dev/staging) |
| 19 | localstack | 4566 | `GET /_localstack/health` (dev) |

**Note:** `vault` and `keycloak` depend on `postgres-primary`. `kafka` depends on `zookeeper`. `grafana` depends on `prometheus`.

---

## Phase 1: Security & Secrets Foundation (8 services)

Sequential deployment. ALL other services depend on this tier.

| Seq | Service | Port | Health Endpoint | Depends On | Strategy | Est. Startup |
|-----|---------|------|-----------------|------------|----------|--------------|
| 1 | medinovai-secrets-manager-bridge | 8000 | /health | vault | rolling | ~30s |
| 2 | medinovai-security | 9000 | /health | keycloak, postgres-primary, redis-cache, pgbouncer, secrets-bridge | rolling | ~45s |
| 3 | medinovai-universal-sign-on | 8000 | /health | postgres-primary, redis-cache, vault, kafka, security | rolling | ~40s |
| 4 | medinovai-role-based-permissions | 8000 | /healthz | postgres-primary, redis-cache, security | rolling | ~35s |
| 5 | medinovai-encryption-vault | 8000 | /health | vault, secrets-bridge | rolling | ~30s |
| 6 | medinovai-hipaa-gdpr-guard | 8000 | /health | postgres-primary, redis-cache, security, RBAC | rolling | ~40s |
| 7 | medinovai-consent-preference-api | 8000 | /health | postgres-primary, redis-cache, security, hipaa-guard | rolling | ~35s |
| 8 | medinovai-audit-trail-explorer | 8000 | /health | postgres-primary, redis-cache, elasticsearch, security | rolling | ~40s |

---

## Phase 2: Platform Core (9 services)

Sequential deployment.

| Seq | Service | Port | Health Endpoint | Depends On | Strategy | Est. Startup |
|-----|---------|------|-----------------|------------|----------|--------------|
| 1 | medinovai-registry | 8080 | /health | postgres-primary, redis-cache, security | rolling | ~45s |
| 2 | medinovai-data-services | 8000 | /health | postgres-primary, postgres-clinical, redis-cache, security | rolling | ~60s |
| 3 | medinovai-real-time-stream-bus | 3000 | /health/ready | kafka, redis-cache, security | rolling | ~40s |
| 4 | medinovai-configuration-management | 8000 | /health | postgres-primary, redis-cache, security | rolling | ~35s |
| 5 | medinovai-notification-center | 8080 | /health | postgres-primary, redis-cache, rabbitmq, security | rolling | ~45s |
| 6 | medinovai-aifactory | 8000 | /health | postgres-primary, redis-cache, security | rolling | ~60s |
| 7 | medinovai-api-gateway | 8080 | /health | security, RBAC, registry | rolling | ~45s |
| 8 | medinovai-web-core | — | — | security, RBAC (npm-publish) | rolling | N/A |
| 9 | medinovai-atlas-engine | 8000 | /health | postgres-primary, redis-cache, security, registry | rolling | ~50s |

---

## Phase 3: AI/ML & Clinical Foundation (6 services)

**Parallel groups** — deploy each group in parallel; groups run sequentially.

### Parallel Group 1 (deploy together)
| Seq | Service | Port | Health Endpoint | Depends On | Est. Startup |
|-----|---------|------|-----------------|------------|--------------|
| 1 | medinovai-healthLLM | 8000 | /health | postgres-primary, redis-cache, security, aifactory | ~90s |
| 2 | medinovai-model-service-orchestrator | 8000 | /health | postgres-primary, redis-cache, kafka, s3, security, data-services | ~60s |
| 3 | medinovai-knowledge-graph | 8000 | /health | postgres-primary, elasticsearch, security, data-services | ~60s |

### Parallel Group 2 (after Group 1)
| Seq | Service | Port | Health Endpoint | Depends On | Est. Startup |
|-----|---------|------|-----------------|------------|--------------|
| 4 | medinovai-clinical-decision-support | 8000 | /health | postgres-primary, redis-cache, healthLLM, model-orchestrator, data-services | ~60s |
| 5 | medinovai-patient-services | 8000 | /health | postgres-primary, redis-cache, security, data-services, consent-preference-api | ~45s |

### Group 3 (config-only; no runtime)
| 6 | medinovai-ai-standards | — | — | config-only | N/A |

---

## Phase 4: Domain Services (54 services across 7 sub-groups)

Each sub-group has its own deploy order. Sub-groups can run in parallel; within a group, services deploy in order.

### 4A: Clinical Services (9 services)
| Order | Service | Port | Health |
|-------|---------|------|--------|
| 1 | medinovai-patient-onboarding | 8000 | /health |
| 2 | medinovai-patientmatching | 8080 | /healthz |
| 3 | medinovai-health-timeline | 8000 | /health |
| 4 | medinovai-care-team-chat | 8000 | /health |
| 5 | medinovai-smart-scheduler | 8000 | /health |
| 6 | medinovai-wait-list-balancer | 8080 | /healthz |
| 7 | medinovai-virtual-triage | 8000 | /health |
| 8 | medinovai-telehealth-hub | 8080 | /healthz |
| 9 | medinovai-remote-vitals-ingest | 8000 | /health |

### 4B: Diagnostic Services (5 services)
| Order | Service | Port | Health |
|-------|---------|------|--------|
| 1 | medinovai-lab-order-router | 8000 | /health |
| 2 | medinovai-pathology-ai | 8000 | /health |
| 3 | medinovai-imaging-viewer | 8000 | /health |
| 4 | medinovai-genomics-interpreter | 8000 | /health |
| 5 | medinovai-image-to-text-ocr | 8000 | /health |

### 4C: AI Services (11 services)
| Order | Service | Port | Health |
|-------|---------|------|--------|
| 1 | medinovai-chatbot | 8000 | /api/health |
| 2 | medinovai-ai-scribe | 8000 | /health |
| 3 | medinovai-doc-summarizer | 8000 | /health |
| 4 | medinovai-natural-language-query | 8000 | /health |
| 5 | medinovai-anomaly-detector | 8000 | /health |
| 6 | medinovai-sentiment-monitor | 8000 | /health |
| 7 | medinovai-drug-interaction-checker | 8000 | /health |
| 8 | medinovai-medical-fax-processing | 8000 | /health |
| 9 | medinovai-content-translator | 8000 | /health |
| 10 | medinovai-text-to-speech-narrator | 8000 | /health |
| 11 | medinovai-voice-command-layer | 8000 | /health |

### 4D: Medication & Pharmacy (2 services)
| Order | Service | Port | Health |
|-------|---------|------|--------|
| 1 | medinovai-e-prescribe-gateway | 8000 | /health |
| 2 | medinovai-medication-tracker | 8000 | /health |

### 4E: Research & Clinical Trials (15 services)
| Order | Service | Port | Health |
|-------|---------|------|--------|
| 1 | medinovai-CTMS | 8000 | /health |
| 2 | medinovai-EDC | 8000 | /health |
| 3 | medinovai-etmf | 8000 | /health |
| 4 | medinovai-saes | 8080 | /api/health |
| 5 | medinovai-eConsent | 8000 | /health |
| 6 | medinovai-ePRO | 8000 | /health |
| 7 | medinovai-eSource | 8000 | /health |
| 8 | medinovai-eISF | 8000 | /health |
| 9 | medinovai-iwrs | 8000 | /health |
| 10 | medinovai-Pharmacovigilance | 8000 | /health |
| 11 | medinovai-ResearchSuite | 8000 | /health |
| 12 | medinovai-regulatory-submissions | 8000 | /health |
| 13 | medinovai-RBM | 8000 | /health |
| 14 | medinovai-reseach-fabric | 8000 | /health |
| 15 | medinovai-SiteFeasibility | 8000 | /health |

### 4F: Business Services (9 services)
| Order | Service | Port | Health |
|-------|---------|------|--------|
| 1 | medinovai-billing | 8000 | /health |
| 2 | medinovai-provider-credentialing | 8000 | /health |
| 3 | medinovai-credentialing | 3000 | /health |
| 4 | medinovai-employee-portal | 3000 | /health |
| 5 | medinovai-subscription | 8000 | /health/ |
| 6 | medinovai-quality-certification | 8000 | /health |
| 7 | medinovai-inventorymanagement | 8000 | /health |
| 8 | medinovai-mail | 8000 | /health |
| 9 | medinovai-email-service | 8000 | /health |

### 4G: Laboratory Information System (3 services)
| Order | Service | Port | Health |
|-------|---------|------|--------|
| 1 | medinovai-lis | 8000 | /health |
| 2 | medinovai-lis-platform | 8000 | /health |
| 3 | medinovai-lis-ui | 3000 | /health |

---

## Phase 5: Integration & Specialized (18 services)

**All parallel** — deploy concurrently (max 4 jobs by default).

| Service | Port | Health | Depends On |
|---------|------|--------|------------|
| medinovai-edge-cache-cdn | 8000 | /health | api-gateway |
| medinovai-data-lake-loader | 8000 | /health | real-time-stream-bus, data-services |
| medinovai-feature-flag-console | 8000 | /health | security, configuration-management |
| medinovai-canary-rollout-orchestrator | 8000 | /health | registry |
| medinovai-devops-telemetry | 8000 | /health | prometheus, security |
| medinovai-policy-diff-watcher | 8000 | /health | security |
| medinovai-etl-designer | 8000 | /health | data-services, security |
| medinovai-prompt-vault | 8000 | /healthz | security |
| medinovai-qa-agent-builder | 8000 | /health | model-service-orchestrator, security |
| medinovai-task-kanban | 8000 | /health | notification-center, security |
| medinovai-guideline-updater | 8000 | /health | knowledge-graph, security |
| medinovai-white-label-skinner | 8000 | /health | web-core |
| medinovai-accessibility-checker | 8000 | /health | security |
| medinovai-governance-templates | 8000 | /health | security |
| medinovai-risk-management | 8000 | /health | data-services, security |
| medinovai-cds | 8000 | /health | clinical-decision-support, security |
| medinovai-developer-portal | 3000 | /health | api-gateway, registry |
| medinovai-Livekit | 7880 | /health | redis-cache, security |

---

## Phase 6: UI Shell & Master Menu (3 services)

**Sequential. medinovaios LAST** — the unified entry point depends on all other services.

| Seq | Service | Port | Health | Depends On | Notes |
|-----|---------|------|--------|------------|-------|
| 1 | medinovai-ui-components | — | — | web-core | npm-publish |
| 2 | medinovai-multimodal-ui-shell | 3000 | /health | web-core, ui-components | |
| 3 | **medinovaios** | 5173 | / | security, SSO, RBAC, api-gateway, registry | Master Menu — deploy last |

---

## Critical Path (Minimum Viable Platform)

The minimum set of 12 services for a functional platform. Deploy in this exact order:

| # | Service |
|---|---------|
| 1 | postgres-primary |
| 2 | redis-cache |
| 3 | keycloak |
| 4 | vault |
| 5 | medinovai-secrets-manager-bridge |
| 6 | medinovai-security |
| 7 | medinovai-universal-sign-on |
| 8 | medinovai-role-based-permissions |
| 9 | medinovai-registry |
| 10 | medinovai-data-services |
| 11 | medinovai-api-gateway |
| 12 | medinovaios |

---

## Rollback Strategy

| Tier | Rollback Approach |
|------|-------------------|
| **Phase 0** | `docker compose down` or Terraform destroy (careful in production). Restore DB backups if needed. |
| **Phase 1** | Roll back services in reverse order: audit-trail → consent-api → hipaa-guard → encryption-vault → RBAC → SSO → security → secrets-bridge. Use `scripts/deploy/rollback_service.sh`. |
| **Phase 2** | Roll back sequentially in reverse: atlas-engine → web-core → api-gateway → aifactory → notification-center → configuration-management → stream-bus → data-services → registry. |
| **Phase 3** | Roll back parallel groups in reverse; within groups, reverse order. |
| **Phase 4** | Roll back per sub-group in reverse deploy order. |
| **Phase 5** | Roll back any failed service; others can remain. |
| **Phase 6** | Roll back medinovaios first, then multimodal-ui-shell, then ui-components. |

**General rollback command:**
```bash
bash scripts/deploy/rollback_service.sh --service <service-id> --environment <env>
```

---

## Post-Deployment Validation

### Tier health checks
```bash
# Check a specific tier
bash scripts/validation/health_check_tier.sh --tier 1 --timeout 30

# Check all tiers
bash scripts/validation/health_check_tier.sh --tier all --timeout 30

# Verbose
bash scripts/validation/health_check_tier.sh --tier 2 --verbose
```

### Smoke tests
```bash
bash scripts/validation/smoke_test.sh
```

### Full platform health
```bash
bash scripts/monitoring/health_check_all.sh
```

---

## Bash Commands: Deploying Each Phase

All commands assume execution from the `medinovai-Deploy` repository root.

### Deploy everything (all phases)
```bash
bash scripts/deploy/deploy_all.sh --environment dev
bash scripts/deploy/deploy_all.sh --environment staging
bash scripts/deploy/deploy_all.sh --environment production
```

### Deploy critical path only (12 services)
```bash
bash scripts/deploy/deploy_all.sh --environment staging --critical-path-only
bash scripts/deploy/deploy_all.sh --environment dev --critical-path-only
```

### Deploy a single tier
```bash
# Phase 1
bash scripts/deploy/deploy_all.sh --environment staging --tier 1

# Phase 2
bash scripts/deploy/deploy_all.sh --environment staging --tier 2

# Phase 3
bash scripts/deploy/deploy_all.sh --environment staging --tier 3

# Phase 4
bash scripts/deploy/deploy_all.sh --environment staging --tier 4

# Phase 5
bash scripts/deploy/deploy_all.sh --environment staging --tier 5

# Phase 6
bash scripts/deploy/deploy_all.sh --environment staging --tier 6
```

### Deploy from a specific tier onward
```bash
# Skip Phases 0–2, start from Phase 3
bash scripts/deploy/deploy_all.sh --environment staging --start-tier 3
```

### Dry run (no actual deployment)
```bash
bash scripts/deploy/deploy_all.sh --environment staging --dry-run
bash scripts/deploy/deploy_all.sh --environment production --critical-path-only --dry-run
```

### Advanced options
```bash
# More parallel jobs for Phase 4/5
bash scripts/deploy/deploy_all.sh --environment staging --parallel-jobs 8

# Longer health timeout
bash scripts/deploy/deploy_all.sh --environment staging --health-timeout 180

# Continue on failure (do not stop at first failed service)
bash scripts/deploy/deploy_all.sh --environment staging --no-stop-on-fail
```

---

*Generated from `config/dependency-graph.json` v2.0.0. For machine-readable data, see the dependency graph and `scripts/deploy/deploy_all.sh`.*
