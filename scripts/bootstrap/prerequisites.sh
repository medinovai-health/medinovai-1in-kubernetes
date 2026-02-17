#!/usr/bin/env bash
# ─── prerequisites.sh ─────────────────────────────────────────────────────────
# Verify all required tools are installed for MedinovAI Deploy operations.
#
# Usage:
#   bash scripts/bootstrap/prerequisites.sh
#   bash scripts/bootstrap/prerequisites.sh --json   # Machine-readable output
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

JSON_MODE=false
[[ "${1:-}" == "--json" ]] && JSON_MODE=true

PASS=0
FAIL=0
WARN=0
RESULTS=()

check_tool() {
    local name="$1"
    local min_version="$2"
    local purpose="$3"
    local required="${4:-true}"

    if command -v "$name" &>/dev/null; then
        local version
        case "$name" in
            terraform) version=$(terraform version -json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['terraform_version'])" 2>/dev/null || terraform version | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+') ;;
            kubectl) version=$(kubectl version --client -o json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['clientVersion']['gitVersion'].lstrip('v'))" 2>/dev/null || echo "unknown") ;;
            helm) version=$(helm version --short 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown") ;;
            docker) version=$(docker version --format '{{.Client.Version}}' 2>/dev/null || echo "unknown") ;;
            aws) version=$(aws --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown") ;;
            gcloud) version=$(gcloud version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown") ;;
            az) version=$(az version 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['azure-cli'])" 2>/dev/null || echo "unknown") ;;
            jq) version=$(jq --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' || echo "unknown") ;;
            node) version=$(node --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown") ;;
            python3) version=$(python3 --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown") ;;
            atlas) version=$(atlas --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown") ;;
            gh) version=$(gh --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown") ;;
            *) version="unknown" ;;
        esac

        if $JSON_MODE; then
            RESULTS+=("{\"tool\": \"$name\", \"status\": \"ok\", \"version\": \"$version\", \"min_version\": \"$min_version\", \"purpose\": \"$purpose\"}")
        else
            printf "  ✓ %-14s %s (min: %s) — %s\n" "$name" "$version" "$min_version" "$purpose"
        fi
        PASS=$((PASS + 1))
    else
        if [ "$required" = "true" ]; then
            if $JSON_MODE; then
                RESULTS+=("{\"tool\": \"$name\", \"status\": \"missing\", \"version\": null, \"min_version\": \"$min_version\", \"purpose\": \"$purpose\"}")
            else
                printf "  ✗ %-14s MISSING (required) — %s\n" "$name" "$purpose"
            fi
            FAIL=$((FAIL + 1))
        else
            if $JSON_MODE; then
                RESULTS+=("{\"tool\": \"$name\", \"status\": \"optional_missing\", \"version\": null, \"min_version\": \"$min_version\", \"purpose\": \"$purpose\"}")
            else
                printf "  ⚠ %-14s MISSING (optional) — %s\n" "$name" "$purpose"
            fi
            WARN=$((WARN + 1))
        fi
    fi
}

if ! $JSON_MODE; then
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║          MedinovAI Deploy — Prerequisites Check             ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "▸ Checking required tools..."
    echo ""
fi

# ─── Required Tools ──────────────────────────────────────────────────────────
check_tool "terraform"  "1.7+"    "Infrastructure provisioning"        true
check_tool "kubectl"    "1.29+"   "Kubernetes cluster management"      true
check_tool "helm"       "3.14+"   "Kubernetes package management"      true
check_tool "docker"     "25+"     "Container building & runtime"       true
check_tool "jq"         "1.7+"    "JSON processing"                    true
check_tool "node"       "22+"     "Atlas runtime & tooling"            true
check_tool "python3"    "3.11+"   "Scripts & automation"               true
check_tool "gh"         "2.0+"    "GitHub CLI"                         true

# ─── Optional Tools (cloud-specific) ─────────────────────────────────────────
if ! $JSON_MODE; then
    echo ""
    echo "▸ Checking cloud CLIs (at least one required)..."
    echo ""
fi
check_tool "aws"        "2.0+"    "AWS cloud operations"               false
check_tool "gcloud"     "400+"    "Google Cloud operations"            false
check_tool "az"         "2.50+"   "Azure cloud operations"             false

# ─── Optional Tools (enhanced operations) ────────────────────────────────────
if ! $JSON_MODE; then
    echo ""
    echo "▸ Checking optional tools..."
    echo ""
fi
check_tool "atlas"      "latest"  "Atlas gateway & agent management"   false

# ─── Results ─────────────────────────────────────────────────────────────────
if $JSON_MODE; then
    JOINED=$(printf ",%s" "${RESULTS[@]}")
    JOINED="${JOINED:1}"
    echo "{\"status\": \"$([ $FAIL -eq 0 ] && echo 'ok' || echo 'error')\", \"passed\": $PASS, \"failed\": $FAIL, \"warnings\": $WARN, \"results\": [$JOINED]}"
else
    echo ""
    echo "────────────────────────────────────────────────────────────────"
    echo "Results: $PASS passed, $FAIL failed, $WARN warnings"
    echo ""

    if [ $FAIL -gt 0 ]; then
        echo "FAIL: $FAIL required tools are missing. Install them before proceeding."
        echo ""
        echo "Quick install guides:"
        echo "  terraform:  https://developer.hashicorp.com/terraform/install"
        echo "  kubectl:    https://kubernetes.io/docs/tasks/tools/"
        echo "  helm:       https://helm.sh/docs/intro/install/"
        echo "  docker:     https://docs.docker.com/get-docker/"
        echo "  jq:         brew install jq"
        echo "  node:       https://nodejs.org/ (22 LTS)"
        echo "  python3:    https://www.python.org/downloads/"
        echo "  gh:         brew install gh"
        exit 1
    else
        echo "All required tools are installed."
        if [ $WARN -gt 0 ]; then
            echo "Some optional tools are missing — install them when needed."
        fi
    fi
fi
