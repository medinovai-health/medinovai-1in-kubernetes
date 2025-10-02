#!/bin/bash

#####################################################################
# MedinovAI Fresh Deployment Master Script
# BMAD Method - Comprehensive Infrastructure Deployment
# Quality Target: 9/10 from 5 Ollama models
# Validation: Playwright end-to-end testing
#####################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_ROOT/logs/deployment"
REPORT_DIR="$PROJECT_ROOT/docs/deployment-reports"

# Create directories
mkdir -p "$LOG_DIR" "$REPORT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_DIR/master-deployment.log"
}

log_success() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1${NC}" | tee -a "$LOG_DIR/master-deployment.log"
}

log_error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1${NC}" | tee -a "$LOG_DIR/master-deployment.log"
}

log_warning() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}" | tee -a "$LOG_DIR/master-deployment.log"
}

# Banner
cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║              MEDINOVAI INFRASTRUCTURE DEPLOYMENT                 ║
║                     BMAD Methodology                             ║
║                                                                  ║
║  Bootstrap → Migrate → Audit → Deepen                           ║
║  Quality Target: 9/10 from 5 Ollama models                      ║
║  Validation: Playwright end-to-end testing                      ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF

log "Starting MedinovAI Infrastructure Fresh Deployment"
log "Estimated Duration: 10-20 hours"
log "Quality Gate: 9/10 from 5 Ollama models"

# Phase tracking
PHASE=1
TOTAL_PHASES=10

#####################################################################
# PHASE 1: Pre-flight Checks
#####################################################################
log "[$PHASE/$TOTAL_PHASES] Pre-flight Checks"
((PHASE++))

# Check Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed"
    exit 1
fi
log_success "Docker is installed: $(docker --version)"

# Check Kubernetes
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl is not installed"
    exit 1
fi
log_success "kubectl is installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"

# Check Helm
if ! command -v helm &> /dev/null; then
    log_error "Helm is not installed"
    exit 1
fi
log_success "Helm is installed: $(helm version --short)"

# Check Ollama
if ! command -v ollama &> /dev/null; then
    log_error "Ollama is not installed"
    exit 1
fi
log_success "Ollama is installed"

# Check Node.js for Playwright
if ! command -v node &> /dev/null; then
    log_warning "Node.js is not installed - Playwright tests will be skipped"
else
    log_success "Node.js is installed: $(node --version)"
fi

#####################################################################
# PHASE 2: Cleanup Existing Deployment (Fresh Install)
#####################################################################
log "[$PHASE/$TOTAL_PHASES] Cleanup Existing Deployment"
((PHASE++))

read -p "This will DELETE all existing deployments in medinovai namespace. Continue? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    log_warning "Deployment cancelled by user"
    exit 0
fi

log "Cleaning up existing deployments..."
./01_cleanup_existing.sh || log_warning "Cleanup script not found or failed"

#####################################################################
# PHASE 3: Bootstrap Infrastructure
#####################################################################
log "[$PHASE/$TOTAL_PHASES] Bootstrap Infrastructure"
((PHASE++))

log "Setting up core infrastructure..."
./02_bootstrap_infrastructure.sh

#####################################################################
# PHASE 4: Pull Required Ollama Models
#####################################################################
log "[$PHASE/$TOTAL_PHASES] Pull Required Ollama Models"
((PHASE++))

log "Ensuring 5 validation models are available..."
./03_setup_ollama_models.sh

#####################################################################
# PHASE 5: Clone All Repositories
#####################################################################
log "[$PHASE/$TOTAL_PHASES] Clone All Repositories"
((PHASE++))

log "Cloning all MedinovAI repositories..."
./04_clone_all_repositories.sh

#####################################################################
# PHASE 6: Build Docker Images
#####################################################################
log "[$PHASE/$TOTAL_PHASES] Build Docker Images"
((PHASE++))

log "Building Docker images for all services..."
./05_build_all_images.sh

#####################################################################
# PHASE 7: Deploy Services by Tier
#####################################################################
log "[$PHASE/$TOTAL_PHASES] Deploy Services by Tier"
((PHASE++))

log "Deploying Tier 1 Services (Core Infrastructure)..."
./06_deploy_tier1_services.sh

log "Deploying Tier 2 Services (Core Services)..."
./07_deploy_tier2_services.sh

log "Deploying Tier 3 Services (Business Services)..."
./08_deploy_tier3_services.sh

log "Deploying Tier 4 Services (Application Services)..."
./09_deploy_tier4_services.sh

#####################################################################
# PHASE 8: Validate with 5 Ollama Models
#####################################################################
log "[$PHASE/$TOTAL_PHASES] Validate with 5 Ollama Models"
((PHASE++))

log "Running validation with 5 Ollama models (Target: 9/10)..."
./10_validate_with_ollama.sh

#####################################################################
# PHASE 9: Run Playwright End-to-End Tests
#####################################################################
log "[$PHASE/$TOTAL_PHASES] Run Playwright End-to-End Tests"
((PHASE++))

if command -v node &> /dev/null; then
    log "Running Playwright end-to-end tests..."
    ./11_run_playwright_tests.sh
else
    log_warning "Skipping Playwright tests - Node.js not installed"
fi

#####################################################################
# PHASE 10: Generate Access Dashboard
#####################################################################
log "[$PHASE/$TOTAL_PHASES] Generate Access Dashboard"
((PHASE++))

log "Generating comprehensive access dashboard..."
./12_generate_access_dashboard.sh

#####################################################################
# Deployment Complete
#####################################################################

log_success "═══════════════════════════════════════════════════════"
log_success "  MEDINOVAI INFRASTRUCTURE DEPLOYMENT COMPLETE!"
log_success "═══════════════════════════════════════════════════════"

log ""
log "📊 Deployment Summary:"
log "  - Duration: $SECONDS seconds"
log "  - Services Deployed: Check deployment report"
log "  - Quality Score: Check validation report"
log "  - Access Dashboard: $REPORT_DIR/access-dashboard.md"
log ""
log "🌐 Access URLs:"
log "  - Main Dashboard: http://medinovai.localhost"
log "  - API Gateway: http://api.medinovai.localhost"
log "  - Grafana: http://grafana.localhost (admin/medinovai123)"
log "  - Prometheus: http://prometheus.localhost"
log ""
log "📚 Documentation:"
log "  - Deployment Report: $REPORT_DIR/deployment-report.md"
log "  - Validation Report: $REPORT_DIR/validation-report.md"
log "  - Playwright Report: $REPORT_DIR/playwright-report.html"
log ""
log_success "Deployment completed successfully! 🎉"

# Open access dashboard in browser
if command -v open &> /dev/null; then
    log "Opening access dashboard in browser..."
    open "$REPORT_DIR/access-dashboard.html"
fi

exit 0

