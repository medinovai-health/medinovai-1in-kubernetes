#!/usr/bin/env bash
# ─── init-network.sh ──────────────────────────────────────────────────────────
# Set up Tailscale mesh networking for the on-prem K3s cluster.
#
# Usage:
#   bash scripts/bootstrap/init-network.sh
#   bash scripts/bootstrap/init-network.sh --verify-only
#   bash scripts/bootstrap/init-network.sh --advertise-routes
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DEPLOY_HOME="${DEPLOY_HOME:-$HOME/.medinovai-deploy}"
FLEET_CONFIG="$REPO_ROOT/config/fleet.json5"
NETWORK_OUT="$DEPLOY_HOME/network.json"
VERIFY_ONLY=false
ADVERTISE_ROUTES=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --verify-only)       VERIFY_ONLY=true; shift ;;
        --advertise-routes)  ADVERTISE_ROUTES=true; shift ;;
        *)                   echo "Unknown option: $1"; exit 1 ;;
    esac
done

mkdir -p "$DEPLOY_HOME"

log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1"; }

K3S_POD_CIDR="10.42.0.0/16"
K3S_SVC_CIDR="10.43.0.0/16"

# ─── Step 1: Check Tailscale is running ──────────────────────────────────────
log "Checking Tailscale status..."
if ! command -v tailscale &>/dev/null; then
    log "ERROR: tailscale CLI not found. Install with: brew install tailscale"
    exit 1
fi

TS_STATUS=$(tailscale status --json 2>/dev/null || echo '{"BackendState":"Stopped"}')
BACKEND_STATE=$(echo "$TS_STATUS" | python3 -c "import sys,json; print(json.load(sys.stdin).get('BackendState','Unknown'))" 2>/dev/null || echo "Unknown")

if [ "$BACKEND_STATE" != "Running" ]; then
    log "Tailscale is not running (state: $BACKEND_STATE). Starting..."
    if [ "$(uname -s)" = "Darwin" ]; then
        open -a Tailscale 2>/dev/null || true
        sleep 3
    else
        sudo systemctl start tailscaled 2>/dev/null || sudo tailscaled &
        sleep 2
    fi
    tailscale up --accept-routes 2>/dev/null || log "WARN: tailscale up may need manual auth"
fi

# ─── Step 2: Get this node's Tailscale IP ────────────────────────────────────
log "Getting Tailscale IP for this node..."
MY_TS_IP=$(tailscale ip -4 2>/dev/null || echo "")
MY_HOSTNAME=$(hostname -s)

if [ -z "$MY_TS_IP" ]; then
    log "ERROR: Could not get Tailscale IPv4 address. Is Tailscale authenticated?"
    log "Run: tailscale up"
    exit 1
fi
log "  This node: $MY_HOSTNAME -> $MY_TS_IP"

# ─── Step 3: Discover other nodes on tailnet ─────────────────────────────────
log "Discovering nodes on tailnet..."
PEERS=$(tailscale status --json 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
peers = data.get('Peer', {})
nodes = []
for key, peer in peers.items():
    if peer.get('Online', False):
        ips = peer.get('TailscaleIPs', [])
        ipv4 = next((ip for ip in ips if '.' in ip), '')
        nodes.append({
            'hostname': peer.get('HostName', ''),
            'tailscale_ip': ipv4,
            'os': peer.get('OS', ''),
            'online': True
        })
myself = {
    'hostname': data.get('Self', {}).get('HostName', '$MY_HOSTNAME'),
    'tailscale_ip': '$MY_TS_IP',
    'os': data.get('Self', {}).get('OS', '$(uname -s | tr '[:upper:]' '[:lower:]')'),
    'online': True
}
nodes.insert(0, myself)
print(json.dumps(nodes, indent=2))
" 2>/dev/null || echo "[]")

NODE_COUNT=$(echo "$PEERS" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null || echo "0")
log "  Found $NODE_COUNT node(s) on tailnet"

# ─── Step 4: Advertise K3s routes (control plane node only) ─────────────────
if $ADVERTISE_ROUTES; then
    log "Advertising K3s routes from this node..."
    tailscale up --advertise-routes="$K3S_POD_CIDR,$K3S_SVC_CIDR" --accept-routes 2>/dev/null
    log "  Advertised: $K3S_POD_CIDR, $K3S_SVC_CIDR"
    log "  Other nodes must run: tailscale up --accept-routes"
fi

# ─── Step 5: Verify connectivity ────────────────────────────────────────────
if $VERIFY_ONLY || true; then
    log "Verifying mesh connectivity..."
    echo "$PEERS" | python3 -c "
import sys, json, subprocess
nodes = json.load(sys.stdin)
for node in nodes[1:]:  # skip self
    ip = node['tailscale_ip']
    hostname = node['hostname']
    result = subprocess.run(['ping', '-c', '1', '-W', '2', ip], capture_output=True)
    status = 'reachable' if result.returncode == 0 else 'UNREACHABLE'
    print(f'  {hostname} ({ip}): {status}')
" 2>/dev/null || log "  (connectivity check skipped — no peers or python3 error)"
fi

# ─── Step 6: Write network.json ─────────────────────────────────────────────
log "Writing network config to $NETWORK_OUT..."
python3 -c "
import json, datetime
nodes = json.loads('''$PEERS''')

network = {
    'generated': datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ'),
    'tailscale_mesh': True,
    'k3s_pod_cidr': '$K3S_POD_CIDR',
    'k3s_svc_cidr': '$K3S_SVC_CIDR',
    'nodes': nodes
}

with open('$NETWORK_OUT', 'w') as f:
    json.dump(network, f, indent=2)
print(f'  Wrote {len(nodes)} node(s) to $NETWORK_OUT')
" 2>/dev/null

log "Network setup complete."
log ""
log "Next steps:"
log "  1. Ensure all nodes have Tailscale running: tailscale up --accept-routes"
log "  2. On the control plane node, run: bash scripts/bootstrap/init-network.sh --advertise-routes"
log "  3. Proceed to K3s setup: bash scripts/bootstrap/init-orbstack.sh --role server"
