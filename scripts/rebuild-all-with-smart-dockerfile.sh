#!/bin/bash
# Rebuild all services with smart Dockerfile and entrypoint

SERVICES=(
  "medinovai-compliance-services"
  "medinovai-audit-logging"
  "medinovai-authorization"
  "medinovai-clinical-services"
  "medinovai-patient-services"
  "medinovai-healthcare-utilities"
  "medinovai-integration-services"
)

for service in "${SERVICES[@]}"; do
  echo ""
  echo "=== Processing $service ==="
  cd ../$service
  
  # Copy smart Dockerfile and entrypoint
  cp ../medinovai-infrastructure/templates/Dockerfile.smart Dockerfile
  cp ../medinovai-infrastructure/templates/entrypoint.sh .
  chmod +x entrypoint.sh
  
  # Build
  echo "Building..."
  docker build -t medinovai/$service:latest . > /dev/null 2>&1 && echo "  ✅ Built" || echo "  ❌ Build failed"
  
  # Load to k3d
  echo "Loading to k3d..."
  k3d image import medinovai/$service:latest -c medinovai-cluster > /dev/null 2>&1 && echo "  ✅ Loaded" || echo "  ❌ Load failed"
  
  cd ../medinovai-infrastructure
done

echo ""
echo "✅ All services rebuilt and loaded"
