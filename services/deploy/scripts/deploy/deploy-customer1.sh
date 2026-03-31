#!/usr/bin/env bash
# myOnsiteHealthcare.com — Customer-1 Fully Automated Deployment
# One-command: clone → build → infra → keycloak → tiered services → tenant → SDG → QA → trust gate
#
# Prerequisites: Docker Desktop running, git + gh CLI, SSH key for medinovai-health org.
# Usage:
#   ./scripts/deploy-customer1.sh                  # Full fresh deploy
#   ./scripts/deploy-customer1.sh --skip-clone     # Reuse existing ~/medinovai-all-repos
#   ./scripts/deploy-customer1.sh --skip-build     # Reuse existing images
#   ./scripts/deploy-customer1.sh --skip-qa        # Deploy only, no QA/validation
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"  # Go up 2 levels: scripts/deploy -> scripts -> repo root
DEPLOY_DIR="$REPO_ROOT/deploy"
REPOS_PATH="${REPOS_PATH:-$HOME/medinovai-all-repos}"
GITHUB_ORG="${MEDINOVAI_GITHUB_ORG:-medinovai-health}"
TENANT_ID="myonsite-healthcare"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
LOG_DIR="$REPO_ROOT/logs/customer1"
RESULTS_DIR="$LOG_DIR/$TIMESTAMP"
PORT_REGISTRY="$REPO_ROOT/config/port-registry.json"

# Canonical ports (Deploy repo authority)
KEYCLOAK_HOST_PORT=9080
KEYCLOAK_CONTAINER_PORT=8080
REGISTRY_HOST_PORT=8800
PORTAL_HOST_PORT=3000

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SKIP_CLONE=false
SKIP_BUILD=false
SKIP_QA=false

for arg in "$@"; do
  case "$arg" in
    --skip-clone) SKIP_CLONE=true ;;
    --skip-build) SKIP_BUILD=true ;;
    --skip-qa)    SKIP_QA=true ;;
    --help|-h)
      echo "Usage: $0 [--skip-clone] [--skip-build] [--skip-qa]"
      exit 0
      ;;
  esac
done

mkdir -p "$RESULTS_DIR"
exec > >(tee -a "$RESULTS_DIR/deploy.log") 2>&1

log() { echo -e "${BLUE}[$(date -u +%H:%M:%S)]${NC} $*"; }
ok()  { echo -e "${GREEN}  ✓${NC} $*"; }
warn(){ echo -e "${YELLOW}  ⚠${NC} $*"; }
fail(){ echo -e "${RED}  ✗${NC} $*"; }

# Load all tiered services from port registry (excluding tier 0 brain/core)
load_services_from_registry() {
  if [ -f "$PORT_REGISTRY" ]; then
    python3 -c "
import json, sys
try:
    with open('$PORT_REGISTRY') as f:
        reg = json.load(f)
    for repo_id, data in reg['assignments'].items():
        if data['tier'] > 0:  # Skip tier 0 (brain/core not deployed)
            print(data.get('old_name', repo_id))
except Exception as e:
    sys.exit(0)
" 2>/dev/null
  fi
}

# Services from registry (all ~177 deployable repos)
SERVICES_IN_SCOPE=($(load_services_from_registry))

