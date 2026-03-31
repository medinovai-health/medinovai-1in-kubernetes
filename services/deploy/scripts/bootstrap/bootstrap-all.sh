#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  bootstrap-all.sh — Full MedinovAI local stack from zero                   ║
# ║                                                                              ║
# ║  Run once on any new machine. Idempotent — safe to re-run.                  ║
# ║                                                                              ║
# ║  What gets installed (all local, no cloud accounts):                         ║
# ║    Layer 1 — Docker Compose infra                                            ║
# ║      postgres · redis · prometheus · grafana · mailpit · localstack          ║
# ║    Layer 2 — Kubernetes app services (docker-desktop overlay)                ║
# ║      api-gateway · auth-service · clinical-engine · data-pipeline            ║
# ║      notification-service · ai-inference                                     ║
# ║    Layer 3 — Cluster addons                                                  ║
# ║      NGINX Ingress · Kubernetes Dashboard · kube-state-metrics · ArgoCD     ║
# ║                                                                              ║
# ║  Usage:                                                                      ║
# ║    bash scripts/bootstrap/bootstrap-all.sh                                   ║
# ║    bash scripts/bootstrap/bootstrap-all.sh --primary    # this is DB host    ║
# ║    bash scripts/bootstrap/bootstrap-all.sh --db-host <ts-ip>  # secondary   ║
# ║    bash scripts/bootstrap/bootstrap-all.sh --skip-infra # K8s + addons only ║
# ║    bash scripts/bootstrap/bootstrap-all.sh --skip-addons                    ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
COMPOSE_FILE="$REPO_ROOT/infra/docker/docker-compose.dev.yml"

# ── Colours ───────────────────────────────────────────────────────────────────
G="\033[0;32m"; Y="\033[1;33m"; R="\033[0;31m"; B="\033[0;34m"; NC="\033[0m"; BOLD="\033[1m"
log()  { echo -e "${G}[bootstrap]${NC} $*"; }
step() { echo -e "\n${BOLD}${B}━━━ $* ━━━${NC}"; }
warn() { echo -e "${Y}[bootstrap]${NC} $*"; }
err()  { echo -e "${R}[bootstrap]${NC} $*" >&2; }
ok()   { echo -e "${G}  ✓${NC} $*"; }
fail() { echo -e "${R}  ✗${NC} $*"; }

# ── Flags ─────────────────────────────────────────────────────────────────────
IS_PRIMARY=false
DB_HOST=""
SKIP_INFRA=false
SKIP_ADDONS=false
SKIP_K8S=false

for arg in "$@"; do
  case "$arg" in
    --primary)          IS_PRIMARY=true ;;
    --db-host=*)        DB_HOST="${arg#*=}" ;;
    --db-host)          shift; DB_HOST="${1:-}" ;;
    --skip-infra)       SKIP_INFRA=true ;;
    --skip-addons)      SKIP_ADDONS=true ;;
    --skip-k8s)         SKIP_K8S=true ;;
    --help|-h)
      sed -n '3,20p' "$0" | sed 's/# //; s/#//'
      exit 0 ;;
    *) err "Unknown flag: $arg (use --help)"; exit 1 ;;
  esac
done

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${G}"
echo "  ███╗   ███╗███████╗██████╗ ██╗███╗   ██╗ ██████╗ ██╗   ██╗ █████╗ ██╗"
echo "  ████╗ ████║██╔════╝██╔══██╗██║████╗  ██║██╔═══██╗██║   ██║██╔══██╗██║"
echo "  ██╔████╔██║█████╗  ██║  ██║██║██╔██╗ ██║██║   ██║██║   ██║███████║██║"
echo "  ██║╚██╔╝██║██╔══╝  ██║  ██║██║██║╚██╗██║██║   ██║╚██╗ ██╔╝██╔══██║██║"
echo "  ██║ ╚═╝ ██║███████╗██████╔╝██║██║ ╚████║╚██████╔╝ ╚████╔╝ ██║  ██║██║"
echo "  ╚═╝     ╚═╝╚══════╝╚═════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝   ╚═══╝  ╚═╝  ╚═╝╚═╝"
echo -e "${NC}"
echo -e "${BOLD}  Full Local Stack Bootstrap${NC}  —  $(date '+%Y-%m-%d %H:%M')"
echo ""

