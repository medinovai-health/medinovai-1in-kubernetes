#!/bin/bash
# Fix Dockerfiles to use standard base images instead of non-existent medinovai/base

SERVICES=(
  "medinovai-compliance-services"
  "medinovai-audit-logging"
  "medinovai-authorization"
  "medinovai-clinical-services"
  "medinovai-data-services"
  "medinovai-patient-services"
  "medinovai-healthcare-utilities"
  "medinovai-integration-services"
)

for service in "${SERVICES[@]}"; do
  DOCKERFILE="../$service/Dockerfile"
  if [ -f "$DOCKERFILE" ]; then
    echo "Fixing $service Dockerfile..."
    # Replace medinovai/base:latest with python:3.11-slim
    sed -i.bak 's|FROM medinovai/base:latest|FROM python:3.11-slim|g' "$DOCKERFILE"
    echo "  ✅ Updated $service"
  fi
done

echo ""
echo "✅ All Dockerfiles fixed"
