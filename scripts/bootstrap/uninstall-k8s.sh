#!/usr/bin/env bash
# ─── uninstall-k8s.sh ──────────────────────────────────────────────────────────
# Cleanly remove all MedinovAI K8s resources from the cluster.
# Preserves Docker Compose infra (postgres, redis, etc.).
#
# Usage:
#   bash scripts/bootstrap/uninstall-k8s.sh
#   bash scripts/bootstrap/uninstall-k8s.sh --context docker-desktop --also-infra
#
# Safe: only deletes medinovai-* namespaces. Does not touch kube-system or Docker Compose.
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
COMPOSE_FILE="$REPO_ROOT/infra/docker/docker-compose.dev.yml"
OVERLAY="$REPO_ROOT/infra/kubernetes/overlays/docker-desktop"

CONTEXT="docker-desktop"
ALSO_INFRA=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --context)     CONTEXT="$2"; shift 2 ;;
        --also-infra)  ALSO_INFRA=true; shift ;;
        *)             echo "Unknown option: $1"; exit 1 ;;
    esac
done

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  MedinovAI — Kubernetes Uninstall"
echo "║  Context: $CONTEXT"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

kubectl config use-context "$CONTEXT" 2>/dev/null || { echo "Context not found: $CONTEXT"; exit 1; }

echo "▸ Removing K8s resources (medinovai-* namespaces)..."

# Delete via kustomize (inverse of apply)
kubectl delete -k "$OVERLAY" --ignore-not-found=true 2>/dev/null || true

# Delete namespaces (this removes everything inside them)
NAMESPACES="medinovai-services medinovai-data medinovai-ai medinovai-monitoring medinovai-system"
for ns in $NAMESPACES; do
    if kubectl get namespace "$ns" &>/dev/null; then
        echo "  Deleting namespace: $ns"
        kubectl delete namespace "$ns" --ignore-not-found=true 2>/dev/null || true
    fi
done

echo "  ✓ K8s resources removed"

if $ALSO_INFRA; then
    echo ""
    echo "▸ Stopping Docker Compose infra..."
    docker compose -f "$COMPOSE_FILE" down
    echo "  ✓ Infra stopped (volumes preserved)"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✓ Uninstall complete."
echo "║  To reinstall: bash scripts/bootstrap/install-k8s.sh"
echo "╚══════════════════════════════════════════════════════════════╝"
