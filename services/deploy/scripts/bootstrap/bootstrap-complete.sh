#!/usr/bin/env bash
# ─── bootstrap-complete.sh ────────────────────────────────────────────────────
# One-command full stack bootstrap — Docker + Kubernetes + Addons + AI + Atlas.
# Everything runs in containers. Nothing is installed on the host.
#
# Prerequisites (host tools only — no services installed natively):
#   docker, kubectl, helm, curl
#
# Usage:
#   bash scripts/bootstrap/bootstrap-complete.sh
#   bash scripts/bootstrap/bootstrap-complete.sh --skip-k8s      # Docker only
#   bash scripts/bootstrap/bootstrap-complete.sh --skip-docker   # K8s only
#   bash scripts/bootstrap/bootstrap-complete.sh --skip-model    # Skip model pull
#
# What this does:
#   1. Start Docker Compose infra (postgres, redis, prometheus, grafana, mailpit, localstack)
#   2. Start Ollama + Open WebUI (Docker Compose)
#   3. Build Atlas image + start Atlas (Docker Compose)
#   4. Install K8s base platform (install-k8s.sh)
#   5. Install all K8s addons (ingress, dashboard, monitoring, argocd, ollama, atlas)
#   6. Pull default LLM model (qwen2.5:1.5b) into Ollama
#   7. Print status summary
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
COMPOSE_FILE="$REPO_ROOT/infra/docker/docker-compose.dev.yml"

SKIP_DOCKER=false
SKIP_K8S=false
SKIP_MODEL=false
SKIP_ATLAS=false

for arg in "$@"; do
  case "$arg" in
    --skip-docker) SKIP_DOCKER=true ;;
    --skip-k8s)    SKIP_K8S=true ;;
    --skip-model)  SKIP_MODEL=true ;;
    --skip-atlas)  SKIP_ATLAS=true ;;
    *) echo "Unknown flag: $arg"; exit 1 ;;
  esac
done

G="\033[0;32m"; B="\033[0;34m"; Y="\033[1;33m"; R="\033[0;31m"; NC="\033[0m"
log()  { echo -e "${G}[bootstrap]${NC} $*"; }
step() { echo -e "${B}[bootstrap]${NC} $*"; }
warn() { echo -e "${Y}[bootstrap]${NC} $*"; }
err()  { echo -e "${R}[bootstrap]${NC} $*" >&2; }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     MedinovAI — Complete Stack Bootstrap                     ║"
echo "║     Docker + Kubernetes + AI (Ollama) + Atlas               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ── Preflight ─────────────────────────────────────────────────────────────────
step "[preflight] Checking required tools..."
MISSING=0
for cmd in docker kubectl helm curl; do
  command -v "$cmd" &>/dev/null && log "  ✓ $cmd" || { err "  ✗ $cmd not found"; MISSING=1; }
done
[[ $MISSING -eq 0 ]] || { err "Install missing tools and re-run."; exit 2; }

if ! docker info &>/dev/null; then
  err "Docker daemon is not running. Start Docker Desktop first."
  exit 2
fi
log "  ✓ Docker daemon running"

# ── Step 1: Docker Compose infra ─────────────────────────────────────────────
if ! $SKIP_DOCKER; then
  step "[1/6] Docker Compose — infra + AI + Atlas..."

  # Check .env exists
  if [ ! -f "$REPO_ROOT/infra/docker/.env" ]; then
    warn "  infra/docker/.env not found — copying from .env.example"
    cp "$REPO_ROOT/infra/docker/.env.example" "$REPO_ROOT/infra/docker/.env"
    warn "  → Edit infra/docker/.env with real API keys before starting Atlas"
  fi

  # Build Atlas image first (required by compose)
  if ! docker image inspect medinovai-atlas:local &>/dev/null; then
    log "  Building Atlas image (first time — takes ~2 min)..."
    docker build -f "$REPO_ROOT/Dockerfile.atlas" -t medinovai-atlas:local "$REPO_ROOT"
    log "  ✓ Atlas image built"
  else
    log "  ✓ Atlas image already built"
  fi

  # Start all Docker services
  log "  Starting Docker Compose stack..."
  docker compose -f "$COMPOSE_FILE" up -d

  # Wait for postgres (the critical dependency)
  log "  Waiting for PostgreSQL..."
  for i in $(seq 1 30); do
    docker exec medinovai-postgres pg_isready -U medinovai -d medinovai 2>/dev/null && break || { echo -n "."; sleep 2; }
  done
  echo ""

  # Wait for Ollama
  log "  Waiting for Ollama..."
  for i in $(seq 1 20); do
    curl -sf http://localhost:11434/api/tags >/dev/null 2>&1 && break || { echo -n "."; sleep 3; }
  done
  echo ""
  log "  ✓ Docker Compose stack running"
