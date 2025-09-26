#!/bin/bash

# Current State Documentation Script
# Documents all existing services, dependencies, and infrastructure

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_deploy() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

# Configuration
DOCUMENTATION_DIR="/Users/dev1/github/medinovai-infrastructure/current-state-documentation"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

log_deploy "Documenting Current System State for Mac Studio Infrastructure Migration"

# Create documentation directory
mkdir -p "$DOCUMENTATION_DIR"

# 1. System Information
log_info "Documenting system information..."
cat > "$DOCUMENTATION_DIR/system-info.md" << EOF
# System Information
Generated: $(date)

## Hardware Specifications
- **Model**: Mac Studio M3 Ultra (Mac15,14)
- **CPU**: 32 cores (24 performance + 8 efficiency)
- **Memory**: 512GB unified memory
- **Storage**: 15TB available (1.5TB used, 13TB free)
- **OS**: macOS 15.6.1 (Darwin 24.6.0)
- **Uptime**: $(uptime)

## Software Stack
- **Docker**: $(docker --version)
- **Kubernetes**: $(kubectl version --client --short 2>/dev/null || echo "Not configured")
- **Ollama**: $(ollama --version 2>/dev/null || echo "Not available")
- **Homebrew**: $(brew --version | head -1)

## Network Configuration
- **Hostname**: $(hostname)
- **IP Address**: $(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -1)
- **Active Ports**: $(netstat -an | grep LISTEN | wc -l) listening ports
EOF

# 2. Docker Services Inventory
log_info "Documenting Docker services..."
cat > "$DOCUMENTATION_DIR/docker-services.md" << EOF
# Docker Services Inventory
Generated: $(date)

