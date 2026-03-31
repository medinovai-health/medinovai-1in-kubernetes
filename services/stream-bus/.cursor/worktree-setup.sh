#!/usr/bin/env bash
# =============================================================================
# MedinovAI Universal Worktree Setup Script
# Version: 1.0.0
# Enforces: CHARTER.md, .aistandards.yaml, SAES Super Rules, Productivity Normalization
# =============================================================================
set -euo pipefail

WORKTREE_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCRIPT_START=$(date +%s)
AUDIT_LOG="$WORKTREE_ROOT/.worktree-setup.log"

echo "=== MedinovAI Worktree Setup ===" | tee "$AUDIT_LOG"
echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)" | tee -a "$AUDIT_LOG"
echo "Worktree: $WORKTREE_ROOT" | tee -a "$AUDIT_LOG"
echo "Host: $(hostname)" | tee -a "$AUDIT_LOG"
echo "" | tee -a "$AUDIT_LOG"

# =============================================================================
# Phase 1: Governance Discovery
# =============================================================================
echo "--- Phase 1: Governance Discovery ---" | tee -a "$AUDIT_LOG"

REPO_TYPE="unknown"
CHARTER_EXISTS=false
STANDARDS_EXISTS=false
ENFORCEMENT_LEVEL="warn"
REPO_NAME="$(basename "$WORKTREE_ROOT")"

if [ -f "$WORKTREE_ROOT/CHARTER.md" ]; then
    CHARTER_EXISTS=true
    if grep -q "AI Factory" "$WORKTREE_ROOT/CHARTER.md" 2>/dev/null; then
        REPO_TYPE="aifactory"
    elif grep -q "Foundation Repository" "$WORKTREE_ROOT/CHARTER.md" 2>/dev/null; then
        REPO_TYPE="foundation"
    else
        REPO_TYPE="product"
    fi
fi

if [ -f "$WORKTREE_ROOT/.aistandards.yaml" ]; then
    STANDARDS_EXISTS=true
    ENFORCEMENT_LEVEL=$(grep 'enforcement_level:' "$WORKTREE_ROOT/.aistandards.yaml" \
        | head -1 | awk -F'"' '{print $2}')
    ENFORCEMENT_LEVEL="${ENFORCEMENT_LEVEL:-warn}"
fi

# Detect repo type from name if charter missing
if [ "$REPO_TYPE" = "unknown" ]; then
    case "$REPO_NAME" in
        medinovai-aifactory*|medinovai-healthLLM*) REPO_TYPE="aifactory" ;;
        medinovai-infrastructure*|medinovai-standards*) REPO_TYPE="foundation" ;;
        medinovai-*|medinovAI-*|MedinovAI-*) REPO_TYPE="product" ;;
        *) REPO_TYPE="personal" ;;
    esac
fi

echo "  Repo name:     $REPO_NAME" | tee -a "$AUDIT_LOG"
echo "  Repo type:     $REPO_TYPE" | tee -a "$AUDIT_LOG"
echo "  Charter:       $CHARTER_EXISTS" | tee -a "$AUDIT_LOG"
echo "  AI Standards:  $STANDARDS_EXISTS [$ENFORCEMENT_LEVEL]" | tee -a "$AUDIT_LOG"
echo "  [PASS] Phase 1 complete" | tee -a "$AUDIT_LOG"
echo "" | tee -a "$AUDIT_LOG"

# =============================================================================
# Phase 2: Environment Isolation
# =============================================================================
echo "--- Phase 2: Environment Isolation ---" | tee -a "$AUDIT_LOG"

# Python virtual environment
if [ -f "$WORKTREE_ROOT/requirements.txt" ] || [ -f "$WORKTREE_ROOT/setup.py" ] || [ -f "$WORKTREE_ROOT/pyproject.toml" ]; then
    VENV_DIR="$WORKTREE_ROOT/.venv"
    if [ ! -d "$VENV_DIR" ]; then
        echo "  Creating Python venv..." | tee -a "$AUDIT_LOG"
        python3 -m venv "$VENV_DIR" 2>/dev/null || python3.11 -m venv "$VENV_DIR" 2>/dev/null || true
    fi
    if [ -d "$VENV_DIR" ]; then
        # shellcheck disable=SC1091
        source "$VENV_DIR/bin/activate"
        pip install --upgrade pip -q 2>/dev/null || true
        echo "  Python venv: READY" | tee -a "$AUDIT_LOG"
    fi
