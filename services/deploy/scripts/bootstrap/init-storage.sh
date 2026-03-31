#!/usr/bin/env bash
# ─── init-storage.sh ──────────────────────────────────────────────────────────
# Install Longhorn distributed storage for the K3s cluster.
#
# Usage:
#   bash scripts/bootstrap/init-storage.sh
#   bash scripts/bootstrap/init-storage.sh --replicas 2
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

REPLICAS=2

while [[ $# -gt 0 ]]; do
    case $1 in
        --replicas) REPLICAS="$2"; shift 2 ;;
        *)          echo "Unknown option: $1"; exit 1 ;;
    esac
done

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1"; }

log "╔══════════════════════════════════════════════════════════════╗"
log "║     MedinovAI Deploy — Longhorn Storage Setup                ║"
log "╚══════════════════════════════════════════════════════════════╝"

# ─── Check if Longhorn is already installed ──────────────────────────────────
if helm list -n longhorn-system 2>/dev/null | grep -q "longhorn"; then
    log "Longhorn already installed. Checking status..."
    kubectl get pods -n longhorn-system --no-headers 2>/dev/null | head -5
    log "Use 'helm upgrade' to update. Skipping install."
    exit 0
fi

# ─── Prerequisites check ────────────────────────────────────────────────────
log "Checking Longhorn prerequisites on nodes..."
for node in $(kubectl get nodes -o jsonpath='{.items[*].metadata.name}'); do
    log "  Node: $node"
done

# ─── Install Longhorn ───────────────────────────────────────────────────────
log "Adding Longhorn Helm repo..."
helm repo add longhorn https://charts.longhorn.io 2>/dev/null || true
helm repo update longhorn 2>/dev/null

log "Installing Longhorn (replicas: $REPLICAS)..."
helm install longhorn longhorn/longhorn \
    --namespace longhorn-system \
    --create-namespace \
    --set defaultSettings.defaultReplicaCount="$REPLICAS" \
    --set defaultSettings.defaultDataLocality="best-effort" \
    --set defaultSettings.storageMinimalAvailablePercentage=15 \
    --set defaultSettings.backupTarget="" \
    --set defaultSettings.createDefaultDiskLabeledNodes=true \
    --set persistence.defaultClassReplicaCount="$REPLICAS" \
    --set ingress.enabled=false \
    --wait --timeout 5m

# ─── Set as default StorageClass ─────────────────────────────────────────────
log "Setting Longhorn as default StorageClass..."

kubectl get storageclass -o name 2>/dev/null | while read -r sc; do
    sc_name=$(echo "$sc" | sed 's|storageclass.storage.k8s.io/||')
    if [ "$sc_name" != "longhorn" ]; then
        kubectl patch "$sc" -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}' 2>/dev/null || true
    fi
done

kubectl patch storageclass longhorn -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}' 2>/dev/null || true

log "Longhorn is now the default StorageClass."

# ─── Verify ─────────────────────────────────────────────────────────────────
log ""
log "Storage setup complete."
log "  Namespace:    longhorn-system"
log "  Replicas:     $REPLICAS"
log "  Default SC:   longhorn"
log ""
log "Verify: kubectl get sc && kubectl get pods -n longhorn-system"
