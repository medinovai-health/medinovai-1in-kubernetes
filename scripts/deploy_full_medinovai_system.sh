#!/bin/bash

#####################################################################
# Complete MedinovAI System Deployment
# Deploy medinovaios and all dependent modules
#####################################################################

set -euo pipefail

LOG_DIR="/Users/dev1/github/medinovai-infrastructure/logs/full-deployment"
mkdir -p "$LOG_DIR"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_DIR/deployment.log"
}

log_success() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1" | tee -a "$LOG_DIR/deployment.log"
}

log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1" | tee -a "$LOG_DIR/deployment.log"
}

cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║       MEDINOVAI COMPLETE SYSTEM DEPLOYMENT                       ║
║       medinovaios + All Dependent Modules                        ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF

log "Starting complete MedinovAI system deployment..."

# Deployment order based on dependencies
DEPLOYMENT_ORDER=(
    # Tier 1: Core Infrastructure
    "medinovai-core-platform"
    "medinovai-configuration-management"
    
    # Tier 2: Security & Auth
    "MedinovAI-security"
    "medinovai-authentication"
    "medinovai-authorization"
    "medinovai-audit-logging"
    
    # Tier 3: Data Layer
    "medinovai-data-services"
    "medinovai-DataOfficer"
    
    # Tier 4: Core Services
    "medinovai-api-gateway"
    "medinovai-healthcare-utilities"
    "medinovai-integration-services"
    
    # Tier 5: Business Services
    "medinovai-clinical-services"
    "medinovai-compliance-services"
    "medinovai-billing"
    
    # Tier 6: AI/ML Services
    "medinovai-healthLLM"
    "medinovai-AI-standards"
    "MedinovAI-AI-Standards-1"
    
    # Tier 7: Application Services
    "medinovai-dashboard"
    "medinovai-ui"
    "medinovai-frontend"
    
    # Tier 8: Supporting Services
    "medinovai-monitoring"
    "medinovai-alerting-services"
    "medinovai-backup-services"
)

deploy_service() {
    local service=$1
    local service_path="/Users/dev1/github/$service"
    
    log "Deploying $service..."
    
    if [ ! -d "$service_path" ]; then
        log_error "Service directory not found: $service_path"
        return 1
    fi
    
    cd "$service_path"
    
    # Check for docker-compose
    if [ -f "docker-compose.yml" ]; then
        log "Found docker-compose.yml for $service"
        docker-compose up -d
        log_success "$service deployed via docker-compose"
        return 0
    fi
    
    # Check for Kubernetes manifests
    if [ -d "k8s" ]; then
        log "Found k8s manifests for $service"
        kubectl apply -f k8s/ -n medinovai
        log_success "$service deployed to Kubernetes"
        return 0
    fi
    
    # Check for Dockerfile
    if [ -f "Dockerfile" ]; then
        log "Found Dockerfile for $service"
        docker build -t "medinovai/$service:latest" .
        docker run -d --name "$service" \
            --network medinovai-infrastructure_medinovai-network \
            "medinovai/$service:latest"
        log_success "$service deployed as Docker container"
        return 0
    fi
    
    log_error "No deployment method found for $service"
    return 1
}

# Deploy each service in order
DEPLOYED=0
FAILED=0

for service in "${DEPLOYMENT_ORDER[@]}"; do
    if deploy_service "$service"; then
        ((DEPLOYED++))
        sleep 2  # Brief pause between deployments
    else
        ((FAILED++))
    fi
done

log ""
log "═══════════════════════════════════════════"
log "  DEPLOYMENT SUMMARY"
log "═══════════════════════════════════════════"
log "Services Deployed: $DEPLOYED"
log "Services Failed: $FAILED"
log "═══════════════════════════════════════════"

# Generate service URLs
cat > "$LOG_DIR/service_urls.txt" << EOF
MedinovAI Service URLs
======================

Core Services:
- API Gateway: http://localhost:8080
- Dashboard: http://localhost:3000
- Auth Service: http://localhost:8081

Monitoring:
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090

Databases:
- PostgreSQL: localhost:5432
- Redis: localhost:6379

AI Services:
- Ollama: http://localhost:11434
- HealthLLM: http://localhost:8090

Generated: $(date)
EOF

log ""
log_success "Deployment complete!"
log "Service URLs: $LOG_DIR/service_urls.txt"

exit 0

