#!/usr/bin/env bash
# =============================================================================
# MedinovAI Agent Installer
# =============================================================================
# Usage (Tailscale-style one-liner):
#   curl -fsSL https://agent.medinovai.com/install.sh | bash
#
# With a join token (for automated node enrollment):
#   curl -fsSL https://agent.medinovai.com/install.sh | \
#     MEDINOVAI_JOIN_TOKEN=<token> MEDINOVAI_ROLE=intern bash
#
# What this script does:
#   1. Detects OS (macOS / Linux) and architecture (arm64 / amd64)
#   2. Checks prerequisites (Python 3.9+, Tailscale)
#   3. Downloads the agent (medinovai_agent.py)
#   4. Installs it to /usr/local/bin/medinovai-agent
#   5. Installs service (launchd on macOS, systemd on Linux)
#   6. Enrolls the machine if MEDINOVAI_JOIN_TOKEN is set
#   7. Starts the agent service
#
# Environment variables:
#   MEDINOVAI_JOIN_TOKEN   - One-time join token from admin (optional, prompted if absent)
#   MEDINOVAI_ROLE         - intern | power-user | dev-machine | aifactory-node (default: dev-machine)
#   MEDINOVAI_COORDINATOR  - Override coordinator URL (auto-discovered if unset)
#   MEDINOVAI_TAGS         - Comma-separated tags (e.g. "india,bengaluru,intern")
#   MEDINOVAI_SKIP_SERVICE - Set to 1 to skip service installation (install binary only)
# =============================================================================

set -euo pipefail

E_VERSION="1.0.0"
E_AGENT_BINARY="/usr/local/bin/medinovai-agent"
E_PLIST_PATH="${HOME}/Library/LaunchAgents/com.medinovai.agent.plist"
E_SYSTEMD_PATH="/etc/systemd/system/medinovai-agent.service"
E_SYSTEMD_USER="${HOME}/.config/systemd/user/medinovai-agent.service"

# Coordinator URLs tried in order
E_COORDINATORS=(
  "https://agent.medinovai.com"
  "https://agent-eu.medinovai.com"
  "http://aifactory.local:8435"
  "http://100.106.54.9:8435"
)

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${BLUE}[medinovai]${RESET} $*"; }
success() { echo -e "${GREEN}[medinovai]${RESET} ✅ $*"; }
warn()    { echo -e "${YELLOW}[medinovai]${RESET} ⚠️  $*"; }
error()   { echo -e "${RED}[medinovai]${RESET} ❌ $*" >&2; exit 1; }

# =============================================================================
# 1. Banner
# =============================================================================

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║     MedinovAI Agent Installer v${E_VERSION}     ║${RESET}"
echo -e "${BOLD}║     MyOnsite Healthcare                  ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""


# =============================================================================
# 2. Detect OS and architecture
# =============================================================================

detect_os() {
  E_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  E_ARCH=$(uname -m)
  case "$E_ARCH" in
    arm64|aarch64) E_ARCH="arm64" ;;
    x86_64|amd64)  E_ARCH="amd64" ;;
    *) error "Unsupported architecture: $E_ARCH" ;;
  esac
  case "$E_OS" in
    darwin) E_OS_DISPLAY="macOS" ;;
    linux)  E_OS_DISPLAY="Linux" ;;
    *) error "Unsupported OS: $E_OS (Windows support via WSL2)" ;;
  esac
  info "Detected: ${E_OS_DISPLAY} ${E_ARCH}"
}

# =============================================================================
# 3. Check prerequisites
# =============================================================================

check_prerequisites() {
  info "Checking prerequisites..."

  # Python 3.9+
  E_PYTHON=""
  for mos_py in python3 python3.12 python3.11 python3.10 python3.9; do
    if command -v "$mos_py" &>/dev/null; then
      mos_ver=$("$mos_py" -c "import sys; print(sys.version_info >= (3,9))" 2>/dev/null)
      if [ "$mos_ver" = "True" ]; then
        E_PYTHON="$mos_py"
        break
      fi
    fi
  done
  [ -z "$E_PYTHON" ] && error "Python 3.9+ required. Install via: brew install python3 (macOS) or apt install python3 (Linux)"
  success "Python: $($E_PYTHON --version)"

  # curl or wget
  if ! command -v curl &>/dev/null && ! command -v wget &>/dev/null; then
    error "curl or wget required"
  fi

  # Tailscale (warn, don't block)
  if ! command -v tailscale &>/dev/null; then
    warn "Tailscale not found. Agent will work on LAN/internet but not Tailscale mesh."
    warn "Install Tailscale: https://tailscale.com/download"
  else
    success "Tailscale: $(tailscale version 2>/dev/null | head -1)"
  fi
}

