#!/bin/bash
# Quick Dashboard Access Script

echo "🎯 MEDINOVAI DASHBOARD ACCESS"
echo "=============================="
echo ""
echo "Opening all dashboards..."
echo ""

# Open Grafana
echo "📊 Grafana: http://localhost:3000"
echo "   Username: admin"
echo "   Password: admin"
open http://localhost:3000

sleep 2

# Open Prometheus
echo ""
echo "📈 Prometheus: http://localhost:9090"
echo "   (No authentication required)"
open http://localhost:9090

sleep 2

# Open RabbitMQ
echo ""
echo "🐰 RabbitMQ: http://localhost:15672"
echo "   Username: medinovai"
echo "   Password: rabbitmq_secure_password"
open http://localhost:15672

sleep 2

# Open MinIO
echo ""
echo "📦 MinIO: http://localhost:9001"
echo "   Username: medinovai"
echo "   Password: minio_secure_password"
open http://localhost:9001

echo ""
echo "✅ All dashboards opened in your browser!"
echo ""
echo "📋 For full credentials, see: DASHBOARD_CREDENTIALS.md"
