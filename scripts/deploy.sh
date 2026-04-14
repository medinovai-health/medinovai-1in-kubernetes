#!/bin/bash
# deploy.sh — medinovai-1in-kubernetes
# Build: 20260413.3100.001 | © 2026 DescartesBio / MedinovAI Health.
# Zero-touch deployment script for MacStudio / AIFactory Docker environments.

set -e

echo "🚀 Starting zero-touch deployment for medinovai-1in-kubernetes..."

# 1. Check Tailscale status
if ! command -v tailscale &> /dev/null; then
    echo "❌ Tailscale is not installed. Required for Vault and Service Mesh."
    exit 1
fi

if ! tailscale status | grep -q "medinovai"; then
    echo "❌ Device is not authenticated to the medinovai Tailnet."
    exit 1
fi

# 2. Pull latest Vault secrets into local .env (if needed for local dev)
# In production, the container fetches directly from Vault.
echo "🔒 Verifying Vault connectivity over Tailnet..."
curl -s -o /dev/null -w "%{http_code}" http://vault.tailnet.medinovai:8200/v1/sys/health || echo "⚠️ Vault unreachable, relying on cached secrets or env vars."

# 3. Stop existing containers
echo "🛑 Stopping existing containers..."
docker-compose down --remove-orphans || true

# 4. Build and start new containers
echo "🏗️ Building and starting medinovai-1in-kubernetes..."
docker-compose up -d --build

# 5. Verify health
echo "🩺 Verifying health endpoint..."
sleep 5
HEALTH=$(curl -s http://localhost:8000/health | grep -o '"status":"ok"')
if [ -n "$HEALTH" ]; then
    echo "✅ Deployment successful. Service is healthy."
else
    echo "❌ Health check failed. Fetching logs:"
    docker-compose logs --tail=50
    exit 1
fi
