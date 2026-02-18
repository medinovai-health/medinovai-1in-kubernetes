#!/usr/bin/env bash
# ─── instantiate-docker.sh ─────────────────────────────────────────────────────
# Full greenfield Docker deployment on local machine.
# Stands up MedinovAI stack with restart/crash resilience.
#
# Usage:
#   bash scripts/bootstrap/instantiate-docker.sh
#   bash scripts/bootstrap/instantiate-docker.sh --dry-run
#   bash scripts/bootstrap/instantiate-docker.sh --resume
#
# Prerequisites: Docker Desktop 25+
# Backup: ~/medinovai-backups/medinovai-Deploy/
# See: docs/DOCKER_GREENFIELD_DEPLOYMENT.md
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
COMPOSE_FILE="$REPO_ROOT/infra/docker/docker-compose.dev.yml"
BACKUP_BASE="$HOME/medinovai-backups/medinovai-Deploy"
DEPLOY_HOME="$HOME/.medinovai-deploy"
CHECKPOINT_DIR="$DEPLOY_HOME/checkpoints-docker"
LOG_DIR="$DEPLOY_HOME/logs"
TIMESTAMP=$(date -u +%Y%m%dT%H%M%SZ)
LOG_FILE="$LOG_DIR/instantiate-docker-$TIMESTAMP.log"

DRY_RUN=false
RESUME=false
TOTAL_STEPS=8

mkdir -p "$CHECKPOINT_DIR" "$LOG_DIR"

log() {
    local msg="[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1"
    echo "$msg" | tee -a "$LOG_FILE"
}

checkpoint_exists() {
    [ -f "$CHECKPOINT_DIR/step_$1.done" ]
}

mark_checkpoint() {
    local step="$1"
    local description="$2"
    echo "{\"step\": $step, \"description\": \"$description\", \"completed_at\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" > "$CHECKPOINT_DIR/step_$step.done"
    log "  ✓ Checkpoint: step $step — $description"
}

run_step() {
    local step_num="$1"
    local description="$2"
    local func="$3"

    if $RESUME && checkpoint_exists "$step_num"; then
        log "  ⏭ Step $step_num/$TOTAL_STEPS: $description — SKIPPED (checkpoint exists)"
        return 0
    fi

    log ""
    log "━━━ Step $step_num/$TOTAL_STEPS: $description ━━━"

    if $DRY_RUN; then
        log "  [DRY RUN] Would execute: $description"
        return 0
    fi

    if $func; then
        mark_checkpoint "$step_num" "$description"
    else
        log "  ✗ Step $step_num FAILED: $description"
        log "  Re-run with --resume to retry from this step."
        exit 1
    fi
}

# ─── Step functions ───────────────────────────────────────────────────────────

step_01_prerequisites() {
    log "  Checking Docker..."
    command -v docker &>/dev/null || { log "  Docker not found"; return 1; }
    docker info &>/dev/null || { log "  Docker daemon not running"; return 1; }
    log "  ✓ Docker OK"
    return 0
}

step_02_backup_dir() {
    log "  Ensuring backup directory exists..."
    mkdir -p "$BACKUP_BASE"/{db,volumes,config}
    log "  ✓ $BACKUP_BASE"
    return 0
}

step_03_compose_validate() {
    log "  Validating docker-compose..."
    cd "$REPO_ROOT"
    docker compose -f "$COMPOSE_FILE" config --quiet 2>/dev/null || { log "  Invalid compose file"; return 1; }
    log "  ✓ Compose valid"
    return 0
}

step_04_backup_before() {
    log "  Running backup before deploy (if postgres running)..."
    bash "$REPO_ROOT/scripts/backup.sh" 2>/dev/null || log "  (Backup skipped — no existing stack)"
    return 0
}

step_05_compose_up() {
    log "  Starting Docker stack..."
    cd "$REPO_ROOT"
    docker compose -f "$COMPOSE_FILE" up -d
    log "  ✓ Stack started"
    return 0
}

step_06_wait_healthy() {
    log "  Waiting for services to become healthy..."
    local max=90
    local n=0
    while [ $n -lt $max ]; do
        if docker exec medinovai-postgres pg_isready -U medinovai -d medinovai 2>/dev/null && \
           docker exec medinovai-redis redis-cli -a localdev ping 2>/dev/null | grep -q PONG; then
            log "  ✓ Postgres and Redis healthy"
            return 0
        fi
        sleep 2
        n=$((n + 2))
    done
    log "  ⚠ Timeout waiting for health (services may still be starting)"
    return 0
}

step_07_smoke_check() {
    log "  Smoke checks..."
    curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/-/healthy 2>/dev/null | grep -q 200 && log "  ✓ Prometheus" || log "  ⚠ Prometheus not ready"
    curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health 2>/dev/null | grep -q 200 && log "  ✓ Grafana" || log "  ⚠ Grafana not ready"
    return 0
}

step_08_final_backup() {
    log "  Creating post-deploy backup..."
    bash "$REPO_ROOT/scripts/backup.sh" 2>/dev/null || true
    return 0
}

# ─── Parse args ───────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)  DRY_RUN=true; shift ;;
        --resume)   RESUME=true; shift ;;
        *)          echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ─── Main ────────────────────────────────────────────────────────────────────
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  MedinovAI — Docker Greenfield Instantiation               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
log "Log: $LOG_FILE"
echo ""

if ! $DRY_RUN; then
    echo "This will start the full Docker stack (postgres, redis, prometheus, grafana, mailpit, localstack)."
    echo "Backups: $BACKUP_BASE"
    echo ""
    read -r -p "Proceed? [y/N] " confirm
    case "$confirm" in
        [yY][eE][sS]|[yY]) ;;
        *) echo "Aborted."; exit 0 ;;
    esac
fi

START_TIME=$(date +%s)

run_step 1 "Prerequisites (Docker)"           step_01_prerequisites
run_step 2 "Backup directory"                 step_02_backup_dir
run_step 3 "Compose validation"              step_03_compose_validate
run_step 4 "Pre-deploy backup"               step_04_backup_before
run_step 5 "Docker compose up"               step_05_compose_up
run_step 6 "Wait for healthy"                step_06_wait_healthy
run_step 7 "Smoke checks"                    step_07_smoke_check
run_step 8 "Post-deploy backup"             step_08_final_backup

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✓ Docker instantiation complete!"
echo "║"
echo "║  Postgres:  localhost:5432   Redis:    localhost:6379"
echo "║  Grafana:   http://localhost:3000"
echo "║  Prometheus: http://localhost:9090   Mailpit: http://localhost:8025"
echo "║"
echo "║  Backup:    $BACKUP_BASE"
echo "║  Log:       $LOG_FILE"
echo "║"
echo "║  Restart-safe: All data in named volumes. Survives host reboot."
echo "╚══════════════════════════════════════════════════════════════╝"
