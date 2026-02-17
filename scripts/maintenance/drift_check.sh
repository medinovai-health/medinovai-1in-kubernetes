#!/usr/bin/env bash
# ─── drift_check.sh ──────────────────────────────────────────────────────────
# Detect infrastructure drift across all environments.
#
# Usage:
#   bash scripts/maintenance/drift_check.sh
#   bash scripts/maintenance/drift_check.sh --environment production
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
ENVIRONMENT="${1:---all}"
DRIFT_FOUND=false

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          IaC Drift Detection                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

check_environment() {
    local env="$1"
    local tf_dir="$REPO_ROOT/infra/terraform/environments/$env"

    if [ ! -f "$tf_dir/main.tf" ]; then
        echo "  ⏭ $env — no Terraform config yet"
        return 0
    fi

    echo "▸ Checking $env..."
    cd "$tf_dir"

    if terraform init -backend=false &>/dev/null; then
        local plan_output
        plan_output=$(terraform plan -detailed-exitcode -no-color 2>&1) || local exit_code=$?

        case "${exit_code:-0}" in
            0) echo "  ✓ $env — no drift detected" ;;
            2)
                echo "  ✗ $env — DRIFT DETECTED"
                echo "$plan_output" | head -50
                DRIFT_FOUND=true
                ;;
            *)
                echo "  ⚠ $env — terraform plan failed"
                ;;
        esac
    else
        echo "  ⚠ $env — terraform init failed"
    fi

    cd "$REPO_ROOT"
}

ENVIRONMENTS=("dev" "staging" "production")

if [ "$ENVIRONMENT" != "--all" ]; then
    ENVIRONMENTS=("${ENVIRONMENT#--environment=}")
fi

for env in "${ENVIRONMENTS[@]}"; do
    check_environment "$env"
done

echo ""
if $DRIFT_FOUND; then
    echo "ALERT: Infrastructure drift detected!"
    echo "Run 'make plan ENV=<environment>' for details."
    echo "Run 'make apply ENV=<environment>' to remediate (review plan first!)."
    exit 2
else
    echo "✓ No drift detected across all environments."
fi