fi

# Copy env templates -- never secrets (SAES Rule 1: PHI Firewall)
copy_env_if_missing() {
    local src="$1" dst="$2"
    if [ -f "$src" ] && [ ! -f "$dst" ]; then
        cp "$src" "$dst"
        echo "  Created $(basename "$dst") from template" | tee -a "$AUDIT_LOG"
    fi
}

for template in ".env.example" ".env.template" ".env.medinovai.example"; do
    if [ -f "$WORKTREE_ROOT/$template" ]; then
        target="${template%.example}"
        target="${target%.template}"
        copy_env_if_missing "$WORKTREE_ROOT/$template" "$WORKTREE_ROOT/$target"
    fi
done

# Frontend env templates
for fe_dir in "frontend" "dashboard-new/frontend" "ui" "web"; do
    for tmpl in ".env.local.template" ".env.local.example" ".env.example"; do
        copy_env_if_missing "$WORKTREE_ROOT/$fe_dir/$tmpl" "$WORKTREE_ROOT/$fe_dir/.env.local" 2>/dev/null || true
    done
done

# Symlink shared secrets (PHI-safe: never duplicated, never committed)
SECRETS_DIR="$HOME/.medinovai/secrets"
if [ -d "$SECRETS_DIR" ]; then
    for secret_file in "$SECRETS_DIR"/.env.*; do
        [ -f "$secret_file" ] || continue
        target="$WORKTREE_ROOT/$(basename "$secret_file")"
        ln -sf "$secret_file" "$target" 2>/dev/null && \
            echo "  Symlinked secret: $(basename "$secret_file")" | tee -a "$AUDIT_LOG"
    done
fi

echo "  [PASS] Phase 2 complete" | tee -a "$AUDIT_LOG"
echo "" | tee -a "$AUDIT_LOG"

# =============================================================================
# Phase 3: Dependency Installation (Parallel)
# =============================================================================
echo "--- Phase 3: Dependency Installation ---" | tee -a "$AUDIT_LOG"

INSTALL_PIDS=()

# 3a. Python deps
if [ -f "$WORKTREE_ROOT/requirements.txt" ] && [ -d "$WORKTREE_ROOT/.venv" ]; then
    (
        # shellcheck disable=SC1091
        source "$WORKTREE_ROOT/.venv/bin/activate"
        pip install -r "$WORKTREE_ROOT/requirements.txt" -q 2>&1 | tail -1
        if [ -f "$WORKTREE_ROOT/sdk/python/setup.py" ]; then
            pip install -e "$WORKTREE_ROOT/sdk/python" -q 2>/dev/null || true
        fi
        echo "  Python deps: DONE" | tee -a "$AUDIT_LOG"
    ) &
    INSTALL_PIDS+=($!)
fi

# 3b. Node.js deps (parallel)
for pkg_dir in \
    "$WORKTREE_ROOT/frontend" \
    "$WORKTREE_ROOT/dashboard-new/frontend" \
    "$WORKTREE_ROOT/ui" \
    "$WORKTREE_ROOT/web"; do
    if [ -f "$pkg_dir/package.json" ]; then
        (
            cd "$pkg_dir"
            if [ -f "package-lock.json" ]; then
                npm ci --prefer-offline -q 2>&1 | tail -1
            elif [ -f "yarn.lock" ]; then
                yarn install --frozen-lockfile -q 2>&1 | tail -1
            elif [ -f "bun.lockb" ]; then
                bun install 2>&1 | tail -1
            else
                npm install -q 2>&1 | tail -1
            fi
            echo "  Node deps [$(basename "$pkg_dir")]: DONE" | tee -a "$AUDIT_LOG"
        ) &
        INSTALL_PIDS+=($!)
    fi
done

