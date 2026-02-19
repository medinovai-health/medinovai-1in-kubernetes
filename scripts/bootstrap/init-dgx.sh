#!/usr/bin/env bash
# ─── init-dgx.sh ─────────────────────────────────────────────────────────────
# Set up DGX/GPU bare-metal servers as K3s worker nodes.
# Installs K3s agent, NVIDIA Container Toolkit, GPU Operator labels.
#
# Usage:
#   bash scripts/bootstrap/init-dgx.sh                            # all DGX nodes from fleet.json5
#   bash scripts/bootstrap/init-dgx.sh --node dgx-1               # single node
#   bash scripts/bootstrap/init-dgx.sh --ip 192.168.68.78 --user medinovai
#   bash scripts/bootstrap/init-dgx.sh --dry-run
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DEPLOY_HOME="$HOME/.medinovai-deploy"
FLEET_CONFIG="${FLEET_CONFIG:-$REPO_ROOT/config/fleet.json5}"
NETWORK_STATE="$DEPLOY_HOME/network.json"

DRY_RUN=false
SINGLE_NODE=""
MANUAL_IP=""
MANUAL_USER="medinovai"

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)     DRY_RUN=true; shift ;;
        --from-fleet)  shift ;;  # Use fleet.json5 (default)
        --node)        SINGLE_NODE="$2"; shift 2 ;;
        --ip)          MANUAL_IP="$2"; shift 2 ;;
        --user)        MANUAL_USER="$2"; shift 2 ;;
        *)             echo "Unknown option: $1"; exit 1 ;;
    esac
done

log() { echo "[$(date -u +%H:%M:%S)] $1"; }

# ─── Load Cluster Info ───────────────────────────────────────────────────────
if [ ! -f "$DEPLOY_HOME/k3s-node-token" ]; then
    log "ERROR: K3s node token not found. Run init-orbstack.sh --role server first."
    exit 1
fi
NODE_TOKEN=$(cat "$DEPLOY_HOME/k3s-node-token")

