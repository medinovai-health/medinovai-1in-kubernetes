#!/usr/bin/env bash
# ─── deploy_rest_to_dev.sh ────────────────────────────────────────────────────
# Deploys all remaining MedinovAI platform services (tiers 1-6, 95 services)
# into the RUNNING medinovai-dev Docker Compose stack.
#
# Prerequisites:
#   - medinovai-dev stack is UP: docker compose -p medinovai-dev -f infra/docker/docker-compose.dev.yml up -d
#   - Repos are cloned to ~/medinovai-all-repos/ (201 repos)
#   - .env file exists at infra/docker/.env
#
# Usage:
#   bash scripts/deploy/deploy_rest_to_dev.sh
#   bash scripts/deploy/deploy_rest_to_dev.sh --skip-build    # Use existing images
#   bash scripts/deploy/deploy_rest_to_dev.sh --tier 1        # Single tier only
#   bash scripts/deploy/deploy_rest_to_dev.sh --dry-run       # Preview only
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPOSE_DEV="$PROJECT_ROOT/infra/docker/docker-compose.dev.yml"
COMPOSE_ALL="$PROJECT_ROOT/infra/docker/docker-compose.all-services.yml"
ENV_FILE="$PROJECT_ROOT/infra/docker/.env"
LOG_DIR="$PROJECT_ROOT/outputs/deploy-rest-$(date +%Y%m%d-%H%M%S)"
COMPOSE_PROJECT="medinovai-dev"

SKIP_BUILD=false
DRY_RUN=false
TIER_FILTER=""
VERIFY_MAX=10
REPOS_BASE_CLI=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-build) SKIP_BUILD=true; shift ;;
        --dry-run)    DRY_RUN=true; shift ;;
        --tier)       TIER_FILTER="$2"; shift 2 ;;
        --verify-max) VERIFY_MAX="$2"; shift 2 ;;
        --repos-base) REPOS_BASE_CLI="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

mkdir -p "$LOG_DIR"