else
  step "[1/6] Skipping Docker Compose (--skip-docker)"
fi

# ── Step 2: Pull default models (Docker Ollama) ───────────────────────────────
if ! $SKIP_MODEL && ! $SKIP_DOCKER; then
  step "[2/6] Pulling default models into Docker Ollama (qwen2.5:1.5b · nomic-embed-text · gemma3)..."
  bash "$SCRIPT_DIR/pull-default-model.sh"
else
  step "[2/6] Skipping model pull"
fi

# ── Step 3: K8s base platform ─────────────────────────────────────────────────
if ! $SKIP_K8S; then
  step "[3/6] Kubernetes base platform..."
  if kubectl cluster-info --request-timeout=5s &>/dev/null; then
    log "  ✓ K8s cluster reachable"
    bash "$SCRIPT_DIR/install-k8s.sh" --context docker-desktop --skip-infra
  else
    warn "  ✗ K8s cluster not reachable — skipping K8s install"
    warn "  Enable Kubernetes in Docker Desktop > Settings > Kubernetes"
  fi
else
  step "[3/6] Skipping K8s install (--skip-k8s)"
fi

# ── Step 4: K8s addons ────────────────────────────────────────────────────────
if ! $SKIP_K8S; then
  step "[4/6] Installing K8s addons (ingress, dashboard, monitoring, argocd, ollama, atlas)..."
  ATLAS_FLAG=""
  $SKIP_ATLAS && ATLAS_FLAG="--ingress --dashboard --monitoring --argocd --ollama" || true
  bash "$SCRIPT_DIR/install-addons.sh" ${ATLAS_FLAG}
else
  step "[4/6] Skipping addons (--skip-k8s)"
fi

# ── Step 5: Pull model into K8s Ollama ────────────────────────────────────────
if ! $SKIP_K8S && ! $SKIP_MODEL; then
  step "[5/6] Pulling default model into K8s Ollama via Job..."
  kubectl delete job ollama-pull-default -n medinovai-ai-local 2>/dev/null || true
  kubectl apply -f "$REPO_ROOT/infra/kubernetes/addons/ollama/model-pull-job.yaml"
  log "  ✓ Pull job submitted (running in background)"
  log "  Watch: kubectl logs -n medinovai-ai-local -l job-name=ollama-pull-default -f"
else
  step "[5/6] Skipping K8s model pull"
fi

# ── Step 6: Atlas K8s secrets ─────────────────────────────────────────────────
if ! $SKIP_K8S && ! $SKIP_ATLAS; then
  step "[6/6] Atlas K8s secrets..."
  if [ -f "$REPO_ROOT/infra/docker/.env" ]; then
    kubectl create secret generic atlas-secrets -n medinovai-system \
      --from-env-file="$REPO_ROOT/infra/docker/.env" \
      --dry-run=client -o yaml | kubectl apply -f -
    log "  ✓ Atlas secrets applied from infra/docker/.env"
    kubectl rollout restart deployment/atlas -n medinovai-system 2>/dev/null || true
  else
    warn "  infra/docker/.env not found — Atlas will start without secrets (limited functionality)"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✓ Bootstrap complete                                       ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  DOCKER COMPOSE (always-on infra)                           ║"
echo "║  PostgreSQL    localhost:5432                               ║"
echo "║  Redis         localhost:6379                               ║"
echo "║  Prometheus    http://localhost:9090                        ║"
echo "║  Grafana       http://localhost:3000  (admin/admin)         ║"
echo "║  Mailpit       http://localhost:8025                        ║"
echo "║  Ollama        http://localhost:11434                       ║"
echo "║  Open WebUI    http://localhost:8091                        ║"
echo "║  Atlas         http://localhost:18789                       ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  KUBERNETES (services + addons)                             ║"
echo "║  api-gateway   localhost:30080                              ║"
echo "║  auth-service  localhost:30081                              ║"
echo "║  Ingress       http://localhost:30800                       ║"
echo "║  Dashboard     https://localhost:8443  (port-forward)       ║"
echo "║  ArgoCD        http://localhost:8080   (port-forward)       ║"
echo "║  Ollama (K8s)  localhost:31434                              ║"
echo "║  WebUI  (K8s)  http://localhost:30090                       ║"
echo "║  Atlas  (K8s)  http://localhost:31789                       ║"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  NEXT STEPS                                                 ║"
echo "║  1. atlas start             → start Atlas AI OS             ║"
echo "║  2. Edit infra/docker/.env  → add real API keys             ║"
echo "║  3. make atlas-secrets      → apply secrets to K8s          ║"
echo "║  4. make clone-repos        → clone all 35 medinovai repos  ║"
echo "║  5. make cluster-status     → verify all services           ║"
echo "║  6. make monitoring-forward → open Grafana + Prometheus      ║"
echo "║  7. make argocd-forward     → open ArgoCD GitOps UI         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
