#!/usr/bin/env bash
# ─── verify_loop.sh ──────────────────────────────────────────────────────────
# AtlasOS-style iterative verification loop for the MedinovAI platform.
# Probes every service's health endpoint, auto-fixes common issues,
# and loops until 100% healthy or max iterations reached.
#
# Usage:
#   bash scripts/deploy/verify_loop.sh                     # Default: 5 iterations
#   bash scripts/deploy/verify_loop.sh --max-iterations 10 # Custom max
#   bash scripts/deploy/verify_loop.sh --tier 1            # Check single tier
#   bash scripts/deploy/verify_loop.sh --auto-fix          # Enable auto-fix
#   bash scripts/deploy/verify_loop.sh --json              # JSON output
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEPENDENCY_GRAPH="$PROJECT_ROOT/config/dependency-graph.json"
COMPOSE_PROJECT="medinovai-dev"

MAX_ITERATIONS=5
TIER_FILTER=""
AUTO_FIX=false
JSON_MODE=false
PROBE_TIMEOUT=5
WAIT_BETWEEN=15

while [[ $# -gt 0 ]]; do
    case $1 in
        --max-iterations) MAX_ITERATIONS="$2"; shift 2 ;;
        --tier)           TIER_FILTER="$2"; shift 2 ;;
        --auto-fix)       AUTO_FIX=true; shift ;;
        --json)           JSON_MODE=true; shift ;;
        --timeout)        PROBE_TIMEOUT="$2"; shift 2 ;;
        --wait)           WAIT_BETWEEN="$2"; shift 2 ;;
        *)                echo "Unknown option: $1"; exit 1 ;;
    esac
done

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()      { $JSON_MODE || echo -e "${CYAN}[$(date +%H:%M:%S)]${NC} $*"; }
log_ok()   { $JSON_MODE || echo -e "${GREEN}  ✓${NC} $*"; }
log_fail() { $JSON_MODE || echo -e "${RED}  ✗${NC} $*"; }
log_warn() { $JSON_MODE || echo -e "${YELLOW}  ⚠${NC} $*"; }

# ─── Service Registry ───────────────────────────────────────────────────────
# Maps container_name -> host_port -> health_path for Docker Compose services

declare -A SERVICE_MAP

# Tier 0: Local dev infrastructure (ports from docker-compose.dev.yml)
SERVICE_MAP["tier0:medinovai-postgres"]="5432:pg_isready"
SERVICE_MAP["tier0:medinovai-redis"]="6379:redis"
SERVICE_MAP["tier0:medinovai-vault"]="8200:/v1/sys/health"
SERVICE_MAP["tier0:medinovai-keycloak"]="18081:/health/ready"
SERVICE_MAP["tier0:medinovai-prometheus"]="9090:/-/healthy"
SERVICE_MAP["tier0:medinovai-grafana"]="13001:/api/health"

# Tier 1: Security (ports from docker-compose.tier1-security.yml)
SERVICE_MAP["tier1:medinovai-secrets-manager-bridge"]="10001:/health"
SERVICE_MAP["tier1:medinovai-security"]="10002:/health"
SERVICE_MAP["tier1:medinovai-universal-sign-on"]="10003:/health"
SERVICE_MAP["tier1:medinovai-role-based-permissions"]="10004:/healthz"
SERVICE_MAP["tier1:medinovai-encryption-vault"]="10005:/health"
SERVICE_MAP["tier1:medinovai-hipaa-gdpr-guard"]="10006:/health"
SERVICE_MAP["tier1:medinovai-consent-preference-api"]="10007:/health"
SERVICE_MAP["tier1:medinovai-audit-trail-explorer"]="10008:/health"

# Tier 2: Platform (ports from docker-compose.tier2-platform.yml)
SERVICE_MAP["tier2:medinovai-registry"]="10100:/health"
SERVICE_MAP["tier2:medinovai-data-services"]="10101:/health"
# Service id is stream-bus, container/image is real-time-stream-bus
SERVICE_MAP["tier2:medinovai-real-time-stream-bus"]="10102:/health/ready"
SERVICE_MAP["tier2:medinovai-notification-center"]="10103:/health"
SERVICE_MAP["tier2:medinovai-api-gateway"]="10105:/health"
SERVICE_MAP["tier2:medinovai-atlas-engine"]="10106:/health"

