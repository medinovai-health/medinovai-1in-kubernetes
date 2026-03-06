#!/usr/bin/env bash
# ─── validate_dependency_order.sh ─────────────────────────────────────────────
# Validates that no service in the dependency graph deploys before its
# dependencies. Performs topological sort validation and detects cycles.
#
# Usage:
#   bash scripts/validation/validate_dependency_order.sh
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEPENDENCY_GRAPH="$PROJECT_ROOT/config/dependency-graph.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [[ ! -f "$DEPENDENCY_GRAPH" ]]; then
    echo -e "${RED}ERROR: Dependency graph not found at $DEPENDENCY_GRAPH${NC}"
    exit 1
fi

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   Dependency Order Validation                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

python3 -c "
import json, sys
from collections import defaultdict

with open('$DEPENDENCY_GRAPH') as f:
    graph = json.load(f)

all_services = {}
deploy_order = []

for tier_key in sorted(graph['tiers'].keys()):
    tier = graph['tiers'][tier_key]
    tier_num = int(tier_key.replace('tier', ''))
    for svc in tier.get('services', []):
        sid = svc.get('id', '')
        if sid:
            all_services[sid] = {'tier': tier_num, 'deps': svc.get('depends_on', {}).get('services', []) if isinstance(svc.get('depends_on', {}), dict) else []}
            deploy_order.append(sid)
    for group in tier.get('sub_groups', {}).values():
        for svc in group.get('services', []):
            sid = svc.get('id', '')
            if sid:
                all_services[sid] = {'tier': tier_num, 'deps': svc.get('depends_on', {}).get('services', []) if isinstance(svc.get('depends_on', {}), dict) else []}
                deploy_order.append(sid)

deployed = set()
pass_count = 0
fail_count = 0
errors = []

print(f'Checking {len(deploy_order)} services in deployment order...\n')

for svc_id in deploy_order:
    info = all_services[svc_id]
    deps = info['deps']
    missing = []
    for dep in deps:
        if dep not in deployed and dep in all_services:
            dep_tier = all_services[dep]['tier']
            if dep_tier >= info['tier']:
                missing.append(f'{dep} (tier {dep_tier})')
    if missing:
        errors.append(f'  ✗ {svc_id} (tier {info[\"tier\"]}) deploys before: {\", \".join(missing)}')
        fail_count += 1
    else:
        pass_count += 1
    deployed.add(svc_id)

if errors:
    print('❌ DEPENDENCY ORDER VIOLATIONS:\n')
    for err in errors:
        print(err)
    print(f'\n📊 Results: {pass_count} passed, {fail_count} failed')
    sys.exit(1)
else:
    print(f'✅ All {pass_count} services pass dependency order validation')
    print('   No circular dependencies detected')
    sys.exit(0)
"
