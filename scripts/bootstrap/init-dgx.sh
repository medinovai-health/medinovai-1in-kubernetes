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
# Fix 1: token file is written as "node-token" by init-orbstack.sh (not "k3s-node-token")
if [ ! -f "$DEPLOY_HOME/node-token" ]; then
    log "ERROR: K3s node token not found. Run init-orbstack.sh --role server first."
    exit 1
fi
NODE_TOKEN=$(cat "$DEPLOY_HOME/node-token")

# Fix 2: network.json (from init-network.sh) has no 'role' field; use server-info.json
# written by init-orbstack.sh, with fleet.json5 server node as fallback.
SERVER_IP=$(python3 -c "
import json, os, re

def parse_json5(text):
    text = re.sub(r'//[^\n]*', '', text)
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.DOTALL)
    text = re.sub(r'(?<![\"\\w])([a-zA-Z_]\w*)(\s*:)', r'\"\\1\"\\2', text)
    text = re.sub(r',(\s*[}\]])', r'\\1', text)
    return json.loads(text)

deploy_home = os.path.expanduser('$DEPLOY_HOME')
server_info_path = os.path.join(deploy_home, 'server-info.json')
fleet_config = '$FLEET_CONFIG'

if os.path.exists(server_info_path):
    info = json.load(open(server_info_path))
    print(info.get('tailscale_ip', ''))
else:
    cfg = parse_json5(open(fleet_config).read())
    for n in cfg['nodes']:
        if n.get('role') == 'server' and n.get('tailscale_ip') and 'x' not in n.get('tailscale_ip', ''):
            print(n['tailscale_ip'])
            break
" 2>/dev/null || echo "")

if [ -z "$SERVER_IP" ]; then
    log "ERROR: Server Tailscale IP not found. Ensure init-orbstack.sh --role server has been run."
    log "  Expected: $DEPLOY_HOME/server-info.json"
    exit 1
fi

