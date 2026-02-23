#!/usr/bin/env bash
# ─── build-all-test2.sh ──────────────────────────────────────────────────────
# Rebuilds all 16 services that require Dockerfile.TEST2.
# Run this when: images are lost, first deploy on new machine, or after code changes.
#
# Usage:
#   bash infra/docker/build-all-test2.sh              # Build all
#   REPOS_PATH=/custom/path bash infra/docker/build-all-test2.sh  # Custom repos path
#   make test2-rebuild
#
# Env vars:
#   REPOS_PATH   Parent dir containing all medinovai-health repos (default: ~/Github)
#   REGISTRY     Docker registry prefix (default: ghcr.io/myonsite-healthcare)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPOS="${REPOS_PATH:-$HOME/Github}/medinovai-health"
REGISTRY="${REGISTRY:-ghcr.io/myonsite-healthcare}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Array: "repo-dirname" "docker-image-name"
declare -A SERVICES=(
  ["medinovai-registry"]="medinovai-registry"
  ["medinovai-data-services"]="medinovai-data-services"
  ["medinovai-real-time-stream-bus"]="medinovai-real-time-stream-bus"
  ["medinovai-healthLLM"]="medinovai-healthllm"
  ["medinovai-aifactory"]="medinovai-aifactory"
  ["medinovai-notification-center"]="medinovai-notification-center"
  ["medinovai-hipaa-gdpr-guard"]="medinovai-hipaa-gdpr-guard"
  ["medinovai-api-gateway"]="medinovai-api-gateway"
  ["medinovai-secrets-manager-bridge"]="medinovai-secrets-manager-bridge"
  ["medinovai-security-service"]="medinovai-security"
  ["medinovai-universal-sign-on"]="medinovai-universal-sign-on"
  ["medinovai-role-based-permissions"]="medinovai-role-based-permissions"
  ["medinovai-encryption-vault"]="medinovai-encryption-vault"
  ["medinovai-consent-preference-api"]="medinovai-consent-preference-api"
  ["medinovai-audit-trail-explorer"]="medinovai-audit-trail-explorer"
  ["MedinovAI-Model-Service-Orchestrator"]="medinovai-model-service-orchestrator"
)

PASS=0
FAIL=0
FAIL_LIST=()

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  TEST2 — Build All Dockerfile.TEST2 Services               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo "  Repos:    ${REPOS}"
echo "  Registry: ${REGISTRY}"
echo "  Services: ${#SERVICES[@]}"
echo ""

# Optional: build shared Python base image first
BASE_DOCKERFILE="${DEPLOY_ROOT}/infra/docker/base-images/python-service/Dockerfile"
if [[ -f "$BASE_DOCKERFILE" ]]; then
  echo "[0/${#SERVICES[@]}] Building shared Python base image..."
  if docker build \
    -f "$BASE_DOCKERFILE" \
    -t "${REGISTRY}/medinovai-python-base:3.12" \
    "$(dirname "$BASE_DOCKERFILE")" 2>&1 | tail -3; then
    echo "  ✅ Base image built: ${REGISTRY}/medinovai-python-base:3.12"
  else
    echo "  ⚠️  Base image build failed — services will fallback to python:3.12-slim"
  fi
  echo ""
fi

I=0
for REPO in "${!SERVICES[@]}"; do
  I=$((I + 1))
  IMAGE="${SERVICES[$REPO]}"
  FULL_TAG="${REGISTRY}/${IMAGE}:latest"
  DOCKERFILE="${REPOS}/${REPO}/Dockerfile.TEST2"
  CONTEXT_DIR="${REPOS}/${REPO}"

  printf "[%2d/${#SERVICES[@]}] Building %-50s" "$I" "$IMAGE"

  if [[ ! -d "$CONTEXT_DIR" ]]; then
    echo "  SKIP (repo not found: $CONTEXT_DIR)"
    continue
  fi

  if [[ ! -f "$DOCKERFILE" ]]; then
    echo "  FAIL (Dockerfile.TEST2 not found)"
    FAIL=$((FAIL + 1))
    FAIL_LIST+=("$IMAGE")
    continue
  fi

  BUILD_LOG=$(mktemp)
  if docker build \
    -f "$DOCKERFILE" \
    -t "$FULL_TAG" \
    "$CONTEXT_DIR" > "$BUILD_LOG" 2>&1; then
    echo "  ✅ OK"
    PASS=$((PASS + 1))
  else
    echo "  ❌ FAIL"
    echo "     --- last 5 build lines ---"
    tail -5 "$BUILD_LOG" | sed 's/^/     /'
    FAIL=$((FAIL + 1))
    FAIL_LIST+=("$IMAGE")
  fi
  rm -f "$BUILD_LOG"
done

echo ""
echo "─────────────────────────────────────────────────────────────"
echo "  Built:  ${PASS}"
echo "  Failed: ${FAIL}"
if [[ "${#FAIL_LIST[@]}" -gt 0 ]]; then
  echo "  Failed services:"
  for svc in "${FAIL_LIST[@]}"; do
    echo "    - $svc"
  done
  echo ""
  echo "  Debug a failed service:"
  echo "    docker build -f \${REPOS_PATH}/medinovai-health/<repo>/Dockerfile.TEST2 \\"
  echo "      -t ${REGISTRY}/<service>:latest \${REPOS_PATH}/medinovai-health/<repo>"
  exit 1
else
  echo ""
  echo "  All ${PASS} services built successfully!"
  echo "  Run: make test2-up   to deploy"
fi
