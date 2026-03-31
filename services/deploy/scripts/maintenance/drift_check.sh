#!/usr/bin/env bash
# ─── drift_check.sh ──────────────────────────────────────────────────────────
# Detect infrastructure drift: K3s cluster state vs Git manifests (on-prem),
# and Terraform plan drift (cloud environments).
#
# Usage:
#   bash scripts/maintenance/drift_check.sh                  # All checks
#   bash scripts/maintenance/drift_check.sh --k8s-only       # K8s manifests only
#   bash scripts/maintenance/drift_check.sh --terraform-only  # Terraform only
#   bash scripts/maintenance/drift_check.sh --environment dev # Specific TF env
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
ENVIRONMENT="${ENVIRONMENT:---all}"
K8S_ONLY=false
TF_ONLY=false
DRIFT_FOUND=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --k8s-only)         K8S_ONLY=true; shift ;;
        --terraform-only)   TF_ONLY=true; shift ;;
        --environment)      ENVIRONMENT="$2"; shift 2 ;;
        *)                  echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          IaC Drift Detection                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ─── K8s Manifest Drift (Kustomize vs Cluster State) ─────────────────────────
check_k8s_drift() {
    echo "▸ Checking K8s manifest drift (Git vs cluster state)..."
    echo ""

    local kustomize_dirs=(
        "infra/kubernetes/base"
        "infra/kubernetes/services/tier0"
        "infra/kubernetes/services/atlasos"
        "infra/kubernetes/services/atlasos-node-agent"
        "infra/kubernetes/services/atlasos-cluster-brain"
        "infra/kubernetes/services/atlasos-sidecar"
        "infra/kubernetes/vault"
        "infra/kubernetes/external-secrets"
        "infra/kubernetes/monitoring"
    )

    local drifted=0
    local checked=0
    local skipped=0

    for dir in "${kustomize_dirs[@]}"; do
        local full_path="$REPO_ROOT/$dir"
        local name
        name=$(basename "$dir")

        if [ ! -d "$full_path" ] || [ ! -f "$full_path/kustomization.yaml" ]; then
            echo "  ⏭ $name — no kustomization.yaml"
            skipped=$((skipped + 1))
            continue
        fi

        checked=$((checked + 1))

        local desired actual
        desired=$(kubectl kustomize "$full_path" 2>/dev/null || echo "KUSTOMIZE_ERROR")

        if [ "$desired" = "KUSTOMIZE_ERROR" ]; then
            echo "  ⚠ $name — kustomize build failed"
            continue
        fi

        local diff_output
        diff_output=$(echo "$desired" | kubectl diff -f - 2>&1) || true
        local diff_exit=$?

        if [ -z "$diff_output" ] || echo "$diff_output" | grep -q "no changes"; then
            echo "  ✓ $name — no drift"
        elif echo "$diff_output" | grep -q "^diff\|^---\|^+++" 2>/dev/null; then
            echo "  ✗ $name — DRIFT DETECTED"
            echo "$diff_output" | head -20 | sed 's/^/    /'
            if [ "$(echo "$diff_output" | wc -l)" -gt 20 ]; then
                echo "    ... ($(echo "$diff_output" | wc -l | xargs) total lines, truncated)"
            fi
            drifted=$((drifted + 1))
            DRIFT_FOUND=true
        else
            echo "  ✓ $name — no drift"
        fi
    done

    echo ""
    echo "  K8s drift summary: $checked checked, $drifted drifted, $skipped skipped"
}

# ─── Node Health Drift (expected vs actual) ──────────────────────────────────
check_node_drift() {
    echo ""
    echo "▸ Checking node inventory drift (fleet.json5 vs cluster)..."

    local fleet_file="$REPO_ROOT/config/fleet.json5"
    if [ ! -f "$fleet_file" ]; then
        echo "  ⏭ No fleet.json5 — skipping"
        return
    fi

    python3 -c "
import json, subprocess, re

# Read fleet config (strip comments for JSON5 compat)
with open('$fleet_file') as f:
    content = f.read()
content = re.sub(r'//.*?\n', '\n', content)
content = re.sub(r'/\*.*?\*/', '', content, flags=re.DOTALL)
content = re.sub(r',\s*([}\]])', r'\1', content)
try:
    fleet = json.loads(content)
except json.JSONDecodeError:
    print('  ⚠ Could not parse fleet.json5')
    exit(0)

expected_nodes = {n['hostname']: n for n in fleet.get('nodes', [])}

# Get actual cluster nodes
result = subprocess.run(
    ['kubectl', 'get', 'nodes', '-o', 'json'],
    capture_output=True, text=True, timeout=15
)
if result.returncode != 0:
    print('  ⚠ Cannot reach K8s API — skipping node drift check')
    exit(0)

actual = json.loads(result.stdout)
actual_nodes = {}
for node in actual.get('items', []):
    name = node['metadata']['name']
    labels = node['metadata'].get('labels', {})
    conditions = {c['type']: c['status'] for c in node.get('status', {}).get('conditions', [])}
    actual_nodes[name] = {
        'ready': conditions.get('Ready') == 'True',
        'role': labels.get('role', 'unknown'),
        'gpu': labels.get('gpu', 'false'),
    }

# Compare
for name, expected in expected_nodes.items():
    if name not in actual_nodes:
        print(f'  ✗ {name} — MISSING from cluster (expected role: {expected.get(\"role\", \"?\")})')
    else:
        actual = actual_nodes[name]
        if not actual['ready']:
            print(f'  ✗ {name} — NotReady')
        else:
            print(f'  ✓ {name} — Ready (role={actual[\"role\"]}, gpu={actual[\"gpu\"]})')

for name in actual_nodes:
    if name not in expected_nodes:
        print(f'  ⚠ {name} — unexpected node (not in fleet.json5)')
" 2>/dev/null || echo "  ⚠ Node drift check failed"
}

# ─── Terraform Drift ─────────────────────────────────────────────────────────
check_terraform_drift() {
    echo ""
    echo "▸ Checking Terraform drift..."
    echo ""

    local environments=("dev" "staging" "production")
    if [ "$ENVIRONMENT" != "--all" ]; then
        environments=("$ENVIRONMENT")
    fi

    for env in "${environments[@]}"; do
        local tf_dir="$REPO_ROOT/infra/terraform/environments/$env"

        if [ ! -f "$tf_dir/main.tf" ]; then
            echo "  ⏭ $env — no Terraform config yet"
            continue
        fi

        echo "  Checking $env..."
        cd "$tf_dir"

        if terraform init -backend=false &>/dev/null; then
            local plan_output exit_code=0
            plan_output=$(terraform plan -detailed-exitcode -no-color 2>&1) || exit_code=$?

            case "$exit_code" in
                0) echo "  ✓ $env — no drift detected" ;;
                2)
                    echo "  ✗ $env — DRIFT DETECTED"
                    echo "$plan_output" | head -30 | sed 's/^/    /'
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
    done
}

# ─── Run checks based on flags ──────────────────────────────────────────────
if ! $TF_ONLY; then
    check_k8s_drift
    check_node_drift
fi

if ! $K8S_ONLY; then
    check_terraform_drift
fi

echo ""
echo "────────────────────────────────────────────────────────────────"
if $DRIFT_FOUND; then
    echo "ALERT: Infrastructure drift detected!"
    echo ""
    echo "Remediation:"
    echo "  K8s:       kubectl apply -k infra/kubernetes/<component>/"
    echo "  Terraform: make apply ENV=<environment>"
    exit 2
else
    echo "✓ No drift detected."
fi