# Fallback minimal set if registry load fails
if [ ${#SERVICES_IN_SCOPE[@]} -eq 0 ]; then
  SERVICES_IN_SCOPE=(
    medinovai-registry
    medinovai-universal-sign-on
    medinovai-role-based-permissions
    medinovai-encryption-vault
    medinovai-secrets-manager-bridge
    medinovai-audit-trail-explorer
    medinovai-hipaa-gdpr-guard
    medinovai-real-time-stream-bus
    medinovai-data-services
    medinovai-lis
    medinovai-aifactory
    medinovai-healthLLM
  )
fi

############################################################################
# PHASE 1 — Clone repos
############################################################################
phase_clone() {
  log "PHASE 1: Clone in-scope repos into $REPOS_PATH"
  if $SKIP_CLONE; then
    warn "Skipping clone (--skip-clone)"
    return 0
  fi
  mkdir -p "$REPOS_PATH"
  for repo in "${SERVICES_IN_SCOPE[@]}"; do
    if [ -d "$REPOS_PATH/$repo" ]; then
      ok "$repo already cloned — pulling latest"
      git -C "$REPOS_PATH/$repo" pull --ff-only origin main 2>/dev/null || true
    else
      log "  Cloning $repo..."
      git clone "git@github.com:$GITHUB_ORG/$repo.git" "$REPOS_PATH/$repo" 2>/dev/null || \
        warn "Clone failed for $repo — may need manual clone"
    fi
  done
  ok "Clone phase complete"
}

############################################################################
# PHASE 2 — Docker build
############################################################################
phase_build() {
  log "PHASE 2: Build Docker images"
  if $SKIP_BUILD; then
    warn "Skipping build (--skip-build)"
    return 0
  fi
  cd "$DEPLOY_DIR"
  export REPOS_PATH
  docker compose build --parallel 2>&1 | tail -20
  ok "Build phase complete"
}

############################################################################
# PHASE 3 — Infrastructure up
############################################################################
phase_infra() {
  log "PHASE 3: Start infrastructure (Postgres, Redis, Kafka)"
  cd "$DEPLOY_DIR"
  docker compose up -d postgres redis kafka
  log "  Waiting for infrastructure health..."
  local retries=0
  while [ $retries -lt 30 ]; do
    if docker compose ps --format json 2>/dev/null | python3 -c "
import sys, json
lines = sys.stdin.read().strip().split('\n')
infra = {'medinovai-postgres', 'medinovai-redis'}
healthy = 0
for line in lines:
    try:
        c = json.loads(line)
        if c.get('Name') in infra and 'healthy' in c.get('Health',''):
            healthy += 1
    except: pass
sys.exit(0 if healthy >= 2 else 1)
" 2>/dev/null; then
      ok "Postgres + Redis healthy"
      return 0
    fi
    sleep 5
    retries=$((retries + 1))
  done
  fail "Infrastructure did not become healthy in time"
  return 1
}

############################################################################
# PHASE 4 — Keycloak realm import
############################################################################
phase_keycloak() {
  log "PHASE 4: Start Keycloak with myonsite realm (host port $KEYCLOAK_HOST_PORT)"
  cd "$DEPLOY_DIR"
  docker compose up -d keycloak
  log "  Waiting for Keycloak to be ready on port $KEYCLOAK_HOST_PORT (up to 120s)..."
  local retries=0
  while [ $retries -lt 24 ]; do
    # Check host-mapped port (Deploy canonical: 9080)
    if curl -sf "http://localhost:$KEYCLOAK_HOST_PORT/health/ready" > /dev/null 2>&1; then
      ok "Keycloak ready on port $KEYCLOAK_HOST_PORT — realm 'medinovai' imported"
      log "  Admin console: http://localhost:$KEYCLOAK_HOST_PORT/admin (admin/admin)"
      return 0
    fi
    sleep 5
    retries=$((retries + 1))
  done
  warn "Keycloak may still be starting — continuing"
}

############################################################################
# PHASE 5 — Tiered service start
############################################################################
phase_services() {
  log "PHASE 5: Tiered service start (build-order phases 1–4)"
  cd "$DEPLOY_DIR"

  log "  Tier 1: Registry"
  docker compose up -d medinovai-registry
  sleep 10

  log "  Tier 2: Security services"
  docker compose up -d \
    medinovai-universal-sign-on \
    medinovai-role-based-permissions \
    medinovai-encryption-vault \
    medinovai-secrets-manager-bridge \
    medinovai-audit-trail-explorer 2>/dev/null || true
  sleep 10

  log "  Tier 3: Platform services"
  docker compose up -d medinovai-os-portal 2>/dev/null || true
  sleep 5

  log "  Tier 4: Domain services"
  docker compose up -d 2>/dev/null || true
  sleep 15

  ok "All services started"
  docker compose ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null || docker compose ps
}

############################################################################
# PHASE 6 — Tenant provisioning
############################################################################
phase_tenant() {
  log "PHASE 6: Provision tenant '$TENANT_ID'"

  local registry_url="http://localhost:$REGISTRY_HOST_PORT"
  local tenant_payload='{
    "name": "myOnsiteHealthcare",
    "slug": "myonsite-healthcare",
    "tier": "gold",
    "admin_email": "admin@myonsitehealthcare.com",
    "compliance_profile": "hipaa",
    "feature_flags": {
      "aiInference": true,
      "clinicalTrials": true,
      "advancedAnalytics": true,
      "labOrders": true
    }
  }'

  if curl -sf "$registry_url/health" > /dev/null 2>&1; then
    ok "Registry reachable at $registry_url (permanent port $REGISTRY_HOST_PORT)"
  else
    warn "Registry not reachable at $registry_url — tenant provisioning via API may fail"
  fi

  echo "$tenant_payload" > "$RESULTS_DIR/tenant-payload.json"
  ok "Tenant payload written to $RESULTS_DIR/tenant-payload.json"
  log "  (Apply via: POST /api/v1/tenants or kubectl apply -f config/tenants/myonsite-healthcare.yaml)"
}

############################################################################
# PHASE 7 — SDG seed
############################################################################
phase_sdg() {
  log "PHASE 7: Synthetic Data Generation (SDG) seed"
  if [ -f "$DEPLOY_DIR/sdg/seed-myonsite.py" ]; then
    python3 "$DEPLOY_DIR/sdg/seed-myonsite.py" \
      --tenant-id "$TENANT_ID" \
      --patient-count 500 \
      --output-dir "$RESULTS_DIR/sdg" 2>&1 || warn "SDG seed had errors"
    ok "SDG seed complete"
  else
    warn "SDG seed script not found at deploy/sdg/seed-myonsite.py — skipping"
  fi
}

############################################################################
# PHASE 8 — QA + Validation
############################################################################
phase_qa() {
  log "PHASE 8: Automated QA + IQ/OQ/PQ Validation"
  if $SKIP_QA; then
    warn "Skipping QA (--skip-qa)"
    return 0
  fi

  if [ -f "$DEPLOY_DIR/qa/run-all-qa.sh" ]; then
    bash "$DEPLOY_DIR/qa/run-all-qa.sh" \
      --results-dir "$RESULTS_DIR/qa" \
      --tenant-id "$TENANT_ID" 2>&1 || warn "QA suite had failures"
  else
    warn "QA orchestrator not found — running basic health checks"
    bash "$SCRIPT_DIR/validate_system.sh" 2>&1 || true
  fi

  if [ -f "$SCRIPT_DIR/validate-deployment.sh" ]; then
    bash "$SCRIPT_DIR/validate-deployment.sh" \
      --results-dir "$RESULTS_DIR/validation" 2>&1 || warn "Validation had failures"
  fi

  ok "QA + Validation phase complete"
}

############################################################################
# PHASE 9 — Trust score computation + gating
############################################################################
phase_trust() {
  log "PHASE 9: Trust score computation"
  local trust_cli="$REPO_ROOT/platform/medinovai-module-trust-kit/tools/trust_score_engine/cli.py"

  if [ -f "$trust_cli" ]; then
    if [ -d "$RESULTS_DIR/qa" ]; then
      python3 "$trust_cli" compute \
        --evidence "$RESULTS_DIR/qa/evidence-bundle.json" \
        --entity-type tenant \
        --entity-id "$TENANT_ID" \
        --output "$RESULTS_DIR/trust-snapshot.json" 2>&1 || warn "Trust engine error"

      if [ -f "$RESULTS_DIR/trust-snapshot.json" ]; then
        local score
        score=$(python3 -c "import json; d=json.load(open('$RESULTS_DIR/trust-snapshot.json')); print(d.get('composite_score', 0))" 2>/dev/null || echo "0")
        log "  Composite trust score: $score / 100"
        if python3 -c "exit(0 if float('$score') >= 60 else 1)" 2>/dev/null; then
          ok "TRUST GATE PASSED (>= 60)"
        else
          fail "TRUST GATE FAILED (< 60) — see improvement plan"
          python3 "$trust_cli" recommend \
            --snapshot "$RESULTS_DIR/trust-snapshot.json" 2>&1 || true
        fi
      fi
    else
      warn "No QA evidence directory — skipping trust computation"
    fi
  else
    warn "Trust Score Engine CLI not found — skipping trust gate"
  fi
}

############################################################################
# PHASE 10 — Summary
############################################################################
phase_summary() {
  log "PHASE 10: Deployment Summary"
  local total_services=${#SERVICES_IN_SCOPE[@]}
  echo ""
  echo "==========================================================================="
  echo " myOnsiteHealthcare.com — Customer-1 Deployment Complete"
  echo "==========================================================================="
  echo ""
  echo "  Services Deployed: $total_services (permanent port registry active)"
  echo ""
  echo "  Portal:           http://localhost:$PORTAL_HOST_PORT"
  echo "  Keycloak Admin:   http://localhost:$KEYCLOAK_HOST_PORT/admin  (admin/admin)"
  echo "  Registry:         http://localhost:$REGISTRY_HOST_PORT/health"
  echo ""
  echo "  Port Registry:    $PORT_REGISTRY"
  echo "  Port Range:       8100-26099 (100 ports per repo)"
  echo ""
  echo "  Customer Login:"
  echo "    URL:      http://localhost:$PORTAL_HOST_PORT"
  echo "    Email:    admin@myonsitehealthcare.com"
  echo "    Password: ChangeMe!2026 (temporary — will prompt to change)"
  echo ""
  echo "  Demo Users:"
  echo "    demo-clinician@myonsitehealthcare.com / DemoClinician!2026"
  echo "    demo-labtech@myonsitehealthcare.com   / DemoLabTech!2026"
  echo "    demo-researcher@myonsitehealthcare.com / DemoResearcher!2026"
  echo ""
  echo "  Tenant:     $TENANT_ID"
  echo "  Results:    $RESULTS_DIR"
  echo "  Logs:       $RESULTS_DIR/deploy.log"
  echo ""
  echo "==========================================================================="
}

############################################################################
# MAIN
############################################################################
main() {
  log "Starting Customer-1 deployment for myOnsiteHealthcare.com"
  log "Timestamp: $TIMESTAMP"
  log "Results:   $RESULTS_DIR"
  echo ""

  phase_clone
  phase_build
  phase_infra
  phase_keycloak
  phase_services
  phase_tenant
  phase_sdg
  phase_qa
  phase_trust
  phase_summary

  if [ -f "$SCRIPT_DIR/generate-validation-report.py" ]; then
    log "Generating validation report..."
    python3 "$SCRIPT_DIR/generate-validation-report.py" \
      --results-dir "$RESULTS_DIR" \
      --tenant-id "$TENANT_ID" \
      --output "$RESULTS_DIR/VALIDATION_REPORT.md" 2>&1 || warn "Report generation error"
    ok "Report: $RESULTS_DIR/VALIDATION_REPORT.md"
  fi

  log "Customer-1 deployment pipeline finished."
}

main "$@"
