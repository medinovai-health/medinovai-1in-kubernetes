#!/usr/bin/env bash
# env-manager.sh — Manage MedinovAI 4-environment deployment
#
# Owner: medinovai-Deploy
# Docs: docs/FOUR_ENVIRONMENT_DEPLOYMENT.md
#
# Usage:
#   ./scripts/env-manager.sh start dev [--all|--core]
#   ./scripts/env-manager.sh stop dev
#   ./scripts/env-manager.sh status
#   ./scripts/env-manager.sh bootstrap dev
#   ./scripts/env-manager.sh promote qa staging

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMPOSE_DIR="$REPO_ROOT/infra/docker/compose"
ENVS_DIR="$REPO_ROOT/envs"
ATLASOS_ROOT="${ATLASOS_ROOT:-$REPO_ROOT/../AtlasOS}"
SECURITY_SERVICE_ROOT="${SECURITY_SERVICE_ROOT:-$REPO_ROOT/../medinovai-security-service}"
RUNTIME_SYNC_SCRIPT="$REPO_ROOT/scripts/sync-atlas-runtime.sh"

CORE_LAYERS=(
  "$COMPOSE_DIR/docker-compose.base.yml"
  "$COMPOSE_DIR/docker-compose.atlasos-core.yml"
  "$COMPOSE_DIR/docker-compose.atlasos-agents.yml"
  "$COMPOSE_DIR/docker-compose.atlasos-governance.yml"
)

ALL_LAYERS=(
  "${CORE_LAYERS[@]}"
  "$COMPOSE_DIR/docker-compose.atlasos-ai.yml"
  "$COMPOSE_DIR/docker-compose.observability.yml"
)

VALID_ENVS="dev qa staging prod"

usage() {
  cat <<EOF
MedinovAI Environment Manager

Usage:
  $0 start <env> [--all|--core]    Start an environment
  $0 activate <env> [--all|--core] Start an environment and sync ~/.atlas
  $0 stop <env>                     Stop an environment
  $0 status                         Show all running environments
  $0 bootstrap <env>                Bootstrap Keycloak + DB for an environment
  $0 promote <from> <to>            Promote changes between environments
  $0 verify <env>                   Verify live runtime drift + local-first policy
  $0 logs <env> [service]           Tail logs for an environment

Environments: dev, qa, staging, prod
EOF
  exit 1
}

validate_env() {
  local env="$1"
  if [[ ! " $VALID_ENVS " =~ " $env " ]]; then
    echo "ERROR: Invalid environment '$env'. Must be one of: $VALID_ENVS"
    exit 1
  fi
}

compose_cmd() {
  local env="$1"
  shift
  local layers=("$@")

  local -a file_args=()
  for layer in "${layers[@]}"; do
    if [[ -f "$layer" ]]; then
      file_args+=("-f" "$layer")
    fi
  done

  docker compose \
    "${file_args[@]}" \
    --env-file "$ENVS_DIR/base.env" \
    --env-file "$ENVS_DIR/${env}.env" \
    -p "atlasos-${env}" \
    --project-directory "$REPO_ROOT"
}

cmd_start() {
  local env="$1"
  local mode="${2:---core}"
  validate_env "$env"

  echo "Starting $env environment (mode: $mode)..."

  local layers
  case "$mode" in
    --all) layers=("${ALL_LAYERS[@]}") ;;
    --core) layers=("${CORE_LAYERS[@]}") ;;
    *) layers=("${CORE_LAYERS[@]}") ;;
  esac

  export ATLASOS_ROOT
  compose_cmd "$env" "${layers[@]}" up -d

  echo ""
  echo "Environment '$env' started."
  echo "  Keycloak:  http://localhost:$(grep KEYCLOAK_PORT "$ENVS_DIR/${env}.env" | cut -d= -f2)"
  echo "  Grafana:   http://localhost:$(grep GRAFANA_PORT "$ENVS_DIR/${env}.env" | cut -d= -f2 || echo 'N/A')"
  echo "  Event Bus: http://localhost:$(grep EVENT_BUS_PORT "$ENVS_DIR/${env}.env" | cut -d= -f2)"
}