## Running Containers
\`\`\`
$(docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}")
\`\`\`

## All Containers
\`\`\`
$(docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}")
\`\`\`

## Docker Images
\`\`\`
$(docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}")
\`\`\`

## Docker Networks
\`\`\`
$(docker network ls)
\`\`\`

## Docker Volumes
\`\`\`
$(docker volume ls)
\`\`\`

## Docker System Information
\`\`\`
$(docker system info)
\`\`\`
EOF

# 3. Port Usage Analysis
log_info "Documenting port usage..."
cat > "$DOCUMENTATION_DIR/port-usage.md" << EOF
# Port Usage Analysis
Generated: $(date)

## Active Listening Ports
\`\`\`
$(netstat -an | grep LISTEN | sort -k4 -n)
\`\`\`

## Port Usage Summary
\`\`\`
$(netstat -an | grep LISTEN | awk '{print $4}' | cut -d: -f2 | sort -n | uniq -c | sort -nr)
\`\`\`

## Port Ranges in Use
- **System Ports (0-1023)**: $(netstat -an | grep LISTEN | awk '{print $4}' | cut -d: -f2 | awk '$1 < 1024' | wc -l) ports
- **User Ports (1024-65535)**: $(netstat -an | grep LISTEN | awk '{print $4}' | cut -d: -f2 | awk '$1 >= 1024' | wc -l) ports
EOF

# 4. Repository Analysis
log_info "Documenting repository structure..."
cat > "$DOCUMENTATION_DIR/repository-analysis.md" << EOF
# Repository Analysis
Generated: $(date)

## MedinovAI Repositories
\`\`\`
$(ls -la /Users/dev1/github/ | grep medinovai | wc -l) MedinovAI repositories found
\`\`\`

## Repository List
\`\`\`
$(ls -la /Users/dev1/github/ | grep medinovai)
\`\`\`

## Repository Sizes
\`\`\`
$(du -sh /Users/dev1/github/medinovai* 2>/dev/null | sort -hr)
\`\`\`

## Total GitHub Directory Size
\`\`\`
$(du -sh /Users/dev1/github/)
\`\`\`
EOF

# 5. Ollama Models Analysis
log_info "Documenting Ollama models..."
cat > "$DOCUMENTATION_DIR/ollama-models.md" << EOF
# Ollama Models Analysis
Generated: $(date)

## Installed Models
\`\`\`
$(ollama list)
\`\`\`

## Model Storage Usage
\`\`\`
$(du -sh ~/.ollama/models/ 2>/dev/null || echo "Models directory not found")
\`\`\`

## Active Ollama Processes
\`\`\`
$(ps aux | grep ollama | grep -v grep)
\`\`\`
EOF

# 6. Service Dependencies
log_info "Documenting service dependencies..."
cat > "$DOCUMENTATION_DIR/service-dependencies.md" << EOF
# Service Dependencies Analysis
Generated: $(date)

## Database Services
- **PostgreSQL**: $(docker ps --filter "name=postgres" --format "{{.Names}} {{.Status}}" || echo "Not running")
- **MongoDB**: $(docker ps --filter "name=mongo" --format "{{.Names}} {{.Status}}" || echo "Not running")
- **Redis**: $(docker ps --filter "name=redis" --format "{{.Names}} {{.Status}}" || echo "Not running")

## AI/ML Services
- **HealthLLM**: $(docker ps --filter "name=healthllm" --format "{{.Names}} {{.Status}}" || echo "Not running")
- **Ollama**: $(docker ps --filter "name=ollama" --format "{{.Names}} {{.Status}}" || echo "Not running")

## Web Services
- **Nginx**: $(docker ps --filter "name=nginx" --format "{{.Names}} {{.Status}}" || echo "Not running")
- **API Gateway**: $(docker ps --filter "name=api-gateway" --format "{{.Names}} {{.Status}}" || echo "Not running")

## Monitoring Services
- **Nginx Proxy Manager**: $(docker ps --filter "name=nginx-proxy-manager" --format "{{.Names}} {{.Status}}" || echo "Not running")
- **Obsidian**: $(docker ps --filter "name=obsidian" --format "{{.Names}} {{.Status}}" || echo "Not running")
EOF

# 7. Network Configuration
log_info "Documenting network configuration..."
cat > "$DOCUMENTATION_DIR/network-config.md" << EOF
# Network Configuration
Generated: $(date)

## Docker Networks
\`\`\`
$(docker network ls)
\`\`\`

## Network Details
\`\`\`
$(docker network inspect $(docker network ls -q) 2>/dev/null | jq '.[] | {Name: .Name, Driver: .Driver, IPAM: .IPAM}' 2>/dev/null || echo "jq not available")
\`\`\`

## Host Network Interfaces
\`\`\`
$(ifconfig | grep -A 1 "flags=")
\`\`\`

## Routing Table
\`\`\`
$(netstat -rn)
\`\`\`
EOF

# 8. Storage Analysis
log_info "Documenting storage configuration..."
cat > "$DOCUMENTATION_DIR/storage-analysis.md" << EOF
# Storage Analysis
Generated: $(date)

## Disk Usage
\`\`\`
$(df -h)
\`\`\`

## Docker Storage Usage
\`\`\`
$(docker system df)
\`\`\`

## Large Directories
\`\`\`
$(du -sh /Users/dev1/* 2>/dev/null | sort -hr | head -20)
\`\`\`

## Docker Volumes Usage
\`\`\`
$(docker system df -v)
\`\`\`
EOF

# 9. Process Analysis
log_info "Documenting running processes..."
cat > "$DOCUMENTATION_DIR/process-analysis.md" << EOF
# Process Analysis
Generated: $(date)

## Top Memory Consumers
\`\`\`
$(ps aux | sort -k4 -nr | head -20)
\`\`\`

## Top CPU Consumers
\`\`\`
$(ps aux | sort -k3 -nr | head -20)
\`\`\`

## Docker-related Processes
\`\`\`
$(ps aux | grep -i docker | grep -v grep)
\`\`\`

## Ollama-related Processes
\`\`\`
$(ps aux | grep -i ollama | grep -v grep)
\`\`\`
EOF

# 10. Configuration Files
log_info "Documenting configuration files..."
cat > "$DOCUMENTATION_DIR/configuration-files.md" << EOF
# Configuration Files
Generated: $(date)

## Docker Configuration
\`\`\`
$(cat ~/.docker/config.json 2>/dev/null || echo "Docker config not found")
\`\`\`

## Kubernetes Configuration
\`\`\`
$(kubectl config view --minify 2>/dev/null || echo "Kubernetes not configured")
\`\`\`

## Shell Configuration
\`\`\`
$(grep -E "(docker|kubectl|ollama)" ~/.zshrc 2>/dev/null || echo "No relevant shell config found")
\`\`\`

## Homebrew Installed Packages
\`\`\`
$(brew list | grep -E "(docker|kubectl|helm|istio|k3d|kind|minikube|ollama)")
\`\`\`
EOF

# 11. Create Summary Report
log_info "Creating summary report..."
cat > "$DOCUMENTATION_DIR/SUMMARY.md" << EOF
# Current State Documentation Summary
Generated: $(date)

## System Overview
- **Hardware**: Mac Studio M3 Ultra (32 cores, 512GB RAM, 15TB storage)
- **OS**: macOS 15.6.1 (Darwin 24.6.0)
- **Docker**: $(docker --version)
- **Active Containers**: $(docker ps -q | wc -l)
- **Active Ports**: $(netstat -an | grep LISTEN | wc -l)
- **MedinovAI Repositories**: $(ls -la /Users/dev1/github/ | grep medinovai | wc -l)
- **Ollama Models**: $(ollama list | wc -l)

## Key Services Running
$(docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}")

## Port Usage Summary
- **System Ports**: $(netstat -an | grep LISTEN | awk '{print $4}' | cut -d: -f2 | awk '$1 < 1024' | wc -l)
- **User Ports**: $(netstat -an | grep LISTEN | awk '{print $4}' | cut -d: -f2 | awk '$1 >= 1024' | wc -l)

## Storage Usage
- **Total Disk**: $(df -h / | awk 'NR==2 {print $2}')
- **Used Disk**: $(df -h / | awk 'NR==2 {print $3}')
- **Available Disk**: $(df -h / | awk 'NR==2 {print $4}')
- **Docker Storage**: $(docker system df | grep "Local Volumes" | awk '{print $4}')

## Migration Readiness
- ✅ System specifications documented
- ✅ Docker services inventoried
- ✅ Port usage analyzed
- ✅ Repository structure documented
- ✅ Ollama models catalogued
- ✅ Service dependencies mapped
- ✅ Network configuration documented
- ✅ Storage usage analyzed
- ✅ Process analysis completed
- ✅ Configuration files documented

## Next Steps
1. Review documentation in: $DOCUMENTATION_DIR/
2. Proceed with Phase 1.3: Security Baseline
3. Begin Phase 2: Kubernetes Cluster Setup
EOF

log_success "🎉 Current state documentation completed!"
echo ""
echo "📊 Documentation Summary:"
echo "  📁 Documentation directory: $DOCUMENTATION_DIR/"
echo "  📄 System information documented"
echo "  🐳 Docker services inventoried"
echo "  🔌 Port usage analyzed"
echo "  📚 Repository structure documented"
echo "  🤖 Ollama models catalogued"
echo "  🔗 Service dependencies mapped"
echo "  🌐 Network configuration documented"
echo "  💾 Storage usage analyzed"
echo "  ⚙️  Process analysis completed"
echo "  📋 Configuration files documented"
echo ""
echo "📖 Review the documentation in: $DOCUMENTATION_DIR/"
echo "📋 Summary report: $DOCUMENTATION_DIR/SUMMARY.md"
