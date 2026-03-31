#!/usr/bin/env bash
# ─── deploy_platform.sh ──────────────────────────────────────────────────────
# Master deployment orchestrator for the MedinovAI platform.
# Deploys all tiers in dependency order via docker-compose with health gates.
# Implements AtlasOS OODA loop: Observe → Orient → Decide → Act per tier.
#
# Usage:
#   bash scripts/deploy/deploy_platform.sh                      # Full deploy
#   bash scripts/deploy/deploy_platform.sh --tier 1             # Single tier
#   bash scripts/deploy/deploy_platform.sh --start-tier 2       # Resume from tier
#   bash scripts/deploy/deploy_platform.sh --critical-path-only # 12-service MVP
#   bash scripts/deploy/deploy_platform.sh --dry-run            # Preview only
#   bash scripts/deploy/deploy_platform.sh --no-build           # Skip image builds
#   bash scripts/deploy/deploy_platform.sh --keycloak-mode platform|standalone
#   bash scripts/deploy/deploy_platform.sh --keycloak-ownership-mode warn|enforce
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEPENDENCY_GRAPH="$PROJECT_ROOT/config/dependency-graph.json"
COMPOSE_DIR="$PROJECT_ROOT/infra/docker"
CHECKPOINT_DIR="${HOME}/.medinovai-deploy/checkpoints/platform"
LOG_DIR="$PROJECT_ROOT/outputs/deploy-$(date +%Y%m%d-%H%M%S)"
KEYCLOAK_VALIDATOR="$PROJECT_ROOT/scripts/validation/validate_keycloak_ownership.sh"

SINGLE_TIER=""
START_TIER=0
CRITICAL_PATH_ONLY=false
DRY_RUN=false
SKIP_BUILD=false
MAX_RETRIES=3
HEALTH_TIMEOUT=120
HEALTH_INTERVAL=5
STOP_ON_FAIL=true
KEYCLOAK_MODE="${KEYCLOAK_MODE:-platform}"
KEYCLOAK_OWNERSHIP_MODE="${KEYCLOAK_OWNERSHIP_MODE:-warn}"

while [[ $# -gt 0 ]]; do
    case $1 in
        --tier)               SINGLE_TIER="$2"; shift 2 ;;
        --start-tier)         START_TIER="$2"; shift 2 ;;
        --critical-path-only) CRITICAL_PATH_ONLY=true; shift ;;
        --dry-run)            DRY_RUN=true; shift ;;
        --no-build)           SKIP_BUILD=true; shift ;;
        --max-retries)        MAX_RETRIES="$2"; shift 2 ;;
        --health-timeout)     HEALTH_TIMEOUT="$2"; shift 2 ;;
        --no-stop-on-fail)    STOP_ON_FAIL=false; shift ;;
        --keycloak-mode)      KEYCLOAK_MODE="$2"; shift 2 ;;
        --keycloak-ownership-mode) KEYCLOAK_OWNERSHIP_MODE="$2"; shift 2 ;;
        *)                    echo "Unknown option: $1"; exit 1 ;;
    esac
done

mkdir -p "$CHECKPOINT_DIR" "$LOG_DIR"

# ─── Colors and Logging ─────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()      { echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} $*" | tee -a "$LOG_DIR/deploy.log"; }
log_ok()   { echo -e "${GREEN}  ✓${NC} $*" | tee -a "$LOG_DIR/deploy.log"; }
log_fail() { echo -e "${RED}  ✗${NC} $*" | tee -a "$LOG_DIR/deploy.log"; }
log_warn() { echo -e "${YELLOW}  ⚠${NC} $*" | tee -a "$LOG_DIR/deploy.log"; }

tier_banner() {
    local tier="$1" name="$2"
    echo "" | tee -a "$LOG_DIR/deploy.log"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_DIR/deploy.log"
    echo -e "${BLUE}  TIER $tier: $name${NC}" | tee -a "$LOG_DIR/deploy.log"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" | tee -a "$LOG_DIR/deploy.log"
}

checkpoint_save() { echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > "$CHECKPOINT_DIR/tier_$1.done"; }
checkpoint_exists() { [ -f "$CHECKPOINT_DIR/tier_$1.done" ]; }

# ─── Compose file mapping ───────────────────────────────────────────────────

COMPOSE_TIER0="$COMPOSE_DIR/docker-compose.tier0-infra.yml"
COMPOSE_TIER1="$COMPOSE_DIR/docker-compose.tier1-security.yml"
COMPOSE_TIER2="$COMPOSE_DIR/docker-compose.tier2-platform.yml"
COMPOSE_DEV="$COMPOSE_DIR/docker-compose.dev.yml"

# ─── Ownership Validation ────────────────────────────────────────────────────