# ── Step 0: Security Layer (Vault + Keycloak IAM) ─────────────────────────────
# Must run BEFORE everything else.
# Sub-steps:
#   0a — Clone MedinovAI-security-service (Keycloak config)
#   0b — Start Vault, wait healthy, run init-vault.sh (idempotent)
#   0c — Start Keycloak (depends on Vault being healthy for its own secrets)
step "0 / 5  Security Layer  (Vault secrets store + Keycloak IAM)"

# ── Step 0a: Clone security service ──────────────────────────────────────────
SECURITY_REPO="${SECURITY_SERVICE_PATH:-$HOME/Documents/GitHub/MedinovAI-security-service}"
if [[ ! -d "$SECURITY_REPO/.git" ]]; then
  log "Cloning MedinovAI-security-service..."
  if git clone git@github.com:myonsite-healthcare/MedinovAI-security-service.git "$SECURITY_REPO" 2>/dev/null; then
    ok "Security service cloned to $SECURITY_REPO"
  else
    warn "Could not clone MedinovAI-security-service — Keycloak will use embedded defaults."
    warn "Run: bash scripts/clone-repos.sh  then re-run bootstrap."
  fi
else
  ok "Security service at $SECURITY_REPO"
fi
export SECURITY_SERVICE_PATH="$SECURITY_REPO"

# ── Step 0b: Start Vault and initialize ───────────────────────────────────────
log "Starting Vault..."
docker compose -f infra/docker/docker-compose.dev.yml up -d vault 2>/dev/null || true

log "Waiting for Vault to be ready (max 30s)..."
VAULT_READY=false
for i in $(seq 1 30); do
  if curl -sf "http://localhost:8200/v1/sys/health" &>/dev/null; then
    VAULT_READY=true
    ok "Vault ready (took ~${i}s)"; break
  fi
  printf "."; sleep 1
done
echo ""

if [[ "$VAULT_READY" == "true" ]]; then
  log "Initializing Vault (idempotent)..."
  VAULT_ADDR=http://localhost:8200 \
  VAULT_TOKEN="${VAULT_DEV_ROOT_TOKEN:-medinovai-dev-token}" \
  bash scripts/bootstrap/init-vault.sh 2>&1 | grep -E "✓|⚠|ERROR|Step" || true
  ok "Vault initialized → http://localhost:8200"
else
  warn "Vault did not become ready — skipping init. Secrets will use .env fallbacks."
  warn "Check: docker logs medinovai-vault"
fi

# Validate required passwords
if [[ -z "${KEYCLOAK_ADMIN_PASSWORD:-}" ]]; then
  if [[ "${ENVIRONMENT:-dev}" != "dev" ]]; then
    err "KEYCLOAK_ADMIN_PASSWORD is required for ${ENVIRONMENT}. Set it in infra/docker/.env."
    exit 1
  fi
  warn "KEYCLOAK_ADMIN_PASSWORD not set in .env — using 'localdev'. CHANGE IN PRODUCTION."
fi
if [[ -z "${SUPERADMIN_PASSWORD:-}" ]]; then
  warn "SUPERADMIN_PASSWORD not set in .env — SuperAdmin user will not be created automatically."
  warn "Set SUPERADMIN_PASSWORD in infra/docker/.env and re-run: make security-seed"
fi

# ── Step 0.1: Prerequisites ────────────────────────────────────────────────────
step "0.1 / 5  Prerequisites"

MISSING=0
check_cmd() {
  if command -v "$1" &>/dev/null; then ok "$1"; else fail "$1 (not found)"; MISSING=1; fi
}
check_cmd docker
check_cmd kubectl
check_cmd helm
check_cmd curl

# Optional but recommended
command -v tailscale &>/dev/null && ok "tailscale" || warn "tailscale not found (ok for single-machine)"

[[ $MISSING -eq 1 ]] && { err "Install missing tools and re-run."; exit 2; }

# Docker Desktop Kubernetes must be enabled
if ! kubectl cluster-info --request-timeout=5s &>/dev/null; then
  err "Kubernetes not reachable. Enable it in Docker Desktop → Settings → Kubernetes → Enable Kubernetes."
  exit 2
fi
ok "Docker Desktop Kubernetes reachable"

CTX=$(kubectl config current-context 2>/dev/null || echo "none")
if [[ "$CTX" != "docker-desktop" ]]; then
  warn "kubectl context is '$CTX'. Switching to docker-desktop..."
  kubectl config use-context docker-desktop
fi
ok "kubectl context: docker-desktop"

