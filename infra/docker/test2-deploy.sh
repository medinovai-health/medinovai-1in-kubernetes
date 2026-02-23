#!/usr/bin/env bash
# ─── test2-deploy.sh ─────────────────────────────────────────────────────────
# Single-command full TEST2 deployment. No Cursor required.
#
# Usage:
#   bash infra/docker/test2-deploy.sh           # Full deploy
#   bash infra/docker/test2-deploy.sh --skip-preflight  # Skip pre-flight checks
#   bash infra/docker/test2-deploy.sh --skip-smoke       # Skip smoke tests
#   make test2-up
#
# This script handles:
#   1. Pre-flight validation
#   2. TEST2-network creation
#   3. Tiered service startup (infra → monitoring → kafka → security → all)
#   4. Health wait between tiers
#   5. Post-deploy smoke tests
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
COMPOSE_FILE="${SCRIPT_DIR}/docker-compose.TEST2-full.yml"
ENV_FILE="${SCRIPT_DIR}/test2.env"

SKIP_PREFLIGHT=false
SKIP_SMOKE=false
for arg in "$@"; do
  [[ "$arg" == "--skip-preflight" ]] && SKIP_PREFLIGHT=true
  [[ "$arg" == "--skip-smoke" ]] && SKIP_SMOKE=true
done

# Compose shorthand
COMPOSE="docker compose -p test2 --env-file ${ENV_FILE} -f ${COMPOSE_FILE}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }
step() { echo ""; echo "═══════════════════════════════════════════════════════════"; echo "[$1/7] $2"; echo "═══════════════════════════════════════════════════════════"; }

cd "$DEPLOY_ROOT"

step 1 "Pre-flight checks"
if [[ "$SKIP_PREFLIGHT" == "true" ]]; then
  log "Skipping pre-flight (--skip-preflight)"
else
  python3 "${SCRIPT_DIR}/preflight-check.py" --env-file "$ENV_FILE"
fi

step 2 "Ensuring TEST2-network exists"
if docker network inspect TEST2-network >/dev/null 2>&1; then
  log "TEST2-network already exists — reusing"
else
  log "Creating TEST2-network..."
  docker network create TEST2-network
  log "TEST2-network created"
fi

step 3 "Starting Infrastructure Tier (Tier 0)"
log "Bringing up databases, caches, messaging, monitoring..."
$COMPOSE up -d \
  postgres-primary postgres-clinical \
  redis-cache \
  mongodb \
  rabbitmq \
  elasticsearch \
  vault \
  zookeeper \
  prometheus \
  grafana loki jaeger \
  mailhog

log "Waiting for infrastructure to be healthy (timeout: 120s)..."
python3 "${SCRIPT_DIR}/health-wait.py" --filter infra --timeout 120 || {
  log "Infrastructure not fully healthy — running diagnostics..."
  bash "${SCRIPT_DIR}/test2-diagnose.sh" || true
  echo ""
  echo "FAIL: Infrastructure tier not healthy after 120s"
  echo "FIX:  Check logs above. Common issues:"
  echo "       - Elasticsearch: needs more RAM (increase Docker memory to 12GB+)"
  echo "       - Kafka: make test2-kafka-reset (if InconsistentClusterIdException)"
  exit 1
}

step 4 "Starting Kafka (after Zookeeper is healthy)"
log "Starting Kafka..."
$COMPOSE up -d kafka

log "Waiting for Kafka to become healthy (timeout: 90s)..."
KAFKA_WAIT=0
while [[ $KAFKA_WAIT -lt 90 ]]; do
  STATUS=$(docker inspect TEST2-kafka --format '{{.State.Health.Status}}' 2>/dev/null || echo "starting")
  if [[ "$STATUS" == "healthy" ]]; then
    log "Kafka is healthy!"
    break
  fi
  if [[ "$STATUS" == "unhealthy" ]]; then
    log "Kafka is unhealthy. Check for InconsistentClusterIdException:"
    docker logs TEST2-kafka --tail 20 2>&1 || true
    echo ""
    echo "FIX: make test2-kafka-reset"
    exit 1
  fi
  log "Kafka status: $STATUS (waited ${KAFKA_WAIT}s)..."
  sleep 10
  KAFKA_WAIT=$((KAFKA_WAIT + 10))
done

step 5 "Starting Keycloak (after Postgres is healthy)"
log "Starting Keycloak..."
$COMPOSE up -d keycloak

step 6 "Starting all remaining services"
log "Starting all services (security, platform, AI/ML, apps, UI)..."
$COMPOSE up -d

log "Waiting for all services to be healthy (timeout: 600s)..."
log "This may take 5-10 minutes on first deploy..."
python3 "${SCRIPT_DIR}/health-wait.py" --timeout 600 || {
  log "Some services not healthy after 600s. Running diagnostics..."
  bash "${SCRIPT_DIR}/test2-diagnose.sh" || true
  echo ""
  echo "WARNING: Not all services are healthy, but continuing..."
  echo "         Run: make test2-diagnose   for details"
}

step 7 "Post-deploy smoke tests"
if [[ "$SKIP_SMOKE" == "true" ]]; then
  log "Skipping smoke tests (--skip-smoke)"
else
  log "Running smoke tests against live services..."
  python3 "${SCRIPT_DIR}/test2-smoke-test.py" || {
    log "Some smoke tests failed — check above for details"
    log "Run: make test2-diagnose   for root cause analysis"
  }
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "TEST2 DEPLOYMENT COMPLETE"
echo "═══════════════════════════════════════════════════════════"
HEALTHY=$(docker ps --filter "name=TEST2" --format '{{.Status}}' | grep -c "(healthy)" || true)
TOTAL=$(docker ps --filter "name=TEST2" -q | wc -l | tr -d ' ')
echo "  Services running: ${TOTAL}"
echo "  Services healthy: ${HEALTHY}"
echo ""
echo "  KEY SERVICE URLS:"
echo "    API Gateway:    http://localhost:16676"
echo "    MedinovAI OS:   http://localhost:16731"
echo "    Keycloak:       http://localhost:16620/admin"
echo "    Grafana:        http://localhost:16631"
echo "    Prometheus:     http://localhost:16630"
echo "    Kibana/ES:      http://localhost:16616"
echo "    Vault:          http://localhost:16619"
echo "    Jaeger:         http://localhost:16634"
echo "    RabbitMQ Mgmt:  http://localhost:16618"
echo "    MailHog:        http://localhost:16623"
echo ""
echo "  OPERATIONS:"
echo "    Status:    make test2-status"
echo "    Logs:      make test2-logs"
echo "    Diagnose:  make test2-diagnose"
echo "    Smoke:     make test2-smoke"
echo "    Tear down: make test2-down"
echo "═══════════════════════════════════════════════════════════"
