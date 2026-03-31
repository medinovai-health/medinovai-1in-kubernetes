#!/usr/bin/env bash
# ─── validate_setup.sh ───────────────────────────────────────────────────────
# Validates the MedinovAI Atlas repo: checks all scripts run, configs parse, and
# workspace structure is correct.
#
# Usage:
#   bash scripts/validate_setup.sh
#
# Exit code 0 = all checks pass. Non-zero = failures found.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0
WARN=0

pass() { echo "  ✓ $1"; PASS=$((PASS + 1)); }
fail() { echo "  ✗ $1"; FAIL=$((FAIL + 1)); }
warn() { echo "  ⚠ $1"; WARN=$((WARN + 1)); }

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          MedinovAI Atlas Setup Validation                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ─── 1. Check required files exist ───────────────────────────────────────────
echo "▸ Checking required files..."

REQUIRED_FILES=(
    "README.md"
    "config/atlas.json5"
    "config/.env.example"
    ".gitignore"
    "docs/slack_setup.md"
    "docs/automation_patterns.md"
    "scripts/install_atlas.sh"
    "scripts/deploy_config.sh"
    "scripts/create_agents.sh"
    "scripts/register_crons.sh"
    "scripts/verify_audit_chain.py"
)

for f in "${REQUIRED_FILES[@]}"; do
    if [ -f "$REPO_ROOT/$f" ]; then
        pass "$f"
    else
        fail "$f — MISSING"
    fi
done

# ─── 2. Check workspace structure ────────────────────────────────────────────
echo ""
echo "▸ Checking workspace structure..."

AGENTS=("ops" "support" "sales" "finance" "eng" "supervisor" "guardian")
for agent in "${AGENTS[@]}"; do
    WS="$REPO_ROOT/workspaces/$agent"
    if [ -d "$WS" ]; then
        pass "workspaces/$agent/ exists"
    else
        fail "workspaces/$agent/ — MISSING"
        continue
    fi

    # Check AGENTS.md
    if [ -f "$WS/AGENTS.md" ]; then
        pass "workspaces/$agent/AGENTS.md"
    else
        fail "workspaces/$agent/AGENTS.md — MISSING"
    fi

    # Check TOOLS.md
    if [ -f "$WS/TOOLS.md" ]; then
        pass "workspaces/$agent/TOOLS.md"
    else
        fail "workspaces/$agent/TOOLS.md — MISSING"
    fi

    # Check SOUL.md
    if [ -f "$WS/SOUL.md" ]; then
        pass "workspaces/$agent/SOUL.md"
    else
        warn "workspaces/$agent/SOUL.md — missing (optional but recommended)"
    fi

    # Check HEARTBEAT.md
    if [ -f "$WS/HEARTBEAT.md" ]; then
        pass "workspaces/$agent/HEARTBEAT.md"
    else
        warn "workspaces/$agent/HEARTBEAT.md — missing (optional but recommended)"
    fi

    # Check MISTAKES.md
    if [ -f "$WS/MISTAKES.md" ]; then
        pass "workspaces/$agent/MISTAKES.md"
    else
        fail "workspaces/$agent/MISTAKES.md — MISSING"
    fi

    # Check skills directory has at least one skill (skip for supervisor/guardian)
    if [ "$agent" != "supervisor" ] && [ "$agent" != "guardian" ]; then
        if [ -d "$WS/skills" ] && [ "$(find "$WS/skills" -name 'SKILL.md' | head -1)" ]; then
            SKILL_COUNT=$(find "$WS/skills" -name 'SKILL.md' | wc -l | tr -d ' ')
            pass "workspaces/$agent/skills/ — $SKILL_COUNT skill(s) found"
        else
            warn "workspaces/$agent/skills/ — no skills found (optional for initial setup)"
        fi
    fi

    # ─── Check state files ─────────────────────────────────────────────────
    # Circuit breakers
    if [ -f "$WS/state/circuit_breakers.json" ]; then
        pass "workspaces/$agent/state/circuit_breakers.json"
    else
        fail "workspaces/$agent/state/circuit_breakers.json — MISSING"
    fi

    # Dead letter directory
    if [ -d "$WS/state/dead_letter" ]; then
        pass "workspaces/$agent/state/dead_letter/"
    else
        fail "workspaces/$agent/state/dead_letter/ — MISSING"
    fi

    # Idempotency keys
    if [ -f "$WS/state/idempotency_keys.json" ]; then
        pass "workspaces/$agent/state/idempotency_keys.json"
    else
        fail "workspaces/$agent/state/idempotency_keys.json — MISSING"
    fi

    # Checkpoints directory
    if [ -d "$WS/state/checkpoints" ]; then
        pass "workspaces/$agent/state/checkpoints/"
    else
        fail "workspaces/$agent/state/checkpoints/ — MISSING"
    fi

    # Audit directory
    if [ -d "$WS/audit" ]; then
        pass "workspaces/$agent/audit/"
    else
        fail "workspaces/$agent/audit/ — MISSING"
    fi

    # Memory files
    if [ -d "$WS/state/memory" ]; then
        for memfile in world.json experiences.json entities.json beliefs.json; do
            if [ -f "$WS/state/memory/$memfile" ]; then
                pass "workspaces/$agent/state/memory/$memfile"
            else
                fail "workspaces/$agent/state/memory/$memfile — MISSING"
            fi
        done
    else
        fail "workspaces/$agent/state/memory/ — MISSING"
    fi

    # SLO daily tracking
    if [ -f "$WS/state/slo/daily.json" ]; then
        pass "workspaces/$agent/state/slo/daily.json"
    else
        fail "workspaces/$agent/state/slo/daily.json — MISSING"
    fi

    # Telemetry directory
    if [ -d "$WS/state/telemetry" ]; then
        pass "workspaces/$agent/state/telemetry/"
    else
        fail "workspaces/$agent/state/telemetry/ — MISSING"
    fi