validate_keycloak_ownership() {
    if [[ ! -x "$KEYCLOAK_VALIDATOR" ]]; then
        log_warn "Keycloak ownership validator missing: $KEYCLOAK_VALIDATOR"
        return 0
    fi

    log "Validating Keycloak ownership (runtime=compose, mode=$KEYCLOAK_MODE, policy=$KEYCLOAK_OWNERSHIP_MODE)..."

    local security_compose=""
    if [[ -n "${SECURITY_SERVICE_COMPOSE_FILE:-}" ]]; then
        security_compose="$SECURITY_SERVICE_COMPOSE_FILE"
    fi

    if ! SECURITY_SERVICE_COMPOSE_FILE="$security_compose" \
        bash "$KEYCLOAK_VALIDATOR" \
        --runtime compose \
        --compose-mode "$KEYCLOAK_MODE" \
        --mode "$KEYCLOAK_OWNERSHIP_MODE" | tee -a "$LOG_DIR/deploy.log"; then
        if [[ "$KEYCLOAK_MODE" == "standalone" && "$KEYCLOAK_OWNERSHIP_MODE" == "warn" ]]; then
            log_warn "Keycloak ownership validation reported advisory issues for standalone compose; continuing."
            return 0
        fi
        log_fail "Keycloak ownership validation failed."
        return 1
    fi

    log_ok "Keycloak ownership validation completed."
    return 0
}

# ─── Health Check Functions ──────────────────────────────────────────────────

check_container_health() {
    local container="$1"
    local status
    status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "missing")
    echo "$status"
}

check_http_health() {
    local url="$1"
    curl -sf --max-time 5 "$url" > /dev/null 2>&1
}

wait_for_container_healthy() {
    local container="$1"
    local timeout="${2:-$HEALTH_TIMEOUT}"
    local elapsed=0

    while [[ $elapsed -lt $timeout ]]; do
        local status
        status=$(check_container_health "$container")
        if [[ "$status" == "healthy" ]]; then
            return 0
        fi
        sleep "$HEALTH_INTERVAL"
        elapsed=$((elapsed + HEALTH_INTERVAL))
    done
    return 1
}

# ─── Tier Deployment with OODA Loop ─────────────────────────────────────────