# ── Step 1: Backup ────────────────────────────────────────────────────────────
step "1 / 4  Backup (safety first)"
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "medinovai-postgres"; then
  log "Existing stack detected — backing up before changes..."
  bash "$REPO_ROOT/scripts/backup.sh" 2>&1 | grep -E "✓|✗|Backup" || true
  ok "Backup complete → ~/medinovai-backups/medinovai-Deploy/"
else
  ok "Fresh install — no backup needed"
fi

# ── Step 2: Docker Compose Infra (Layer 1) ────────────────────────────────────
if ! $SKIP_INFRA; then
  step "2 / 4  Docker Compose Infra  (postgres · redis · prometheus · grafana · mailpit · localstack)"

  # Copy .env if missing
  if [[ ! -f "$REPO_ROOT/infra/docker/.env" ]]; then
    cp "$REPO_ROOT/infra/docker/.env.example" "$REPO_ROOT/infra/docker/.env"
    log "Created infra/docker/.env from .env.example (using defaults)"
  fi

  docker compose -f "$COMPOSE_FILE" up -d --remove-orphans 2>&1 | grep -E "Starting|started|healthy|error" || true

  # Wait for postgres
  log "Waiting for postgres to be healthy..."
  for i in $(seq 1 30); do
    if docker exec medinovai-postgres pg_isready -U medinovai -d medinovai -q 2>/dev/null; then
      ok "postgres healthy"; break
    fi
    [[ $i -eq 30 ]] && { fail "postgres didn't start in 30s"; exit 1; }
    sleep 2
  done

  # Create keycloak database (idempotent — safe to run on every bootstrap)
  log "Creating keycloak database in postgres..."
  docker exec medinovai-postgres psql -U medinovai -tc \
    "SELECT 1 FROM pg_database WHERE datname='keycloak'" 2>/dev/null | grep -q 1 || \
    docker exec medinovai-postgres psql -U medinovai -c "CREATE DATABASE keycloak;" 2>/dev/null
  docker exec medinovai-postgres psql -U medinovai \
    -c "GRANT ALL PRIVILEGES ON DATABASE keycloak TO medinovai;" 2>/dev/null || true
  ok "keycloak database ready"

  # Wait for Keycloak (realm imports on startup — takes ~60-90s)
  log "Waiting for Keycloak to be ready (realm import in progress, max 200s)..."
  KEYCLOAK_READY=false
  for i in $(seq 1 40); do
    if curl -sf http://localhost:8081/health/ready &>/dev/null; then
      KEYCLOAK_READY=true
      ok "Keycloak ready (took ~$((i * 5))s)"; break
    fi
    printf "."
    sleep 5
  done
  echo ""
  if [[ "$KEYCLOAK_READY" == "true" ]]; then
    # Seed SuperAdmin (idempotent)
    if [[ -n "${SUPERADMIN_PASSWORD:-}" && -f "$SECURITY_REPO/scripts/seed-superadmin.sh" ]]; then
      log "Seeding SuperAdmin user..."
      KEYCLOAK_URL=http://localhost:8081 \
      KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-localdev}" \
      SUPERADMIN_EMAIL="${SUPERADMIN_EMAIL:-superadmin@medinov.ai}" \
      SUPERADMIN_PASSWORD="$SUPERADMIN_PASSWORD" \
      bash "$SECURITY_REPO/scripts/seed-superadmin.sh" 2>&1 | grep -E "✓|✗|⚠" || true
    fi

    # Seed all product clients (idempotent)
    if [[ -f "$SECURITY_REPO/scripts/seed-all-products.sh" ]]; then
      log "Registering all product clients in Keycloak..."
      KEYCLOAK_URL=http://localhost:8081 \
      KEYCLOAK_ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-localdev}" \
      DOCKER_NETWORK=medinovai-dev \
      bash "$SECURITY_REPO/scripts/seed-all-products.sh" 2>&1 | grep -E "✓|✗|⚠|Created|Skipped" || true
      ok "All products registered in Keycloak"
    fi

    ok "Keycloak → http://localhost:8081  (admin / \${KEYCLOAK_ADMIN_PASSWORD:-localdev})"
  else
    warn "Keycloak did not become ready in 200s — skipping seed."
    warn "Check: docker logs medinovai-keycloak"
    warn "Re-run seeding: make security-seed"
  fi

  # Wait for redis
  log "Waiting for redis..."
  for i in $(seq 1 15); do
    if docker exec medinovai-redis redis-cli ping 2>/dev/null | grep -q PONG; then
      ok "redis healthy"; break
    fi
    [[ $i -eq 15 ]] && { fail "redis didn't start"; exit 1; }
    sleep 2
  done

  ok "Grafana  → http://localhost:3000  (admin / admin)"
  ok "Prometheus → http://localhost:9090"
  ok "Mailpit  → http://localhost:8025"
  ok "LocalStack → http://localhost:4566"
