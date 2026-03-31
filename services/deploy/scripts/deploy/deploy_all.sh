#!/usr/bin/env bash
# ─── deploy_all.sh ────────────────────────────────────────────────────────────
# Deploy ALL MedinovAI services in tiered dependency order.
#
# Reads config/dependency-graph.json to determine deployment phases, ordering,
# and parallelization strategy. Validates each tier's health before proceeding
# to the next.
#
# Usage:
#   bash scripts/deploy/deploy_all.sh --environment staging
#   bash scripts/deploy/deploy_all.sh --environment production --tier 1
#   bash scripts/deploy/deploy_all.sh --environment dev --dry-run
#   bash scripts/deploy/deploy_all.sh --environment staging --start-tier 3
#   bash scripts/deploy/deploy_all.sh --environment staging --critical-path-only
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEPENDENCY_GRAPH="$PROJECT_ROOT/config/dependency-graph.json"

ENVIRONMENT="staging"
DRY_RUN=false
SINGLE_TIER=""
START_TIER=0
CRITICAL_PATH_ONLY=false
PARALLEL_JOBS=4
HEALTH_TIMEOUT=120
HEALTH_INTERVAL=5
STOP_ON_FAIL=true
LOG_DIR="$PROJECT_ROOT/outputs/deploy-$(date +%Y%m%d-%H%M%S)"

while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)          ENVIRONMENT="$2"; shift 2 ;;
        --dry-run)              DRY_RUN=true; shift ;;
        --tier)                 SINGLE_TIER="$2"; shift 2 ;;
        --start-tier)           START_TIER="$2"; shift 2 ;;
        --critical-path-only)   CRITICAL_PATH_ONLY=true; shift ;;
        --parallel-jobs)        PARALLEL_JOBS="$2"; shift 2 ;;
        --health-timeout)       HEALTH_TIMEOUT="$2"; shift 2 ;;
        --no-stop-on-fail)      STOP_ON_FAIL=false; shift ;;
        *)                      echo "Unknown option: $1"; exit 1 ;;
    esac
done

mkdir -p "$LOG_DIR"

# ─── Utilities ────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log()      { echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} $*"; }
log_ok()   { echo -e "${GREEN}  ✓${NC} $*"; }
log_fail() { echo -e "${RED}  ✗${NC} $*"; }
log_warn() { echo -e "${YELLOW}  ⚠${NC} $*"; }
log_tier() { echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; echo -e "${BLUE}  TIER $1: $2${NC}"; echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; }

check_dependency_graph() {
    if [[ ! -f "$DEPENDENCY_GRAPH" ]]; then
        echo "ERROR: Dependency graph not found at $DEPENDENCY_GRAPH"
        exit 1
    fi
    if ! python3 -c "import json; json.load(open('$DEPENDENCY_GRAPH'))" 2>/dev/null; then
        echo "ERROR: Dependency graph is not valid JSON"
        exit 1
    fi
}

# Extract service list for a tier from dependency graph
get_tier_services() {
    local tier="$1"
    python3 -c "
import json, sys
with open('$DEPENDENCY_GRAPH') as f:
    graph = json.load(f)
tier_data = graph['tiers'].get('$tier', {})

if 'deploy_order' in tier_data:
    for svc in tier_data['deploy_order']:
        print(svc)
elif 'sub_groups' in tier_data:
    for group_key in sorted(tier_data['sub_groups'].keys()):
        group = tier_data['sub_groups'][group_key]
        if 'deploy_order' in group:
            for svc in group['deploy_order']:
                print(svc)
elif 'services' in tier_data:
    for svc in tier_data['services']:
        sid = svc.get('id', '')
        if sid:
            print(sid)
"
}

get_tier_name() {
    python3 -c "
import json
with open('$DEPENDENCY_GRAPH') as f:
    graph = json.load(f)
print(graph['tiers'].get('$1', {}).get('name', 'Unknown'))
"
}

get_tier_parallel() {
    python3 -c "
import json
with open('$DEPENDENCY_GRAPH') as f:
    graph = json.load(f)
print(str(graph['tiers'].get('$1', {}).get('parallel', False)).lower())
"
}