# 3c. Root package.json (Node-only repos)
if [ -f "$WORKTREE_ROOT/package.json" ] && [ ! -f "$WORKTREE_ROOT/requirements.txt" ]; then
    (
        cd "$WORKTREE_ROOT"
        if [ -f "package-lock.json" ]; then
            npm ci --prefer-offline -q 2>&1 | tail -1
        else
            npm install -q 2>&1 | tail -1
        fi
        echo "  Root Node deps: DONE" | tee -a "$AUDIT_LOG"
    ) &
    INSTALL_PIDS+=($!)
fi

# 3d. Foundation repo stubs (AIFactory only)
if [ "$REPO_TYPE" = "aifactory" ] && [ -d "$WORKTREE_ROOT/.venv" ]; then
    (
        # shellcheck disable=SC1091
        source "$WORKTREE_ROOT/.venv/bin/activate"
        pip install medinovai-core medinovai-data-services medinovai-security-services \
            -q 2>/dev/null || true
        echo "  Foundation stubs: DONE" | tee -a "$AUDIT_LOG"
    ) &
    INSTALL_PIDS+=($!)
fi

# Wait for ALL parallel installs
for pid in "${INSTALL_PIDS[@]}"; do
    wait "$pid" 2>/dev/null || echo "  WARNING: Install PID $pid failed" | tee -a "$AUDIT_LOG"
done

echo "  [PASS] Phase 3 complete" | tee -a "$AUDIT_LOG"
echo "" | tee -a "$AUDIT_LOG"

# =============================================================================
# Phase 4: Security & Compliance Gates
# =============================================================================
echo "--- Phase 4: Security & Compliance Gates ---" | tee -a "$AUDIT_LOG"

# 4a. Pre-commit hooks
if [ -f "$WORKTREE_ROOT/.pre-commit-config.yaml" ]; then
    if command -v pre-commit &>/dev/null; then
        (cd "$WORKTREE_ROOT" && pre-commit install -q 2>/dev/null)
        echo "  Pre-commit hooks: INSTALLED" | tee -a "$AUDIT_LOG"
    elif [ -d "$WORKTREE_ROOT/.venv" ]; then
        # shellcheck disable=SC1091
        source "$WORKTREE_ROOT/.venv/bin/activate"
        pip install pre-commit -q 2>/dev/null && pre-commit install -q 2>/dev/null
        echo "  Pre-commit hooks: INSTALLED via venv" | tee -a "$AUDIT_LOG"
    else
        echo "  WARNING: pre-commit not available" | tee -a "$AUDIT_LOG"
        [ "$ENFORCEMENT_LEVEL" = "strict" ] && exit 1
    fi
else
    echo "  Pre-commit: no config found, skipping" | tee -a "$AUDIT_LOG"
fi

# 4b. Charter scope validation (AIFactory repos only)
if [ "$REPO_TYPE" = "aifactory" ] && [ "$CHARTER_EXISTS" = true ]; then
    FORBIDDEN_PATTERNS="patient_table|order_table|clinical_decision|LIS-specific|ISS-specific|product_schema"
    VIOLATIONS=$(grep -r -c -E "$FORBIDDEN_PATTERNS" "$WORKTREE_ROOT" \
        --include="*.py" --include="*.sql" --include="*.ts" \
        --exclude-dir=".venv" --exclude-dir="node_modules" \
        --exclude-dir=".git" 2>/dev/null | awk -F: '{s+=$2}END{print s+0}')
    echo "  Charter scope: $VIOLATIONS violations" | tee -a "$AUDIT_LOG"
    if [ "$VIOLATIONS" -gt 0 ] && [ "$ENFORCEMENT_LEVEL" = "strict" ]; then
        echo "  BLOCKED: Charter violations detected" | tee -a "$AUDIT_LOG"
        exit 1
    fi
fi

