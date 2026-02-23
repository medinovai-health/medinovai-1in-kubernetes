#!/usr/bin/env bash
# ─── test2-diagnose.sh ────────────────────────────────────────────────────────
# Auto-triage all unhealthy/crashing TEST2 containers.
# Shows: healthcheck failure output, last 15 log lines, port in use.
#
# Usage:
#   bash infra/docker/test2-diagnose.sh              # Triage all unhealthy
#   bash infra/docker/test2-diagnose.sh --all        # Show all services (not just unhealthy)
#   make test2-diagnose
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SHOW_ALL="${1:-}"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  TEST2 Deployment Diagnostics                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

TOTAL=$(docker ps --filter "name=TEST2" -q | wc -l | tr -d ' ')
HEALTHY=$(docker ps --filter "name=TEST2" --format '{{.Status}}' | grep -c "(healthy)" || true)
UNHEALTHY=$(docker ps --filter "name=TEST2" --format '{{.Status}}' | grep -c "unhealthy" || true)
CRASHING=$(docker ps --filter "name=TEST2" --format '{{.Status}}' | grep -c "Restarting" || true)
STARTING=$(docker ps --filter "name=TEST2" --format '{{.Status}}' | grep -c "health: starting" || true)

echo "  Total containers : ${TOTAL}"
printf "  Healthy          : ${GREEN}${HEALTHY}${NC}\n"
if [[ "${UNHEALTHY}" -gt 0 ]]; then
  printf "  Unhealthy        : ${RED}${UNHEALTHY}${NC}\n"
else
  echo "  Unhealthy        : 0"
fi
if [[ "${CRASHING}" -gt 0 ]]; then
  printf "  Crashing         : ${RED}${CRASHING}${NC}\n"
else
  echo "  Crashing         : 0"
fi
echo "  Starting         : ${STARTING}"

PROBLEM_COUNT=$((UNHEALTHY + CRASHING))

if [[ "${PROBLEM_COUNT}" -eq 0 && "${SHOW_ALL}" != "--all" ]]; then
  echo ""
  printf "  ${GREEN}All services are healthy!${NC}\n"
  echo ""
  exit 0
fi

echo ""
echo "─────────────────────────────────────────────────────────────"

# Process each container
while IFS=$'\t' read -r container status; do
  [[ -z "$container" ]] && continue

  HEALTH=$(docker inspect "$container" --format '{{.State.Health.Status}}' 2>/dev/null || echo "none")
  IS_RESTARTING=$(echo "$status" | grep -c "Restarting" || true)

  if [[ "$HEALTH" == "unhealthy" ]] || [[ "$IS_RESTARTING" -gt 0 ]] || [[ "$SHOW_ALL" == "--all" ]]; then

    if [[ "$HEALTH" == "unhealthy" ]]; then
      printf "\n${RED}UNHEALTHY${NC}: ${CYAN}${container}${NC}\n"
    elif [[ "$IS_RESTARTING" -gt 0 ]]; then
      printf "\n${RED}CRASHING${NC}: ${CYAN}${container}${NC}\n"
    else
      printf "\n${GREEN}OK${NC}: ${CYAN}${container}${NC} — ${status}\n"
    fi
    echo "  Status: ${status}"

    # Show healthcheck test command
    HC_TEST=$(docker inspect "$container" --format '{{range .Config.Healthcheck.Test}}{{.}} {{end}}' 2>/dev/null | sed 's/CMD-SHELL //' || echo "none")
    if [[ -n "$HC_TEST" && "$HC_TEST" != "none " ]]; then
      echo "  Healthcheck: ${HC_TEST}"
    fi

    # Show last 2 healthcheck outputs
    if [[ "$HEALTH" != "none" && "$HEALTH" != "" ]]; then
      HC_LOG=$(docker inspect "$container" --format '{{json .State.Health.Log}}' 2>/dev/null | \
        python3 -c "
import json,sys
try:
    logs = json.load(sys.stdin)
    for l in logs[-2:]:
        out = l.get('Output','').strip()
        if out:
            print('  HC OUTPUT: ' + out[:200])
except:
    pass
" 2>/dev/null || true)
      if [[ -n "$HC_LOG" ]]; then
        echo "$HC_LOG"
      fi
    fi

    # Show last 15 log lines
    echo "  --- Last 15 log lines ---"
    docker logs "$container" --tail 15 2>&1 | sed 's/^/  /' || true

    echo ""
  fi
done < <(docker ps -a --filter "name=TEST2" --format "{{.Names}}\t{{.Status}}")

echo "─────────────────────────────────────────────────────────────"
echo ""
echo "Quick fixes:"
echo "  Kafka InconsistentClusterIdException → make test2-kafka-reset"
echo "  Service unhealthy (port wrong)       → check healthcheck port in compose"
echo "  Service crashing (cmd fails)         → run: docker logs TEST2-<service>"
echo "  Image missing                        → make test2-rebuild"
echo "  Full redeploy                        → make test2-down && make test2-up"
echo ""