SERVER_IP=$(python3 -c "
import json
with open('$NETWORK_STATE') as f:
    state = json.load(f)
for n in state['nodes']:
    if n['role'] == 'server' and n.get('tailscale_ip'):
        print(n['tailscale_ip'])
        break
" 2>/dev/null || echo "")

if [ -z "$SERVER_IP" ]; then
    log "ERROR: Server Tailscale IP not found in $NETWORK_STATE"
    exit 1
fi

# ─── Build Node List ────────────────────────────────────────────────────────
get_gpu_nodes() {
    python3 -c "
import json, re
with open('$FLEET_CONFIG') as f:
    txt = re.sub(r'//.*', '', f.read())
    txt = re.sub(r'/\*.*?\*/', '', txt, flags=re.DOTALL)
    cfg = json.loads(txt)
for n in cfg['nodes']:
    if n.get('runtime') == 'bare-metal' and n.get('labels', {}).get('gpu') == 'true':
        node_filter = '$SINGLE_NODE'
        if node_filter and n['id'] != node_filter:
            continue
        print(f\"{n['id']}|{n.get('lan_ip', '')}|{n.get('ssh_user', 'medinovai')}\")
"
}

setup_dgx_node() {
    local NODE_ID="$1"
    local NODE_IP="$2"
    local SSH_USER="$3"

    log ""
    log "━━━ Setting up $NODE_ID ($NODE_IP) ━━━"

    # Test SSH connectivity
    log "  Testing SSH connectivity..."
    if ! ssh -o ConnectTimeout=10 -o BatchMode=yes "$SSH_USER@$NODE_IP" "echo ok" &>/dev/null; then
        log "  ✗ Cannot SSH to $SSH_USER@$NODE_IP"
        log "  Ensure SSH key is authorized: ssh-copy-id $SSH_USER@$NODE_IP"
        return 1
    fi
    log "  ✓ SSH connected"

    # Check NVIDIA driver
    log "  Checking NVIDIA driver..."
    DRIVER_VERSION=$(ssh "$SSH_USER@$NODE_IP" "nvidia-smi --query-gpu=driver_version --format=csv,noheader 2>/dev/null | head -1" || echo "")
    if [ -z "$DRIVER_VERSION" ]; then
        log "  ✗ nvidia-smi not found or no GPU detected"
        log "  Install NVIDIA drivers first: https://docs.nvidia.com/datacenter/tesla/tesla-installation-notes/"
        return 1
    fi
    log "  ✓ NVIDIA driver: $DRIVER_VERSION"

    GPU_COUNT=$(ssh "$SSH_USER@$NODE_IP" "nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | wc -l")
    GPU_MODEL=$(ssh "$SSH_USER@$NODE_IP" "nvidia-smi --query-gpu=name --format=csv,noheader 2>/dev/null | head -1")
    log "  ✓ GPUs: $GPU_COUNT x $GPU_MODEL"

    # Install Tailscale if not present
    log "  Checking Tailscale..."
    TS_STATUS=$(ssh "$SSH_USER@$NODE_IP" "tailscale status 2>/dev/null && echo 'ok' || echo 'missing'" || echo "missing")
    if [ "$TS_STATUS" = "missing" ]; then
        log "  Installing Tailscale..."
        if $DRY_RUN; then
            log "  [DRY RUN] Would install Tailscale"
        else
            ssh "$SSH_USER@$NODE_IP" "curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up"
        fi
    else
        log "  ✓ Tailscale already connected"
    fi

    # Install NVIDIA Container Toolkit
    log "  Checking NVIDIA Container Toolkit..."
    NCT_STATUS=$(ssh "$SSH_USER@$NODE_IP" "command -v nvidia-ctk &>/dev/null && echo 'ok' || echo 'missing'")
    if [ "$NCT_STATUS" = "missing" ]; then
        log "  Installing NVIDIA Container Toolkit..."
        if $DRY_RUN; then
            log "  [DRY RUN] Would install nvidia-container-toolkit"
        else
            ssh "$SSH_USER@$NODE_IP" bash <<'REMOTE_NCT'
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update && sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=containerd
sudo systemctl restart containerd
REMOTE_NCT
        fi
    else
        log "  ✓ NVIDIA Container Toolkit installed"
    fi

    # Install K3s agent
    log "  Installing K3s agent..."
    if $DRY_RUN; then
        log "  [DRY RUN] Would install K3s agent joining $SERVER_IP:6443"
    else
        ssh "$SSH_USER@$NODE_IP" bash -c "'
curl -sfL https://get.k3s.io | K3S_URL=https://$SERVER_IP:6443 K3S_TOKEN=$NODE_TOKEN sh -s - \
    --node-label role=gpu-worker \
    --node-label gpu=true \
    --node-label tier=gpu \
    --node-label \"nvidia.com/gpu.product=$GPU_MODEL\" \
    --node-label \"nvidia.com/gpu.count=$GPU_COUNT\" \
    --node-name $NODE_ID
'"
        log "  ✓ K3s agent installed and joined cluster"
    fi

    log "  ✓ $NODE_ID setup complete"
}

# ─── Main ────────────────────────────────────────────────────────────────────
log "╔══════════════════════════════════════════════════════════════╗"
log "║        MedinovAI Deploy — DGX Node Setup                     ║"
log "╚══════════════════════════════════════════════════════════════╝"

if [ -n "$MANUAL_IP" ]; then
    setup_dgx_node "manual-node" "$MANUAL_IP" "$MANUAL_USER"
else
    NODES=$(get_gpu_nodes)
    if [ -z "$NODES" ]; then
        log "No GPU nodes found in fleet config."
        exit 0
    fi
    while IFS='|' read -r NODE_ID NODE_IP SSH_USER; do
        if [ -z "$NODE_IP" ]; then
            log "WARN: $NODE_ID has no IP configured in fleet.json5"
            continue
        fi
        setup_dgx_node "$NODE_ID" "$NODE_IP" "$SSH_USER"
    done <<< "$NODES"
fi

log ""
log "Verify GPU nodes in cluster:"
log "  kubectl get nodes -l gpu=true"
log "  kubectl describe node <dgx-node> | grep nvidia.com/gpu"
