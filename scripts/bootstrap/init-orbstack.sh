#!/usr/bin/env bash
# ─── init-orbstack.sh ─────────────────────────────────────────────────────────
# Set up K3s via OrbStack on macOS nodes.
#
# Usage:
#   bash scripts/bootstrap/init-orbstack.sh --role server   # Mac Studio (control plane)
#   bash scripts/bootstrap/init-orbstack.sh --role agent     # MacBook Pro (worker)
#   bash scripts/bootstrap/init-orbstack.sh --role server --vm-name k3s-server
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DEPLOY_HOME="${DEPLOY_HOME:-$HOME/.medinovai-deploy}"
NETWORK_FILE="$DEPLOY_HOME/network.json"

ROLE=""
VM_NAME=""
SERVER_URL=""
SERVER_TOKEN=""
K3S_EXTRA_ARGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --role)          ROLE="$2"; shift 2 ;;
        --vm-name)       VM_NAME="$2"; shift 2 ;;
        --server-url)    SERVER_URL="$2"; shift 2 ;;
        --server-token)  SERVER_TOKEN="$2"; shift 2 ;;
        --k3s-args)      K3S_EXTRA_ARGS="$2"; shift 2 ;;
        *)               echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [ -z "$ROLE" ]; then
    echo "ERROR: --role is required (server|agent)"
    echo "Usage: bash scripts/bootstrap/init-orbstack.sh --role server"
    exit 1
fi

mkdir -p "$DEPLOY_HOME"

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1"; }

# ─── Step 1: Verify OrbStack ────────────────────────────────────────────────
log "Checking OrbStack..."
if ! command -v orb &>/dev/null; then
    log "ERROR: OrbStack not found. Install from https://orbstack.dev or: brew install orbstack"
    exit 1
fi

ORB_VERSION=$(orb version 2>/dev/null || echo "unknown")
log "  OrbStack version: $ORB_VERSION"

# ─── Step 2: Get Tailscale IP ───────────────────────────────────────────────
MY_TS_IP=$(tailscale ip -4 2>/dev/null || echo "")
MY_LAN_IP=$(ipconfig getifaddr en0 2>/dev/null || echo "")
log "  Tailscale IP: ${MY_TS_IP:-not available}"
log "  LAN IP: ${MY_LAN_IP:-not available}"

# ─── Step 3: Create or reuse OrbStack VM ────────────────────────────────────
if [ "$ROLE" = "server" ]; then
    VM_NAME="${VM_NAME:-k3s-server}"
elif [ "$ROLE" = "agent" ]; then
    VM_NAME="${VM_NAME:-k3s-worker}"
fi

EXISTING_VM=$(orb list 2>/dev/null | grep -c "$VM_NAME" || echo "0")
if [ "$EXISTING_VM" -gt 0 ]; then
    log "VM '$VM_NAME' already exists. Reusing."
else
    log "Creating OrbStack VM: $VM_NAME (Ubuntu)..."
    orb create ubuntu "$VM_NAME"
    log "  VM created."
fi

log "Starting VM if not running..."
orb start "$VM_NAME" 2>/dev/null || true
sleep 2

# ─── Step 4: Install K3s inside the VM ──────────────────────────────────────
if [ "$ROLE" = "server" ]; then
    log "Installing K3s SERVER in VM '$VM_NAME'..."

    TLS_SAN_ARGS=""
    [ -n "$MY_TS_IP" ] && TLS_SAN_ARGS="--tls-san $MY_TS_IP"
    [ -n "$MY_LAN_IP" ] && TLS_SAN_ARGS="$TLS_SAN_ARGS --tls-san $MY_LAN_IP"

    orb run -m "$VM_NAME" bash -c "
        if command -v k3s &>/dev/null; then
            echo 'K3s already installed.'
        else
            curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='server' sh -s - \
                $TLS_SAN_ARGS \
                --node-label role=control-plane \
                --node-label gpu=false \
                --node-label os=macos \
                --write-kubeconfig-mode 644 \
                --disable traefik \
                $K3S_EXTRA_ARGS
        fi
    "

    log "Extracting kubeconfig and node token..."
    mkdir -p "$DEPLOY_HOME"

    orb run -m "$VM_NAME" cat /etc/rancher/k3s/k3s.yaml > "$DEPLOY_HOME/kubeconfig.yaml" 2>/dev/null

    VM_IP=$(orb run -m "$VM_NAME" hostname -I 2>/dev/null | awk '{print $1}')

    if [ -n "$MY_TS_IP" ]; then
        python3 -c "
