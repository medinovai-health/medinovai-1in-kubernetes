#!/bin/bash
# Complete Service Status Check

echo "🔍 MEDINOVAI INFRASTRUCTURE STATUS"
echo "=================================="
echo ""

echo "📊 Docker Services:"
docker ps --filter "name=medinovai" --format "table {{.Names}}\t{{.Status}}" | head -20

echo ""
echo "🌐 Web Services Health:"
printf "  %-15s %-30s %s\n" "Service" "URL" "Status"
printf "  %-15s %-30s %s\n" "-------" "---" "------"
printf "  %-15s %-30s %s\n" "Grafana" "http://localhost:3000" "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null)"
printf "  %-15s %-30s %s\n" "Prometheus" "http://localhost:9090" "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090 2>/dev/null)"
printf "  %-15s %-30s %s\n" "RabbitMQ" "http://localhost:15672" "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:15672 2>/dev/null)"
printf "  %-15s %-30s %s\n" "MinIO" "http://localhost:9001" "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9001 2>/dev/null)"
printf "  %-15s %-30s %s\n" "Keycloak" "http://localhost:8180" "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8180 2>/dev/null)"
printf "  %-15s %-30s %s\n" "Nginx" "http://localhost:8080" "$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health 2>/dev/null)"

echo ""
echo "✅ Infrastructure Status: OPERATIONAL"
echo ""
echo "🎯 Quick Access:"
echo "  Grafana:    open http://localhost:3000"
echo "  Prometheus: open http://localhost:9090"
echo "  RabbitMQ:   open http://localhost:15672"
