# Deployment Brain — Master Reference

> This document is the single source of truth for deploying the MedinovAI platform on local developer machines, Tailscale HA clusters, and cloud Kubernetes. It encodes everything learned from live deployments so any future agent or engineer can reproduce the full environment from zero.

**Last validated**: February 2026  
**Primary machine**: `mayank-mbp25` · Tailscale `100.79.214.33`  
**Repo**: `medinovai-Deploy` (this repo)

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Quick Start (TL;DR)](#2-quick-start-tldr)
3. [Docker Compose Infra Layer](#3-docker-compose-infra-layer)
4. [Kubernetes App Layer](#4-kubernetes-app-layer)
5. [Cluster Addons](#5-cluster-addons)
6. [Tailscale Multi-Machine HA](#6-tailscale-multi-machine-ha)
4. [Kubernetes App Layer](#4-kubernetes-app-layer)
5. [Tailscale Multi-Machine HA](#5-tailscale-multi-machine-ha)
6. [Scripts Reference](#6-scripts-reference)
7. [Makefile Targets](#7-makefile-targets)
8. [Service Endpoints](#8-service-endpoints)
9. [Smoke Tests](#9-smoke-tests)
10. [Known Issues and Fixes](#10-known-issues-and-fixes)
11. [Adding a New Machine](#11-adding-a-new-machine)
12. [Replacing Stub Images with Real Services](#12-replacing-stub-images-with-real-services)
13. [Backup and Restore](#13-backup-and-restore)
14. [File Map](#14-file-map)

---

## 1. Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│  DEVELOPER MACHINE (macOS)                                          │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  LAYER 1: Docker Compose (infra/docker/docker-compose.dev.yml│   │
│  │                                                              │   │
│  │  ┌──────────┐ ┌──────┐ ┌────────────┐ ┌────────┐           │   │
│  │  │ postgres │ │redis │ │ prometheus │ │grafana │  ...       │   │
│  │  │  :5432   │ │:6379 │ │   :9090    │ │ :3000  │           │   │
│  │  └──────────┘ └──────┘ └────────────┘ └────────┘           │   │
│  │                                                              │   │
│  │  All have: restart=unless-stopped, named volumes, healthcheck│   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                ↕  host.docker.internal              │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  LAYER 2: Kubernetes (docker-desktop context)                │   │
│  │                                                              │   │
│  │  namespace: medinovai-services                               │   │
│  │  ┌─────────────┐ ┌──────────────┐ ┌─────────────────────┐  │   │
│  │  │ api-gateway  │ │ auth-service │ │  clinical-engine    │  │   │
│  │  │  NodePort    │ │  NodePort    │ │  data-pipeline      │  │   │
│  │  │  :30080      │ │  :30081      │ │  notification-svc   │  │   │
│  │  └─────────────┘ └──────────────┘ └─────────────────────┘  │   │
│  │  namespace: medinovai-ai                                     │   │
│  │  ┌─────────────┐                                            │   │
│  │  │ ai-inference │  (no GPU requirement in local overlay)    │   │
│  │  └─────────────┘                                            │   │
│  └──────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

**Key principle**: Layer 1 (Docker Compose) must be running before Layer 2 (K8s) — K8s pods connect to postgres/redis via `host.docker.internal`.

---

## 2. Quick Start (TL;DR)

### Prerequisites
- Docker Desktop with Kubernetes enabled
- `kubectl` configured: `kubectl config use-context docker-desktop`
- Tailscale installed and authenticated

### First machine (primary — hosts shared DB)
```bash
git clone git@github.com:myonsite-healthcare/medinovai-Deploy.git
cd medinovai-Deploy
make docker-up
make k8s-install-primary
```

### Every additional machine
```bash
git clone git@github.com:myonsite-healthcare/medinovai-Deploy.git
cd medinovai-Deploy
make docker-up
bash scripts/bootstrap/install-k8s.sh --db-host 100.79.214.33
# Replace 100.79.214.33 with primary machine's Tailscale IP
```

### Verify everything works
```bash
make k8s-status
curl -sf http://localhost:30080 | grep Hostname
```

---

## 3. Docker Compose Infra Layer

**File**: `infra/docker/docker-compose.dev.yml`  
**Project name**: `medinovai-dev` (volumes are prefixed `medinovai-dev_*`)

### Services

| Service | Container Name | Ports | Volume |
|---------|---------------|-------|--------|
| postgres | `medinovai-postgres` | `5432:5432` | `medinovai-dev_postgres-data` |
| redis | `medinovai-redis` | `6379:6379` | `medinovai-dev_redis-data` |
| prometheus | `medinovai-prometheus` | `9090:9090` | `medinovai-dev_prometheus-data` |
| grafana | `medinovai-grafana` | `3000:3000` | `medinovai-dev_grafana-data` |
| mailhog | `medinovai-mailhog` | `1025`, `8025` | — |
| localstack | `medinovai-localstack` | `4566:4566` | `medinovai-dev_localstack-data` |

### Key Design Decisions
- `restart: unless-stopped` on every service — survives machine reboots
- `healthcheck` on every service with `start_period` — compose waits for health before dependent services start
- `depends_on` with `condition: service_healthy` — ordering guaranteed
- Redis uses `--appendonly yes` for AOF persistence (survives restarts with no data loss)
- All volumes are **named** (never anonymous) — makes backup/restore reliable

### Environment Variables
Copy `infra/docker/.env.example` to `infra/docker/.env` and adjust:
```bash
POSTGRES_PASSWORD=your-password
REDIS_PASSWORD=your-password
GRAFANA_ADMIN_PASSWORD=your-password
```

---

## 4. Kubernetes App Layer

### Overlay System (Kustomize)

| Overlay | Context | When to Use |
|---------|---------|------------|
| `docker-desktop` | Local laptop, Docker Desktop K8s | Development, testing, demos |
| `dev` | Cloud dev cluster | Shared dev environment |
| `staging` | Cloud staging cluster | Pre-production validation |
| `production` | Cloud production cluster | Live traffic |

**Always use `docker-desktop` overlay on local machines:**
```bash
kubectl apply -k infra/kubernetes/overlays/docker-desktop
```

### What the docker-desktop Overlay Does

1. **Image substitution**: Swaps real service images for `traefik/whoami:latest` (stub that responds to any HTTP path)
2. **Resource reduction**: Lowers CPU/memory requests/limits for laptop hardware
3. **GPU removal**: JSON patches remove `nvidia.com/gpu` requirement from `ai-inference`
4. **NodePort exposure**: Exposes `api-gateway` (30080) and `auth-service` (30081) for Tailscale access
5. **Quota reduction**: Reduces ResourceQuota limits for `medinovai-services` and `medinovai-ai` namespaces
6. **ConfigMap injection**: Injects `DATABASE_URL`, `REDIS_URL`, `NODE_ENV` pointing to `host.docker.internal`

### Namespaces

| Namespace | Services |
|-----------|---------|
| `medinovai-services` | api-gateway, auth-service, clinical-engine, data-pipeline, notification-service |
| `medinovai-ai` | ai-inference |
| `medinovai-data` | (future: data services) |
| `medinovai-monitoring` | (future: observability) |

### Patch Files

| File | Purpose |
|------|---------|
| `patch-api-gateway.yaml` | Stub image + resources + env injection |
| `patch-auth-service.yaml` | Stub image + resources + env injection |
| `patch-clinical-engine.yaml` | Stub image + resources + env injection |
| `patch-data-pipeline.yaml` | Stub image + resources + env injection |
| `patch-notification-service.yaml` | Stub image + resources + env injection |
| `patch-ai-inference.yaml` | Stub image + resources + remove GPU limit/toleration |
| `patch-api-gateway-nodeport.yaml` | NodePort 30080 |
| `patch-auth-service-nodeport.yaml` | NodePort 30081 |
| `patch-quota-services.yaml` | Reduce medinovai-services ResourceQuota |
| `patch-quota-ai.yaml` | Reduce medinovai-ai ResourceQuota |
| `patch-quota-monitoring.yaml` | Reduce medinovai-monitoring ResourceQuota |

### ConfigMaps for Environment Variables

| File | Namespace | Committed? | Content |
|------|-----------|-----------|---------|
| `configmap-env.yaml` | medinovai-services | ✓ Yes | Default (host.docker.internal) |
| `configmap-env-local.yaml` | medinovai-services | ✗ Gitignored | Generated by tailscale-config.sh with actual DB host |
| `configmap-env-ai.yaml` | medinovai-ai | ✓ Yes | Default (host.docker.internal) |
| `configmap-env-ai-local.yaml` | medinovai-ai | ✗ Gitignored | Generated by tailscale-config.sh |

---

## 5. Tailscale Multi-Machine HA

### Concept

One machine is "primary" — it runs postgres and redis for the entire cluster. All other machines ("secondaries") point their K8s pods at the primary's Tailscale IP for database access. Each machine runs its own K8s cluster with all 6 app services, enabling HA.

```
Primary:   docker-up (postgres + redis serve entire cluster)
           k8s install (6 app services → DB via host.docker.internal)

Secondary: docker-up (monitoring only — postgres not exposed externally)
           k8s install → DB via PRIMARY_TAILSCALE_IP:5432
```

### This Deployment's Primary Machine

| Field | Value |
|-------|-------|
| Hostname | `mayank-mbp25` |
| Tailscale IP | `100.79.214.33` |
| Postgres | `100.79.214.33:5432` |
| Redis | `100.79.214.33:6379` |
| api-gateway | `http://100.79.214.33:30080` |
| auth-service | `http://100.79.214.33:30081` |

### Required Firewall / Tailscale ACL

Ensure these ports are open on the Tailscale ACL for intra-cluster traffic:

| Port | Service | Direction |
|------|---------|-----------|
| 5432 | PostgreSQL | Secondary → Primary |
| 6379 | Redis | Secondary → Primary |
| 30080 | api-gateway NodePort | Any → Any |
| 30081 | auth-service NodePort | Any → Any |
| 9090 | Prometheus | Any → Any (optional) |
| 3000 | Grafana | Any → Any (optional) |

### Tailscale Detection Script

`scripts/bootstrap/tailscale-config.sh` auto-detects this machine's Tailscale IP and hostname, then generates:
- `.env.tailscale` — shell-sourceable with `TS_IP`, `TS_HOSTNAME`, `DB_HOST`, `REDIS_HOST`
- `configmap-env-local.yaml` — K8s ConfigMap for medinovai-services namespace
- `configmap-env-ai-local.yaml` — K8s ConfigMap for medinovai-ai namespace

These files are gitignored — they are machine-specific and must be regenerated on each new machine.

---

## 6. Scripts Reference

### Lifecycle Scripts

```bash
# Full greenfield Docker Compose setup (8 steps with checkpoints)
bash scripts/bootstrap/instantiate-docker.sh

# Kubernetes install (auto-detects Tailscale, installs overlay, waits for healthy)
bash scripts/bootstrap/install-k8s.sh
bash scripts/bootstrap/install-k8s.sh --primary          # This machine is primary
bash scripts/bootstrap/install-k8s.sh --db-host <ts-ip>  # Secondary pointing at primary

# Kubernetes uninstall
bash scripts/bootstrap/uninstall-k8s.sh              # K8s only
bash scripts/bootstrap/uninstall-k8s.sh --also-infra # K8s + Docker Compose

# Tailscale config (re-run whenever Tailscale IP changes)
bash scripts/bootstrap/tailscale-config.sh --primary
bash scripts/bootstrap/tailscale-config.sh --db-host <primary-ts-ip>
```

### Data Management Scripts

```bash
# Backup (run before any infra change)
bash scripts/backup.sh
# Output: ~/medinovai-backups/medinovai-Deploy/{db,volumes,config}/

# Restore from latest backup
bash scripts/restore.sh --from-latest

# Seed fresh environment
bash scripts/seed.sh
bash scripts/seed.sh --reset  # Wipe volumes first, then seed
```

---

## 7. Makefile Targets

```bash
make docker-up           # Start Docker Compose infra
make docker-down         # Stop (volumes preserved)
make docker-backup       # Backup DB + volumes
make docker-restore      # Restore from backup
make docker-seed         # Seed fresh DB
make docker-instantiate  # Full greenfield bootstrap

make k8s-install         # Install K8s (auto Tailscale)
make k8s-install-primary # Install K8s as primary node
make k8s-uninstall       # Remove K8s resources
make k8s-reinstall       # Uninstall + reinstall
make k8s-status          # Print pod + service status

make tailscale-config    # Re-run Tailscale detection
```

---

## 8. Service Endpoints

| Service | Local | Via Primary Tailscale |
|---------|-------|----------------------|
| api-gateway | `http://localhost:30080` | `http://100.79.214.33:30080` |
| auth-service | `http://localhost:30081` | `http://100.79.214.33:30081` |
| Grafana | `http://localhost:3000` | `http://100.79.214.33:3000` |
| Prometheus | `http://localhost:9090` | `http://100.79.214.33:9090` |
| MailHog UI | `http://localhost:8025` | — |
| PostgreSQL | `localhost:5432` | `100.79.214.33:5432` |
| Redis | `localhost:6379` | `100.79.214.33:6379` |
| LocalStack | `localhost:4566` | — |

---

## 9. Smoke Tests

Run this sequence after every install or reinstall. All checks should pass.

```bash
#!/usr/bin/env bash
set -e
echo "=== Docker Infra ==="
docker exec medinovai-postgres pg_isready -U medinovai -d medinovai && echo "✓ postgres"
docker exec medinovai-redis redis-cli -a localdev ping && echo "✓ redis"
curl -sf http://localhost:9090/-/healthy && echo "✓ prometheus"
curl -sf http://localhost:3000/api/health && echo "✓ grafana"

echo ""
echo "=== K8s Pods ==="
kubectl get pods -n medinovai-services
kubectl get pods -n medinovai-ai

echo ""
echo "=== K8s NodePorts ==="
curl -sf http://localhost:30080 | grep -q Hostname && echo "✓ api-gateway"
curl -sf http://localhost:30081 | grep -q Hostname && echo "✓ auth-service"

echo ""
echo "=== Tailscale (run from secondary machine) ==="
echo "nc -zv 100.79.214.33 5432"
echo "curl -sf http://100.79.214.33:30080 | grep Hostname"
```

---

## 10. Known Issues and Fixes

These bugs were encountered and fixed during live deployment. Do not re-introduce them.

### Issue 1 — `readOnlyRootFilesystem` at pod level (strict decoding error)

**Error**:
```
error: error validating data: strict decoding error:
  unknown field "spec.template.spec.securityContext.readOnlyRootFilesystem",
  unknown field "spec.template.spec.securityContext.allowPrivilegeEscalation"
```

**Root cause**: `readOnlyRootFilesystem` and `allowPrivilegeEscalation` are **container-level** security context fields, not pod-level. The base `deployment.yaml` files had them at the wrong level.

**Fix**: Removed from `spec.template.spec.securityContext` in all 6 base service `deployment.yaml` files. Only `runAsNonRoot`, `runAsUser`, `fsGroup`, `supplementalGroups`, `sysctls` are valid pod-level security context fields.

**Rule going forward**: Always check field placement before adding securityContext fields. Pod level ≠ container level.

---

### Issue 2 — ai-inference pod stuck Pending (GPU)

**Error**:
```
0/1 nodes are available: 1 Insufficient nvidia.com/gpu.
preemption: 0/1 nodes are available: 1 No preemption victims found for incoming pod.
```

**Root cause**: Base `ai-inference` deployment requests `nvidia.com/gpu: 1` and has a toleration for `nvidia.com/gpu: NoSchedule`. Docker Desktop has no GPU node.

**Fix**: JSON 6902 patches in `patch-ai-inference.yaml`:
```yaml
- op: remove
  path: /spec/template/spec/tolerations
- op: remove
  path: /spec/template/spec/containers/0/resources/limits/nvidia.com~1gpu
```

**Key learning**: `/` in JSON Patch paths must be escaped as `~1`. So `nvidia.com/gpu` → `/nvidia.com~1gpu`.

---

### Issue 3 — ResourceQuota conflict

**Error**:
```
may not add resource with an already registered id: ~G_v1_ResourceQuota|medinovai-services|compute-quota
```

**Root cause**: Base already defines `ResourceQuota`. Overlay was re-adding it as a `resource:` (Kustomize treats this as a new resource, causing a duplicate ID conflict).

**Fix**: Move quota overrides from `resources:` to `patches:` targeting the existing base objects:
```yaml
patches:
  - path: patch-quota-services.yaml
    target:
      kind: ResourceQuota
      name: compute-quota
      namespace: medinovai-services
```

---

### Issue 4 — `commonLabels` deprecated in Kustomize

**Warning**:
```
'commonLabels' is deprecated. Please use 'labels' instead.
```

**Fix**: Replace `commonLabels:` block with:
```yaml
labels:
  - pairs:
      environment: docker-desktop
    includeSelectors: false
```

---

### Issue 5 — Strategic merge patch cannot delete resource limit keys

**Problem**: Patching `resources.limits` with a strategic merge patch merges map keys. If the base has `nvidia.com/gpu: 1` and your patch omits it, the GPU key survives. You cannot delete a key by omitting it.

**Fix**: Use JSON 6902 patch with `op: remove` to explicitly delete the key.

---

### Issue 6 — Docker Compose volume names have project prefix

**Problem**: With `name: medinovai-dev` in the compose file, Docker prefixes all volumes: `medinovai-dev_postgres-data`, not `postgres-data`. Scripts that use bare volume names fail.

**Fix**: Use dynamic lookup:
```bash
vol=$(docker volume ls -q | grep "postgres-data$" | head -1)
```

---

### Issue 7 — kubectl context not set

**Error**: `error: current-context is not set`

**Fix**: `kubectl config use-context docker-desktop`

---

### Issue 8 — Tailscale client/server version mismatch

**Warning**: `Warning: client (1.x.y) / server (1.x.y-1) version mismatch`

**Impact**: None. Tailscale still works. Update Tailscale when convenient.

---

## 11. Adding a New Machine

Complete checklist for onboarding a new developer machine to the HA cluster:

```bash
# 1. Prerequisites
brew install --cask docker
# Enable Kubernetes in Docker Desktop settings
brew install kubectl
brew install tailscale
# Authenticate: open Tailscale app and log in with company account

# 2. Clone repo
git clone git@github.com:myonsite-healthcare/medinovai-Deploy.git
cd medinovai-Deploy

# 3. Verify kubectl context
kubectl config use-context docker-desktop

# 4. Start Docker infra (local monitoring stack)
make docker-up

# 5. Install K8s pointing at primary
bash scripts/bootstrap/install-k8s.sh --db-host 100.79.214.33

# 6. Verify
make k8s-status
curl -sf http://localhost:30080 | grep Hostname

# 7. Cross-machine test (from this machine)
nc -zv 100.79.214.33 5432 && echo "Can reach primary postgres"
curl -sf http://100.79.214.33:30080 | grep Hostname && echo "Can reach primary api-gateway"
```

---

## 12. Replacing Stub Images with Real Services

When application code is built and pushed to the container registry, replace `traefik/whoami` with the real images.

In `infra/kubernetes/overlays/docker-desktop/kustomization.yaml`, add an `images:` block:

```yaml
images:
  - name: traefik/whoami
    newName: ghcr.io/myonsite-healthcare/api-gateway
    newTag: v1.2.3
```

Or use per-service image replacement by updating each `patch-<service>.yaml` to reference the actual image instead of `traefik/whoami:latest`.

For the full registry, image naming follows: `<registry>/<service>:<git-sha>` for traceability.

---

## 5b. Cluster Addons (Layer 3)

Four addons deployed on top of the K8s app layer. All fully local — no cloud accounts required.

### Architecture with Addons

```
Internet traffic → localhost:30800 → NGINX Ingress → medinovai-services pods
                                                   ↗ api-gateway
                                                   ↗ auth-service
                                                   ↗ clinical-engine
                                                   ↗ data-pipeline
                                                   ↗ notification-service
                                                   ↗ ai-inference

GitHub repo (main) ← ArgoCD watches ← auto-syncs cluster state
kube-state-metrics → exposes K8s objects as Prometheus metrics → local Prometheus
Kubernetes Dashboard → visual cluster management at https://localhost:8443
```

### Addon Reference

| Addon | Namespace | Helm Chart | Local URL |
|-------|-----------|-----------|-----------|
| NGINX Ingress | `ingress-nginx` | `ingress-nginx/ingress-nginx` | `http://localhost:30800` |
| Kubernetes Dashboard | `kubernetes-dashboard` | kubectl apply (v2.7) | `https://localhost:8443` (port-forward) |
| kube-state-metrics | `medinovai-monitoring` | `prometheus-community/kube-state-metrics` | internal only |
| ArgoCD | `argocd` | `argo/argo-cd` | `http://localhost:8080` (port-forward) |

### Install / Reinstall Addons

```bash
make addons-install           # install all 4 addons
make addons-ingress           # NGINX ingress only
make addons-dashboard         # Dashboard only
make addons-monitoring        # kube-state-metrics only
make addons-argocd            # ArgoCD only
make addons-uninstall         # remove all addons
```

### Access Addons

```bash
# Kubernetes Dashboard (open in browser after running)
make dashboard-forward        # → https://localhost:8443
# Token is in .dashboard-token (gitignored) or run:
kubectl -n kubernetes-dashboard get secret medinovai-dashboard-admin-token \
  -o jsonpath="{.data.token}" | base64 --decode

# ArgoCD (open in browser after running)
make argocd-forward           # → http://localhost:8080
# Password:
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 --decode
# Login: admin / <password above>

# NGINX Ingress — direct HTTP (no port-forward needed)
curl -H "Host: medinovai.local" http://localhost:30800/
curl -H "Host: medinovai.local" http://localhost:30800/auth
curl -H "Host: medinovai.local" http://localhost:30800/clinical

# Optional: add to /etc/hosts for hostname-based access
# 127.0.0.1  medinovai.local
```

### NGINX Ingress Routes

| Path | Routes To | Port |
|------|-----------|------|
| `/` | api-gateway | 3000 |
| `/auth` | auth-service | 3000 |
| `/clinical` | clinical-engine | 8080 |
| `/pipeline` | data-pipeline | 8080 |
| `/notify` | notification-service | 3000 |
| `/ai` | ai-inference (medinovai-ai ns) | 8080 |

### ArgoCD GitOps Wiring

ArgoCD is configured to watch `infra/kubernetes/overlays/docker-desktop` on `main` branch.
On every `git push` to `main`, ArgoCD auto-syncs the cluster within ~3 minutes.

- **selfHeal: true** — if someone manually edits K8s objects, ArgoCD reverts to Git state
- **prune: false** — ArgoCD won't auto-delete resources (safety guard)
- **App manifest**: `infra/kubernetes/addons/argocd/medinovai-app.yaml`

### Addon Files

```
infra/kubernetes/addons/
├── ingress-nginx/
│   ├── values.yaml             # Helm values (NodePort 30800/30843, single replica)
│   └── ingress-medinovai.yaml  # Ingress routes for all services
├── dashboard/
│   ├── install.yaml            # Kubernetes Dashboard v2.7 upstream manifest
│   ├── values.yaml             # (reference — using kubectl apply not Helm)
│   └── dashboard-admin.yaml    # ServiceAccount + ClusterRoleBinding + token Secret
├── kube-state-metrics/
│   └── values.yaml             # Helm values (medinovai-monitoring ns, minimal resources)
└── argocd/
    ├── values.yaml             # Helm values (insecure mode, single replica, no SSO)
    └── medinovai-app.yaml      # ArgoCD Application CRD → docker-desktop overlay
```

## 13. Backup and Restore

### Backup (run before any infra change)

```bash
bash scripts/backup.sh
```

Output: `~/medinovai-backups/medinovai-Deploy/YYYY-MM-DD_HH-MM-SS/`
- `db/medinovai_dump_*.sql` — PostgreSQL dump
- `volumes/postgres-data_*.tar.gz` — Volume tarballs
- `config/docker-compose.dev_*.yml` — Compose file snapshot

### Restore

```bash
bash scripts/restore.sh --from-latest
```

### Seed Fresh Environment

```bash
bash scripts/seed.sh            # Start infra + run migrations
bash scripts/seed.sh --reset    # Wipe all volumes first, then seed
```

### Backup Hierarchy

```
Level 0: Git repo (committed + pushed to remote)
Level 1: ~/medinovai-backups/medinovai-Deploy/ (local, outside Docker)
Level 2: docker-compose.yml in Git (rebuild infra from scratch)
Level 3: Database SQL dumps (restore data state)
Level 4: macOS Time Machine (full machine backup)
Level 5: GitHub remote (off-site code)
```

---

## 14. File Map

```
medinovai-Deploy/
├── infra/
│   ├── docker/
│   │   ├── docker-compose.dev.yml          # Main infra stack (postgres, redis, etc.)
│   │   └── .env.example                    # Env template — copy to .env
│   └── kubernetes/
│       ├── base/                           # Shared K8s base (RBAC, NetworkPolicy, Quotas)
│       ├── services/
│       │   ├── api-gateway/                # Deployment, Service, HPA, PDB
│       │   ├── auth-service/
│       │   ├── clinical-engine/
│       │   ├── data-pipeline/
│       │   ├── ai-inference/
│       │   └── notification-service/
│       └── overlays/
│           ├── docker-desktop/             # LOCAL MACHINE OVERLAY
│           │   ├── kustomization.yaml      # Overlay entry point
│           │   ├── configmap-env.yaml      # Default env (committed)
│           │   ├── configmap-env-local.yaml # Machine env (GITIGNORED)
│           │   ├── configmap-env-ai.yaml   # AI namespace env (committed)
│           │   ├── configmap-env-ai-local.yaml # AI machine env (GITIGNORED)
│           │   ├── patch-*.yaml            # Per-service patches
│           │   └── patch-quota-*.yaml      # Quota patches
│           ├── dev/
│           ├── staging/
│           └── production/
├── scripts/
│   ├── backup.sh                           # DB + volume backup
│   ├── restore.sh                          # Restore from backup
│   ├── seed.sh                             # Fresh environment setup
│   └── bootstrap/
│       ├── instantiate-docker.sh           # Full greenfield Docker
│       ├── install-k8s.sh                  # K8s install (Tailscale-aware)
│       ├── uninstall-k8s.sh                # K8s cleanup
│       ├── tailscale-config.sh             # Generate machine-specific config
│       ├── init-cloud-account.sh           # Cloud account setup
│       ├── init-secrets.sh                 # Secrets initialization
│       ├── install_atlas.sh                # Atlas agent install
│       └── prerequisites.sh               # Dependency checker
├── agents/
│   └── platform/AGENTS.md                 # Platform agent rules (includes learned knowledge)
├── docs/
│   ├── DEPLOYMENT_BRAIN.md                 # ← THIS FILE
│   ├── DOCKER_GREENFIELD_DEPLOYMENT.md     # Docker Compose guide
│   ├── KUBERNETES_HA_DEPLOYMENT.md         # K8s Tailscale HA guide
│   ├── DISASTER_RECOVERY.md                # DR procedures
│   └── RUNBOOK.md                          # Operations runbook
├── .cursor/rules/
│   ├── local-docker-k8s-deployment.mdc     # AI rule: deployment patterns + known bugs
│   ├── deploy-safety.mdc                   # AI rule: deployment safety
│   └── infra-conventions.mdc               # AI rule: IaC conventions
├── Makefile                                # All make targets
└── .gitignore                              # Includes machine-specific config files
```

---

*This document is part of the Atlas Autonomous Deployment System. Update it whenever a new bug is found, a new machine is added, or a pattern changes.*