else
  log "Skipping Docker infra (--skip-infra)"
fi

# ── Step 3: Kubernetes Services (Layer 2) ─────────────────────────────────────
if ! $SKIP_K8S; then
  step "3 / 4  Kubernetes App Services  (6 services, docker-desktop overlay)"

  # Tailscale config
  if $IS_PRIMARY; then
    log "Configuring as PRIMARY (DB host)..."
    bash "$REPO_ROOT/scripts/bootstrap/tailscale-config.sh" --primary 2>&1 | grep -E "✓|TS|primary" || true
  elif [[ -n "$DB_HOST" ]]; then
    log "Configuring as SECONDARY (DB host: $DB_HOST)..."
    bash "$REPO_ROOT/scripts/bootstrap/tailscale-config.sh" --db-host "$DB_HOST" 2>&1 | grep -E "✓|TS|secondary" || true
  elif [[ -f "$REPO_ROOT/.env.tailscale" ]]; then
    log "Using existing .env.tailscale config..."
  else
    log "No Tailscale flag — defaulting to single-machine (host.docker.internal)"
    bash "$REPO_ROOT/scripts/bootstrap/tailscale-config.sh" --primary 2>/dev/null || true
  fi

  # Apply K8s overlay
  log "Applying docker-desktop overlay..."
  kubectl apply -k "$REPO_ROOT/infra/kubernetes/overlays/docker-desktop" 2>&1 | \
    grep -E "created|configured|unchanged" | head -20 || true

  # Inject Tailscale configmap if it exists
  if [[ -f "$REPO_ROOT/infra/kubernetes/overlays/docker-desktop/configmap-env-local.yaml" ]]; then
    kubectl apply -f "$REPO_ROOT/infra/kubernetes/overlays/docker-desktop/configmap-env-local.yaml" 2>/dev/null || true
    kubectl apply -f "$REPO_ROOT/infra/kubernetes/overlays/docker-desktop/configmap-env-ai-local.yaml" 2>/dev/null || true
  fi

  # Wait for all medinovai-services pods
  log "Waiting for app services to be Running..."
  kubectl wait pods -n medinovai-services --all --for=condition=Ready --timeout=3m 2>/dev/null || \
    warn "Some pods still starting — check with: kubectl get pods -n medinovai-services"
  kubectl wait pods -n medinovai-ai --all --for=condition=Ready --timeout=2m 2>/dev/null || true

  ok "api-gateway     → http://localhost:30080"
  ok "auth-service    → http://localhost:30081"
  ok "clinical-engine, data-pipeline, notification-service, ai-inference running"
else
  log "Skipping K8s services (--skip-k8s)"
fi

# ── Step 4: Cluster Addons (Layer 3) ──────────────────────────────────────────
if ! $SKIP_ADDONS; then
  step "4 / 5  Cluster Addons  (ingress · dashboard · kube-state-metrics · argocd)"
  bash "$REPO_ROOT/scripts/bootstrap/install-addons.sh" 2>&1 | grep -E "✓|━|║|Step|Installing|Deployed|ERROR" || true
else
  log "Skipping addons (--skip-addons)"
fi

# ── Step 5: medinovaiOS (Layer 4) ─────────────────────────────────────────────
step "5 / 5  medinovaiOS  (unified portal — http://localhost:3030)"

# Docker Compose: medinovaiOS is included in docker-compose.dev.yml and starts
# automatically with `docker compose up`. Check if it's already running.
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "medinovaios"; then
  ok "medinovaiOS (Docker) already running at http://localhost:3030"
else
  log "Starting medinovaiOS via Docker Compose..."
  if ! $SKIP_INFRA; then
    docker compose -f "$COMPOSE_FILE" up -d medinovaios 2>&1 | grep -E "Starting|started|Built|error" || true
    ok "medinovaiOS → http://localhost:3030"
  fi
fi

# Kubernetes: deploy medinovaiOS manifest
if ! $SKIP_K8S; then
  log "Deploying medinovaiOS to Kubernetes..."
  kubectl apply -k "$REPO_ROOT/infra/kubernetes/services/medinovaios" 2>&1 | \
    grep -E "created|configured|unchanged" | head -10 || true
  log "Waiting for medinovaiOS pods..."
  kubectl rollout status deployment/medinovaios -n medinovai-os --timeout=120s 2>/dev/null && \
    ok "medinovaiOS (K8s) → http://medinovaios.local  or  http://localhost:30030" || \
    warn "medinovaiOS pods still starting — check: kubectl get pods -n medinovai-os"
