#!/bin/bash

# Kubernetes Cluster Setup Script for Mac Studio M3 Ultra
# Deploys production-ready Kubernetes cluster with k3d

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_deploy() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

# Configuration
CLUSTER_NAME="medinovai-cluster"
CLUSTER_CONFIG_DIR="/Users/dev1/github/medinovai-infrastructure/k8s-cluster-config"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

log_deploy "Setting up Kubernetes Cluster for Mac Studio M3 Ultra Infrastructure"

# Create cluster configuration directory
mkdir -p "$CLUSTER_CONFIG_DIR"

# 1. Check prerequisites
log_info "Checking prerequisites..."

# Check if k3d is installed
if ! command -v k3d >/dev/null 2>&1; then
    log_error "k3d is not installed. Please install k3d first:"
    echo "  brew install k3d"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl >/dev/null 2>&1; then
    log_error "kubectl is not installed. Please install kubectl first:"
    echo "  brew install kubectl"
    exit 1
fi

# Check if helm is installed
if ! command -v helm >/dev/null 2>&1; then
    log_error "helm is not installed. Please install helm first:"
    echo "  brew install helm"
    exit 1
fi

# Check if Docker is running
if ! docker info >/dev/null 2>&1; then
    log_error "Docker is not running. Please start Docker Desktop first."
    exit 1
fi

log_success "All prerequisites are met"

# 2. Create k3d cluster configuration
log_info "Creating k3d cluster configuration..."

cat > "$CLUSTER_CONFIG_DIR/k3d-config.yaml" << 'EOF'
apiVersion: k3d.io/v1alpha4
kind: Simple
name: medinovai-cluster
servers: 2
agents: 3
kubeAPI:
  host: "0.0.0.0"
  hostPort: "6443"
ports:
  - port: 80:80
    nodeFilters:
      - loadbalancer
  - port: 443:443
    nodeFilters:
      - loadbalancer
  - port: 8080:8080
    nodeFilters:
      - loadbalancer
  - port: 30000-30100:30000-30100
    nodeFilters:
      - loadbalancer
volumes:
  - volume: /Users/dev1/github/medinovai-infrastructure:/var/lib/rancher/k3s/storage
    nodeFilters:
      - agent:*
options:
  k3s:
    extraArgs:
      - arg: --disable=traefik
        nodeFilters:
          - server:*
      - arg: --disable=servicelb
        nodeFilters:
          - server:*
      - arg: --disable=local-storage
        nodeFilters:
          - server:*
      - arg: --disable=metrics-server
        nodeFilters:
          - server:*
      - arg: --disable=coredns
        nodeFilters:
          - server:*
      - arg: --cluster-cidr=10.42.0.0/16
        nodeFilters:
          - server:*
      - arg: --service-cidr=10.43.0.0/16
        nodeFilters:
          - server:*
      - arg: --cluster-dns=10.43.0.10
        nodeFilters:
          - server:*
      - arg: --cluster-domain=cluster.local
        nodeFilters:
          - server:*
      - arg: --enable-admission-plugins=NodeRestriction,PodSecurityPolicy
        nodeFilters:
          - server:*
      - arg: --audit-log-path=/var/log/audit.log
        nodeFilters:
          - server:*
      - arg: --audit-log-maxage=30
        nodeFilters:
          - server:*
      - arg: --audit-log-maxbackup=3
        nodeFilters:
          - server:*
      - arg: --audit-log-maxsize=100
        nodeFilters:
          - server:*
      - arg: --audit-policy-file=/etc/kubernetes/audit-policy.yaml
        nodeFilters:
          - server:*
    extraServerArgs:
      - --disable=traefik
      - --disable=servicelb
      - --disable=local-storage
      - --disable=metrics-server
      - --disable=coredns
      - --cluster-cidr=10.42.0.0/16
      - --service-cidr=10.43.0.0/16
      - --cluster-dns=10.43.0.10
      - --cluster-domain=cluster.local
      - --enable-admission-plugins=NodeRestriction,PodSecurityPolicy
      - --audit-log-path=/var/log/audit.log
      - --audit-log-maxage=30
      - --audit-log-maxbackup=3
      - --audit-log-maxsize=100
      - --audit-policy-file=/etc/kubernetes/audit-policy.yaml
    extraAgentArgs:
      - --cluster-cidr=10.42.0.0/16
      - --service-cidr=10.43.0.0/16
      - --cluster-dns=10.43.0.10
      - --cluster-domain=cluster.local
EOF

log_success "k3d cluster configuration created"

# 3. Create audit policy
log_info "Creating audit policy..."

cat > "$CLUSTER_CONFIG_DIR/audit-policy.yaml" << 'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  namespaces: ["kube-system", "kube-public", "kube-node-lease"]
  verbs: ["get", "list", "watch"]
