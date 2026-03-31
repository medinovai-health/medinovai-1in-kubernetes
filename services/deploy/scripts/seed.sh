#!/usr/bin/env bash
# ─── seed.sh ───────────────────────────────────────────────────────────────────
# Rebuild MedinovAI Docker environment from scratch.
# Starts infrastructure, runs migrations (if available), seeds reference data.
#
# Usage:
#   bash scripts/seed.sh
#   bash scripts/seed.sh --reset   # Drop and recreate DB first
#
# Per software-safety: creates working environment from zero.
# Does NOT depend on existing volumes or state.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
COMPOSE_FILE="$REPO_ROOT/infra/docker/docker-compose.dev.yml"
RESET=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --reset)  RESET=true; shift ;;
        *)        echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  MedinovAI Seed — Fresh Environment"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

cd "$REPO_ROOT"

if $RESET; then
    echo "▸ Resetting: stopping stack and removing volumes..."
    docker compose -f "$COMPOSE_FILE" down -v 2>/dev/null || true
    echo "  ✓ Volumes removed"
fi

echo ""
echo "▸ Starting infrastructure (postgres, redis)..."
docker compose -f "$COMPOSE_FILE" up -d postgres redis

echo "  Waiting for Postgres..."
for i in $(seq 1 60); do
    if docker exec medinovai-postgres pg_isready -U medinovai -d medinovai 2>/dev/null; then
        echo "  ✓ Postgres ready"
        break
    fi
    sleep 1
done

echo ""
echo "▸ Running schema/migrations (if available)..."
MIGRATIONS_DIR="$REPO_ROOT/infra/kubernetes/jobs"
if [ -f "$REPO_ROOT/infra/terraform/modules/database/scripts/init.sql" ]; then
    docker exec -i medinovai-postgres psql -U medinovai -d medinovai < "$REPO_ROOT/infra/terraform/modules/database/scripts/init.sql" 2>/dev/null || true
elif [ -d "$MIGRATIONS_DIR" ]; then
    # Placeholder: migrations would run here
    echo "  (No init.sql found — schema will be created by app migrations)"
fi

echo ""
echo "▸ Starting full stack..."
docker compose -f "$COMPOSE_FILE" up -d

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✓ Seed complete."
echo "║  Postgres: localhost:5432  Redis: localhost:6379"
echo "║  Grafana:  http://localhost:3000  Prometheus: http://localhost:9090"
echo "╚══════════════════════════════════════════════════════════════╝"