import yaml, sys
with open('$DEPLOY_HOME/kubeconfig.yaml') as f:
    kc = yaml.safe_load(f)
for cluster in kc.get('clusters', []):
    server = cluster.get('cluster', {}).get('server', '')
    cluster['cluster']['server'] = server.replace('127.0.0.1', '$MY_TS_IP').replace('$VM_IP', '$MY_TS_IP')
with open('$DEPLOY_HOME/kubeconfig.yaml', 'w') as f:
    yaml.dump(kc, f, default_flow_style=False)
print('  Updated kubeconfig server to use Tailscale IP: $MY_TS_IP')
" 2>/dev/null || log "  WARN: Could not update kubeconfig with Tailscale IP. Update manually."
    fi

    orb run -m "$VM_NAME" cat /var/lib/rancher/k3s/server/node-token > "$DEPLOY_HOME/node-token" 2>/dev/null
    chmod 600 "$DEPLOY_HOME/node-token" "$DEPLOY_HOME/kubeconfig.yaml"

    log ""
    log "K3s server installed successfully."
    log "  Kubeconfig: $DEPLOY_HOME/kubeconfig.yaml"
    log "  Node token: $DEPLOY_HOME/node-token"
    log ""
    log "Export kubeconfig:"
    log "  export KUBECONFIG=$DEPLOY_HOME/kubeconfig.yaml"
    log ""
    log "Join worker nodes with:"
    log "  bash scripts/bootstrap/init-orbstack.sh --role agent \\"
    log "    --server-url https://${MY_TS_IP:-<TAILSCALE_IP>}:6443 \\"
    log "    --server-token \$(cat $DEPLOY_HOME/node-token)"

    # Save server info for other scripts
    python3 -c "
import json
info = {
    'role': 'server',
    'vm_name': '$VM_NAME',
    'tailscale_ip': '$MY_TS_IP',
    'lan_ip': '$MY_LAN_IP',
    'k3s_url': 'https://${MY_TS_IP:-127.0.0.1}:6443',
    'kubeconfig': '$DEPLOY_HOME/kubeconfig.yaml',
    'node_token_path': '$DEPLOY_HOME/node-token'
}
with open('$DEPLOY_HOME/server-info.json', 'w') as f:
    json.dump(info, f, indent=2)
" 2>/dev/null

elif [ "$ROLE" = "agent" ]; then
    # Resolve server URL and token
    if [ -z "$SERVER_URL" ]; then
        if [ -f "$DEPLOY_HOME/server-info.json" ]; then
            SERVER_URL=$(python3 -c "import json; print(json.load(open('$DEPLOY_HOME/server-info.json'))['k3s_url'])" 2>/dev/null || "")
        fi
    fi
    if [ -z "$SERVER_TOKEN" ]; then
        if [ -f "$DEPLOY_HOME/node-token" ]; then
            SERVER_TOKEN=$(cat "$DEPLOY_HOME/node-token")
        fi
    fi

    if [ -z "$SERVER_URL" ] || [ -z "$SERVER_TOKEN" ]; then
        log "ERROR: --server-url and --server-token are required for agent role."
        log "  Get these from the server node: cat ~/.medinovai-deploy/server-info.json"
        exit 1
    fi

    log "Installing K3s AGENT in VM '$VM_NAME'..."
    log "  Server: $SERVER_URL"

    orb run -m "$VM_NAME" bash -c "
        if command -v k3s &>/dev/null; then
            echo 'K3s already installed.'
        else
            curl -sfL https://get.k3s.io | K3S_URL='$SERVER_URL' K3S_TOKEN='$SERVER_TOKEN' sh -s - \
                --node-label role=worker \
                --node-label gpu=false \
                --node-label os=macos \
                $K3S_EXTRA_ARGS
        fi
    "

    log ""
    log "K3s agent installed. Node should appear in cluster shortly."
    log "  Verify: kubectl get nodes"
else
    log "ERROR: Invalid role '$ROLE'. Must be 'server' or 'agent'."
    exit 1
fi
