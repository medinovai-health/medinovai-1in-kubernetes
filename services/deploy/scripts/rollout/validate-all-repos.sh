#!/usr/bin/env bash
set -euo pipefail

# Validate MedinovAI standards compliance across all repos.
# Usage: ./validate-all-repos.sh [--clone-dir <path>]

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BRAIN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
CLONE_DIR="${1:-$HOME/medinovai-all-repos}"
REPORT="$BRAIN_DIR/standards-rollout-package/VALIDATION_REPORT.md"

echo "# MedinovAI Standards Validation Report" > "$REPORT"
echo "" >> "$REPORT"
echo "**Generated**: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$REPORT"
echo "" >> "$REPORT"

TOTAL=0
PASS=0
FAIL=0
MISSING_CURSORRULES=0
MISSING_CLAUDE=0
MISSING_AGENTS=0
MISSING_CURSOR_DIR=0
HARDCODED_PORTS=0

for repo_dir in "$CLONE_DIR"/*/; do
  [ -d "$repo_dir/.git" ] || continue
  TOTAL=$((TOTAL + 1))
  repo_name=$(basename "$repo_dir")
  issues=""

  # Check .cursorrules
  if [ ! -f "$repo_dir/.cursorrules" ]; then
    issues="${issues}missing .cursorrules; "
    MISSING_CURSORRULES=$((MISSING_CURSORRULES + 1))
  fi

  # Check CLAUDE.md
  if [ ! -f "$repo_dir/CLAUDE.md" ]; then
    issues="${issues}missing CLAUDE.md; "
    MISSING_CLAUDE=$((MISSING_CLAUDE + 1))
  fi

  # Check AGENTS.md
  if [ ! -f "$repo_dir/AGENTS.md" ]; then
    issues="${issues}missing AGENTS.md; "
    MISSING_AGENTS=$((MISSING_AGENTS + 1))
  fi

  # Check .cursor/rules/
  if [ ! -d "$repo_dir/.cursor/rules" ]; then
    issues="${issues}missing .cursor/rules/; "
    MISSING_CURSOR_DIR=$((MISSING_CURSOR_DIR + 1))
  fi

  if [ -z "$issues" ]; then
    PASS=$((PASS + 1))
  else
    FAIL=$((FAIL + 1))
    echo "| $repo_name | $issues |" >> /tmp/validation_failures.txt
  fi
done

{
  echo "## Summary"
  echo ""
  echo "| Metric | Count |"
  echo "|--------|-------|"
  echo "| Total repos scanned | $TOTAL |"
  echo "| Fully compliant | $PASS |"
  echo "| Non-compliant | $FAIL |"
  echo "| Missing .cursorrules | $MISSING_CURSORRULES |"
  echo "| Missing CLAUDE.md | $MISSING_CLAUDE |"
  echo "| Missing AGENTS.md | $MISSING_AGENTS |"
  echo "| Missing .cursor/rules/ | $MISSING_CURSOR_DIR |"
  echo ""
  echo "**Compliance Rate**: $(( PASS * 100 / TOTAL ))%"
  echo ""

  if [ -f /tmp/validation_failures.txt ]; then
    echo "## Non-Compliant Repos"
    echo ""
    echo "| Repo | Issues |"
    echo "|------|--------|"
    cat /tmp/validation_failures.txt
    rm /tmp/validation_failures.txt
  fi
} >> "$REPORT"

echo ""
echo "Validation complete: $PASS/$TOTAL compliant ($(( PASS * 100 / TOTAL ))%)"
echo "Report: $REPORT"
