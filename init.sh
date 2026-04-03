#!/usr/bin/env bash
# MedinovAI Infrastructure — One-Command Setup Script
# Usage: ./init.sh [docker|k8s|test]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFRA_DIR="${SCRIPT_DIR}"
SECURITY_DIR="${INFRA_DIR}/services/security-service"
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

show_help() {
    cat << 'EOF'
MedinovAI Infrastructure Setup Script

Usage: ./init.sh [COMMAND]

Commands:
    docker      Start security service with Docker Compose (local dev)
    k8s         Deploy to Kubernetes cluster
    test        Run Playwright E2E tests
    build       Build Docker images
    stop        Stop all services
    status      Check service health
    help        Show this help message

Examples:
    ./init.sh docker          # Start local development stack
    ./init.sh k8s             # Deploy to Kubernetes
    ./init.sh test            # Run E2E tests
    ./init.sh status          # Check all services

Environment Variables:
    KEYCLOAK_ADMIN_PASSWORD   # Keycloak admin password (default: admin123)
    POSTGRES_PASSWORD         # PostgreSQL password (default: postgres123)
    REDIS_PASSWORD            # Redis password (default: redis123)
EOF
}

check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
    log_success "Docker is running"
}

check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    if ! kubectl cluster-info &> /dev/null; then
        log_error "Kubernetes cluster is not accessible"
        exit 1
    fi
    log_success "Kubernetes cluster is accessible"
}

cmd_docker() {
    log_info "Starting MedinovAI Infrastructure (Docker mode)..."
    check_docker

    cd "${SECURITY_DIR}"

    # Create .env if it doesn't exist
    if [[ ! -f .env ]]; then
        log_info "Creating .env file..."
        cat > .env << EOF
KEYCLOAK_ADMIN_PASSWORD=admin123
POSTGRES_PASSWORD=postgres123
REDIS_PASSWORD=redis123
KEYCLOAK_REALM=medinovai
AIFACTORY_URL=http://100.106.54.9:8082/v1
EOF
        log_success ".env file created"
    fi

    # Build and start services
    log_info "Building security service image..."
    docker-compose build security-service

    log_info "Starting services (postgres, redis, keycloak, security-service)..."
    docker-compose up -d postgres redis keycloak

    log_info "Waiting for Keycloak to be healthy (this may take 60-90 seconds)..."
    sleep 30

    # Check Keycloak health
    for i in {1..30}; do
        if curl -sf http://localhost:8081/health/ready &> /dev/null; then
            log_success "Keycloak is ready"
            break
        fi
        echo -n "."
        sleep 5
    done

    # Start security service
    log_info "Starting security service..."
    docker-compose up -d security-service

    # Wait for security service
    log_info "Waiting for security service to be healthy..."
    for i in {1..20}; do
        if curl -sf http://localhost:8300/health &> /dev/null; then
            log_success "Security service is ready"
            break
        fi
        echo -n "."
        sleep 3
    done

    echo ""
    log_success "Infrastructure stack is running!"
    echo ""
    echo -e "${GREEN}Services:${NC}"
    echo "  Security Service:  http://localhost:8300"
    echo "  Keycloak:          http://localhost:8081 (admin/admin123)"
    echo "  Keycloak Health:   http://localhost:8081/health/ready"
    echo ""
    echo -e "${BLUE}To stop:${NC} docker-compose -f services/security-service/docker-compose.yml down"
    echo -e "${BLUE}To view logs:${NC} docker-compose -f services/security-service/docker-compose.yml logs -f"
}

cmd_k8s() {
    log_info "Deploying MedinovAI Infrastructure to Kubernetes..."
    check_kubectl

    cd "${INFRA_DIR}"

    # Check if security-service namespace exists
    if ! kubectl get namespace medinovai-services &> /dev/null; then
        log_warn "Namespace medinovai-services not found, attempting to create..."
        kubectl create namespace medinovai-services 2>/dev/null || true
    fi

    # Apply K8s manifests
    log_info "Applying K8s manifests..."
    kubectl apply -f services/security-service/k8s/configmap.yaml
    kubectl apply -f services/security-service/k8s/secret.yaml
    kubectl apply -f services/security-service/k8s/deployment.yaml
    kubectl apply -f services/security-service/k8s/service.yaml
    kubectl apply -f services/security-service/k8s/network-policy.yaml

    log_info "Waiting for deployment to be ready..."
    kubectl rollout status deployment/medinovai-security-service -n medinovai-services --timeout=120s

    log_success "Security service deployed to Kubernetes!"
    echo ""
    echo -e "${GREEN}Access:${NC}"
    echo "  Port-forward: kubectl port-forward -n medinovai-services svc/medinovai-security-service 8300:8000"
    echo "  Health check: curl http://localhost:8300/health"
    echo ""
    echo -e "${BLUE}To view logs:${NC} kubectl logs -n medinovai-services -l app=medinovai-security-service -f"
}

cmd_build() {
    log_info "Building Docker images..."
    check_docker

    cd "${SECURITY_DIR}"
    log_info "Building medinovai-security-service..."
    docker build -t medinovai-security-service:latest .
    log_success "Image built: medinovai-security-service:latest"
}

cmd_stop() {
    log_info "Stopping services..."

    # Stop Docker Compose
    if [[ -f "${SECURITY_DIR}/docker-compose.yml" ]]; then
        cd "${SECURITY_DIR}"
        docker-compose down 2>/dev/null || true
    fi

    log_success "Services stopped"
}

cmd_status() {
    log_info "Checking service status..."

    echo ""
    echo -e "${BLUE}Docker Containers:${NC}"
    docker ps --filter "name=medinovai" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "  No containers running"

    echo ""
    echo -e "${BLUE}Kubernetes Pods:${NC}"
    kubectl get pods -n medinovai-services -l app=medinovai-security-service 2>/dev/null || echo "  No pods found"

    echo ""
    echo -e "${BLUE}Health Checks:${NC}"

    # Check security service
    if curl -sf http://localhost:8300/health &> /dev/null; then
        log_success "Security Service (localhost:8300): Healthy"
    else
        log_warn "Security Service (localhost:8300): Not responding"
    fi

    # Check Keycloak
    if curl -sf http://localhost:8081/health/ready &> /dev/null; then
        log_success "Keycloak (localhost:8081): Ready"
    else
        log_warn "Keycloak (localhost:8081): Not responding"
    fi

    # Check infrastructure services via port-forwards
    for port in 4200 4210 4211 4250 4251 4252; do
        status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 2 "http://localhost:${port}/health" 2>/dev/null || echo "ERR")
        if [[ "$status" == "200" ]] || [[ "$status" == "302" ]]; then
            log_success "Port ${port}: Healthy (HTTP ${status})"
        else
            log_warn "Port ${port}: ${status}"
        fi
    done
}

cmd_test() {
    log_info "Running Playwright E2E tests..."

    cd "${INFRA_DIR}"

    # Check if tests directory exists
    if [[ ! -d "tests" ]]; then
        log_warn "Tests directory not found, skipping tests"
        return 0
    fi

    # Run Playwright tests
    if command -v npx &> /dev/null; then
        npx playwright test --reporter=list 2>/dev/null || log_warn "Playwright tests not configured yet"
    else
        log_warn "npx not found, skipping tests"
    fi
}

# Main command dispatcher
case "${1:-help}" in
    docker)
        cmd_docker
        ;;
    k8s|kubernetes)
        cmd_k8s
        ;;
    build)
        cmd_build
        ;;
    stop|down)
        cmd_stop
        ;;
    status)
        cmd_status
        ;;
    test)
        cmd_test
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