get_critical_path() {
    python3 -c "
import json
with open('$DEPENDENCY_GRAPH') as f:
    graph = json.load(f)
for svc in graph.get('summary', {}).get('critical_path', []):
    print(svc)
"
}

get_service_health() {
    local svc_id="$1"
    python3 -c "
import json
with open('$DEPENDENCY_GRAPH') as f:
    graph = json.load(f)
for tier_key, tier_data in graph['tiers'].items():
    for svc in tier_data.get('services', []):
        if svc.get('id') == '$svc_id':
            print(svc.get('health', '/health'))
            exit()
    for group in tier_data.get('sub_groups', {}).values():
        for svc in group.get('services', []):
            if svc.get('id') == '$svc_id':
                print(svc.get('health', '/health'))
                exit()
print('/health')
"
}

get_service_port() {
    local svc_id="$1"
    python3 -c "
import json
with open('$DEPENDENCY_GRAPH') as f:
    graph = json.load(f)
for tier_key, tier_data in graph['tiers'].items():
    for svc in tier_data.get('services', []):
        if svc.get('id') == '$svc_id' and svc.get('port'):
            print(svc['port'])
            exit()
    for group in tier_data.get('sub_groups', {}).values():
        for svc in group.get('services', []):
            if svc.get('id') == '$svc_id' and svc.get('port'):
                print(svc['port'])
                exit()
print('8000')
"
}

# ─── Deployment Functions ─────────────────────────────────────────────────────

deploy_infrastructure() {
    log_tier "0" "Bare Infrastructure"
    log "Deploying infrastructure services..."

    if $DRY_RUN; then
        log_warn "DRY RUN: Would deploy infrastructure via docker-compose"
        return 0
    fi

    local compose_file="$PROJECT_ROOT/infra/docker/docker-compose.dev.yml"
    if [[ "$ENVIRONMENT" == "production" || "$ENVIRONMENT" == "staging" ]]; then
        log "Using Terraform for $ENVIRONMENT infrastructure..."
        if [[ -d "$PROJECT_ROOT/infra/terraform/environments/$ENVIRONMENT" ]]; then
            cd "$PROJECT_ROOT/infra/terraform/environments/$ENVIRONMENT"
            terraform init -upgrade -input=false 2>&1 | tee "$LOG_DIR/tier0-terraform-init.log"
            terraform plan -out=tfplan 2>&1 | tee "$LOG_DIR/tier0-terraform-plan.log"
            terraform apply -auto-approve tfplan 2>&1 | tee "$LOG_DIR/tier0-terraform-apply.log"
            cd "$PROJECT_ROOT"
        else
            log_warn "Terraform environment $ENVIRONMENT not found, falling back to docker-compose"
            docker compose -f "$compose_file" up -d 2>&1 | tee "$LOG_DIR/tier0-docker.log"
        fi
    else
        if [[ -f "$compose_file" ]]; then
            docker compose -f "$compose_file" up -d 2>&1 | tee "$LOG_DIR/tier0-docker.log"
        else
            log_warn "No docker-compose.dev.yml found, skipping infrastructure deployment"
        fi
    fi

    log "Waiting for infrastructure health checks..."
    sleep 10

    local infra_services=("postgres-primary:5432" "redis-cache:6379")
    for entry in "${infra_services[@]}"; do
        local name="${entry%%:*}"
        local port="${entry##*:}"
        if nc -z localhost "$port" 2>/dev/null; then
            log_ok "$name (port $port) is reachable"
        else
            log_warn "$name (port $port) is not reachable — may be external"
        fi
    done
}

deploy_service() {
    local service="$1"
    local strategy="rolling"
    [[ "$ENVIRONMENT" == "production" ]] && strategy="canary"

    local svc_log="$LOG_DIR/${service}.log"

    if $DRY_RUN; then
        log_warn "DRY RUN: Would deploy $service ($strategy)"
        echo "DRY_RUN: $service" >> "$svc_log"
        return 0
    fi

    if bash "$SCRIPT_DIR/deploy_service.sh" \
        --service "$service" \
        --environment "$ENVIRONMENT" \
        --strategy "$strategy" 2>&1 | tee "$svc_log"; then
        return 0
    else
        return 1
    fi
}