done

# ─── 3. Check OODA section in all AGENTS.md ───────────────────────────────────
echo ""
echo "▸ Checking OODA protocol in AGENTS.md files..."

for agent in "${AGENTS[@]}"; do
    AGENTS_FILE="$REPO_ROOT/workspaces/$agent/AGENTS.md"
    if [ -f "$AGENTS_FILE" ]; then
        if grep -q "Self-Diagnosis Protocol (OODA)" "$AGENTS_FILE" 2>/dev/null; then
            pass "workspaces/$agent/AGENTS.md — OODA section present"
        else
            fail "workspaces/$agent/AGENTS.md — OODA section MISSING"
        fi
    fi
done

# ─── 4. Check health probe config ────────────────────────────────────────────
echo ""
echo "▸ Checking health probe config..."

CONFIG_FILE="$REPO_ROOT/config/atlas.json5"
if grep -q '"\/health"' "$CONFIG_FILE" 2>/dev/null || grep -q '/health' "$CONFIG_FILE" 2>/dev/null; then
    pass "Health probe path configured in atlas.json5"
else
    fail "Health probe path MISSING in atlas.json5"
fi

if grep -q '"\/ready"' "$CONFIG_FILE" 2>/dev/null || grep -q '/ready' "$CONFIG_FILE" 2>/dev/null; then
    pass "Ready probe path configured in atlas.json5"
else
    fail "Ready probe path MISSING in atlas.json5"
fi

# ─── 5. Check memory config ──────────────────────────────────────────────────
echo ""
echo "▸ Checking memory config..."

if grep -q 'memory:' "$CONFIG_FILE" 2>/dev/null; then
    pass "Memory config present in atlas.json5"
else
    fail "Memory config MISSING in atlas.json5"
fi

# ─── 6. Check circuit breaker config ─────────────────────────────────────────
echo ""
echo "▸ Checking circuit breaker config..."

if grep -q 'circuit_breaker:' "$CONFIG_FILE" 2>/dev/null; then
    pass "Circuit breaker config present in atlas.json5"
else
    fail "Circuit breaker config MISSING in atlas.json5"
fi

# ─── 7. Check Python scripts execute ─────────────────────────────────────────
echo ""
echo "▸ Checking Python scripts (syntax + basic execution)..."

PYTHON_SCRIPTS=$(find "$REPO_ROOT/workspaces" "$REPO_ROOT/scripts" -name '*.py' -type f 2>/dev/null)

for script in $PYTHON_SCRIPTS; do
    REL="${script#$REPO_ROOT/}"

    # Check syntax
    if python3 -c "import ast; ast.parse(open('$script').read())" 2>/dev/null; then
        pass "$REL — syntax OK"
    else
        fail "$REL — SYNTAX ERROR"
        continue
    fi

    # Try running scripts that don't require --json-in (they should output JSON)
    if grep -q 'def main' "$script" 2>/dev/null; then
        OUTPUT=$(cd "$(dirname "$script")" && python3 "$(basename "$script")" 2>/dev/null || true)
        if echo "$OUTPUT" | python3 -c "import json,sys; json.load(sys.stdin)" 2>/dev/null; then
            pass "$REL — produces valid JSON"
        elif echo "$OUTPUT" | grep -q '"status".*"error"' 2>/dev/null; then
            pass "$REL — returns expected error (no --json-in)"
        else
            warn "$REL — could not verify JSON output (may need --json-in)"
        fi
    fi