deploy_tier_compose() {
    local tier_num="$1"
    local tier_name="$2"
    local compose_file="$3"
    shift 3
    local -a service_checks=("$@")

    tier_banner "$tier_num" "$tier_name"

    if [ ! -f "$compose_file" ]; then
        log_fail "Compose file not found: $compose_file"
        return 1
    fi

    local attempt=0
    local all_healthy=false

    while [[ $attempt -lt $MAX_RETRIES ]] && ! $all_healthy; do
        attempt=$((attempt + 1))
        log "Attempt $attempt/$MAX_RETRIES"

        # ── OBSERVE: Check current state ──
        log "OBSERVE: Checking current service state..."
        local unhealthy_services=()
        for entry in "${service_checks[@]}"; do
            local container="${entry%%:*}"
            local port_health="${entry#*:}"
            local port="${port_health%%:*}"
            local health_path="${port_health#*:}"
            local status
            status=$(check_container_health "$container")
            if [[ "$status" != "healthy" ]]; then
                unhealthy_services+=("$entry")
            else
                log_ok "$container: already healthy"
            fi
        done

        if [[ ${#unhealthy_services[@]} -eq 0 ]]; then
            log_ok "All services in Tier $tier_num already healthy"
            all_healthy=true
            break
        fi

        # ── ORIENT: Classify what needs to happen ──
        log "ORIENT: ${#unhealthy_services[@]} service(s) need deployment"

        # ── DECIDE + ACT: Deploy ──
        if $DRY_RUN; then
            log "[DRY RUN] Would run: docker compose -f $compose_file up -d"
        else
            log "ACT: Deploying Tier $tier_num..."
            if ! docker compose -f "$compose_file" up -d 2>&1 | tee -a "$LOG_DIR/tier${tier_num}.log"; then
                log_fail "docker compose up failed for Tier $tier_num"
                if $STOP_ON_FAIL && [[ $attempt -ge $MAX_RETRIES ]]; then
                    return 1
                fi
                continue
            fi
        fi

        # ── VERIFY: Health-check every service ──
        log "VERIFY: Waiting for health checks (timeout: ${HEALTH_TIMEOUT}s)..."
        local pass=0 fail=0
        for entry in "${service_checks[@]}"; do
            local container="${entry%%:*}"
            local port_health="${entry#*:}"
            local port="${port_health%%:*}"
            local health_path="${port_health#*:}"

            if $DRY_RUN; then
                log_ok "$container: [DRY RUN] would check localhost:$port$health_path"
                pass=$((pass + 1))
                continue
            fi

            if wait_for_container_healthy "$container" "$HEALTH_TIMEOUT"; then
                log_ok "$container: healthy"
                pass=$((pass + 1))
            elif check_http_health "http://localhost:${port}${health_path}"; then
                log_ok "$container: HTTP health OK (container status lagging)"
                pass=$((pass + 1))
            else
                log_fail "$container: unhealthy after ${HEALTH_TIMEOUT}s"
                # Diagnose: show last few log lines
                docker logs --tail 10 "$container" 2>&1 | while IFS= read -r line; do
                    echo "    $line" | tee -a "$LOG_DIR/deploy.log"
                done
                fail=$((fail + 1))
            fi
        done

        log "Tier $tier_num results: $pass passed, $fail failed"
        if [[ $fail -eq 0 ]]; then
            all_healthy=true
        elif [[ $attempt -lt $MAX_RETRIES ]]; then
            log_warn "Retrying Tier $tier_num in 15s (attempt $((attempt + 1))/$MAX_RETRIES)..."
            sleep 15
        fi
    done

    if $all_healthy; then
        log_ok "GATE PASSED: Tier $tier_num — all services healthy"
        checkpoint_save "$tier_num"
        return 0
    else
        log_fail "GATE FAILED: Tier $tier_num — not all services healthy after $MAX_RETRIES attempts"
        if $STOP_ON_FAIL; then
            log_fail "Stopping deployment. Fix Tier $tier_num issues and re-run with --start-tier $tier_num"
            return 1
        fi
        return 1
    fi
}

# ─── Tier 0: Infrastructure ─────────────────────────────────────────────────

deploy_tier0() {
    local -a checks=(
        "medinovai-postgres-primary:5432:/health"
        "medinovai-postgres-clinical:5433:/health"
        "medinovai-redis:6379:/health"
        "medinovai-vault:8200:/v1/sys/health"
        "medinovai-keycloak:9080:/health/ready"
        "medinovai-kafka:9092:/health"
        "medinovai-zookeeper:2181:/health"
        "medinovai-mongodb:27017:/health"
        "medinovai-elasticsearch:9200:/_cluster/health"
        "medinovai-rabbitmq:15672:/api/health"
        "medinovai-prometheus:9090:/-/healthy"
        "medinovai-grafana:3000:/api/health"
        "medinovai-loki:3100:/ready"
        "medinovai-jaeger:16686:/"
    )
    deploy_tier_compose 0 "Bare Infrastructure" "$COMPOSE_TIER0" "${checks[@]}"
}

# ─── Tier 1: Security ───────────────────────────────────────────────────────

deploy_tier1() {
    if ! $SKIP_BUILD; then
        log "Building Tier 1 images..."
        bash "$SCRIPT_DIR/build_tier_images.sh" --tier 1 ${DRY_RUN:+--dry-run} 2>&1 | tee -a "$LOG_DIR/build-tier1.log"
    fi

    local -a checks=(
        "medinovai-secrets-manager-bridge:10001:/health"
        "medinovai-security:9000:/health"
        "medinovai-universal-sign-on:10003:/health"
        "medinovai-role-based-permissions:10004:/healthz"
        "medinovai-encryption-vault:10005:/health"
        "medinovai-hipaa-gdpr-guard:10006:/health"
        "medinovai-consent-preference-api:10007:/health"
        "medinovai-audit-trail-explorer:10008:/health"
    )
    deploy_tier_compose 1 "Security & Secrets Foundation" "$COMPOSE_TIER1" "${checks[@]}"
}

# ─── Tier 2: Platform Core ──────────────────────────────────────────────────

deploy_tier2() {
    if ! $SKIP_BUILD; then
        log "Building Tier 2 images..."
        bash "$SCRIPT_DIR/build_tier_images.sh" --tier 2 ${DRY_RUN:+--dry-run} 2>&1 | tee -a "$LOG_DIR/build-tier2.log"
    fi

    local -a checks=(
        "medinovai-registry:10100:/health"
        "medinovai-data-services:10101:/health"
        "medinovai-stream-bus:10102:/health/ready"
        "medinovai-notification-center:10103:/health"
        "medinovai-aifactory:10104:/health"
        "medinovai-api-gateway:8080:/health"
        "medinovai-atlas-engine:10106:/health"
    )
    deploy_tier_compose 2 "Platform Core Services" "$COMPOSE_TIER2" "${checks[@]}"
}

# ─── medinovaios Portal ─────────────────────────────────────────────────────

deploy_medinovaios() {
    tier_banner "OS" "medinovaios Portal"

    if $DRY_RUN; then
        log "[DRY RUN] Would deploy medinovaios from docker-compose.dev.yml"
        return 0
    fi

    log "ACT: Deploying medinovaios..."
    docker compose -f "$COMPOSE_DEV" up -d medinovaios 2>&1 | tee -a "$LOG_DIR/medinovaios.log"

    log "VERIFY: Checking medinovaios health..."
    local elapsed=0
    while [[ $elapsed -lt $HEALTH_TIMEOUT ]]; do
        if check_http_health "http://localhost:3030/health"; then
            log_ok "medinovaios: healthy at http://localhost:3030"
            return 0
        fi
        sleep "$HEALTH_INTERVAL"
        elapsed=$((elapsed + HEALTH_INTERVAL))
    done
    log_fail "medinovaios: unhealthy after ${HEALTH_TIMEOUT}s"
    return 1
}

# ─── Main Orchestration ─────────────────────────────────────────────────────

echo -e "${BOLD}${BLUE}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║     MedinovAI Platform — Tiered Deployment Orchestrator     ║"
echo "║     $(date -u +%Y-%m-%dT%H:%M:%SZ)                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

if ! validate_keycloak_ownership; then
    exit 1
fi

# Ensure docker network exists
if ! docker network inspect medinovai-network &>/dev/null; then
    log "Creating Docker network: medinovai-network"
    if ! $DRY_RUN; then
        docker network create medinovai-network 2>/dev/null || true
    fi
fi

DEPLOY_START=$(date +%s)
TIERS_PASSED=0
TIERS_FAILED=0

if [ -n "$SINGLE_TIER" ]; then
    case "$SINGLE_TIER" in
        0) deploy_tier0 && TIERS_PASSED=$((TIERS_PASSED + 1)) || TIERS_FAILED=$((TIERS_FAILED + 1)) ;;
        1) deploy_tier1 && TIERS_PASSED=$((TIERS_PASSED + 1)) || TIERS_FAILED=$((TIERS_FAILED + 1)) ;;
        2) deploy_tier2 && TIERS_PASSED=$((TIERS_PASSED + 1)) || TIERS_FAILED=$((TIERS_FAILED + 1)) ;;
        os|OS) deploy_medinovaios && TIERS_PASSED=$((TIERS_PASSED + 1)) || TIERS_FAILED=$((TIERS_FAILED + 1)) ;;
        *) echo "Unknown tier: $SINGLE_TIER (use 0, 1, 2, or os)"; exit 1 ;;
    esac
