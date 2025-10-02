#!/bin/bash

# MedinovAI Service Image Build Script
# Builds and optionally pushes Docker images for all MedinovAI services
# Usage: ./build-all-service-images.sh [--push] [--registry REGISTRY]

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
PARENT_DIR="$(dirname "$PROJECT_ROOT")"

# Default values
PUSH_IMAGES=false
REGISTRY="medinovai"
BUILD_LOG="$PROJECT_ROOT/logs/image-builds-$(date +%Y%m%d-%H%M%S).log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --push)
      PUSH_IMAGES=true
      shift
      ;;
    --registry)
      REGISTRY="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [--push] [--registry REGISTRY]"
      echo ""
      echo "Options:"
      echo "  --push              Push images to registry after building"
      echo "  --registry REGISTRY Container registry (default: medinovai)"
      echo "  --help              Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Create logs directory
mkdir -p "$PROJECT_ROOT/logs"

# Logging function
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$BUILD_LOG"
}

log_success() {
  echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1${NC}" | tee -a "$BUILD_LOG"
}

log_error() {
  echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1${NC}" | tee -a "$BUILD_LOG"
}

log_warning() {
  echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  $1${NC}" | tee -a "$BUILD_LOG"
}

# Service list organized by category
declare -a SECURITY_SERVICES=(
  "medinovai-security-services"
  "medinovai-compliance-services"
  "medinovai-audit-logging"
  "medinovai-authorization"
)

declare -a CORE_SERVICES=(
  "medinovai-clinical-services"
  "medinovai-data-services"
  "medinovai-healthcare-utilities"
  "medinovai-patient-services"
  "medinovai-core-platform"
)

declare -a PLATFORM_SERVICES=(
  "medinovai-integration-services"
  "medinovai-monitoring-services"
  "medinovai-alerting-services"
  "medinovai-backup-services"
  "medinovai-disaster-recovery"
  "medinovai-performance-monitoring"
)

declare -a DEV_SERVICES=(
  "medinovai-testing-framework"
  "medinovai-ui-components"
  "medinovai-devkit-infrastructure"
  "medinovai-configuration-management"
  "medinovai-development"
)

declare -a RESEARCH_SERVICES=(
  "medinovai-ResearchSuite"
  "medinovai-DataOfficer"
  "medinovai-research-services"
)

# Combine all services
ALL_SERVICES=(
  "${SECURITY_SERVICES[@]}"
  "${CORE_SERVICES[@]}"
  "${PLATFORM_SERVICES[@]}"
  "${DEV_SERVICES[@]}"
  "${RESEARCH_SERVICES[@]}"
)

# Statistics
TOTAL_SERVICES=${#ALL_SERVICES[@]}
BUILT_COUNT=0
FAILED_COUNT=0
SKIPPED_COUNT=0

# Build function
build_service() {
  local service_name=$1
  local service_dir="$PARENT_DIR/$service_name"
  
  log "Building $service_name..."
  
  # Check if directory exists
  if [ ! -d "$service_dir" ]; then
    log_warning "$service_name directory not found at $service_dir - SKIPPING"
    ((SKIPPED_COUNT++))
    return 1
  fi
  
  # Check if Dockerfile exists
  if [ ! -f "$service_dir/Dockerfile" ]; then
    log_warning "$service_name has no Dockerfile - SKIPPING"
    ((SKIPPED_COUNT++))
    return 1
  fi
  
  # Build image
  local image_name="$REGISTRY/${service_name#medinovai-}:latest"
  log "Building image: $image_name"
  
  if docker build -t "$image_name" "$service_dir" >> "$BUILD_LOG" 2>&1; then
    log_success "Built $image_name"
    ((BUILT_COUNT++))
    
    # Push if requested
    if [ "$PUSH_IMAGES" = true ]; then
      log "Pushing $image_name to registry..."
      if docker push "$image_name" >> "$BUILD_LOG" 2>&1; then
        log_success "Pushed $image_name"
      else
        log_error "Failed to push $image_name"
        return 1
      fi
    fi
    
    return 0
  else
    log_error "Failed to build $image_name"
    ((FAILED_COUNT++))
    return 1
  fi
}

# Main execution
main() {
  log "╔══════════════════════════════════════════════════════════════╗"
  log "║   MedinovAI Service Image Build Script                      ║"
  log "╚══════════════════════════════════════════════════════════════╝"
  log ""
  log "Configuration:"
  log "  Registry: $REGISTRY"
  log "  Push Images: $PUSH_IMAGES"
  log "  Total Services: $TOTAL_SERVICES"
  log "  Build Log: $BUILD_LOG"
  log ""
  
  # Check Docker availability
  if ! command -v docker &> /dev/null; then
    log_error "Docker is not installed or not in PATH"
    exit 1
  fi
  
  log "Docker version: $(docker --version)"
  log ""
  
  # Check Docker daemon
  if ! docker info &> /dev/null; then
    log_error "Docker daemon is not running"
    exit 1
  fi
  
  # Build all services
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log "Building Security Services..."
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for service in "${SECURITY_SERVICES[@]}"; do
    build_service "$service" || true
  done
  
  log ""
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log "Building Core Services..."
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for service in "${CORE_SERVICES[@]}"; do
    build_service "$service" || true
  done
  
  log ""
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log "Building Platform Services..."
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for service in "${PLATFORM_SERVICES[@]}"; do
    build_service "$service" || true
  done
  
  log ""
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log "Building Development Services..."
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for service in "${DEV_SERVICES[@]}"; do
    build_service "$service" || true
  done
  
  log ""
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  log "Building Research Services..."
  log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for service in "${RESEARCH_SERVICES[@]}"; do
    build_service "$service" || true
  done
  
  # Summary
  log ""
  log "╔══════════════════════════════════════════════════════════════╗"
  log "║   Build Summary                                              ║"
  log "╚══════════════════════════════════════════════════════════════╝"
  log ""
  log "Total Services: $TOTAL_SERVICES"
  log_success "Successfully Built: $BUILT_COUNT"
  log_error "Failed: $FAILED_COUNT"
  log_warning "Skipped: $SKIPPED_COUNT"
  log ""
  log "Build log saved to: $BUILD_LOG"
  log ""
  
  # List built images
  if [ $BUILT_COUNT -gt 0 ]; then
    log "Built images:"
    docker images | grep "$REGISTRY" | head -20
  fi
  
  # Exit code
  if [ $FAILED_COUNT -gt 0 ]; then
    log_error "Some builds failed. Check the log for details."
    exit 1
  else
    log_success "All builds completed successfully!"
    exit 0
  fi
}

# Run main function
main


