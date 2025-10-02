#!/bin/bash
# MedinovAI Infrastructure - Comprehensive Test Runner
# Run all 100+ Playwright tests after every deployment

set -e

echo "🧪 MEDINOVAI INFRASTRUCTURE - COMPREHENSIVE TEST SUITE"
echo "======================================================"
echo ""
echo "Running 100+ validation tests..."
echo "Test categories:"
echo "  - Credential validation"
echo "  - Grafana comprehensive (10 tests)"
echo "  - Prometheus comprehensive (12 tests)"
echo "  - AlertManager comprehensive (10 tests)"
echo "  - RabbitMQ comprehensive (8 tests)"
echo "  - MinIO comprehensive (3 tests)"
echo "  - Database comprehensive (10 tests)"
echo ""

# Check if services are running
echo "🔍 Pre-flight check: Verifying services are running..."
if ! docker ps | grep -q medinovai-grafana-tls; then
    echo "❌ Error: Grafana is not running!"
    exit 1
fi

if ! docker ps | grep -q medinovai-prometheus-tls; then
    echo "❌ Error: Prometheus is not running!"
    exit 1
fi

echo "✅ Services are running"
echo ""

# Run tests
echo "🚀 Starting test execution..."
echo ""

npx playwright test \
  --workers=4 \
  --reporter=list \
  --reporter=html \
  --reporter=json

echo ""
echo "📊 Test Results:"
echo "  - HTML Report: playwright-report/index.html"
echo "  - JSON Report: playwright-results.json"
echo ""

# Open HTML report
if [[ "$OSTYPE" == "darwin"* ]]; then
    open playwright-report/index.html
else
    echo "View HTML report: file://$(pwd)/playwright-report/index.html"
fi

echo ""
echo "✅ Test suite execution complete!"

