#!/usr/bin/env bash
set -euo pipefail

# Check port registry compliance across all repos.
# Scans for hardcoded ports that don't come from the registry.

CLONE_DIR="${1:-$HOME/medinovai-all-repos}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BRAIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPORT="$BRAIN_DIR/standards-rollout-package/PORT_COMPLIANCE_REPORT.md"

echo "# Port Compliance Report" > "$REPORT"
echo "**Generated**: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$REPORT"
echo "" >> "$REPORT"

TOTAL=0
VIOLATIONS=0

for repo_dir in "$CLONE_DIR"/*/; do
  [ -d "$repo_dir/.git" ] || continue
  TOTAL=$((TOTAL + 1))
  repo_name=$(basename "$repo_dir")

  hits=$(grep -rn --include="*.yml" --include="*.yaml" --include="*.json" \
    --include="*.sh" --include="*.py" --include="*.ts" --include="*.js" \
    --include="*.html" \
    -E '"[0-9]{4}:[0-9]{4}"' "$repo_dir" 2>/dev/null \
    | grep -v node_modules | grep -v .git | grep -v port-registry | head -5 || true)

  if [ -n "$hits" ]; then
    VIOLATIONS=$((VIOLATIONS + 1))
    echo "### $repo_name" >> "$REPORT"
    echo '```' >> "$REPORT"
    echo "$hits" >> "$REPORT"
    echo '```' >> "$REPORT"
    echo "" >> "$REPORT"
  fi
done

{
  echo "## Summary"
  echo "| Metric | Count |"
  echo "|--------|-------|"
  echo "| Repos scanned | $TOTAL |"
  echo "| Repos with potential violations | $VIOLATIONS |"
  echo "| Compliance rate | $(( (TOTAL - VIOLATIONS) * 100 / TOTAL ))% |"
} >> "$REPORT"

echo "Port compliance check complete: $VIOLATIONS violations in $TOTAL repos"
echo "Report: $REPORT"
