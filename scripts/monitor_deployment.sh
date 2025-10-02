#!/bin/bash

#####################################################################
# Deployment Monitoring Dashboard
# Real-time status of MedinovAI deployment
#####################################################################

clear

cat << "EOF"
╔══════════════════════════════════════════════════════════════════╗
║                                                                  ║
║         MEDINOVAI DEPLOYMENT MONITORING DASHBOARD                ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
EOF

echo ""
echo "📊 DEPLOYMENT STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check if orchestrator is running
if ps aux | grep -v grep | grep deployment_orchestrator > /dev/null; then
    echo "✅ Deployment Orchestrator: RUNNING"
    ORCHESTRATOR_PID=$(ps aux | grep -v grep | grep deployment_orchestrator | awk '{print $2}')
    echo "   PID: $ORCHESTRATOR_PID"
else
    echo "❌ Deployment Orchestrator: NOT RUNNING"
fi

echo ""
echo "📝 RECENT LOG ENTRIES (Last 10 lines)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f logs/deployment/orchestrator.log ]; then
    tail -10 logs/deployment/orchestrator.log
else
    echo "Log file not found yet"
fi

echo ""
echo "🔧 INFRASTRUCTURE STATUS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "PostgreSQL:"
kubectl get pods -n medinovai -l app.kubernetes.io/instance=postgresql 2>/dev/null | tail -n +2 || echo "  Not deployed yet"

echo ""
echo "Redis:"
kubectl get pods -n medinovai -l app.kubernetes.io/instance=redis 2>/dev/null | tail -n +2 || echo "  Not deployed yet"

echo ""
echo "Prometheus & Grafana:"
kubectl get pods -n monitoring -l app.kubernetes.io/part-of=kube-prometheus-stack 2>/dev/null | tail -5

echo ""
echo "🚀 MEDINOVAI SERVICES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
POD_COUNT=$(kubectl get pods -n medinovai 2>/dev/null | grep -v NAME | wc -l)
RUNNING_COUNT=$(kubectl get pods -n medinovai 2>/dev/null | grep Running | wc -l)
echo "Total Pods: $POD_COUNT | Running: $RUNNING_COUNT"

if [ $POD_COUNT -gt 0 ]; then
    echo ""
    kubectl get pods -n medinovai 2>/dev/null | head -20
fi

echo ""
echo "📈 RESOURCE USAGE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
kubectl top nodes 2>/dev/null || echo "Metrics not available yet"

echo ""
echo "⏱️  DEPLOYMENT DURATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f logs/deployment/orchestrator.log ]; then
    START_TIME=$(head -1 logs/deployment/orchestrator.log | grep -oE '\[.*?\]' | head -1 | tr -d '[]')
    echo "Started: $START_TIME"
    echo "Current: $(date '+%Y-%m-%d %H:%M:%S')"
fi

echo ""
echo "💡 MONITORING COMMANDS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Watch logs:  tail -f logs/deployment/orchestrator.log"
echo "  Watch pods:  watch kubectl get pods -n medinovai"
echo "  Kill process: kill $ORCHESTRATOR_PID"
echo "  This dashboard: ./scripts/monitor_deployment.sh"
echo ""
echo "🔄 Auto-refresh: watch -n 5 ./scripts/monitor_deployment.sh"
echo ""

