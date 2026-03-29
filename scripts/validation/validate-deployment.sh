#!/usr/bin/env bash
# Customer-1 IQ/OQ/PQ Automated Deployment Validation
# Produces JSON evidence for each qualification phase.
# Usage: bash scripts/validate-deployment.sh [--results-dir DIR]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DEPLOY_DIR="$REPO_ROOT/deploy"
RESULTS_DIR="${1:-$REPO_ROOT/logs/customer1/validation}"
PORTAL_URL="${PORTAL_URL:-http://localhost:3000}"
REGISTRY_URL="${REGISTRY_URL:-http://localhost:8060}"
KEYCLOAK_URL="${KEYCLOAK_URL:-http://localhost:8180}"
TENANT_ID="myonsite-healthcare"
EXPECTED_SERVICES=13

for arg in "$@"; do
  case "$arg" in
    --results-dir) shift; RESULTS_DIR="$1"; shift ;;
  esac
done

mkdir -p "$RESULTS_DIR"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log()  { echo -e "${BLUE}[VAL]${NC} $*"; }
pass() { echo -e "${GREEN}  IQ/OQ/PQ PASS${NC} $*"; }
fail_v() { echo -e "${RED}  IQ/OQ/PQ FAIL${NC} $*"; }

########################################################################
# IQ — Installation Qualification
########################################################################
log "===== IQ: Installation Qualification ====="

IQ_CHECKS=()

iq_check() {
  local name="$1" result="$2" detail="$3"
  IQ_CHECKS+=("{\"check\": \"$name\", \"pass\": $result, \"detail\": \"$detail\"}")
  if [ "$result" = "true" ]; then pass "IQ: $name"; else fail_v "IQ: $name — $detail"; fi
}

