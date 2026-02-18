# Self-Contained Deploy Stack — Architecture & Training Guide

> **Audience:** New engineers joining the MedinovAI platform team.
> **Purpose:** Explains *why* and *how* the deploy stack bootstraps itself from within Docker Compose and Kubernetes — no host-side setup required.

---

## 1. The Problem This Solves

Before this change, bringing up the MedinovAI stack on a fresh machine required three manual host-side steps **before** `docker compose up` would work:

| Problem | Location | Root cause |
|---|---|---|
| Config written to `~/.atlas/` on the host | `scripts/deploy/deploy_config.sh:14` | `ATLAS_HOME` was hardcoded to `$HOME/.atlas` |
| Atlas UI source mounted from `${HOME}/.medinovai/atlas/ui` | `docker-compose.dev.yml:187` | Host bind-mount — requires Atlas installed on the host |
| `atlas onboard --install-daemon` runs interactively | `scripts/bootstrap/install_atlas.sh:59` | Host-only daemon — cannot run inside a container |

This meant every new developer had to: install Node.js, install Atlas globally, run `deploy_config.sh`, populate `~/.env`, and *then* start Docker.  
On CI runners, staging VMs, or team machines provisioned from an image, the stack simply would not start.

**Goal:** `git clone` → `docker compose up` → everything running. No host steps.

---

## 2. Core Concept: The Deployer Pattern

The solution introduces a **deployer service** — a short-lived container that runs first, installs itself, writes all configuration into named Docker volumes, and exits.  Every other service that depends on that configuration waits (`depends_on: condition: service_healthy`) until the deployer is done.

```
docker compose up -d
    │
    ├─ deployer  ──────── runs once, exits 0 ─────────────────────────────┐
    │     │                                                                │
    │     ├─ npm install -g atlas@latest                                  │
    │     ├─ deploy_config.sh  (ATLAS_HOME=/atlas-home)                   │
    │     ├─ writes .env from injected env vars                           │
    │     ├─ builds Atlas UI  → atlas-ui-source volume                    │
    │     └─ touch /atlas-home/.deploy-complete  ← sentinel               │
    │                                                                      │
    ├─ atlas-agent  ── depends_on: deployer: service_healthy ─────────────┤
    │     └─ reads atlas.json + .env from atlas-config volume             │
    │                                                                      │
    ├─ atlas-ui  ── depends_on: deployer: service_healthy ────────────────┘
    │     └─ serves pre-built Next.js from atlas-ui-source volume
    │
    └─ postgres / redis / ollama / prometheus / grafana  (independent)
```

This is called the **bootstrapper pattern**.  The deployer is the installer — it runs inside the stack and teaches the stack about itself.

---

## 3. File Map

### New files added

| File | What it does |
|---|---|
| `Dockerfile.deployer` | Builds the deployer image (`node:22-alpine` + `bash curl jq python3`). Copies `scripts/`, `config/`, `workspaces/` into the image at build time. |
| `docker/deployer-entrypoint.sh` | The bootstrap script. Installs Atlas CLI, runs `deploy_config.sh`, writes `.env`, optionally builds the Atlas UI, touches the sentinel, exits 0. |
| `infra/kubernetes/services/atlas/pvc.yaml` | Two Kubernetes PersistentVolumeClaims: `atlas-config-pvc` (1 Gi) and `atlas-workspaces-pvc` (5 Gi) in the `medinovai-atlas` namespace. |
| `infra/kubernetes/services/atlas/deployment.yaml` | Atlas agent K8s Deployment. Uses an `initContainer` (`atlas-bootstrap`) to populate the PVCs before the main container starts. |
| `infra/kubernetes/services/atlas/service.yaml` | ClusterIP Service exposing port 18789 (`atlas-agent.medinovai-atlas.svc.cluster.local`). |

### Modified files

| File | Change |
|---|---|
| `scripts/deploy/deploy_config.sh` | Line 14: `ATLAS_HOME="${ATLAS_HOME:-$HOME/.atlas}"` — now respects env override; defaults to host path for backward compatibility. |
| `scripts/bootstrap/install_atlas.sh` | Detects `/.dockerenv`; skips `atlas onboard --install-daemon` inside containers (daemon requires host). `mkdir` also uses `$ATLAS_HOME` instead of hardcoded `~/.atlas`. |
| `infra/docker/docker-compose.dev.yml` | Added `deployer` service; changed `atlas-ui` from host bind-mount to `atlas-ui-source` named volume; added `atlas-config`, `atlas-workspaces`, `atlas-ui-source` volumes. |
| `infra/docker/.env.example` | Added "Self-Contained Bootstrap" section explaining the deployer and `NEXT_PUBLIC_AGENT_URL` override. |
| `infra/kubernetes/services/atlas/kustomization.yaml` | Added `pvc.yaml`, `deployment.yaml`, `service.yaml` to the resources list. |

