#!/usr/bin/env bash
# health-check.sh
# Check health of all AIFactory nodes in the federation
# Usage: ./health-check.sh
# Run from any machine on the Tailscale mesh

set -uo pipefail

NODES=(
  "aifactory-us-mac-studio|100.106.54.9|macstudio"
  "spark-08dd|100.125.48.57|n8n"
  "spark-b587|100.83.165.95|n8n"
  "spark-d0a6|100.94.48.43|n8n"
)

PASS=0; WARN=0; FAIL=0

check_node() {
  local name=$1 ip=$2 user=$3
  local ollama_url="http://${ip}:11434"
  local status="✅"
  local notes=""

  # Ollama API check
  ver=$(curl -s --connect-timeout 3 "${ollama_url}/api/version" 2>/dev/null | python3 -c "import json,sys; print(json.load(sys.stdin).get('version','?'))" 2>/dev/null || echo "unreachable")

  if [ "$ver" = "unreachable" ]; then
    status="❌"; ((FAIL++))
    notes="Ollama not reachable"
  else
    # Model count
    count=$(curl -s --connect-timeout 3 "${ollama_url}/api/tags" 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('models',[])))" 2>/dev/null || echo "?")
    # Running models
    running=$(curl -s --connect-timeout 3 "${ollama_url}/api/ps" 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('models',[])))" 2>/dev/null || echo "?")
    notes="Ollama v${ver} | ${count} models | ${running} running"
    ((PASS++))
  fi

  printf "%-35s %-18s %s %s\n" "$name" "$ip" "$status" "$notes"
}

echo "╔══════════════════════════════════════════════════════════════════════════╗"
echo "║                    AIFactory Node Health Check                          ║"
printf "║  %s%-70s║\n" "$(date '+%Y-%m-%d %H:%M:%S')" ""
echo "╠══════════════════════════════════════════════════════════════════════════╣"
printf "║ %-35s %-18s %-2s %-16s║\n" "NODE" "TAILSCALE IP" "ST" "DETAILS"
echo "╠══════════════════════════════════════════════════════════════════════════╣"

for node in "${NODES[@]}"; do
  IFS='|' read -r name ip user <<< "$node"
  printf "║ "
  check_node "$name" "$ip" "$user"
  printf " ║" 2>/dev/null || true
  echo ""
done 2>/dev/null | grep -v "^$"

echo "╠══════════════════════════════════════════════════════════════════════════╣"
printf "║  PASS: %-4s  WARN: %-4s  FAIL: %-4s%38s║\n" "$PASS" "$WARN" "$FAIL" ""
echo "╚══════════════════════════════════════════════════════════════════════════╝"