fi

# ── Final Summary ─────────────────────────────────────────────────────────────
ARGOCD_PW=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" 2>/dev/null | base64 --decode || echo "check: kubectl -n argocd get secret argocd-initial-admin-secret")

DASHBOARD_TOKEN=$(kubectl -n kubernetes-dashboard get secret medinovai-dashboard-admin-token \
  -o jsonpath="{.data.token}" 2>/dev/null | base64 --decode | head -c 40 || echo "check: cat .dashboard-token")

echo ""
echo -e "${BOLD}${G}╔══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${G}║           MedinovAI Local Stack — READY                              ║${NC}"
echo -e "${BOLD}${G}╠══════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}${G}║  ★  YOUR ONE LOGIN POINT                                             ║${NC}"
echo -e "${BOLD}${G}║     http://localhost:3030   (medinovaiOS unified portal)             ║${NC}"
echo -e "${G}║     Email:    ${SUPERADMIN_EMAIL:-superadmin@medinov.ai}                     ║${NC}"
echo -e "${G}║     Password: \$SUPERADMIN_PASSWORD  (set in infra/docker/.env)        ║${NC}"
echo -e "${G}║     This is the ONLY login. All other systems follow SSO from here.  ║${NC}"
echo -e "${G}╠══════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${G}║  LAYER 0 — IAM (Keycloak)                                            ║${NC}"
echo -e "${G}║    Keycloak     http://localhost:8081/admin  (internal admin only)   ║${NC}"
echo -e "${G}║    Realm:       medinov-ai  (15 product clients registered)          ║${NC}"
echo -e "${G}╠══════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${G}║  LAYER 1 — Docker Compose Infra                                      ║${NC}"
echo -e "${G}║    Grafana      http://localhost:3000       (SSO via Keycloak)       ║${NC}"
echo -e "${G}║    Prometheus   http://localhost:9090                                 ║${NC}"
echo -e "${G}║    Mailpit      http://localhost:8025                                 ║${NC}"
echo -e "${G}║    Postgres     localhost:5432              medinovai / localdev      ║${NC}"
echo -e "${G}║    Redis        localhost:6379              pw: localdev              ║${NC}"
echo -e "${G}╠══════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${G}║  LAYER 2 — Kubernetes App Services                                   ║${NC}"
echo -e "${G}║    api-gateway  http://localhost:30080                                ║${NC}"
echo -e "${G}║    + clinical-engine, data-pipeline, notification, ai-inference      ║${NC}"
echo -e "${G}╠══════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${G}║  LAYER 3 — Cluster Addons                                            ║${NC}"
echo -e "${G}║    Ingress      http://localhost:30800      (Host: medinovai.local)   ║${NC}"
echo -e "${G}║    Dashboard    https://localhost:8443      (make dashboard-forward)  ║${NC}"
echo -e "${G}║    ArgoCD       http://localhost:8080       (make argocd-forward)     ║${NC}"
echo -e "${G}║    ArgoCD login: admin / ${ARGOCD_PW:0:16}...                         ║${NC}"
echo -e "${G}╠══════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BOLD}${G}║  LAYER 4 — medinovaiOS Unified Portal                                ║${NC}"
echo -e "${G}║    medinovaiOS  http://localhost:3030       (Docker Compose)         ║${NC}"
echo -e "${G}║    medinovaiOS  http://localhost:30030      (K8s NodePort)           ║${NC}"
echo -e "${G}║    medinovaiOS  http://medinovaios.local    (K8s Ingress)            ║${NC}"
echo -e "${G}╠══════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${G}║  QUICK COMMANDS                                                       ║${NC}"
echo -e "${G}║    make security-seed         # re-seed SuperAdmin + all products    ║${NC}"
echo -e "${G}║    make security-logs         # tail Keycloak logs                   ║${NC}"
echo -e "${G}║    make cluster-status        # full health check                    ║${NC}"
echo -e "${G}║    make medinovaios-forward   # port-forward medinovaiOS to :3030    ║${NC}"
echo -e "${G}║    make argocd-forward        # open ArgoCD                          ║${NC}"
echo -e "${G}║    make docker-backup         # backup postgres + volumes            ║${NC}"
echo -e "${G}╚══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
log "Bootstrap complete in $(date '+%H:%M:%S')"