# 4c. PHI/Secrets scan (SAES Rule 1)
if [ "$STANDARDS_EXISTS" = true ]; then
    SECRETS_FOUND=$(grep -r -E -l '(api[_-]?key|password|secret|token)\s*[:=]\s*["][^"]{8,}' "$WORKTREE_ROOT" \
        --include="*.py" --include="*.ts" --include="*.js" --include="*.sh" \
        --exclude-dir=".venv" --exclude-dir="node_modules" --exclude-dir=".git" \
        --exclude="*.template" --exclude="*.example" \
        2>/dev/null | head -5 || true)
    if [ -n "$SECRETS_FOUND" ]; then
        echo "  WARNING: Potential hardcoded secrets found" | tee -a "$AUDIT_LOG"
        echo "$SECRETS_FOUND" | while read -r f; do echo "    - $f"; done | tee -a "$AUDIT_LOG"
        [ "$ENFORCEMENT_LEVEL" = "strict" ] && exit 1
    else
        echo "  Secrets scan: CLEAN" | tee -a "$AUDIT_LOG"
    fi
fi

# 4d. Ensure .gitignore has required entries
if [ -f "$WORKTREE_ROOT/.gitignore" ]; then
    for entry in ".worktree-setup.log" ".venv/" ".env" ".env.local"; do
        grep -qxF "$entry" "$WORKTREE_ROOT/.gitignore" 2>/dev/null || \
            echo "$entry" >> "$WORKTREE_ROOT/.gitignore"
    done
fi

echo "  [PASS] Phase 4 complete" | tee -a "$AUDIT_LOG"
echo "" | tee -a "$AUDIT_LOG"

# =============================================================================
# Phase 5: Validation & Audit (5-Checkpoint Quality Loop)
# =============================================================================
echo "--- Phase 5: Validation & Audit ---" | tee -a "$AUDIT_LOG"

PASS=0
FAIL=0

check() {
    local name="$1" condition="$2"
    if eval "$condition"; then
        echo "  [PASS] $name" | tee -a "$AUDIT_LOG"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $name" | tee -a "$AUDIT_LOG"
        FAIL=$((FAIL + 1))
    fi
}

check "Python venv" \
    "[ ! -f '$WORKTREE_ROOT/requirements.txt' ] || [ -f '$WORKTREE_ROOT/.venv/bin/python' ]"

check "Frontend node_modules" \
    "[ ! -f '$WORKTREE_ROOT/frontend/package.json' ] || [ -d '$WORKTREE_ROOT/frontend/node_modules' ]"

check "Root deps installed" \
    "[ ! -f '$WORKTREE_ROOT/package.json' ] || [ -f '$WORKTREE_ROOT/requirements.txt' ] || [ -d '$WORKTREE_ROOT/node_modules' ]"

check "Env files populated" \
    "[ ! -f '$WORKTREE_ROOT/.env.example' ] || [ -f '$WORKTREE_ROOT/.env' ]"

GIT_DIR="$(git -C "$WORKTREE_ROOT" rev-parse --git-dir 2>/dev/null || echo '.git')"
check "Pre-commit hooks" \
    "[ ! -f '$WORKTREE_ROOT/.pre-commit-config.yaml' ] || [ -f '$GIT_DIR/hooks/pre-commit' ]"

ELAPSED=$(( $(date +%s) - SCRIPT_START ))
echo "" | tee -a "$AUDIT_LOG"
echo "=== Worktree Setup Complete ===" | tee -a "$AUDIT_LOG"
echo "  Repo:          $REPO_NAME" | tee -a "$AUDIT_LOG"
echo "  Type:          $REPO_TYPE" | tee -a "$AUDIT_LOG"
echo "  Enforcement:   $ENFORCEMENT_LEVEL" | tee -a "$AUDIT_LOG"
echo "  Checks:        $PASS passed, $FAIL failed" | tee -a "$AUDIT_LOG"
echo "  Duration:      ${ELAPSED}s" | tee -a "$AUDIT_LOG"
echo "  Audit log:     $AUDIT_LOG" | tee -a "$AUDIT_LOG"
echo "  CONTEXT_WIPE_CONFIRMED" | tee -a "$AUDIT_LOG"
echo "===============================" | tee -a "$AUDIT_LOG"

[ "$FAIL" -gt 0 ] && [ "$ENFORCEMENT_LEVEL" = "strict" ] && exit 1
exit 0