# =============================================================================
# 4. Find a reachable coordinator
# =============================================================================

find_coordinator() {
  info "Discovering coordinator..."
  E_COORDINATOR="${MEDINOVAI_COORDINATOR:-}"

  if [ -n "$E_COORDINATOR" ]; then
    info "Using specified coordinator: $E_COORDINATOR"
    return
  fi

  for mos_url in "${E_COORDINATORS[@]}"; do
    mos_status=$(curl -sf --max-time 5 "${mos_url}/v1/health" 2>/dev/null | grep -c '"ok"' || true)
    if [ "$mos_status" -gt 0 ]; then
      E_COORDINATOR="$mos_url"
      success "Coordinator found: $E_COORDINATOR"
      return
    fi
  done

  warn "No coordinator reachable right now. Agent will retry at startup."
  E_COORDINATOR="${E_COORDINATORS[0]}"
}


# =============================================================================
# 5. Download and install the agent binary
# =============================================================================

install_agent() {
  info "Downloading MedinovAI Agent v${E_VERSION}..."

  # Try to download from coordinator, fall back to GitHub
  E_AGENT_URL="${E_COORDINATOR}/agent/medinovai_agent.py"
  E_GITHUB_URL="https://raw.githubusercontent.com/medinovai-health/medinovai-deploy/main/infra/medinovai-agent/agent/medinovai_agent.py"

  E_TMP=$(mktemp /tmp/medinovai_agent_XXXXXX.py)

  if curl -sf --max-time 30 "$E_AGENT_URL" -o "$E_TMP" 2>/dev/null; then
    info "Downloaded from coordinator"
  elif curl -sf --max-time 30 "$E_GITHUB_URL" -o "$E_TMP" 2>/dev/null; then
    info "Downloaded from GitHub"
  else
    error "Could not download agent. Check your network connection."
  fi

  # Create wrapper script that calls the right python
  cat > /tmp/medinovai_wrapper.sh << WRAPPER
#!/usr/bin/env bash
exec "${E_PYTHON}" "${E_AGENT_BINARY}.py" "\$@"
WRAPPER

  # Install
  if [ -w "/usr/local/bin" ]; then
    cp "$E_TMP" "${E_AGENT_BINARY}.py"
    chmod 755 "${E_AGENT_BINARY}.py"
    cp /tmp/medinovai_wrapper.sh "$E_AGENT_BINARY"
    chmod 755 "$E_AGENT_BINARY"
  else
    sudo cp "$E_TMP" "${E_AGENT_BINARY}.py"
    sudo chmod 755 "${E_AGENT_BINARY}.py"
    sudo cp /tmp/medinovai_wrapper.sh "$E_AGENT_BINARY"
    sudo chmod 755 "$E_AGENT_BINARY"
  fi

  rm -f "$E_TMP" /tmp/medinovai_wrapper.sh
  success "Agent installed: $E_AGENT_BINARY"
}

# =============================================================================
# 6. Install service
# =============================================================================

install_service_macos() {
  info "Installing macOS LaunchAgent..."

  E_PLIST_URL="${E_COORDINATOR}/service/com.medinovai.agent.plist"
  E_PLIST_GH="https://raw.githubusercontent.com/medinovai-health/medinovai-deploy/main/infra/medinovai-agent/service/com.medinovai.agent.plist"

  mkdir -p "${HOME}/Library/LaunchAgents"
  E_TMP_PLIST=$(mktemp /tmp/medinovai_plist_XXXXXX.plist)

  curl -sf --max-time 10 "$E_PLIST_URL" -o "$E_TMP_PLIST" 2>/dev/null \
    || curl -sf --max-time 10 "$E_PLIST_GH" -o "$E_TMP_PLIST" \
    || error "Could not download plist"

  # Inject real HOME path
  sed -i.bak "s|PLACEHOLDER_HOME|${HOME}|g" "$E_TMP_PLIST"
  cp "$E_TMP_PLIST" "$E_PLIST_PATH"
  rm -f "$E_TMP_PLIST" "${E_TMP_PLIST}.bak"

  # Unload if already loaded, then reload
  launchctl unload "$E_PLIST_PATH" 2>/dev/null || true
  launchctl load "$E_PLIST_PATH"
  success "LaunchAgent installed and loaded"
}