done

# ─── 8. Check shell scripts are executable ────────────────────────────────────
echo ""
echo "▸ Checking shell scripts..."

SHELL_SCRIPTS=$(find "$REPO_ROOT/scripts" -name '*.sh' -type f 2>/dev/null)

for script in $SHELL_SCRIPTS; do
    REL="${script#$REPO_ROOT/}"

    if [ -x "$script" ]; then
        pass "$REL — executable"
    else
        fail "$REL — NOT executable (run: chmod +x $REL)"
    fi

    # Check syntax
    if bash -n "$script" 2>/dev/null; then
        pass "$REL — syntax OK"
    else
        fail "$REL — SYNTAX ERROR"
    fi
done

# ─── 9. Check JSON configs parse ─────────────────────────────────────────────
echo ""
echo "▸ Checking JSON config files..."

JSON_FILES=$(find "$REPO_ROOT/workspaces" -name '*.json' -type f 2>/dev/null)

for jf in $JSON_FILES; do
    REL="${jf#$REPO_ROOT/}"
    if python3 -c "import json; json.load(open('$jf'))" 2>/dev/null; then
        pass "$REL — valid JSON"
    else
        fail "$REL — INVALID JSON"
    fi
done

# ─── 10. Check for accidental secrets ────────────────────────────────────────
echo ""
echo "▸ Checking for accidental secrets..."

# Check that no real tokens are committed
if grep -r 'xoxb-[0-9]' "$REPO_ROOT/config/" 2>/dev/null | grep -v 'REPLACE_ME' | grep -v '.example' > /dev/null 2>&1; then
    fail "Possible real Slack bot token found in config/"
else
    pass "No real Slack tokens in config/"
fi

if grep -r 'xapp-[0-9]' "$REPO_ROOT/config/" 2>/dev/null | grep -v 'REPLACE_ME' | grep -v '.example' > /dev/null 2>&1; then
    fail "Possible real Slack app token found in config/"
else
    pass "No real Slack app tokens in config/"
fi

if grep -r 'sk-ant-' "$REPO_ROOT/config/" 2>/dev/null | grep -v 'REPLACE_ME' | grep -v '.example' > /dev/null 2>&1; then
    fail "Possible real Anthropic API key found in config/"
else
    pass "No real API keys in config/"
fi

# Check .env is not tracked
if [ -f "$REPO_ROOT/.env" ] || [ -f "$REPO_ROOT/config/.env" ]; then
    if git -C "$REPO_ROOT" ls-files --error-unmatch .env 2>/dev/null || git -C "$REPO_ROOT" ls-files --error-unmatch config/.env 2>/dev/null; then
        fail ".env file is tracked by git — remove it!"
    else
        pass ".env exists but is not tracked by git"
    fi
else
    pass "No .env file present (use config/.env.example as template)"
fi

# ─── 11. Check Approval Pipeline workflows ─────────────────────────────────────────────
echo ""
echo "▸ Checking Approval Pipeline workflows..."

if [ -d "$REPO_ROOT/workflows" ]; then
    WORKFLOW_COUNT=$(find "$REPO_ROOT/workflows" -name '*.lobster.md' | wc -l | tr -d ' ')
    pass "workflows/ — $WORKFLOW_COUNT workflow(s) found"
else
    warn "workflows/ directory not found (optional)"
fi

# ─── 12. Check supervisor and guardian ────────────────────────────────────────
echo ""
echo "▸ Checking meta-agents..."

if [ -d "$REPO_ROOT/workspaces/supervisor" ]; then
    pass "Supervisor workspace exists"
else
    fail "Supervisor workspace MISSING"
fi

if [ -d "$REPO_ROOT/workspaces/guardian" ]; then
    pass "Guardian workspace exists"
else
    fail "Guardian workspace MISSING"
fi

# ─── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════════════"
echo "  Results: $PASS passed, $FAIL failed, $WARN warnings"
echo "══════════════════════════════════════════════════════════════"

if [ "$FAIL" -gt 0 ]; then
    echo "  Status: FAILED — fix the issues above before deploying."
    exit 1
else
    echo "  Status: PASSED — repo is ready for deployment."
    exit 0
fi