---

## 4. How Volumes Replace Host Paths

Before and after comparison:

| Thing that needs a path | Before (host-dependent) | After (self-contained) |
|---|---|---|
| Atlas config directory | `~/.atlas/` on the host | `atlas-config` named volume → `/atlas-home` inside containers |
| Agent workspace dirs | `~/.atlas/workspace-*/` on the host | `atlas-workspaces` named volume → `/atlas-workspaces` inside containers |
| Atlas UI source/build | `${HOME}/.medinovai/atlas/ui` host bind-mount | `atlas-ui-source` named volume → `/app` inside `atlas-ui` |

Named volumes live inside Docker's storage layer — they survive container restarts and reboots, but are never tied to any specific host path.

---

## 5. The Sentinel File Pattern

The deployer's healthcheck is:

```yaml
healthcheck:
  test: ["CMD", "test", "-f", "/atlas-home/.deploy-complete"]
  interval: 5s
  timeout: 3s
  retries: 30
  start_period: 120s
```

The sentinel `/atlas-home/.deploy-complete` is created only after **all** bootstrap steps succeed.  Docker will not mark the container healthy until the file exists, so downstream services (`atlas-agent`, `atlas-ui`) are blocked from starting until the deployer finishes cleanly.

If the deployer crashes midway, the sentinel is never written, the healthcheck never passes, and downstream services never start — giving you an obvious failure signal.

---

## 6. Idempotency

The deployer is designed to be safe to run repeatedly:

```bash
# Inside docker/deployer-entrypoint.sh
if [ -f "$SENTINEL" ]; then
    log "Sentinel found — already bootstrapped. Skipping."
    exit 0
fi
```

On subsequent `docker compose up` runs (e.g., after a host reboot), the deployer starts, checks for the sentinel, finds it, and exits 0 in under a second.  All downstream services start immediately.

**To force a re-bootstrap** (e.g., after config changes):

```bash
docker compose rm -f deployer
docker volume rm medinovai-dev_atlas-config
docker compose up -d deployer
```

---

## 7. Kubernetes — initContainer Pattern

In Kubernetes, the equivalent of Docker Compose's `depends_on: service_healthy` is the **initContainer**.  Init containers run to completion before any of the main containers in a Pod start.

```
Atlas agent Pod lifecycle:
  1. initContainer: atlas-bootstrap  runs deploy_config.sh → writes to PVC → exits 0
  2. (K8s waits for all initContainers to exit 0)
  3. container: atlas-agent  starts, reads config from PVC
```

The `atlas-bootstrap` initContainer uses the same `medinovai-deployer:latest` image as the Docker Compose deployer — same entrypoint, same scripts, same logic.  The only difference is that it writes to a PersistentVolumeClaim instead of a named Docker volume.

Secrets are injected from a Kubernetes Secret named `atlas-secrets`:

```bash
# Create the secret before applying the deployment:
kubectl create secret generic atlas-secrets \
  --namespace medinovai-atlas \
  --from-literal=slack-app-token=xapp-... \
  --from-literal=slack-bot-token=xoxb-... \
  --from-literal=anthropic-api-key=sk-ant-... \
  --from-literal=hooks-token=$(openssl rand -hex 32)
```

---

## 8. Environment Variables Reference

All secrets are passed to the deployer via environment variables — never baked into the image.

| Variable | Required | Description |
|---|---|---|
| `SLACK_APP_TOKEN` | Yes (for Slack) | `xapp-...` — Socket Mode app token |
| `SLACK_BOT_TOKEN` | Yes (for Slack) | `xoxb-...` — Bot user OAuth token |
| `ANTHROPIC_API_KEY` | Yes (at least one LLM) | `sk-ant-...` — Claude API key |
| `OPENAI_API_KEY` | Optional | OpenAI fallback |
| `HOOKS_TOKEN` | Yes | Random secret for webhook validation |
| `OLLAMA_DEFAULT_MODEL` | Optional | Default: `qwen2.5:1.5b` |
| `ATLAS_HOME` | Auto-set | Set to `/atlas-home` inside deployer; defaults to `~/.atlas` on host |
| `NEXT_PUBLIC_AGENT_URL` | Optional | Default: `ws://atlas-agent:18789`; override for host-side agent |

