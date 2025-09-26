# 🚀 MedinovAI Infrastructure Deployment Guide

## 📋 Overview

This guide provides comprehensive instructions for deploying the MedinovAI infrastructure with continuous monitoring and zero-conflict configuration.

## 🎯 Prerequisites

### System Requirements
- **MacStudio M4 Ultra** (or compatible system)
- **OrbStack** or Docker Desktop
- **k3d** (Kubernetes in Docker)
- **kubectl** (Kubernetes CLI)
- **helm** (Kubernetes package manager)
- **istioctl** (Istio CLI)

### Software Versions
- **Python**: 3.11.9 (standardized across all services)
- **Kubernetes**: v1.28.0
- **Istio**: v1.27.1
- **Helm**: v3.12.0
- **k3d**: v5.6.0

## 🏗️ Infrastructure Components

### Core Infrastructure
- **Kubernetes Cluster**: k3d-medinovai-cluster
- **Service Mesh**: Istio for traffic management and security
- **DNS**: CoreDNS for service discovery
- **Metrics**: Kubernetes Metrics Server
- **Storage**: Local storage with emptyDir volumes

### MedinovAI Services
- **API Gateway**: medinovai-api-gateway (Port: 8080)
- **PostgreSQL**: Primary database (Port: 5432)
- **Redis**: Caching and session storage (Port: 6379)
- **Ollama**: AI/ML models and inference (Port: 11434)

### Monitoring Stack
- **Prometheus**: Metrics collection and storage
- **Grafana**: Dashboards and visualization
- **Loki**: Log aggregation and analysis
- **AlertManager**: Alert routing and notification

## 🚀 Deployment Process

### Phase 1: Prerequisites Check
```bash
# Check if all required tools are installed
kubectl version --client
helm version
istioctl version
k3d version

# Verify cluster status
kubectl cluster-info
k3d cluster list
```

### Phase 2: Enhanced Infrastructure Deployment
```bash
# Deploy complete infrastructure with monitoring
./scripts/deploy-enhanced-infrastructure.sh

# Or deploy components individually:
./scripts/deploy-enhanced-infrastructure.sh --monitoring-only
./scripts/deploy-enhanced-infrastructure.sh --core-only
```

### Phase 3: Production Services Deployment
```bash
# Deploy all MedinovAI production services
./scripts/deploy-medinovai-production.sh

# Check deployment status
./scripts/deploy-medinovai-production.sh --status
```

### Phase 4: Validation and Testing
```bash
# Validate deployment
./scripts/validate-deployment.sh

# Run health checks
./scripts/health-check.sh

# Performance testing
./scripts/performance-test.sh
```

## 📊 Monitoring and Observability

### Access Monitoring Services
```bash
# Grafana Dashboards
kubectl port-forward -n medinovai-monitoring svc/grafana 3000:80
# Access: http://localhost:3000 (admin/admin123)

# Prometheus Metrics
kubectl port-forward -n medinovai-monitoring svc/prometheus-server 9090:80
# Access: http://localhost:9090

# AlertManager
kubectl port-forward -n medinovai-monitoring svc/prometheus-alertmanager 9093:80
# Access: http://localhost:9093

# Loki Logs
kubectl port-forward -n medinovai-monitoring svc/loki 3100:3100
# Access: http://localhost:3100
```

### Key Dashboards
- **MedinovAI Infrastructure Overview**: System-wide health and performance
- **Kubernetes Cluster Monitoring**: Cluster resource usage and health
- **Pod and Service Monitoring**: Individual service performance
- **Resource Usage Monitoring**: CPU, memory, and storage utilization

### Alerting Rules
- **Pod Down Alerts**: Critical alerts when pods are not running
- **High CPU Usage**: Warning alerts for CPU usage > 80%
- **High Memory Usage**: Warning alerts for memory usage > 80%
- **Service Down Alerts**: Critical alerts when services are unreachable

## 🔧 Configuration Management

### Port Allocation
```
MedinovAI Service Ports (20000-29999):
├── 20000-20099: Core Infrastructure (10 repos)
├── 20100-20199: Security & Compliance (5 repos)
├── 20200-20299: Core Services (4 repos)
├── 20300-20399: Platform Services (6 repos)
└── 20400-20499: Development & Research (4 repos)

Reserved Buffer Ranges:
├── 30000-30999: Future expansion buffer
├── 31000-31999: Emergency fallback ports
└── 32000-32999: Testing and development
```

### Python Standardization
```yaml
Python Version: 3.11.9
Virtual Environment: venv (per service)
Dependency Management: requirements.txt + pip-tools
Container Base: python:3.11-slim

Core Dependencies:
  FastAPI: 0.104.0
  Pydantic: 2.5.0
  Uvicorn: 0.24.0
  Redis: 5.0.0
  PostgreSQL: psycopg2-binary 2.9.0
  Security: cryptography 41.0.0
```