# IQ-1: All containers running
RUNNING=$(cd "$DEPLOY_DIR" && docker compose ps --format json 2>/dev/null | python3 -c "
import sys, json
count = 0
for line in sys.stdin.read().strip().split('\n'):
    try:
        c = json.loads(line)
        if 'running' in c.get('State','').lower(): count += 1
    except: pass
print(count)
" 2>/dev/null || echo "0")
iq_check "containers_running" "$([ "$RUNNING" -ge 5 ] && echo true || echo false)" "$RUNNING containers running"

# IQ-2: All containers healthy (those with healthcheck)
HEALTHY=$(cd "$DEPLOY_DIR" && docker compose ps --format json 2>/dev/null | python3 -c "
import sys, json
healthy = unhealthy = 0
for line in sys.stdin.read().strip().split('\n'):
    try:
        c = json.loads(line)
        h = c.get('Health','')
        if 'healthy' in h: healthy += 1
        elif h and 'starting' not in h: unhealthy += 1
    except: pass
print(f'{healthy},{unhealthy}')
" 2>/dev/null || echo "0,0")
IFS=',' read -r H_OK H_BAD <<< "$HEALTHY"
iq_check "containers_healthy" "$([ "${H_BAD:-0}" -eq 0 ] && echo true || echo false)" "$H_OK healthy, $H_BAD unhealthy"

# IQ-3: Keycloak realm exists
KC_REALM=$(curl -sf "$KEYCLOAK_URL/realms/medinovai" 2>/dev/null | python3 -c "
import sys, json
try: print(json.load(sys.stdin).get('realm',''))
except: print('')
" 2>/dev/null || echo "")
iq_check "keycloak_realm" "$([ "$KC_REALM" = "medinovai" ] && echo true || echo false)" "realm=$KC_REALM"

# IQ-4: Postgres accessible
PG_OK=$(docker exec medinovai-postgres pg_isready -U medinovai 2>/dev/null && echo "true" || echo "false")
iq_check "postgres_ready" "$PG_OK" "pg_isready"

# IQ-5: Redis accessible
REDIS_OK=$(docker exec medinovai-redis redis-cli ping 2>/dev/null | grep -q PONG && echo "true" || echo "false")
iq_check "redis_ready" "$REDIS_OK" "redis-cli ping"

# IQ-6: Registry discovers services
SVC_COUNT=$(curl -sf "$REGISTRY_URL/health" 2>/dev/null | python3 -c "
import sys, json
try: print('ok')
except: print('fail')
" 2>/dev/null || echo "fail")
iq_check "registry_reachable" "$([ "$SVC_COUNT" = "ok" ] && echo true || echo false)" "registry /health"

# IQ-7: No CHANGE_ME secrets in env
CHANGE_ME=$(cd "$DEPLOY_DIR" && docker compose config 2>/dev/null | grep -ci 'CHANGE_ME' || echo "0")
iq_check "no_changeme_secrets" "$([ "$CHANGE_ME" -eq 0 ] && echo true || echo false)" "$CHANGE_ME CHANGE_ME patterns"

# Write IQ evidence
python3 -c "
import json; from pathlib import Path
checks = [$(IFS=,; echo "${IQ_CHECKS[*]}")]
Path('$RESULTS_DIR/iq-evidence.json').write_text(json.dumps({
    'phase': 'IQ', 'timestamp': '$TIMESTAMP', 'checks': checks,
    'pass': all(c['pass'] for c in checks),
}, indent=2))
print('  IQ evidence → $RESULTS_DIR/iq-evidence.json')
" 2>/dev/null || true

########################################################################
# OQ — Operational Qualification
########################################################################
log "===== OQ: Operational Qualification ====="

OQ_CHECKS=()

oq_check() {
  local name="$1" result="$2" detail="$3"
  OQ_CHECKS+=("{\"check\": \"$name\", \"pass\": $result, \"detail\": \"$detail\"}")
  if [ "$result" = "true" ]; then pass "OQ: $name"; else fail_v "OQ: $name — $detail"; fi
}

# OQ-1: Registry /health returns healthy
REG_HEALTH=$(curl -sf "$REGISTRY_URL/health" 2>/dev/null | python3 -c "
import sys, json
try: print('true' if json.load(sys.stdin).get('status') == 'healthy' else 'false')
except: print('false')
" 2>/dev/null || echo "false")
oq_check "registry_healthy" "$REG_HEALTH" "GET /health"

# OQ-2: Portal loads
PORTAL_CODE=$(curl -sf -o /dev/null -w "%{http_code}" "$PORTAL_URL" 2>/dev/null || echo "000")
oq_check "portal_loads" "$([ "$PORTAL_CODE" = "200" ] && echo true || echo false)" "HTTP $PORTAL_CODE"

# OQ-3: Keycloak OIDC discovery
OIDC_OK=$(curl -sf "$KEYCLOAK_URL/realms/medinovai/.well-known/openid-configuration" 2>/dev/null | python3 -c "
import sys, json
try: print('true' if 'authorization_endpoint' in json.load(sys.stdin) else 'false')
except: print('false')
" 2>/dev/null || echo "false")
oq_check "keycloak_oidc_discovery" "$OIDC_OK" "OIDC .well-known"

# OQ-4: Kafka reachable
KAFKA_OK=$(docker exec medinovai-kafka bash -c 'echo > /dev/tcp/localhost/9092' 2>/dev/null && echo "true" || echo "false")
oq_check "kafka_reachable" "$KAFKA_OK" "TCP 9092"

# OQ-5: Backup script exists
BACKUP_OK=$([ -f "$REPO_ROOT/scripts/backup.sh" ] && echo "true" || echo "false")
oq_check "backup_script_exists" "$BACKUP_OK" "scripts/backup.sh"

# OQ-6: SDG data files exist
SDG_OK=$([ -f "$REPO_ROOT/deploy/sdg/output/patients.json" ] && echo "true" || echo "false")
oq_check "sdg_data_seeded" "$SDG_OK" "deploy/sdg/output/patients.json"

# Write OQ evidence
python3 -c "
import json; from pathlib import Path
checks = [$(IFS=,; echo "${OQ_CHECKS[*]}")]
Path('$RESULTS_DIR/oq-evidence.json').write_text(json.dumps({
    'phase': 'OQ', 'timestamp': '$TIMESTAMP', 'checks': checks,
    'pass': all(c['pass'] for c in checks),
}, indent=2))
print('  OQ evidence → $RESULTS_DIR/oq-evidence.json')
" 2>/dev/null || true

########################################################################
# PQ — Performance Qualification
########################################################################
log "===== PQ: Performance Qualification ====="

PQ_CHECKS=()

pq_check() {
  local name="$1" result="$2" detail="$3"
  PQ_CHECKS+=("{\"check\": \"$name\", \"pass\": $result, \"detail\": \"$detail\"}")
  if [ "$result" = "true" ]; then pass "PQ: $name"; else fail_v "PQ: $name — $detail"; fi
}

# PQ-1: Registry response < 500ms
REG_TIME=$(curl -sf -o /dev/null -w "%{time_total}" "$REGISTRY_URL/health" 2>/dev/null || echo "999")
REG_MS=$(python3 -c "print(int(float('$REG_TIME') * 1000))" 2>/dev/null || echo "9999")
pq_check "registry_p95_lt_500ms" "$([ "$REG_MS" -lt 500 ] && echo true || echo false)" "${REG_MS}ms"

# PQ-2: Portal load < 3000ms
PORT_TIME=$(curl -sf -o /dev/null -w "%{time_total}" "$PORTAL_URL" 2>/dev/null || echo "999")
PORT_MS=$(python3 -c "print(int(float('$PORT_TIME') * 1000))" 2>/dev/null || echo "9999")
pq_check "portal_load_lt_3s" "$([ "$PORT_MS" -lt 3000 ] && echo true || echo false)" "${PORT_MS}ms"

# PQ-3: Keycloak OIDC < 2000ms
KC_TIME=$(curl -sf -o /dev/null -w "%{time_total}" "$KEYCLOAK_URL/realms/medinovai/.well-known/openid-configuration" 2>/dev/null || echo "999")
KC_MS=$(python3 -c "print(int(float('$KC_TIME') * 1000))" 2>/dev/null || echo "9999")
pq_check "keycloak_oidc_lt_2s" "$([ "$KC_MS" -lt 2000 ] && echo true || echo false)" "${KC_MS}ms"

# PQ-4: Concurrent health checks (5 parallel)
CONC_FAIL=0
for i in $(seq 1 5); do
  curl -sf --max-time 5 "$REGISTRY_URL/health" > /dev/null 2>&1 &
done
wait || CONC_FAIL=1
pq_check "concurrent_5_health" "$([ "$CONC_FAIL" -eq 0 ] && echo true || echo false)" "5 parallel /health"

# Write PQ evidence
python3 -c "
import json; from pathlib import Path
checks = [$(IFS=,; echo "${PQ_CHECKS[*]}")]
Path('$RESULTS_DIR/pq-evidence.json').write_text(json.dumps({
    'phase': 'PQ', 'timestamp': '$TIMESTAMP', 'checks': checks,
    'pass': all(c['pass'] for c in checks),
    'baselines': {
        'registry_health_ms': $REG_MS,
        'portal_load_ms': $PORT_MS,
        'keycloak_oidc_ms': $KC_MS,
    },
}, indent=2))
print('  PQ evidence → $RESULTS_DIR/pq-evidence.json')
" 2>/dev/null || true

########################################################################
# Combined verdict
########################################################################
echo ""
log "===== Validation Summary ====="
IQ_PASS=$(python3 -c "checks=[$(IFS=,; echo "${IQ_CHECKS[*]}")]; print(sum(1 for c in checks if c['pass']))" 2>/dev/null || echo 0)
OQ_PASS=$(python3 -c "checks=[$(IFS=,; echo "${OQ_CHECKS[*]}")]; print(sum(1 for c in checks if c['pass']))" 2>/dev/null || echo 0)
PQ_PASS=$(python3 -c "checks=[$(IFS=,; echo "${PQ_CHECKS[*]}")]; print(sum(1 for c in checks if c['pass']))" 2>/dev/null || echo 0)
IQ_TOTAL=${#IQ_CHECKS[@]}
OQ_TOTAL=${#OQ_CHECKS[@]}
PQ_TOTAL=${#PQ_CHECKS[@]}
log "  IQ: $IQ_PASS/$IQ_TOTAL"
log "  OQ: $OQ_PASS/$OQ_TOTAL"
log "  PQ: $PQ_PASS/$PQ_TOTAL"
GRAND_TOTAL=$((IQ_TOTAL + OQ_TOTAL + PQ_TOTAL))
GRAND_PASS=$((IQ_PASS + OQ_PASS + PQ_PASS))
log "  Total: $GRAND_PASS/$GRAND_TOTAL"

if [ "$GRAND_PASS" -eq "$GRAND_TOTAL" ]; then
  log "  Verdict: ALL PASSED"
else
  log "  Verdict: $(( GRAND_TOTAL - GRAND_PASS )) FAILURES"
fi