- level: Request
  namespaces: ["medinovai", "medinovai-database", "medinovai-ai", "medinovai-monitoring"]
  verbs: ["create", "update", "patch", "delete"]
- level: RequestResponse
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
  - group: "apps"
    resources: ["deployments", "replicasets"]
  - group: "networking.k8s.io"
    resources: ["networkpolicies"]
- level: Metadata
  omitStages:
  - RequestReceived
EOF

log_success "Audit policy created"

# 4. Create storage configuration
log_info "Creating storage configuration..."

cat > "$CLUSTER_CONFIG_DIR/storage-config.yaml" << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: kube-system
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-path
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: rancher.io/local-path
volumeBindingMode: WaitForFirstConsumer
reclaimPolicy: Delete
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: local-path-config
  namespace: kube-system
data:
  config.json: |
    {
      "nodePathMap":[
      {
        "node": "DEFAULT_PATH_FOR_NON_LISTED_NODES",
        "paths": ["/opt/local-path-provisioner"]
      }
      ]
    }
  setup: |
    #!/bin/bash
    set -eu
    mkdir -m 0777 -p "$VOL_DIR"
  teardown: |
    #!/bin/bash
    set -eu
    rm -rf "$VOL_DIR"
  helperPod.yaml: |
    apiVersion: v1
    kind: Pod
    metadata:
      name: helper-pod
    spec:
      containers:
      - name: helper-pod
        image: busybox
        imagePullPolicy: IfNotPresent
        command:
        - sh
        - -c
        - 'while true; do sleep 30; done'
        volumeMounts:
        - name: data
          mountPath: /data
      volumes:
      - name: data
        hostPath:
          path: /opt/local-path-provisioner
EOF

log_success "Storage configuration created"

# 5. Create networking configuration
log_info "Creating networking configuration..."

cat > "$CLUSTER_CONFIG_DIR/networking-config.yaml" << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: kube-system
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: coredns
  namespace: kube-system
  labels:
    k8s-app: kube-dns
    kubernetes.io/name: "CoreDNS"
spec:
  replicas: 2
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  selector:
    matchLabels:
      k8s-app: kube-dns
  template:
    metadata:
      labels:
        k8s-app: kube-dns
    spec:
      priorityClassName: system-cluster-critical
      serviceAccountName: coredns
      tolerations:
        - key: "CriticalAddonsOnly"
          operator: "Exists"
      nodeSelector:
        kubernetes.io/os: linux
      affinity:
         podAntiAffinity:
           preferredDuringSchedulingIgnoredDuringExecution:
           - weight: 100
             podAffinityTerm:
               labelSelector:
                 matchExpressions:
                   - key: k8s-app
                     operator: In
                     values: ["kube-dns"]
               topologyKey: kubernetes.io/hostname
      containers:
      - name: coredns
        image: coredns/coredns:1.10.1
        imagePullPolicy: IfNotPresent
        resources:
          limits:
            memory: 170Mi
          requests:
            cpu: 100m
            memory: 70Mi
        args: [ "-conf", "/etc/coredns/Corefile" ]
        volumeMounts:
        - name: config-volume
          mountPath: /etc/coredns
          readOnly: true
        ports:
        - containerPort: 53
          name: dns
          protocol: UDP
        - containerPort: 53
          name: dns-tcp
          protocol: TCP
        - containerPort: 9153
          name: metrics
          protocol: TCP
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            add:
            - NET_BIND_SERVICE
            drop:
            - all
          readOnlyRootFilesystem: true
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
            scheme: HTTP
          initialDelaySeconds: 60
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 5
        readinessProbe:
          httpGet:
            path: /ready
            port: 8181
            scheme: HTTP
      dnsPolicy: Default
      volumes:
        - name: config-volume
          configMap:
            name: coredns
            items:
            - key: Corefile
              path: Corefile
---
apiVersion: v1
kind: Service
metadata:
  name: kube-dns
  namespace: kube-system
  annotations:
    prometheus.io/port: "9153"
    prometheus.io/scrape: "true"
  labels:
    k8s-app: kube-dns
    kubernetes.io/cluster-service: "true"
    kubernetes.io/name: "CoreDNS"
spec:
  selector:
    k8s-app: kube-dns
  clusterIP: 10.43.0.10
  ports:
  - name: dns
    port: 53
    protocol: UDP
  - name: dns-tcp
    port: 53
    protocol: TCP
  - name: metrics
    port: 9153
    protocol: TCP
EOF

log_success "Networking configuration created"

# 6. Create metrics server configuration
log_info "Creating metrics server configuration..."

