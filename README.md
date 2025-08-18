# MedinovAI Infrastructure Services

Centralized infrastructure services for the entire MedinovAI ecosystem including Docker, Kubernetes, monitoring, and deployment automation.

## Architecture

This repository provides:
- Docker Compose configurations for all services
- Kubernetes manifests and Helm charts
- Terraform infrastructure as code
- Monitoring and observability stack
- CI/CD pipeline templates
- Service mesh configuration (Istio)

## Services

### Core Infrastructure
- **Docker Registry**: Private container registry
- **Kubernetes Cluster**: Container orchestration
- **Service Mesh**: Istio for service communication
- **Load Balancer**: Traefik/NGINX ingress

### Monitoring Stack
- **Prometheus**: Metrics collection
- **Grafana**: Visualization and dashboards
- **Jaeger**: Distributed tracing
- **ELK Stack**: Centralized logging

### Data Infrastructure
- **PostgreSQL**: Primary database
- **Redis**: Caching and session storage
- **Elasticsearch**: Search and analytics
- **MinIO/S3**: Object storage

## Integration

All MedinovAI repositories should use these infrastructure services:

```yaml
# Example service configuration
apiVersion: v1
kind: Service
metadata:
  name: your-service
  labels:
    app.kubernetes.io/part-of: medinovai
spec:
  selector:
    app: your-service
  ports:
  - port: 80
    targetPort: 8080
```

## Deployment

### Development
```bash
docker-compose -f docker-compose.dev.yml up -d
```

### Production
```bash
kubectl apply -f k8s/
```

## Directory Structure

```
infrastructure/
├── docker/                 # Docker configurations
├── k8s/                   # Kubernetes manifests
├── terraform/             # Infrastructure as code
├── monitoring/            # Observability stack
├── scripts/               # Automation scripts
└── docs/                  # Documentation
```