wait_for_service_health() {
    local service="$1"
    local port
    port=$(get_service_port "$service")
    local health_path
    health_path=$(get_service_health "$service")
    local elapsed=0

    if [[ "$health_path" == "None" || "$health_path" == "null" || -z "$health_path" ]]; then
        log_warn "No health endpoint for $service — skipping health check"
        return 0
    fi

    if $DRY_RUN; then
        return 0
    fi

    while [[ $elapsed -lt $HEALTH_TIMEOUT ]]; do
        if curl -sf "http://localhost:${port}${health_path}" >/dev/null 2>&1; then
            return 0
        fi
        sleep "$HEALTH_INTERVAL"
        elapsed=$((elapsed + HEALTH_INTERVAL))
    done
    return 1
}

deploy_tier_sequential() {
    local tier="$1"
    local tier_name
    tier_name=$(get_tier_name "$tier")
    log_tier "${tier#tier}" "$tier_name"

    local services=()
    while IFS= read -r svc; do
        [[ -n "$svc" ]] && services+=("$svc")
    done < <(get_tier_services "$tier")

    local total=${#services[@]}
    local pass=0
    local fail=0

    if [[ $total -eq 0 ]]; then
        log_warn "No services found for $tier"
        return 0
    fi

    log "Deploying $total services sequentially..."

    for i in "${!services[@]}"; do
        local service="${services[$i]}"
        local step=$((i + 1))
        log "[$step/$total] Deploying: $service"

        if deploy_service "$service"; then
            if wait_for_service_health "$service"; then
                log_ok "$service deployed and healthy"
                pass=$((pass + 1))
            else
                log_fail "$service deployed but health check failed"
                fail=$((fail + 1))
                if $STOP_ON_FAIL; then
                    log_fail "Stopping deployment at $service. $pass/$total succeeded, $fail failed."
                    return 1
                fi
            fi
        else
            log_fail "$service deployment FAILED"
            fail=$((fail + 1))
            if $STOP_ON_FAIL; then
                log_fail "Stopping deployment at $service. $pass/$total succeeded, $fail failed."
                return 1
            fi
        fi
    done

    log "Tier ${tier#tier} complete: $pass/$total succeeded, $fail failed"
    [[ $fail -eq 0 ]] && return 0 || return 1
}

deploy_tier_parallel() {
    local tier="$1"
    local tier_name
    tier_name=$(get_tier_name "$tier")
    log_tier "${tier#tier}" "$tier_name"

    local services=()
    while IFS= read -r svc; do
        [[ -n "$svc" ]] && services+=("$svc")
    done < <(get_tier_services "$tier")

    local total=${#services[@]}

    if [[ $total -eq 0 ]]; then
        log_warn "No services found for $tier"
        return 0
    fi

    log "Deploying $total services (parallel, max $PARALLEL_JOBS concurrent)..."

    local pids=()
    local svc_names=()
    local running=0
    local pass=0
    local fail=0

    for service in "${services[@]}"; do
        while [[ $running -ge $PARALLEL_JOBS ]]; do
            for idx in "${!pids[@]}"; do
                if ! kill -0 "${pids[$idx]}" 2>/dev/null; then
                    wait "${pids[$idx]}" && pass=$((pass + 1)) || fail=$((fail + 1))
                    unset "pids[$idx]"
                    unset "svc_names[$idx]"
                    running=$((running - 1))
                fi
            done
            pids=("${pids[@]}")
            svc_names=("${svc_names[@]}")
            sleep 1
        done

        log "  Starting: $service"
        (
            deploy_service "$service"
        ) &
        pids+=($!)
        svc_names+=("$service")
        running=$((running + 1))
    done

    for idx in "${!pids[@]}"; do
        if wait "${pids[$idx]}"; then
            log_ok "${svc_names[$idx]} deployed"
            pass=$((pass + 1))
        else
            log_fail "${svc_names[$idx]} FAILED"
            fail=$((fail + 1))
        fi
    done

    log "Tier ${tier#tier} complete: $pass/$total succeeded, $fail failed"

    # Health check all services in tier
    log "Running health checks for tier ${tier#tier}..."
    for service in "${services[@]}"; do
        if wait_for_service_health "$service"; then
            log_ok "$service healthy"
        else
            log_warn "$service health check failed or no endpoint"
        fi
    done

    [[ $fail -eq 0 ]] && return 0 || return 1
}

deploy_tier() {
    local tier="$1"
    local is_parallel
    is_parallel=$(get_tier_parallel "$tier")

    if [[ "$is_parallel" == "true" ]]; then
        deploy_tier_parallel "$tier"
    else
        deploy_tier_sequential "$tier"
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║     MedinovAI Platform — Full Tiered Deployment                     ║"
    echo "║     Environment: $ENVIRONMENT"
    echo "║     Dependency Graph: $DEPENDENCY_GRAPH"
    echo "║     Log Directory: $LOG_DIR"
    $DRY_RUN && echo "║     MODE: DRY RUN"
    $CRITICAL_PATH_ONLY && echo "║     MODE: CRITICAL PATH ONLY"
    echo "╚══════════════════════════════════════════════════════════════════════╝"
    echo ""

    check_dependency_graph

    if $CRITICAL_PATH_ONLY; then
        log "Deploying critical path only..."
        local critical_services=()
        while IFS= read -r svc; do
            [[ -n "$svc" ]] && critical_services+=("$svc")
        done < <(get_critical_path)

        local total=${#critical_services[@]}
        local pass=0

        for i in "${!critical_services[@]}"; do
            local service="${critical_services[$i]}"
            local step=$((i + 1))
            log "[$step/$total] Critical path: $service"

            if deploy_service "$service"; then
                if wait_for_service_health "$service"; then
                    log_ok "$service deployed and healthy"
                    pass=$((pass + 1))
                else
                    log_fail "$service health check failed"
                    if $STOP_ON_FAIL; then exit 1; fi
                fi
            else
                log_fail "$service deployment FAILED"
                if $STOP_ON_FAIL; then exit 1; fi
            fi
        done

        log "Critical path deployment complete: $pass/$total"
        exit 0
    fi

    local TIERS=("tier0" "tier1" "tier2" "tier3" "tier4" "tier5" "tier6")

    if [[ -n "$SINGLE_TIER" ]]; then
        TIERS=("tier${SINGLE_TIER}")
    fi

    local total_pass=0
    local total_fail=0
    local tier_results=()

    for tier in "${TIERS[@]}"; do
        local tier_num="${tier#tier}"

        if [[ "$tier_num" -lt "$START_TIER" ]]; then
            log "Skipping $tier (below start-tier $START_TIER)"
            continue
        fi

        if [[ "$tier" == "tier0" ]]; then
            deploy_infrastructure
            tier_results+=("Tier 0 (Infrastructure): OK")
            continue
        fi

        if deploy_tier "$tier"; then
            tier_results+=("Tier $tier_num ($(get_tier_name "$tier")): OK")
            total_pass=$((total_pass + 1))
        else
            tier_results+=("Tier $tier_num ($(get_tier_name "$tier")): FAILED")
            total_fail=$((total_fail + 1))
            if $STOP_ON_FAIL; then
                log_fail "Deployment halted at Tier $tier_num. Fix issues before proceeding."
                break
            fi
        fi
    done

    echo ""
    echo "╔══════════════════════════════════════════════════════════════════════╗"
    echo "║     DEPLOYMENT SUMMARY                                              ║"
    echo "╠══════════════════════════════════════════════════════════════════════╣"
    for result in "${tier_results[@]}"; do
        printf "║  %-66s ║\n" "$result"
    done
    echo "╠══════════════════════════════════════════════════════════════════════╣"
    printf "║  Tiers Passed: %-51s ║\n" "$total_pass"
    printf "║  Tiers Failed: %-51s ║\n" "$total_fail"
    printf "║  Logs: %-59s ║\n" "$LOG_DIR"
    echo "╚══════════════════════════════════════════════════════════════════════╝"

    [[ $total_fail -eq 0 ]] && exit 0 || exit 1
}

main "$@"
