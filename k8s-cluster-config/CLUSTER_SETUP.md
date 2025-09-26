# Kubernetes Cluster Setup Documentation
Generated: $(date)

## Cluster Configuration

### Basic Information
- **Cluster Name**: medinovai-cluster
- **Type**: k3d (Kubernetes in Docker)
- **Nodes**: 2 servers + 3 agents
- **Load Balancer**: Ports 80, 443, 8080, 30000-30100

### Network Configuration
- **Cluster CIDR**: 10.42.0.0/16
- **Service CIDR**: 10.43.0.0/16
- **Cluster DNS**: 10.43.0.10
- **Cluster Domain**: cluster.local

### Security Configuration
- **Admission Plugins**: NodeRestriction, PodSecurityPolicy
- **Audit Logging**: Enabled with policy
- **RBAC**: Enabled
- **Network Policies**: Ready for deployment

### Storage Configuration
- **Default Storage Class**: local-path
- **Volume Binding**: WaitForFirstConsumer
- **Reclaim Policy**: Delete

### Monitoring Configuration
- **Metrics Server**: Enabled
- **CoreDNS**: Enabled
- **Audit Logging**: Enabled

## Deployment Steps

### 1. Prerequisites
- Docker Desktop running
- k3d installed (`brew install k3d`)
- kubectl installed (`brew install kubectl`)
- helm installed (`brew install helm`)

### 2. Deploy Cluster
```bash
cd /Users/dev1/github/medinovai-infrastructure/k8s-cluster-config
./deploy-cluster.sh
```

### 3. Verify Deployment
```bash
kubectl get nodes
kubectl get pods -n kube-system
kubectl cluster-info
```

### 4. Manage Cluster
```bash
./manage-cluster.sh status    # Show cluster status
./manage-cluster.sh info      # Show cluster information
./manage-cluster.sh usage     # Show resource usage
./manage-cluster.sh backup    # Backup cluster configuration
./manage-cluster.sh cleanup   # Delete cluster
```

## Configuration Files

### k3d-config.yaml
- Cluster configuration with 2 servers and 3 agents
- Load balancer configuration for external access
- Volume mounts for persistent storage
- Security and audit configurations

### audit-policy.yaml
- Kubernetes audit policy
- Logs security-relevant events
- Configures audit log retention

### storage-config.yaml
- Local path storage class
- Default storage class configuration
- Volume provisioning settings

### networking-config.yaml
- CoreDNS configuration
- DNS resolution settings
- Service discovery configuration

### metrics-server.yaml
- Metrics server deployment
- Resource usage monitoring
- HPA (Horizontal Pod Autoscaler) support

## Security Features

### Pod Security Standards
- Restricted security context
- Non-root containers
- Read-only root filesystem
- Dropped capabilities

### Network Security
- Network policies ready
- Service mesh ready (Istio)
- Ingress controller ready

### Audit and Monitoring
- Comprehensive audit logging
- Metrics collection
- Resource monitoring
- Security event tracking

## Next Steps

### 1. Deploy Istio Service Mesh
- Service-to-service communication
- Traffic management
- Security policies
- Observability

### 2. Deploy Monitoring Stack
- Prometheus for metrics
- Grafana for visualization
- Loki for logging
- Tempo for tracing

### 3. Deploy Security Baseline
- Pod security standards
- Network policies
- RBAC configuration
- Secrets management

### 4. Deploy Applications
- Database services
- AI/ML services
- Web applications
- API gateways

## Troubleshooting

### Common Issues
1. **Cluster not starting**: Check Docker Desktop is running
2. **Pods not ready**: Check resource constraints
3. **Network issues**: Verify CoreDNS is running
4. **Storage issues**: Check local-path provisioner

### Useful Commands
```bash
# Check cluster status
kubectl get nodes
kubectl get pods --all-namespaces

# Check logs
kubectl logs -n kube-system <pod-name>

# Check events
kubectl get events --all-namespaces

# Check resource usage
kubectl top nodes
kubectl top pods --all-namespaces
```

## Performance Optimization

### Resource Allocation
- **CPU**: 24 cores allocated to Docker
- **Memory**: 32GB allocated to Docker
- **Storage**: 2TB allocated for infrastructure

### Scaling Considerations
- **Horizontal Scaling**: Add more agent nodes
- **Vertical Scaling**: Increase resource limits
- **Storage Scaling**: Add more storage classes

### Monitoring
- **Resource Usage**: Monitor CPU, memory, storage
- **Performance Metrics**: Monitor response times
- **Health Checks**: Monitor pod health