else
    # Full deployment: tier 0 → 1 → 2 → medinovaios
    for tier_num in 0 1 2; do
        if [[ $tier_num -lt $START_TIER ]]; then
            log "Skipping Tier $tier_num (start-tier=$START_TIER)"
            continue
        fi

        case $tier_num in
            0) deploy_tier0 ;;
            1) deploy_tier1 ;;
            2) deploy_tier2 ;;
        esac

        if [[ $? -eq 0 ]]; then
            TIERS_PASSED=$((TIERS_PASSED + 1))
        else
            TIERS_FAILED=$((TIERS_FAILED + 1))
            if $STOP_ON_FAIL; then
                log_fail "Deployment halted at Tier $tier_num"
                break
            fi
        fi
    done

    # Deploy medinovaios last (only if all prior tiers passed)
    if [[ $TIERS_FAILED -eq 0 ]] || ! $STOP_ON_FAIL; then
        if deploy_medinovaios; then
            TIERS_PASSED=$((TIERS_PASSED + 1))
        else
            TIERS_FAILED=$((TIERS_FAILED + 1))
        fi
    fi
fi

DEPLOY_END=$(date +%s)
ELAPSED=$((DEPLOY_END - DEPLOY_START))

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "  Deployment Complete in ${ELAPSED}s"
echo -e "  Tiers passed: ${GREEN}$TIERS_PASSED${NC}, failed: ${RED}$TIERS_FAILED${NC}"
echo -e "  Logs: $LOG_DIR/"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [[ $TIERS_FAILED -gt 0 ]]; then
    echo ""
    echo "Next steps:"
    echo "  1. Review logs: $LOG_DIR/deploy.log"
    echo "  2. Fix failing services"
    echo "  3. Re-run: bash scripts/deploy/deploy_platform.sh --start-tier <failed_tier>"
    echo "  4. Or run verification loop: bash scripts/deploy/verify_loop.sh"
    exit 1
fi

echo ""
echo -e "${GREEN}${BOLD}All tiers deployed and healthy.${NC}"
echo "  medinovaios portal: http://localhost:3030"
echo "  API gateway:        http://localhost:8080"
echo "  Grafana:            http://localhost:3000"
echo "  Vault:              http://localhost:8200"
echo ""
echo "Run verification loop to confirm: bash scripts/deploy/verify_loop.sh"
