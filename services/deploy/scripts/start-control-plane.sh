#!/usr/bin/env bash
# =============================================================================
# MedinovAI Control Plane Startup Script
# Starts the complete self-assembly control plane in the correct order:
#   1. Registry + Redis (Tier 0 foundation)
#   2. 11 Provisioner microservices
#   3. Self-Healing Engine
#   4. Orchestrator
#
# Usage:
#   ./scripts/start-control-plane.sh [--build] [--detach]
#
# Prerequisites:
#   - Docker and docker-compose installed
#   - .env file with required secrets (ENCRYPTION_KEY, POSTGRES_ADMIN_PASSWORD, etc.)
#   - medinovai-internal Docker network created
#
# See: medinovai-Developer/UNIVERSAL_SELF_ASSEMBLY_ARCHITECTURE.md
# =============================================================================
set -euo pipefail

E_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
E_DEPLOY_ROOT="$(dirname "$E_SCRIPT_DIR")"
E_BUILD_FLAG=""
E_DETACH_FLAG="-d"

# Parse arguments
for arg in "$@"; do
    case $arg in
        --build) E_BUILD_FLAG="--build" ;;
        --no-detach) E_DETACH_FLAG="" ;;
        --help) echo "Usage: $0 [--build] [--no-detach]"; exit 0 ;;
    esac
done

echo "============================================="
echo "  MedinovAI Control Plane — Self-Assembly"
echo "  $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
echo "============================================="

# Step 0: Ensure network exists
echo ""
echo "[Phase 0] Creating Docker network..."
docker network create medinovai-internal 2>/dev/null || echo "  Network already exists"

# Step 1: Start Registry + Redis
echo ""
echo "[Phase 1] Starting Registry + Redis (Tier 0)..."
docker-compose -f "$E_DEPLOY_ROOT/services/registry/docker-compose.registry.yml" \
    up $E_DETACH_FLAG $E_BUILD_FLAG

echo "  Waiting for Registry health..."
for i in $(seq 1 30); do
    if curl -sf http://localhost:9010/health > /dev/null 2>&1; then
        echo "  Registry healthy after ${i}s"
        break
    fi
    sleep 1
done

# Step 2: Start Control Plane (provisioners + healing + orchestrator)
echo ""
echo "[Phase 2] Starting Control Plane services..."
docker-compose -f "$E_DEPLOY_ROOT/services/registry/docker-compose.registry.yml" \
               -f "$E_DEPLOY_ROOT/services/docker-compose.control-plane.yml" \
    up $E_DETACH_FLAG $E_BUILD_FLAG

echo "  Waiting for all provisioners..."
E_PROVISIONER_PORTS="9011 9012 9013 9014 9015 9016 9017 9018 9019 9020 9021"
for port in $E_PROVISIONER_PORTS; do
    for i in $(seq 1 30); do
        if curl -sf "http://localhost:$port/health" > /dev/null 2>&1; then
            echo "  Port $port healthy"
            break
        fi
        sleep 1
    done
done

# Step 3: Verify Self-Healing and Orchestrator
echo ""
echo "[Phase 3] Verifying Self-Healing Engine and Orchestrator..."
for port in 9030 9040; do
    for i in $(seq 1 30); do
        if curl -sf "http://localhost:$port/health" > /dev/null 2>&1; then
            echo "  Port $port healthy"
            break
        fi
        sleep 1
    done
done

echo ""
echo "============================================="
echo "  Control Plane READY"
echo "  Registry:        http://localhost:9010"
echo "  Provisioners:    http://localhost:9011-9021"
echo "  Self-Healing:    http://localhost:9030"
echo "  Orchestrator:    http://localhost:9040"
echo ""
echo "  Next: Run the orchestrator to deploy all modules:"
echo "    curl -X POST http://localhost:9040/api/v1/deploy/start"
echo "============================================="