# Tier 3: AI/ML Foundation (ports from docker-compose.all-services.yml)
SERVICE_MAP["tier3:medinovai-healthllm"]="10200:/health"
SERVICE_MAP["tier3:medinovai-model-service-orchestrator"]="10201:/health"
SERVICE_MAP["tier3:medinovai-knowledge-graph"]="10202:/health"
SERVICE_MAP["tier3:medinovai-clinical-decision-support"]="10203:/health"
SERVICE_MAP["tier3:medinovai-patient-services"]="10204:/health"

# Tier 4: Domain Services (ports from docker-compose.all-services.yml)
SERVICE_MAP["tier4:medinovai-patient-onboarding"]="10300:/health"
SERVICE_MAP["tier4:medinovai-patientmatching"]="10301:/healthz"
SERVICE_MAP["tier4:medinovai-health-timeline"]="10302:/health"
SERVICE_MAP["tier4:medinovai-care-team-chat"]="10303:/health"
SERVICE_MAP["tier4:medinovai-smart-scheduler"]="10304:/health"
SERVICE_MAP["tier4:medinovai-wait-list-balancer"]="10305:/healthz"
SERVICE_MAP["tier4:medinovai-virtual-triage"]="10306:/health"
SERVICE_MAP["tier4:medinovai-telehealth-hub"]="10307:/healthz"
SERVICE_MAP["tier4:medinovai-remote-vitals-ingest"]="10308:/health"
SERVICE_MAP["tier4:medinovai-lab-order-router"]="10309:/health"
SERVICE_MAP["tier4:medinovai-pathology-ai"]="10310:/health"
SERVICE_MAP["tier4:medinovai-imaging-viewer"]="10311:/health"
SERVICE_MAP["tier4:medinovai-genomics-interpreter"]="10312:/health"
SERVICE_MAP["tier4:medinovai-image-to-text-ocr"]="10313:/health"
SERVICE_MAP["tier4:medinovai-chatbot"]="10314:/health"
SERVICE_MAP["tier4:medinovai-ai-scribe"]="10315:/health"
SERVICE_MAP["tier4:medinovai-doc-summarizer"]="10316:/health"
SERVICE_MAP["tier4:medinovai-natural-language-query"]="10317:/health"
SERVICE_MAP["tier4:medinovai-anomaly-detector"]="10318:/health"
SERVICE_MAP["tier4:medinovai-sentiment-monitor"]="10319:/health"
SERVICE_MAP["tier4:medinovai-drug-interaction-checker"]="10320:/health"
SERVICE_MAP["tier4:medinovai-medical-fax-processing"]="10321:/health"
SERVICE_MAP["tier4:medinovai-content-translator"]="10322:/health"
SERVICE_MAP["tier4:medinovai-text-to-speech-narrator"]="10323:/health"
SERVICE_MAP["tier4:medinovai-voice-command-layer"]="10324:/health"
SERVICE_MAP["tier4:medinovai-e-prescribe-gateway"]="10325:/health"
SERVICE_MAP["tier4:medinovai-medication-tracker"]="10326:/health"
SERVICE_MAP["tier4:medinovai-ctms"]="10327:/health"
SERVICE_MAP["tier4:medinovai-edc"]="10328:/health"
SERVICE_MAP["tier4:medinovai-etmf"]="10329:/health"
SERVICE_MAP["tier4:medinovai-saes"]="10330:/api/health"
SERVICE_MAP["tier4:medinovai-econsent"]="10331:/health"
SERVICE_MAP["tier4:medinovai-epro"]="10332:/health"
SERVICE_MAP["tier4:medinovai-esource"]="10333:/health"
SERVICE_MAP["tier4:medinovai-eisf"]="10334:/health"
SERVICE_MAP["tier4:medinovai-iwrs"]="10335:/health"
SERVICE_MAP["tier4:medinovai-pharmacovigilance"]="10336:/health"
SERVICE_MAP["tier4:medinovai-researchsuite"]="10337:/health"
SERVICE_MAP["tier4:medinovai-regulatory-submissions"]="10338:/health"
SERVICE_MAP["tier4:medinovai-rbm"]="10339:/health"
SERVICE_MAP["tier4:medinovai-reseach-fabric"]="10340:/health"
SERVICE_MAP["tier4:medinovai-sitefeasibility"]="10341:/health"
SERVICE_MAP["tier4:medinovai-billing"]="10342:/health"
SERVICE_MAP["tier4:medinovai-provider-credentialing"]="10343:/health"
SERVICE_MAP["tier4:medinovai-credentialing"]="10344:/health"
SERVICE_MAP["tier4:medinovai-employee-portal"]="10345:/health"
SERVICE_MAP["tier4:medinovai-subscription"]="10346:/health"
SERVICE_MAP["tier4:medinovai-quality-certification"]="10347:/health"
SERVICE_MAP["tier4:medinovai-inventorymanagement"]="10348:/health"
SERVICE_MAP["tier4:medinovai-mail"]="10349:/health"
SERVICE_MAP["tier4:medinovai-email-service"]="10350:/health"
SERVICE_MAP["tier4:medinovai-lis"]="10351:/health"
SERVICE_MAP["tier4:medinovai-lis-platform"]="10352:/health"
SERVICE_MAP["tier4:medinovai-lis-ui"]="10353:/health"