cat > "$CLUSTER_CONFIG_DIR/metrics-server.yaml" << 'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    k8s-app: metrics-server
    rbac.authorization.k8s.io/aggregate-to-admin: "true"
    rbac.authorization.k8s.io/aggregate-to-edit: "true"
    rbac.authorization.k8s.io/aggregate-to-view: "true"
  name: system:aggregated-metrics-reader
rules:
- apiGroups:
  - metrics.k8s.io
  resources:
  - pods
  - nodes
  verbs:
  - get
  - list
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  labels:
    k8s-app: metrics-server
  name: system:metrics-server
rules:
- apiGroups:
  - ""
  resources:
  - nodes/metrics
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - pods
  - nodes
  verbs:
  - get
  - list
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server-auth-reader
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: extension-apiserver-authentication-reader
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server:system:auth-delegator
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  labels:
    k8s-app: metrics-server
  name: system:metrics-server
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:metrics-server
subjects:
- kind: ServiceAccount
  name: metrics-server
  namespace: kube-system
---
apiVersion: v1
kind: Service
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
spec:
  ports:
  - name: https
    port: 443
    protocol: TCP
    targetPort: https
  selector:
    k8s-app: metrics-server
---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    k8s-app: metrics-server
  name: metrics-server
  namespace: kube-system
spec:
  selector:
    matchLabels:
      k8s-app: metrics-server
  strategy:
    rollingUpdate:
      maxUnavailable: 0
  template:
    metadata:
      labels:
        k8s-app: metrics-server
    spec:
      containers:
      - args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls
        image: registry.k8s.io/metrics-server/metrics-server:v0.6.4
        imagePullPolicy: IfNotPresent
        livenessProbe:
          failureThreshold: 3
          httpGet:
            path: /livez
            port: https
            scheme: HTTPS
          periodSeconds: 10
        name: metrics-server
        ports:
        - containerPort: 4443
          name: https
          protocol: TCP
        readinessProbe:
          failureThreshold: 3
          httpGet:
            path: /readyz
            port: https
            scheme: HTTPS
          initialDelaySeconds: 20
          periodSeconds: 10
        resources:
          requests:
            cpu: 100m
            memory: 200Mi
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
        volumeMounts:
        - mountPath: /tmp
          name: tmp-dir
      nodeSelector:
        kubernetes.io/os: linux
      priorityClassName: system-cluster-critical
      serviceAccountName: metrics-server
      volumes:
      - emptyDir: {}
        name: tmp-dir
EOF

log_success "Metrics server configuration created"

# 7. Create cluster deployment script
log_info "Creating cluster deployment script..."

cat > "$CLUSTER_CONFIG_DIR/deploy-cluster.sh" << 'EOF'
#!/bin/bash

# Kubernetes Cluster Deployment Script
# Deploys the k3d cluster with all configurations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_deploy() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

log_deploy "Deploying Kubernetes Cluster"

# Check if cluster already exists
if k3d cluster list | grep -q "medinovai-cluster"; then
    log_warning "Cluster medinovai-cluster already exists. Deleting..."
    k3d cluster delete medinovai-cluster
fi

# Create the cluster
log_info "Creating k3d cluster..."
k3d cluster create --config k3d-config.yaml

# Wait for cluster to be ready
log_info "Waiting for cluster to be ready..."
kubectl wait --for=condition=Ready nodes --all --timeout=300s

# Deploy storage configuration
log_info "Deploying storage configuration..."
kubectl apply -f storage-config.yaml

# Deploy networking configuration
log_info "Deploying networking configuration..."
kubectl apply -f networking-config.yaml

# Deploy metrics server
log_info "Deploying metrics server..."
kubectl apply -f metrics-server.yaml

# Wait for components to be ready
log_info "Waiting for components to be ready..."
kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=300s

# Verify cluster status
log_info "Verifying cluster status..."
kubectl get nodes
kubectl get pods -n kube-system

log_success "🎉 Kubernetes cluster deployed successfully!"

echo ""
echo "📊 Cluster Summary:"
echo "  🏗️  Cluster Name: medinovai-cluster"
echo "  🖥️  Nodes: 2 servers + 3 agents"
echo "  🌐 Load Balancer: Ports 80, 443, 8080, 30000-30100"
echo "  💾 Storage: Local path provisioner"
echo "  🌐 Networking: CoreDNS"
echo "  📊 Metrics: Metrics server"
echo "  🔍 Audit: Audit logging enabled"
echo ""
echo "🔧 Next Steps:"
echo "  1. Verify cluster connectivity: kubectl cluster-info"
echo "  2. Deploy Istio service mesh"
echo "  3. Deploy monitoring stack"
echo "  4. Deploy security baseline"
EOF

