#!/usr/bin/env bash
# ─── validate_compliance.sh ───────────────────────────────────────────────────
# Validate GOV-01 through GOV-10 AI governance compliance.
#
# Usage:
#   bash scripts/validation/validate_compliance.sh
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

PASS=0
FAIL=0
WARN=0

check() {
    local gov_id="$1"
    local name="$2"
    local status="$3"
    local detail="$4"

    case "$status" in
        pass) PASS=$((PASS + 1)); printf "  ✓ [%s] %s — %s\n" "$gov_id" "$name" "$detail" ;;
        warn) WARN=$((WARN + 1)); printf "  ⚠ [%s] %s — %s\n" "$gov_id" "$name" "$detail" ;;
        fail) FAIL=$((FAIL + 1)); printf "  ✗ [%s] %s — %s\n" "$gov_id" "$name" "$detail" ;;
    esac
}

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  AI Governance Compliance Check (GOV-01 — GOV-10)           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# GOV-01: Model Risk Register
if [ -f "$REPO_ROOT/config/schemas/model_risk_register.schema.json" ]; then
    check "GOV-01" "Model Risk Register Schema" "pass" "Schema exists"
else
    check "GOV-01" "Model Risk Register Schema" "fail" "Schema missing"
fi

# GOV-02: Pre-Deployment Validation
if [ -f "$REPO_ROOT/workflows/ai-model-validation.lobster.md" ]; then
    check "GOV-02" "Pre-Deployment Validation Pipeline" "pass" "Workflow defined"
else
    check "GOV-02" "Pre-Deployment Validation Pipeline" "fail" "Workflow missing"
fi

# GOV-03: Bias Testing
if [ -d "$REPO_ROOT/agents/ai-ml/skills/bias-testing" ]; then
    check "GOV-03" "Bias Testing Skill" "pass" "Skill defined"
else
    check "GOV-03" "Bias Testing Skill" "fail" "Skill missing"
fi

# GOV-04: Human Override Pathways
if grep -rq "override" "$REPO_ROOT/agents/" 2>/dev/null; then
    check "GOV-04" "Human Override Pathways" "pass" "Override references found in agent specs"
else
    check "GOV-04" "Human Override Pathways" "warn" "No explicit override references in agents"
fi

# GOV-05: Explainability Standards
if [ -f "$REPO_ROOT/agents/ai-ml/config/explainability_standards.md" ]; then
    check "GOV-05" "Explainability Standards" "pass" "Standards documented"
else
    check "GOV-05" "Explainability Standards" "fail" "Standards missing"
fi

# GOV-06: Performance Monitoring
if [ -f "$REPO_ROOT/agents/ai-ml/HEARTBEAT.md" ]; then
    check "GOV-06" "AI Performance Monitoring" "pass" "Heartbeat checks defined"
else
    check "GOV-06" "AI Performance Monitoring" "fail" "No heartbeat checks"
fi

# GOV-07: Data Lineage Tracking
if [ -f "$REPO_ROOT/config/schemas/data_lineage.schema.json" ]; then
    check "GOV-07" "Data Lineage Schema" "pass" "Schema exists"
else
    check "GOV-07" "Data Lineage Schema" "fail" "Schema missing"
fi

# GOV-08: Vendor Accountability
if [ -f "$REPO_ROOT/templates/vendor-ai-accountability-terms.md" ]; then
    check "GOV-08" "Vendor Accountability Terms" "pass" "Template exists"
else
    check "GOV-08" "Vendor Accountability Terms" "fail" "Template missing"
fi

# GOV-09: Incident Response
AI_INCIDENT_FOUND=false
if [ -d "$REPO_ROOT/agents/ai-ml/skills/ai-incident" ] || [ -d "$REPO_ROOT/agents/security/skills/incident-response" ]; then
    AI_INCIDENT_FOUND=true
fi
if $AI_INCIDENT_FOUND; then
    check "GOV-09" "AI Incident Response" "pass" "Incident response skill defined"
else
    check "GOV-09" "AI Incident Response" "fail" "No incident response skill"
fi

# GOV-10: Cross-Functional Oversight
if [ -f "$REPO_ROOT/docs/AI_GOVERNANCE_BOARD.md" ]; then
    check "GOV-10" "Governance Board Charter" "pass" "Board charter exists"
else
    check "GOV-10" "Governance Board Charter" "fail" "Board charter missing"
fi

# ─── Deployment Safety Checks ────────────────────────────────────────────────
echo ""
echo "▸ Deployment Safety"

if [ -f "$REPO_ROOT/workflows/deploy.lobster.md" ]; then
    check "DEPLOY" "Deploy Pipeline" "pass" "Approval-gated pipeline defined"
else
    check "DEPLOY" "Deploy Pipeline" "fail" "No deploy pipeline"
fi

if [ -f "$REPO_ROOT/.cursor/rules/deploy-safety.mdc" ]; then
    check "DEPLOY" "Safety Rules" "pass" "Deploy safety rules configured"
else
    check "DEPLOY" "Safety Rules" "warn" "No deploy safety rules"
fi

# ─── Summary ─────────────────────────────────────────────────────────────────
echo ""
echo "────────────────────────────────────────────────────────────────"
echo "Compliance Results: $PASS passed, $FAIL failed, $WARN warnings"
echo ""

if [ "$FAIL" -gt 0 ]; then
    echo "COMPLIANCE: NOT MET — $FAIL controls not satisfied"
    exit 1
else
    echo "COMPLIANCE: ALL CONTROLS MET"
    [ "$WARN" -gt 0 ] && echo "  ($WARN advisory warnings — review recommended)"
fi