Set these in `infra/docker/.env` (copied from `.env.example`).  Never commit `.env`.

---

## 9. Developer Quickstart

### First time on a new machine

```bash
# 1. Clone the repo
git clone git@github.com:myonsite-healthcare/medinovai-Deploy.git
cd medinovai-Deploy

# 2. Copy env template and fill in secrets
cp infra/docker/.env.example infra/docker/.env
# Edit infra/docker/.env — add SLACK tokens, ANTHROPIC_API_KEY, etc.

# 3. Start the full stack (deployer runs automatically)
docker compose -f infra/docker/docker-compose.dev.yml up -d

# 4. Watch the deployer bootstrap (takes ~2-3 min on first run)
docker logs -f medinovai-deployer

# 5. Verify everything is healthy
docker compose -f infra/docker/docker-compose.dev.yml ps
```

### After first run (every subsequent start)

```bash
docker compose -f infra/docker/docker-compose.dev.yml up -d
# deployer exits in <1s (sentinel already present), rest of stack starts normally
```

### Check deployer status

```bash
docker inspect medinovai-deployer --format='{{.State.Health.Status}}'
# Should print: healthy

docker exec medinovai-deployer cat /atlas-home/.deploy-complete
# Prints the JSON sentinel with bootstrap timestamp
```

---

## 10. Troubleshooting

### Deployer never becomes healthy

```bash
docker logs medinovai-deployer
```

Common causes:
- `npm install -g atlas@latest` fails (no internet access or npm registry issue) — check network
- `deploy_config.sh` fails — check that `config/deploy.json5` is valid JSON5
- Volume permissions issue — the container must be able to write to `/atlas-home`

### `atlas-ui` or `atlas-agent` not starting

They wait for the deployer to be healthy.  If the deployer is still bootstrapping, this is normal — give it time.

```bash
docker compose -f infra/docker/docker-compose.dev.yml ps
# deployer should show: health: starting → health: healthy
```

### Force full re-bootstrap

```bash
docker compose -f infra/docker/docker-compose.dev.yml rm -f deployer
docker volume rm medinovai-dev_atlas-config medinovai-dev_atlas-workspaces medinovai-dev_atlas-ui-source
docker compose -f infra/docker/docker-compose.dev.yml up -d
```

### Kubernetes: initContainer stuck

```bash
kubectl describe pod -n medinovai-atlas -l app.kubernetes.io/name=atlas-agent
# Look at the initContainer status section

kubectl logs -n medinovai-atlas -l app.kubernetes.io/name=atlas-agent -c atlas-bootstrap
```

Common cause: `atlas-secrets` Secret not created.  See Section 7.

---

## 11. Design Principles Applied

This implementation applies three patterns from the MedinovAI platform architecture playbook:

**Deployer pattern (bootstrapper):** A short-lived init container is responsible for installing and configuring the system before any long-lived services start.  This is the same principle as database migration jobs — run-to-completion before the app starts.

**Named volumes over host bind-mounts:** Named volumes are owned by Docker/Kubernetes and are portable across machines.  Host bind-mounts create a hard dependency on a specific host path, breaking the "works from any machine" guarantee.

**Sentinel file for health signalling:** A file written only on successful completion is more reliable than checking process state.  It is idempotent (re-checked on every start), human-readable (`cat /atlas-home/.deploy-complete`), and works across both Docker healthchecks and Kubernetes readiness gates.

---

## 12. Related Documentation

| Document | What it covers |
|---|---|
| `docs/DOCKER_GREENFIELD_DEPLOYMENT.md` | Full local stack from zero using `make up` |
| `docs/INSTANTIATION_GUIDE.md` | Cloud instantiation (AWS/GCP/Azure) with Terraform |
| `docs/KUBERNETES_HA_DEPLOYMENT.md` | Multi-node production K8s setup |
| `docs/RUNBOOK.md` | Operational runbook — health checks, restarts, rollbacks |
| `docs/DISASTER_RECOVERY.md` | Backup, restore, and disaster recovery procedures |
| `scripts/deploy/deploy_config.sh` | Config deployment script (modified) |
| `docker/deployer-entrypoint.sh` | Deployer bootstrap script |
| `Dockerfile.deployer` | Deployer image definition |
| `infra/docker/docker-compose.dev.yml` | Full compose stack |
| `infra/kubernetes/services/atlas/` | K8s Atlas service manifests |