chmod +x "$CLUSTER_CONFIG_DIR/deploy-cluster.sh"

log_success "Cluster deployment script created"

# 8. Create cluster management script
log_info "Creating cluster management script..."

cat > "$CLUSTER_CONFIG_DIR/manage-cluster.sh" << 'EOF'
#!/bin/bash

# Kubernetes Cluster Management Script
# Provides common cluster management operations

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_deploy() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

# Function to show cluster status
show_status() {
    log_info "Cluster Status:"
    echo ""
    echo "=== Nodes ==="
    kubectl get nodes -o wide
    echo ""
    echo "=== System Pods ==="
    kubectl get pods -n kube-system
    echo ""
    echo "=== Storage Classes ==="
    kubectl get storageclass
    echo ""
    echo "=== Services ==="
    kubectl get services -n kube-system
}

# Function to show cluster info
show_info() {
    log_info "Cluster Information:"
    kubectl cluster-info
    echo ""
    kubectl version --short
}

# Function to show resource usage
show_usage() {
    log_info "Resource Usage:"
    echo ""
    echo "=== Node Resources ==="
    kubectl top nodes
    echo ""
    echo "=== Pod Resources ==="
    kubectl top pods --all-namespaces
}

# Function to backup cluster
backup_cluster() {
    log_info "Backing up cluster configuration..."
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_DIR="cluster-backup-$TIMESTAMP"
    mkdir -p "$BACKUP_DIR"
    
    kubectl get all --all-namespaces -o yaml > "$BACKUP_DIR/all-resources.yaml"
    kubectl get configmaps --all-namespaces -o yaml > "$BACKUP_DIR/configmaps.yaml"
    kubectl get secrets --all-namespaces -o yaml > "$BACKUP_DIR/secrets.yaml"
    kubectl get pv -o yaml > "$BACKUP_DIR/persistent-volumes.yaml"
    kubectl get pvc --all-namespaces -o yaml > "$BACKUP_DIR/persistent-volume-claims.yaml"
    
    log_success "Cluster backup created in: $BACKUP_DIR"
}

# Function to clean up cluster
cleanup_cluster() {
    log_warning "This will delete the entire cluster. Are you sure? (y/N)"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_info "Deleting cluster..."
        k3d cluster delete medinovai-cluster
        log_success "Cluster deleted"
    else
        log_info "Cluster deletion cancelled"
    fi
}

# Main menu
case "${1:-status}" in
    "status")
        show_status
        ;;
    "info")
        show_info
        ;;
    "usage")
        show_usage
        ;;
    "backup")
        backup_cluster
        ;;
    "cleanup")
        cleanup_cluster
        ;;
    "help"|*)
        echo "Usage: $0 {status|info|usage|backup|cleanup|help}"
        echo ""
        echo "Commands:"
        echo "  status  - Show cluster status"
        echo "  info    - Show cluster information"
        echo "  usage   - Show resource usage"
        echo "  backup  - Backup cluster configuration"
        echo "  cleanup - Delete the cluster"
        echo "  help    - Show this help message"
        ;;
esac
EOF

chmod +x "$CLUSTER_CONFIG_DIR/manage-cluster.sh"

log_success "Cluster management script created"

# 9. Create cluster documentation
log_info "Creating cluster documentation..."

cat > "$CLUSTER_CONFIG_DIR/CLUSTER_SETUP.md" << 'EOF'
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
EOF

log_success "Cluster documentation created"

# Summary
echo ""
log_success "🎉 Kubernetes cluster setup configuration completed!"
echo ""
echo "📊 Cluster Configuration Summary:"
echo "  📁 Configuration directory: $CLUSTER_CONFIG_DIR/"
echo "  🏗️  k3d cluster configuration: Created"
echo "  🔍 Audit policy: Created"
echo "  💾 Storage configuration: Created"
echo "  🌐 Networking configuration: Created"
echo "  📊 Metrics server: Created"
echo "  🚀 Deployment script: Created"
echo "  ⚙️  Management script: Created"
echo "  📖 Documentation: Created"
echo ""
echo "📖 Review cluster configuration in: $CLUSTER_CONFIG_DIR/"
echo "📋 Cluster documentation: $CLUSTER_CONFIG_DIR/CLUSTER_SETUP.md"
echo "🚀 Deploy cluster: $CLUSTER_CONFIG_DIR/deploy-cluster.sh"
echo "⚙️  Manage cluster: $CLUSTER_CONFIG_DIR/manage-cluster.sh"
echo ""
echo "🔧 Next Steps:"
echo "  1. Review cluster configuration"
echo "  2. Deploy the cluster: ./deploy-cluster.sh"
echo "  3. Verify cluster deployment"
echo "  4. Proceed with Istio service mesh deployment"
