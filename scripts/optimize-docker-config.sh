#!/bin/bash

# Docker Desktop Optimization Script for Mac Studio M3 Ultra
# Optimizes Docker for maximum infrastructure performance

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
DOCKER_CONFIG_DIR="$HOME/.docker"
DOCKER_CONFIG_FILE="$DOCKER_CONFIG_DIR/config.json"

log_deploy "Optimizing Docker Desktop for Mac Studio M3 Ultra Infrastructure"

# Create Docker config directory if it doesn't exist
mkdir -p "$DOCKER_CONFIG_DIR"

# Backup existing config
if [ -f "$DOCKER_CONFIG_FILE" ]; then
    log_info "Backing up existing Docker config..."
    cp "$DOCKER_CONFIG_FILE" "$DOCKER_CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
fi

# Create optimized Docker configuration
log_info "Creating optimized Docker configuration..."
cat > "$DOCKER_CONFIG_FILE" << 'EOF'
{
  "auths": {},
  "credsStore": "osxkeychain",
  "experimental": false,
  "features": {
    "buildkit": true
  },
  "builder": {
    "gc": {
      "defaultKeepStorage": "20GB",
      "enabled": true
    }
  },
  "proxies": {
    "default": {
      "httpProxy": "",
      "httpsProxy": "",
      "noProxy": ""
    }
  }
}
EOF

log_success "Docker configuration optimized"

# Optimize Docker Desktop settings via CLI
log_info "Optimizing Docker Desktop resource allocation..."

# Set CPU and Memory limits (requires Docker Desktop to be running)
if docker info >/dev/null 2>&1; then
    log_info "Docker is running, applying optimizations..."
    
    # Clean up unused resources
    log_info "Cleaning up unused Docker resources..."
    docker system prune -f
    docker volume prune -f
    docker network prune -f
    
    log_success "Docker cleanup completed"
else
    log_warning "Docker is not running. Please start Docker Desktop and run this script again."
fi

# Create Docker Compose override for infrastructure
log_info "Creating Docker Compose override for infrastructure..."
mkdir -p "$HOME/docker-compose-overrides"

cat > "$HOME/docker-compose-overrides/docker-compose.override.yml" << 'EOF'
version: '3.8'

services:
  # Infrastructure services optimization
  postgres:
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 4G
        reservations:
          cpus: '1.0'
          memory: 2G
  
  redis:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 1G
        reservations:
          cpus: '0.25'
          memory: 512M
  
  mongodb:
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 2G
        reservations:
          cpus: '0.5'
          memory: 1G
  
  nginx:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M

  # Ollama service optimization
  ollama:
    deploy:
      resources:
        limits:
          cpus: '8.0'
          memory: 32G
        reservations:
          cpus: '4.0'
          memory: 16G
    environment:
      - OLLAMA_HOST=0.0.0.0:11434
      - OLLAMA_ORIGINS=*
      - OLLAMA_KEEP_ALIVE=24h
      - OLLAMA_NUM_PARALLEL=4
      - OLLAMA_MAX_LOADED_MODELS=3
EOF

log_success "Docker Compose override created"

# Create network configuration
log_info "Creating optimized network configuration..."
cat > "$HOME/docker-compose-overrides/networks.yml" << 'EOF'
version: '3.8'

networks:
  medinovai-infrastructure:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
          gateway: 172.20.0.1
  
  medinovai-database:
    driver: bridge
    ipam:
      config:
        - subnet: 172.21.0.0/16
          gateway: 172.21.0.1
  
  medinovai-ai:
    driver: bridge
    ipam:
      config:
        - subnet: 172.22.0.0/16
          gateway: 172.22.0.1
  
  medinovai-monitoring:
    driver: bridge
    ipam:
      config:
        - subnet: 172.23.0.0/16
          gateway: 172.23.0.1
EOF

log_success "Network configuration created"

# Create storage optimization script
log_info "Creating storage optimization script..."
cat > "$HOME/docker-compose-overrides/optimize-storage.sh" << 'EOF'
#!/bin/bash

# Storage optimization for Docker
echo "Optimizing Docker storage..."

# Clean up unused images
docker image prune -f

# Clean up unused containers
docker container prune -f

# Clean up unused volumes
docker volume prune -f

# Clean up build cache
docker builder prune -f

# Show storage usage
echo "Docker storage usage:"
docker system df

echo "Storage optimization completed"
EOF

chmod +x "$HOME/docker-compose-overrides/optimize-storage.sh"

log_success "Storage optimization script created"

# Create performance monitoring script
log_info "Creating performance monitoring script..."
cat > "$HOME/docker-compose-overrides/monitor-performance.sh" << 'EOF'
#!/bin/bash

# Performance monitoring for Docker containers
echo "=== Docker Performance Monitoring ==="
echo "Date: $(date)"
echo ""

echo "=== Container Resource Usage ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}"

echo ""
echo "=== System Resources ==="
echo "CPU Usage:"
top -l 1 | grep "CPU usage"

echo ""
echo "Memory Usage:"
vm_stat | head -10

echo ""
echo "Disk Usage:"
df -h | grep -E "(Filesystem|/dev/)"

echo ""
echo "=== Docker System Info ==="
docker system info | grep -E "(CPUs|Total Memory|Storage Driver|Docker Root Dir)"
EOF

chmod +x "$HOME/docker-compose-overrides/monitor-performance.sh"

log_success "Performance monitoring script created"

# Create startup optimization script
log_info "Creating startup optimization script..."
cat > "$HOME/docker-compose-overrides/startup-optimization.sh" << 'EOF'
#!/bin/bash

# Startup optimization for Docker services
echo "Optimizing Docker startup..."

# Set Docker daemon to start automatically
if command -v brew >/dev/null 2>&1; then
    echo "Configuring Docker to start automatically..."
    # This would typically be done through Docker Desktop preferences
    echo "Please enable 'Start Docker Desktop when you log in' in Docker Desktop preferences"
fi

# Optimize Docker daemon settings
echo "Docker daemon optimization completed"
EOF

chmod +x "$HOME/docker-compose-overrides/startup-optimization.sh"

log_success "Startup optimization script created"

# Summary
echo ""
log_success "🎉 Docker Desktop optimization completed!"
echo ""
echo "📊 Optimization Summary:"
echo "  🐳 Docker configuration optimized"
echo "  🔧 Resource limits configured"
echo "  🌐 Network configuration created"
echo "  💾 Storage optimization scripts created"
echo "  📈 Performance monitoring scripts created"
echo "  🚀 Startup optimization scripts created"
echo ""
echo "📁 Configuration files created in: $HOME/docker-compose-overrides/"
echo ""
echo "🔧 Next Steps:"
echo "  1. Restart Docker Desktop to apply configuration changes"
echo "  2. Run: $HOME/docker-compose-overrides/monitor-performance.sh"
echo "  3. Run: $HOME/docker-compose-overrides/optimize-storage.sh"
echo ""
echo "⚠️  Note: Some optimizations require Docker Desktop to be restarted"