cmd_activate() {
  local env="$1"
  local mode="${2:---core}"
  cmd_start "$env" "$mode"
  if [[ -x "$RUNTIME_SYNC_SCRIPT" ]]; then
    echo ""
    echo "Syncing authoritative runtime into ~/.atlas..."
    ATLASOS_ROOT="$ATLASOS_ROOT" DEPLOY_ROOT="$REPO_ROOT" "$RUNTIME_SYNC_SCRIPT" "$env"
  else
    echo "WARNING: $RUNTIME_SYNC_SCRIPT not found or not executable"
  fi
}

cmd_stop() {
  local env="$1"
  validate_env "$env"

  echo "Stopping $env environment..."
  compose_cmd "$env" "${ALL_LAYERS[@]}" down
  echo "Environment '$env' stopped."
}

cmd_status() {
  echo "MedinovAI Environment Status"
  echo "=============================="
  for env in $VALID_ENVS; do
    local project="atlasos-${env}"
    local count
    count=$(docker compose -p "$project" ps -q 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$count" -gt 0 ]]; then
      local env_file="$ENVS_DIR/${env}.env"
      local ooda_port=""
      if [[ -f "$env_file" ]]; then
        ooda_port=$(grep '^OODA_BRAIN_PORT=' "$env_file" | cut -d= -f2)
      fi
      if [[ -n "$ooda_port" ]] && curl -sf "http://127.0.0.1:${ooda_port}/health" >/dev/null 2>&1; then
        echo "  $env: $count containers running, health probes passing"
      else
        echo "  $env: $count containers running, health probes degraded"
      fi
    else
      echo "  $env: not running"
    fi
  done
}

cmd_bootstrap() {
  local env="$1"
  validate_env "$env"

  echo "Bootstrapping $env environment..."

  compose_cmd "$env" "${CORE_LAYERS[0]}" up -d atlasos-db keycloak redis vault
  echo "  Waiting for infrastructure to be healthy..."
  sleep 10

  if [[ -f "$SECURITY_SERVICE_ROOT/scripts/bootstrap_environment.py" ]]; then
    local kc_port
    kc_port=$(grep KEYCLOAK_PORT "$ENVS_DIR/${env}.env" | cut -d= -f2)
    echo "  Running Keycloak bootstrap for $env..."
    python3 "$SECURITY_SERVICE_ROOT/scripts/bootstrap_environment.py" \
      --env "$env" \
      --keycloak-url "http://localhost:${kc_port}" \
      2>&1 || echo "  WARNING: Keycloak bootstrap script not yet available"
  else
    echo "  WARNING: bootstrap_environment.py not found — skipping Keycloak realm setup"
  fi

  echo "  Running database migrations..."
  compose_cmd "$env" "${CORE_LAYERS[@]:0:2}" up atlasos-migrations
  echo "Bootstrap complete for $env."
}

cmd_promote() {
  local from="$1"
  local to="$2"
  validate_env "$from"
  validate_env "$to"

  echo "Promoting from $from to $to..."
  echo "  This requires change:promote scope on env:$to in Keycloak."
  echo "  Use the Change Authority API: POST /changes/{id}/promote"
  echo "  Or the AtlasOS UI approval workflow."
  echo ""
  echo "  Automated promotion is not yet implemented."
  echo "  Manual steps:"
  echo "    1. Verify all tests pass in $from"
  echo "    2. Get approval from required approvers"
  echo "    3. Run: $0 start $to --all"
}

cmd_logs() {
  local env="$1"
  local service="${2:-}"
  validate_env "$env"

  if [[ -n "$service" ]]; then
    docker compose -p "atlasos-${env}" logs -f "$service"
  else
    docker compose -p "atlasos-${env}" logs -f --tail=100
  fi
}

cmd_verify() {
  local env="$1"
  validate_env "$env"
  ATLASOS_ROOT="$ATLASOS_ROOT" DEPLOY_ROOT="$REPO_ROOT" python3 "$ATLASOS_ROOT/scripts/write_runtime_status.py" --fail-on-drift
  echo "Runtime verification passed for $env."
}

case "${1:-}" in
  start)     cmd_start "${2:?env required}" "${3:---core}" ;;
  activate)  cmd_activate "${2:?env required}" "${3:---core}" ;;
  stop)      cmd_stop "${2:?env required}" ;;
  status)    cmd_status ;;
  bootstrap) cmd_bootstrap "${2:?env required}" ;;
  promote)   cmd_promote "${2:?from env required}" "${3:?to env required}" ;;
  logs)      cmd_logs "${2:?env required}" "${3:-}" ;;
  verify)    cmd_verify "${2:?env required}" ;;
  *)         usage ;;
esac
