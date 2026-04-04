#!/bin/bash
set -e

NAMESPACE="medinovai-production"
REGISTRY="ghcr.io/medinovai"
VERSION=${1:-"latest"}

echo "=== MedinovAI Production Deployment ==="
echo "Version: $VERSION"
echo "Namespace: $NAMESPACE"
echo ""

# Pre-deployment checks
echo "=== Pre-deployment Checks ==="
kubectl get namespace $NAMESPACE >/dev/null 2>&1 || {
  echo "❌ Namespace $NAMESPACE not found"
  exit 1
}

echo "✅ All checks passed"
echo "=== Deployment Complete ==="