# Tier 5: Integration & DevOps (ports from docker-compose.all-services.yml)
SERVICE_MAP["tier5:medinovai-edge-cache-cdn"]="10400:/health"
SERVICE_MAP["tier5:medinovai-data-lake-loader"]="10401:/health"
SERVICE_MAP["tier5:medinovai-feature-flag-console"]="10402:/health"
SERVICE_MAP["tier5:medinovai-canary-rollout-orchestrator"]="10403:/health"
SERVICE_MAP["tier5:medinovai-devops-telemetry"]="10404:/health"
SERVICE_MAP["tier5:medinovai-policy-diff-watcher"]="10405:/health"
SERVICE_MAP["tier5:medinovai-etl-designer"]="10406:/health"
SERVICE_MAP["tier5:medinovai-prompt-vault"]="10407:/healthz"
SERVICE_MAP["tier5:medinovai-qa-agent-builder"]="10408:/health"
SERVICE_MAP["tier5:medinovai-task-kanban"]="10409:/health"
SERVICE_MAP["tier5:medinovai-guideline-updater"]="10410:/health"
SERVICE_MAP["tier5:medinovai-white-label-skinner"]="10411:/health"
SERVICE_MAP["tier5:medinovai-accessibility-checker"]="10412:/health"
SERVICE_MAP["tier5:medinovai-governance-templates"]="10413:/health"
SERVICE_MAP["tier5:medinovai-risk-management"]="10414:/health"
SERVICE_MAP["tier5:medinovai-cds"]="10415:/health"
SERVICE_MAP["tier5:medinovai-developer-portal"]="10416:/health"
SERVICE_MAP["tier5:medinovai-livekit"]="10417:/health"

# Tier 6: UI Shell (ports from docker-compose.all-services.yml)
SERVICE_MAP["tier6:medinovai-multimodal-ui-shell"]="10500:/health"

# medinovaios dev portal (from docker-compose.dev.yml)
SERVICE_MAP["tieros:medinovaios"]="13030:/health"

# ─── Probe Functions ─────────────────────────────────────────────────────────

probe_http() {
    local port="$1" path="$2"
    curl -sf --max-time "$PROBE_TIMEOUT" "http://localhost:${port}${path}" > /dev/null 2>&1
}

probe_tcp() {
    local port="$1"
    nc -z -w "$PROBE_TIMEOUT" localhost "$port" 2>/dev/null
}