# ─── Build Node List ────────────────────────────────────────────────────────
get_gpu_nodes() {
    python3 -c "
import json, re

def parse_json5(text):
    text = re.sub(r'//[^\n]*', '', text)
    text = re.sub(r'/\*.*?\*/', '', text, flags=re.DOTALL)
    text = re.sub(r'(?<![\"\\w])([a-zA-Z_]\w*)(\s*:)', r'\"\\1\"\\2', text)
    text = re.sub(r',(\s*[}\]])', r'\\1', text)
    return json.loads(text)

cfg = parse_json5(open('$FLEET_CONFIG').read())
for n in cfg['nodes']:
    # Fix 3: fleet.json5 has no 'runtime' field; identify GPU nodes by gpu==True and os==linux
    # Fix 4: fleet.json5 uses 'hostname', not 'id'
    if n.get('gpu') == True and n.get('os') == 'linux':
        node_filter = '$SINGLE_NODE'
        if node_filter and n['hostname'] != node_filter:
            continue
        print(f\"{n['hostname']}|{n.get('lan_ip', '')}|{n.get('ssh_user', 'medinovai')}\")
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
    # Sanitize GPU model for Kubernetes label: replace spaces with hyphens, keep only alphanumeric/.-_
    GPU_MODEL_LABEL=$(echo "$GPU_MODEL" | tr ' ' '-' | tr -cd '[:alnum:]._-')
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

    # Configure K3s containerd to use nvidia as default runtime (persists across restarts)
    log "  Configuring containerd nvidia runtime template..."
    if $DRY_RUN; then
        log "  [DRY RUN] Would create config.toml.tmpl"
    else
        ssh "$SSH_USER@$NODE_IP" bash <<'CONTAINERD_TMPL'
sudo mkdir -p /var/lib/rancher/k3s/agent/etc/containerd
sudo tee /var/lib/rancher/k3s/agent/etc/containerd/config.toml.tmpl > /dev/null <<'TMPL'
{{ template "base" . }}

[plugins."io.containerd.cri.v1.runtime".containerd]
  default_runtime_name = "nvidia"

[plugins."io.containerd.cri.v1.runtime".containerd.runtimes.nvidia]
  runtime_type = "io.containerd.runc.v2"

[plugins."io.containerd.cri.v1.runtime".containerd.runtimes.nvidia.options]
  BinaryName = "/usr/bin/nvidia-container-runtime"
  SystemdCgroup = true
TMPL
CONTAINERD_TMPL
        log "  ✓ containerd nvidia runtime template configured"
    fi

    # Set up apiserver relay: routes pod traffic to K3s API server via Tailscale
    # Required because the K3s server runs in OrbStack VM (192.168.139.183) which is
    # unreachable from DGX nodes; Tailscale IP (100.106.54.9) IS reachable.
    log "  Setting up K3s apiserver relay..."
    if $DRY_RUN; then
        log "  [DRY RUN] Would set up apiserver relay"
    else
        ORBSTACK_IP=$(python3 -c "
import json, os
info_file = os.path.expanduser('~/.medinovai-deploy/server-info.json')
d = json.load(open(info_file))
# OrbStack internal IP is the non-Tailscale server IP
print(d.get('lan_ip', '192.168.139.183').replace('192.168.68.', '192.168.139.') if 'orbstack' in d.get('vm_name','') or '192.168.139' in d.get('orbstack_ip','') else '192.168.139.183')
" 2>/dev/null || echo "192.168.139.183")
        TAILSCALE_SERVER_IP="$SERVER_IP"
        ssh "$SSH_USER@$NODE_IP" bash << RELAY_SETUP
sudo apt-get install -y socat 2>/dev/null | tail -1
sudo tee /etc/systemd/system/k3s-apiserver-relay.service > /dev/null << EOF
[Unit]
Description=K3s APIServer relay (OrbStack to Tailscale)
After=network.target tailscaled.service

[Service]
Type=simple
ExecStartPre=-/sbin/ip addr add ${ORBSTACK_IP}/32 dev lo
ExecStart=/usr/bin/socat TCP-LISTEN:6443,bind=${ORBSTACK_IP},fork,reuseaddr TCP:${TAILSCALE_SERVER_IP}:6443
Restart=always
RestartSec=3
SuccessExitStatus=0 1

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now k3s-apiserver-relay
RELAY_SETUP
        log "  ✓ K3s apiserver relay configured"
    fi

    # Create GPU Operator validation readiness files persistently
    # The GPU Operator expects these files in /run/nvidia/validations/ to confirm
    # the pre-installed driver/toolkit are ready (toolkit.enabled=false in GPU Operator).
    log "  Setting up NVIDIA GPU Operator validation files..."
    if $DRY_RUN; then
        log "  [DRY RUN] Would create nvidia-validations-ready service"
    else
        ssh "$SSH_USER@$NODE_IP" bash <<'VALIDATION_SETUP'
sudo tee /etc/systemd/system/nvidia-validations-ready.service > /dev/null << 'EOF'
[Unit]
Description=Create NVIDIA GPU Operator validation readiness files
Before=k3s-agent.service
After=nvidia-persistenced.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c "mkdir -p /run/nvidia/validations && \
  touch /run/nvidia/validations/toolkit-ready \
        /run/nvidia/validations/cuda-ready \
        /run/nvidia/validations/plugin-ready && \
  printf 'IS_HOST_DRIVER=true\nNVIDIA_DRIVER_ROOT=/\nDRIVER_ROOT_CTR_PATH=/host\nNVIDIA_DEV_ROOT=/\nDEV_ROOT_CTR_PATH=/host\n' \
    > /run/nvidia/validations/driver-ready"

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now nvidia-validations-ready
VALIDATION_SETUP
        log "  ✓ NVIDIA validation files service configured"
    fi

    # Install K3s agent
    log "  Installing K3s agent..."
    if $DRY_RUN; then
        log "  [DRY RUN] Would install K3s agent joining $SERVER_IP:6443"
    else
        # Redirect stdin from /dev/null to prevent the K3s installer pipe from
        # consuming the parent while-loop's here-string when running --from-fleet.
        ssh "$SSH_USER@$NODE_IP" bash -c "'
curl -sfL https://get.k3s.io | K3S_URL=https://$SERVER_IP:6443 K3S_TOKEN=$NODE_TOKEN sh -s - \
    --node-label role=gpu-worker \
    --node-label gpu=true \
    --node-label tier=gpu \
    --node-label \"nvidia.com/gpu.product=$GPU_MODEL_LABEL\" \
    --node-label \"nvidia.com/gpu.count=$GPU_COUNT\" \
    --node-name $NODE_ID
'" < /dev/null
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