install_service_linux() {
  info "Installing systemd service..."

  E_SVC_URL="${E_COORDINATOR}/service/medinovai-agent.service"
  E_SVC_GH="https://raw.githubusercontent.com/medinovai-health/medinovai-deploy/main/infra/medinovai-agent/service/medinovai-agent.service"
  E_TMP_SVC=$(mktemp /tmp/medinovai_svc_XXXXXX.service)

  curl -sf --max-time 10 "$E_SVC_URL" -o "$E_TMP_SVC" 2>/dev/null \
    || curl -sf --max-time 10 "$E_SVC_GH" -o "$E_TMP_SVC" \
    || error "Could not download service file"

  if [ "$EUID" -eq 0 ]; then
    cp "$E_TMP_SVC" "$E_SYSTEMD_PATH"
    systemctl daemon-reload
    systemctl enable --now medinovai-agent
    success "systemd service installed (system-level)"
  else
    mkdir -p "${HOME}/.config/systemd/user"
    cp "$E_TMP_SVC" "$E_SYSTEMD_USER"
    systemctl --user daemon-reload
    systemctl --user enable --now medinovai-agent
    success "systemd service installed (user-level)"
  fi
  rm -f "$E_TMP_SVC"
}


# =============================================================================
# 7. Enrollment
# =============================================================================

enroll_node() {
  E_JOIN_TOKEN="${MEDINOVAI_JOIN_TOKEN:-}"
  E_ROLE="${MEDINOVAI_ROLE:-dev-machine}"
  E_TAGS="${MEDINOVAI_TAGS:-}"

  if [ -z "$E_JOIN_TOKEN" ]; then
    echo ""
    echo -e "${BOLD}Enrollment${RESET}"
    echo "Enter the join token from your MedinovAI admin."
    echo "(Skip with Ctrl+C — you can enroll later with: medinovai-agent enroll --join-token <TOKEN>)"
    echo ""
    read -r -p "Join token: " E_JOIN_TOKEN
  fi

  if [ -z "$E_JOIN_TOKEN" ]; then
    warn "No join token provided. Skipping enrollment."
    warn "Enroll later: medinovai-agent enroll --join-token <TOKEN>"
    return
  fi

  # Select role interactively if not set via env
  if [ "${MEDINOVAI_ROLE:-}" = "" ]; then
    echo ""
    echo "Select node role:"
    echo "  1) intern        - AI intern workstation (tier-1 models)"
    echo "  2) power-user    - Senior dev / power user (tier-2 models)"
    echo "  3) dev-machine   - General dev machine (default)"
    echo "  4) aifactory-node - Dedicated inference node (all tiers)"
    read -r -p "Choice [3]: " mos_choice
    case "$mos_choice" in
      1) E_ROLE="intern" ;;
      2) E_ROLE="power-user" ;;
      4) E_ROLE="aifactory-node" ;;
      *) E_ROLE="dev-machine" ;;
    esac
  fi

  info "Enrolling as role: ${E_ROLE}..."
  mos_enroll_args=(
    "--join-token" "$E_JOIN_TOKEN"
    "--coordinator" "$E_COORDINATOR"
    "--role" "$E_ROLE"
  )
  [ -n "$E_TAGS" ] && mos_enroll_args+=("--tags" "$E_TAGS")

  "$E_AGENT_BINARY" enroll "${mos_enroll_args[@]}" \
    || warn "Enrollment failed — agent will retry when service starts"
}

# =============================================================================
# 8. Main
# =============================================================================

main() {
  detect_os
  check_prerequisites
  find_coordinator
  install_agent

  if [ "${MEDINOVAI_SKIP_SERVICE:-0}" != "1" ]; then
    case "$E_OS" in
      darwin) install_service_macos ;;
      linux)  install_service_linux ;;
    esac
  fi

  enroll_node

  echo ""
  echo -e "${BOLD}${GREEN}╔══════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}${GREEN}║  MedinovAI Agent installed! 🎉       ║${RESET}"
  echo -e "${BOLD}${GREEN}╚══════════════════════════════════════╝${RESET}"
  echo ""
  echo "  Status:    medinovai-agent status"
  echo "  Logs:      tail -f ~/.medinovai/agent.log"
  echo "  Dashboard: https://agent.medinovai.com/dashboard"
  echo ""
}

main "$@"