# ── Colors ───────────────────────────────────────────────────────────────────
G="\033[0;32m"; Y="\033[1;33m"; R="\033[0;31m"; B="\033[0;34m"; C="\033[0;36m"; BOLD="\033[1m"; NC="\033[0m"
log()  { echo -e "${C}[$(date +%H:%M:%S)]${NC} $*" | tee -a "$LOG_DIR/deploy.log"; }
ok()   { echo -e "${G}  ✓${NC} $*" | tee -a "$LOG_DIR/deploy.log"; }
warn() { echo -e "${Y}  ⚠${NC} $*" | tee -a "$LOG_DIR/deploy.log"; }
fail() { echo -e "${R}  ✗${NC} $*" | tee -a "$LOG_DIR/deploy.log"; }
banner() {
    echo -e "\n${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${B}  $*${NC}"
    echo -e "${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

echo -e "${BOLD}${B}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   MedinovAI — Deploy Rest of Platform to medinovai-dev      ║"
echo "║   $(date -u +%Y-%m-%dT%H:%M:%SZ)                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Phase 0: Preflight checks ─────────────────────────────────────────────────
banner "Phase 0 — Preflight"

# Verify Docker daemon is running — use plain `docker` so any shell wrapper
# (e.g. auto-snapshot) keeps working correctly.
log "Checking Docker daemon..."
if ! docker info &>/dev/null 2>&1; then
    fail "Docker daemon is not running! Start Docker Desktop first, then re-run this script."
    exit 1
fi
ok "Docker daemon is running"

# Verify dev stack is running
log "Checking medinovai-dev stack..."
if ! docker ps --format "{{.Names}}" 2>/dev/null | grep -q "medinovai-postgres"; then
    fail "medinovai-postgres is not running! Start the dev stack first:"
    echo "  docker compose -p $COMPOSE_PROJECT -f infra/docker/docker-compose.dev.yml up -d"
    exit 1
fi
ok "medinovai-dev stack is running"

# Resolve REPOS_BASE — CLI flag wins; otherwise default to ~/medinovai-all-repos.
# We deliberately do NOT read REPOS_BASE from .env (it has ../../repos which is wrong).
if [ -n "$REPOS_BASE_CLI" ]; then
    REPOS_BASE="$REPOS_BASE_CLI"
else
    REPOS_BASE="$HOME/medinovai-all-repos"
fi

if [ ! -d "$REPOS_BASE" ]; then
    fail "Repos directory not found: $REPOS_BASE"
    echo "  Clone repos first: bash scripts/clone-repos.sh"
    exit 1
fi
REPO_COUNT=$(ls "$REPOS_BASE" | wc -l | tr -d ' ')
ok "Found $REPO_COUNT repos at $REPOS_BASE"

# Verify network exists
NETWORK_NAME="medinovai-dev_medinovai-dev"
if ! docker network inspect "$NETWORK_NAME" &>/dev/null 2>&1; then
    fail "Docker network '$NETWORK_NAME' not found. Ensure medinovai-dev is up."
    exit 1
fi
ok "Network $NETWORK_NAME exists"

# Read only the credentials we need from .env (avoid allexport which can break docker env)
_read_env_var() {
    local var="$1" default="$2"
    local val
    val=$(grep -E "^${var}=" "$ENV_FILE" 2>/dev/null | tail -1 | cut -d= -f2- | tr -d '"' | tr -d "'")
    echo "${val:-$default}"
}
POSTGRES_PASSWORD=$(_read_env_var POSTGRES_PASSWORD localdev)
REDIS_PASSWORD=$(_read_env_var REDIS_PASSWORD localdev)
VAULT_DEV_ROOT_TOKEN=$(_read_env_var VAULT_DEV_ROOT_TOKEN medinovai-dev-token)
ok "Credentials loaded from $ENV_FILE"

# ── Phase 1: Build base images ─────────────────────────────────────────────────
if ! $SKIP_BUILD; then
    banner "Phase 1 — Build Base Images"
    log "Building medinovai-base-python and medinovai-base-node..."

    if $DRY_RUN; then
        warn "[DRY RUN] Would build base images"
    else
        docker build -t medinovai-base-python:latest \
            -f "$PROJECT_ROOT/infra/docker/Dockerfile.base-python" \
            "$PROJECT_ROOT/infra/docker/" \
            2>&1 | tee "$LOG_DIR/base-python.log" | tail -3
        ok "medinovai-base-python:latest built"

        docker build -t medinovai-base-node:latest \
            -f "$PROJECT_ROOT/infra/docker/Dockerfile.base-node" \
            "$PROJECT_ROOT/infra/docker/" \
            2>&1 | tee "$LOG_DIR/base-node.log" | tail -3
        ok "medinovai-base-node:latest built"
    fi
fi

# ── Phase 2: Build/Ensure service images ──────────────────────────────────────
banner "Phase 2 — Ensure Service Images (95 services from $REPOS_BASE)"
if $SKIP_BUILD; then
    log "--skip-build enabled: will only build missing images (existing images are skipped)."
else
    log "Building service images (existing images are skipped unless --force is used)."
fi
log "This may take ~10-20 min depending on hardware. Logs: $LOG_DIR/"

BUILD_CMD="bash $SCRIPT_DIR/build_tier_images.sh --repos-base \"$REPOS_BASE\""
[ -n "$TIER_FILTER" ] && BUILD_CMD="$BUILD_CMD --tier $TIER_FILTER"
$DRY_RUN && BUILD_CMD="$BUILD_CMD --dry-run"

log "Running: $BUILD_CMD"
if eval "$BUILD_CMD" 2>&1 | tee "$LOG_DIR/build-images.log"; then
    ok "Image ensure phase complete"
else
    warn "Some images failed to build. Compose will likely fail for those services."
    warn "Check: $LOG_DIR/build-images.log"
fi

# ── Phase 3: Regenerate all-services compose ──────────────────────────────────
banner "Phase 3 — Generate docker-compose.all-services.yml"

if $DRY_RUN; then
    warn "[DRY RUN] Would regenerate $COMPOSE_ALL"
else
    TIER_ARG=""
    [ -n "$TIER_FILTER" ] && TIER_ARG="--tier $TIER_FILTER"
    python3 "$SCRIPT_DIR/generate_all_services_compose.py" $TIER_ARG
    ok "Generated $COMPOSE_ALL"
fi

# ── Phase 4: Deploy all services ───────────────────────────────────────────────
banner "Phase 4 — Deploy All Services"

SVC_COUNT=$(grep -c "container_name:" "$COMPOSE_ALL" 2>/dev/null || echo "?")
log "Starting $SVC_COUNT services on network $NETWORK_NAME..."

if $DRY_RUN; then
    warn "[DRY RUN] Would run: docker compose -p $COMPOSE_PROJECT -f $COMPOSE_ALL up -d"
else
    # Pass credentials explicitly; do NOT use --env-file (it passes REPOS_BASE=../../repos etc.)
    if POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
       REDIS_PASSWORD="$REDIS_PASSWORD" \
       VAULT_DEV_ROOT_TOKEN="$VAULT_DEV_ROOT_TOKEN" \
       docker compose -p "$COMPOSE_PROJECT" -f "$COMPOSE_ALL" up -d \
       2>&1 | tee "$LOG_DIR/compose-up.log"; then
        ok "docker compose up -d complete"
    else
        fail "docker compose up failed — check $LOG_DIR/compose-up.log"
        fail "Aborting before verify loop because deployment failed."
        exit 1
    fi
fi

# ── Phase 5: Verify loop ────────────────────────────────────────────────────
banner "Phase 5 — Verify & Auto-Fix (max $VERIFY_MAX iterations)"

VERIFY_CMD="bash $SCRIPT_DIR/verify_loop.sh --auto-fix --max-iterations $VERIFY_MAX --wait 20"
[ -n "$TIER_FILTER" ] && VERIFY_CMD="$VERIFY_CMD --tier $TIER_FILTER"

if $DRY_RUN; then
    warn "[DRY RUN] Would run: $VERIFY_CMD"
else
    log "Running: $VERIFY_CMD"
    if eval "$VERIFY_CMD" 2>&1 | tee "$LOG_DIR/verify.log"; then
        ok "All services verified healthy"
    else
        warn "Some services still unhealthy after $VERIFY_MAX iterations"
        warn "Check: $LOG_DIR/verify.log"
        warn "Re-run: bash $SCRIPT_DIR/verify_loop.sh --auto-fix --max-iterations 5"
    fi
fi

# ── Summary ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  ${BOLD}Deploy complete${NC} — Logs: $LOG_DIR/"
echo ""
echo "  Key endpoints:"
echo "    medinovaios portal   → http://localhost:13030"
echo "    API Gateway          → http://localhost:8080/health"
echo "    Registry             → http://localhost:10100/health"
echo "    Security service     → http://localhost:9000/health"
echo "    Grafana              → http://localhost:13001"
echo "    Vault                → http://localhost:8200"
echo ""
echo "  Platform status:"
echo "    docker compose -p $COMPOSE_PROJECT -f infra/docker/docker-compose.dev.yml ps"
echo "    docker compose -p $COMPOSE_PROJECT -f infra/docker/docker-compose.all-services.yml ps"
echo ""
echo "  Re-run verification:"
echo "    bash scripts/deploy/verify_loop.sh --auto-fix"
echo -e "${B}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