### Resource Allocation
```yaml
CPU Allocation (per service):
  Core Services: 500m-1000m (with auto-scaling)
  API Services: 200m-500m (with auto-scaling)
  Database Services: 1000m-2000m (with auto-scaling)
  Monitoring Services: 100m-200m (with auto-scaling)

Memory Allocation (per service):
  Core Services: 512Mi-1Gi (with auto-scaling)
  API Services: 256Mi-512Mi (with auto-scaling)
  Database Services: 1Gi-2Gi (with auto-scaling)
  Monitoring Services: 128Mi-256Mi (with auto-scaling)
```

## 🔒 Security Configuration

### Pod Security Standards
- **Restricted Profile**: Enforced across all namespaces
- **Non-root Containers**: All containers run as non-root users
- **Read-only Root Filesystems**: Where possible
- **Security Contexts**: Properly configured for all pods

### Network Policies
- **Istio Service Mesh**: Traffic management and security
- **Network Segmentation**: Isolated communication between services
- **TLS Encryption**: All inter-service communication encrypted

### RBAC Configuration
- **Service Accounts**: Dedicated service accounts for each service
- **Role-based Access**: Minimal required permissions
- **Cluster Roles**: Restricted cluster-level access

## 🚨 Troubleshooting

### Common Issues

#### Port Conflicts
```bash
# Check for port conflicts
./scripts/port-conflict-checker.py

# Resolve conflicts
kubectl get svc --all-namespaces | grep <port>
```

#### Python Version Issues
```bash
# Validate Python versions
./scripts/python-version-validator.py

# Check dependency conflicts
pip check
```

#### Resource Issues
```bash
# Check resource usage
kubectl top nodes
kubectl top pods -n medinovai

# Check resource limits
kubectl describe nodes
```

#### Service Connectivity
```bash
# Test service connectivity
kubectl exec -it <pod-name> -n medinovai -- curl <service-url>

# Check DNS resolution
kubectl exec -it <pod-name> -n medinovai -- nslookup <service-name>
```

### Log Analysis
```bash
# View pod logs
kubectl logs -f <pod-name> -n medinovai

# View service logs
kubectl logs -f deployment/<deployment-name> -n medinovai

# Search logs in Loki
kubectl port-forward -n medinovai-monitoring svc/loki 3100:3100
# Then access Loki UI for log search
```

## 🔄 Maintenance and Updates

### Regular Maintenance Tasks
```bash
# Update Helm repositories
helm repo update

# Check for updates
helm list -n medinovai
helm list -n medinovai-monitoring

# Backup configurations
kubectl get all -n medinovai -o yaml > backup-medinovai.yaml
kubectl get all -n medinovai-monitoring -o yaml > backup-monitoring.yaml
```

### Scaling Services
```bash
# Scale services horizontally
kubectl scale deployment <deployment-name> -n medinovai --replicas=3

# Check auto-scaling
kubectl get hpa -n medinovai
```

### Monitoring Maintenance
```bash
# Check monitoring health
kubectl get pods -n medinovai-monitoring

# Restart monitoring services if needed
kubectl rollout restart deployment/prometheus-server -n medinovai-monitoring
kubectl rollout restart deployment/grafana -n medinovai-monitoring
```

## 📈 Performance Optimization

### Resource Optimization
- **Horizontal Pod Autoscaler**: Automatic scaling based on metrics
- **Vertical Pod Autoscaler**: Automatic resource adjustment
- **Cluster Autoscaler**: Automatic node scaling

### Monitoring Optimization
- **Metrics Retention**: Configure appropriate retention periods
- **Alert Optimization**: Fine-tune alert thresholds
- **Dashboard Optimization**: Optimize dashboard queries

## 🆘 Support and Documentation

### Additional Resources
- **Comprehensive Deployment Plan**: `COMPREHENSIVE_CLEAN_DEPLOYMENT_PLAN.md`
- **CI/CD Pipeline**: `.github/workflows/medinovai-deployment-pipeline.yml`
- **Production Deployment**: `MEDINOVAI_PRODUCTION_DEPLOYMENT_SUMMARY.md`

### Getting Help
1. Check the troubleshooting section above
2. Review logs using the monitoring stack
3. Consult the comprehensive deployment plan
4. Check GitHub Issues for known problems

### Contributing
1. Follow the deployment standards in `medinovai-AI-standards`
2. Test changes in development environment first
3. Update documentation for any changes
4. Submit pull requests with comprehensive testing

---

**Last Updated**: $(date)
**Version**: 1.0.0
**Status**: ✅ Production Ready
