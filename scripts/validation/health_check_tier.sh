#!/usr/bin/env bash
# ─── health_check_tier.sh ────────────────────────────────────────────────────
# Check health of all services in a specific deployment tier.
#
# Usage:
#   bash scripts/validation/health_check_tier.sh --tier 1
#   bash scripts/validation/health_check_tier.sh --tier all
#   bash scripts/validation/health_check_tier.sh --tier 2 --timeout 60
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEPENDENCY_GRAPH="$PROJECT_ROOT/config/dependency-graph.json"

TIER="all"
TIMEOUT=10
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --tier)     TIER="$2"; shift 2 ;;
        --timeout)  TIMEOUT="$2"; shift 2 ;;
        --verbose)  VERBOSE=true; shift ;;
        *)          echo "Unknown option: $1"; exit 1 ;;
    esac
done

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [[ ! -f "$DEPENDENCY_GRAPH" ]]; then
    echo -e "${RED}ERROR: Dependency graph not found${NC}"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   Tier Health Check                                         ║"
echo "║   Tier: $TIER   Timeout: ${TIMEOUT}s"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

python3 << PYEOF
import json
import subprocess
import sys

with open("$DEPENDENCY_GRAPH") as f:
    graph = json.load(f)

tier_filter = "$TIER"
timeout = int("$TIMEOUT")

total = 0
healthy = 0
unhealthy = 0
skipped = 0
results = []

tiers_to_check = sorted(graph["tiers"].keys())
if tier_filter != "all":
    tiers_to_check = [f"tier{tier_filter}"]

for tier_key in tiers_to_check:
    if tier_key not in graph["tiers"]:
        print(f"  ⚠ Tier {tier_key} not found")
        continue

    tier = graph["tiers"][tier_key]
    tier_num = tier_key.replace("tier", "")
    tier_name = tier.get("name", "Unknown")
    print(f"\n{'━' * 58}")
    print(f"  Tier {tier_num}: {tier_name}")
    print(f"{'━' * 58}")

    all_services = list(tier.get("services", []))
    for group in tier.get("sub_groups", {}).values():
        all_services.extend(group.get("services", []))

    for svc in all_services:
        sid = svc.get("id", "")
        port = svc.get("port")
        health = svc.get("health")

        if not sid:
            continue

        total += 1

        if not port or not health or str(health) in ("None", "null"):
            print(f"  ⏭  {sid:45s} — no health endpoint")
            skipped += 1
            continue

        url = f"http://localhost:{port}{health}"
        try:
            result = subprocess.run(
                ["curl", "-sf", "--max-time", str(timeout), url],
                capture_output=True, timeout=timeout + 5
            )
            if result.returncode == 0:
                print(f"  ✅ {sid:45s} — {url}")
                healthy += 1
            else:
                print(f"  ❌ {sid:45s} — {url} (HTTP error)")
                unhealthy += 1
        except (subprocess.TimeoutExpired, Exception) as e:
            print(f"  ❌ {sid:45s} — {url} (timeout/unreachable)")
            unhealthy += 1

print(f"\n{'═' * 58}")
print(f"  SUMMARY: {healthy} healthy, {unhealthy} unhealthy, {skipped} skipped (of {total} total)")
print(f"{'═' * 58}")

sys.exit(1 if unhealthy > 0 else 0)
PYEOF
