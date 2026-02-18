#!/usr/bin/env bash
# ─── prerequisites.sh ─────────────────────────────────────────────────────────
# Verify all required tools are installed for MedinovAI on-prem deployment.
#
# Usage:
#   bash scripts/bootstrap/prerequisites.sh
#   bash scripts/bootstrap/prerequisites.sh --json       # Machine-readable output
#   bash scripts/bootstrap/prerequisites.sh --gpu-node   # Check GPU tools too
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

JSON_MODE=false
GPU_NODE=false
while [[ $# -gt 0 ]]; do
    case $1 in
        --json)     JSON_MODE=true; shift ;;
        --gpu-node) GPU_NODE=true; shift ;;
        *)          echo "Unknown option: $1"; exit 1 ;;
    esac
done

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
            orbctl|orb)     version=$(orb version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown") ;;
            kubectl)        version=$(kubectl version --client -o json 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin)['clientVersion']['gitVersion'].lstrip('v'))" 2>/dev/null || echo "unknown") ;;
            helm)           version=$(helm version --short 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown") ;;
            docker)         version=$(docker version --format '{{.Client.Version}}' 2>/dev/null || echo "unknown") ;;
            tailscale)      version=$(tailscale version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown") ;;
            vault)          version=$(vault version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown") ;;
            jq)             version=$(jq --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' || echo "unknown") ;;
            node)           version=$(node --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown") ;;
            python3)        version=$(python3 --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown") ;;
            atlas)          version=$(atlas --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown") ;;
            gh)             version=$(gh --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "unknown") ;;
            k3sup)          version=$(k3sup version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown") ;;
            nvidia-smi)     version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1 || echo "unknown") ;;
            nvidia-ctk)     version=$(nvidia-ctk --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown") ;;
            ssh)            version=$(ssh -V 2>&1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "unknown") ;;
            curl)           version=$(curl --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "unknown") ;;
            *)              version="unknown" ;;
        esac

        if $JSON_MODE; then
            RESULTS+=("{\"tool\": \"$name\", \"status\": \"ok\", \"version\": \"$version\", \"min_version\": \"$min_version\", \"purpose\": \"$purpose\"}")
        else
            printf "  ✓ %-20s %s (min: %s) — %s\n" "$name" "$version" "$min_version" "$purpose"
        fi
        PASS=$((PASS + 1))
    else
        if [ "$required" = "true" ]; then
            if $JSON_MODE; then
                RESULTS+=("{\"tool\": \"$name\", \"status\": \"missing\", \"version\": null, \"min_version\": \"$min_version\", \"purpose\": \"$purpose\"}")
            else
                printf "  ✗ %-20s MISSING (required) — %s\n" "$name" "$purpose"
            fi
            FAIL=$((FAIL + 1))
        else
            if $JSON_MODE; then
                RESULTS+=("{\"tool\": \"$name\", \"status\": \"optional_missing\", \"version\": null, \"min_version\": \"$min_version\", \"purpose\": \"$purpose\"}")
            else
                printf "  ⚠ %-20s MISSING (optional) — %s\n" "$name" "$purpose"
            fi
            WARN=$((WARN + 1))
        fi
    fi
}

detect_os() {
    case "$(uname -s)" in
        Darwin*) echo "macos" ;;
        Linux*)  echo "linux" ;;
        *)       echo "unknown" ;;
    esac
}

OS=$(detect_os)

if ! $JSON_MODE; then
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║     MedinovAI Deploy — On-Prem Prerequisites Check         ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  OS: $(uname -s) $(uname -m)"
    echo ""
    echo "▸ Core tools..."
    echo ""
fi

# ─── Core Tools (all nodes) ──────────────────────────────────────────────────
check_tool "kubectl"    "1.29+"   "Kubernetes cluster management"      true
check_tool "helm"       "3.14+"   "Kubernetes package management"      true
check_tool "docker"     "25+"     "Container building & runtime"       true
check_tool "jq"         "1.7+"    "JSON processing"                    true
check_tool "node"       "22+"     "Atlas runtime & tooling"            true
check_tool "python3"    "3.11+"   "Scripts & automation"               true
check_tool "gh"         "2.0+"    "GitHub CLI"                         true
check_tool "curl"       "8.0+"    "HTTP operations"                    true
check_tool "ssh"        "9.0+"    "Remote node management"             true

# ─── On-Prem Infrastructure Tools ────────────────────────────────────────────
if ! $JSON_MODE; then
    echo ""
    echo "▸ On-prem infrastructure..."
    echo ""
fi

check_tool "tailscale"  "1.60+"   "Mesh networking (Tailscale)"        true
check_tool "vault"      "1.15+"   "Secrets management (HashiCorp)"     true

if [ "$OS" = "macos" ]; then
    check_tool "orb"    "1.0+"    "OrbStack VM runtime (macOS)"        true
else
    check_tool "orb"    "1.0+"    "OrbStack (macOS only)"              false
fi

check_tool "k3sup"      "0.13+"   "K3s cluster bootstrap"             false

# ─── GPU Tools (DGX nodes only) ─────────────────────────────────────────────
if $GPU_NODE; then
    if ! $JSON_MODE; then
        echo ""
        echo "▸ GPU tools (DGX node)..."
        echo ""
    fi
    check_tool "nvidia-smi"  "535+"    "NVIDIA GPU driver"              true
    check_tool "nvidia-ctk"  "1.14+"   "NVIDIA Container Toolkit"       true
fi

# ─── Optional / Enhanced ────────────────────────────────────────────────────
if ! $JSON_MODE; then
    echo ""
    echo "▸ Optional tools..."
    echo ""
fi
check_tool "atlas"      "latest"  "Atlas gateway & agent management"   false

# ─── Results ─────────────────────────────────────────────────────────────────
if $JSON_MODE; then
    JOINED=$(printf ",%s" "${RESULTS[@]}")
    JOINED="${JOINED:1}"
    echo "{\"status\": \"$([ $FAIL -eq 0 ] && echo 'ok' || echo 'error')\", \"os\": \"$OS\", \"gpu_node\": $GPU_NODE, \"passed\": $PASS, \"failed\": $FAIL, \"warnings\": $WARN, \"results\": [$JOINED]}"
else
    echo ""
    echo "────────────────────────────────────────────────────────────────"
    echo "Results: $PASS passed, $FAIL failed, $WARN warnings"
    echo ""

    if [ $FAIL -gt 0 ]; then
        echo "FAIL: $FAIL required tools are missing. Install them before proceeding."
        echo ""
        echo "Quick install guides:"
        echo "  kubectl:    brew install kubectl"
        echo "  helm:       brew install helm"
        echo "  docker:     Install OrbStack (includes Docker)"
        echo "  jq:         brew install jq"
        echo "  node:       brew install node@22"
        echo "  python3:    brew install python@3.12"
        echo "  gh:         brew install gh"
        echo "  tailscale:  brew install tailscale"
        echo "  vault:      brew install hashicorp/tap/vault"
        echo "  orbstack:   brew install orbstack (macOS)"
        echo "  k3sup:      brew install k3sup"
        echo ""
        echo "For GPU nodes (DGX):"
        echo "  nvidia-smi:       Included with NVIDIA drivers"
        echo "  nvidia-ctk:       https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html"
        exit 1
    else
        echo "All required tools are installed."
        if [ $WARN -gt 0 ]; then
            echo "Some optional tools are missing — install them when needed."
        fi
    fi
fi