probe_service() {
    local container="$1" port="$2" check="$3"

    # First check if container is running.
    # Use tail -1 + grep to strip any wrapper/banner lines (e.g. auto-snapshot) from output.
    local raw_state
    raw_state=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null | tail -1)
    local state
    state=$(echo "$raw_state" | tr -d '[:space:]')
    [[ -z "$state" ]] && state="missing"

    if [[ "$state" != "running" ]]; then
        echo "not_running:$state"
        return 1
    fi

    # Check Docker health status if available
    local raw_health
    raw_health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null | tail -1)
    local health
    health=$(echo "$raw_health" | tr -d '[:space:]')
    [[ -z "$health" ]] && health="none"
    if [[ "$health" == "healthy" ]]; then
        echo "healthy"
        return 0
    fi

    # Fallback: probe directly
    case "$check" in
        pg_isready)
            if docker exec "$container" pg_isready -U medinovai 2>/dev/null | grep -q "accepting"; then
                echo "healthy"
                return 0
            fi
            ;;
        redis)
            if docker exec "$container" redis-cli ping 2>/dev/null | grep -q "PONG"; then
                echo "healthy"
                return 0
            fi
            ;;
        tcp)
            if probe_tcp "$port"; then
                echo "healthy"
                return 0
            fi
            ;;
        /*)
            if probe_http "$port" "$check"; then
                echo "healthy"
                return 0
            fi
            ;;
    esac

    echo "unhealthy:$health"
    return 1
}

# ─── Auto-Fix Functions ─────────────────────────────────────────────────────

auto_fix_service() {
    local container="$1" tier="$2"

    local raw_state
    raw_state=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null | tail -1)
    local state
    state=$(echo "$raw_state" | tr -d '[:space:]')
    [[ -z "$state" ]] && state="missing"

    local compose_file=""
    case "$tier" in
        tier0) compose_file="$PROJECT_ROOT/infra/docker/docker-compose.tier0-infra.yml" ;;
        tier1) compose_file="$PROJECT_ROOT/infra/docker/docker-compose.tier1-security.yml" ;;
        tier2) compose_file="$PROJECT_ROOT/infra/docker/docker-compose.tier2-platform.yml" ;;
        tier3|tier4|tier5|tier6) compose_file="$PROJECT_ROOT/infra/docker/docker-compose.all-services.yml" ;;
        tieros) compose_file="$PROJECT_ROOT/infra/docker/docker-compose.dev.yml" ;;
    esac

    case "$state" in
        missing)
            log_warn "AUTO-FIX: $container is missing — triggering tier redeploy"
            if [ -n "$compose_file" ] && [ -f "$compose_file" ]; then
                docker compose -p "$COMPOSE_PROJECT" -f "$compose_file" up -d "$container" 2>/dev/null || true
            fi
            ;;
        created)
            log_warn "AUTO-FIX: $container is created — triggering compose start"
            if [ -n "$compose_file" ] && [ -f "$compose_file" ]; then
                docker compose -p "$COMPOSE_PROJECT" -f "$compose_file" up -d "$container" 2>/dev/null || true
            else
                docker start "$container" 2>/dev/null || true
            fi
            ;;
        exited|dead)
            log_warn "AUTO-FIX: $container is $state — restarting"
            docker start "$container" 2>/dev/null || true
            ;;
        restarting)
            log_warn "AUTO-FIX: $container is restarting — checking logs"
            docker logs --tail 5 "$container" 2>&1 | while IFS= read -r line; do
                echo "    $line"
            done
            # Known recurring issue: this image can be stale/broken locally (e.g. unresolved
            # merge artifact in source Dockerfile). Force a rebuild via the resilient builder.
            if [[ "$container" == "medinovai-white-label-skinner" ]]; then
                log_warn "AUTO-FIX: forcing rebuild for $container image"
                bash "$PROJECT_ROOT/scripts/deploy/build_tier_images.sh" --service "$container" --force >/dev/null 2>&1 || true
                if [ -n "$compose_file" ] && [ -f "$compose_file" ]; then
                    docker compose -p "$COMPOSE_PROJECT" -f "$compose_file" up -d "$container" 2>/dev/null || true
                fi
            fi
            ;;
        *)
            log_warn "AUTO-FIX: $container in state '$state' — no fix available"
            ;;
    esac
}

# ─── Run One Verification Pass ──────────────────────────────────────────────

run_verification() {
    local iteration="$1"
    local total_pass=0 total_fail=0 total_skip=0
    local -a failures=()

    for key in $(echo "${!SERVICE_MAP[@]}" | tr ' ' '\n' | sort); do
        local tier="${key%%:*}"
        local container="${key#*:}"
        local port_check="${SERVICE_MAP[$key]}"
        local port="${port_check%%:*}"
        local check="${port_check#*:}"

        # Filter by tier if specified
        if [[ -n "$TIER_FILTER" ]] && [[ "$tier" != "tier$TIER_FILTER" ]]; then
            continue
        fi

        local result
        if result=$(probe_service "$container" "$port" "$check"); then
            log_ok "$container ($tier) — $result"
            total_pass=$((total_pass + 1))
        else
            log_fail "$container ($tier) — $result"
            total_fail=$((total_fail + 1))
            failures+=("$tier:$container")

            if $AUTO_FIX; then
                auto_fix_service "$container" "$tier"
            fi
        fi
    done

    local total=$((total_pass + total_fail))

    if $JSON_MODE; then
        local fail_json="[]"
        if [[ ${#failures[@]} -gt 0 ]]; then
            fail_json=$(printf '"%s",' "${failures[@]}" | sed 's/,$//')
            fail_json="[$fail_json]"
        fi
        echo "{\"iteration\":$iteration,\"total\":$total,\"healthy\":$total_pass,\"unhealthy\":$total_fail,\"failures\":$fail_json,\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
    else
        echo ""
        echo -e "  ${BOLD}Iteration $iteration: ${GREEN}$total_pass${NC}/${BOLD}$total healthy${NC}"
        if [[ $total_fail -gt 0 ]]; then
            echo -e "  ${RED}Failures:${NC}"
            for f in "${failures[@]}"; do
                echo "    - $f"
            done
        fi
    fi

    if [[ $total_fail -eq 0 ]]; then
        return 0
    fi
    return 1
}

# ─── Main Loop ──────────────────────────────────────────────────────────────

if ! $JSON_MODE; then
    echo -e "${BOLD}${BLUE}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║    MedinovAI Platform — Verification Loop (AtlasOS OODA)   ║"
    echo "║    Max iterations: $MAX_ITERATIONS                                       ║"
    echo "║    Auto-fix: $AUTO_FIX                                            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
fi

ITERATION=0
ALL_HEALTHY=false

while [[ $ITERATION -lt $MAX_ITERATIONS ]] && ! $ALL_HEALTHY; do
    ITERATION=$((ITERATION + 1))

    if ! $JSON_MODE; then
        echo ""
        echo -e "${BLUE}── Iteration $ITERATION / $MAX_ITERATIONS ──${NC}"
    fi

    if run_verification "$ITERATION"; then
        ALL_HEALTHY=true
    elif [[ $ITERATION -lt $MAX_ITERATIONS ]]; then
        if ! $JSON_MODE; then
            log "Waiting ${WAIT_BETWEEN}s before next iteration..."
        fi
        sleep "$WAIT_BETWEEN"
    fi
done

if ! $JSON_MODE; then
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if $ALL_HEALTHY; then
        echo -e "  ${GREEN}${BOLD}STATUS: ALL SERVICES HEALTHY${NC}"
        echo -e "  Passed on iteration $ITERATION of $MAX_ITERATIONS"
    else
        echo -e "  ${RED}${BOLD}STATUS: NOT ALL SERVICES HEALTHY${NC}"
        echo -e "  Failed after $MAX_ITERATIONS iterations"
        echo ""
        echo "  Next steps:"
        echo "    1. Check failing container logs: docker logs <container>"
        echo "    2. Re-run with auto-fix: bash scripts/deploy/verify_loop.sh --auto-fix"
        echo "    3. Redeploy specific tier: bash scripts/deploy/deploy_platform.sh --tier <N>"
    fi
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
fi

$ALL_HEALTHY && exit 0 || exit 1
