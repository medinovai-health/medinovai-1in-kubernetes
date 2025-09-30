#!/bin/bash

# Update Orchestration Configurations
# This script updates service discovery and orchestration configurations
# to reflect the new distributed architecture after migration

set -e

echo "🔄 Updating orchestration configurations..."
echo "Timestamp: $(date)"
echo "=========================================="

# Configuration
BASE_DIR="/Users/dev1/github"
ORCHESTRATOR_FILE="$BASE_DIR/medinovai-infrastructure/bmad_master_orchestrator.py"
DISCOVERY_FILE="$BASE_DIR/medinovai-infrastructure/comprehensive_repository_discovery.json"
CONFIG_DIR="$BASE_DIR/medinovai-infrastructure/config"

# Create config directory if it doesn't exist
mkdir -p "$CONFIG_DIR"

echo "📋 Updating BMAD Master Orchestrator..."

# Update the orchestrator with new repository structure
cat > "$ORCHESTRATOR_FILE" << 'EOF'
#!/usr/bin/env python3
"""
BMAD Master Orchestrator - Updated for Distributed Architecture
Manages service discovery, deployment, and agent assignment across MedinovAI ecosystem
"""

import json
import os
import subprocess
import sys
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional

class BMADMasterOrchestrator:
    def __init__(self, base_path: str = "/Users/dev1/github"):
        self.base_path = Path(base_path)
        self.config_file = self.base_path / "medinovai-infrastructure" / "comprehensive_repository_discovery.json"
        self.repositories = self.load_repositories()
        
    def load_repositories(self) -> Dict:
        """Load repository configuration from JSON file"""
        try:
            with open(self.config_file, 'r') as f:
                return json.load(f)
        except FileNotFoundError:
            return self.initialize_repositories()
    
    def initialize_repositories(self) -> Dict:
        """Initialize repository configuration for distributed architecture"""
        return {
            "discovery_timestamp": datetime.now().isoformat() + "Z",
            "total_repositories_discovered": 13,
            "local_repositories": 13,
            "tier_1_core_infrastructure": 1,
            "tier_2_specialized_services": 12,
            "repositories": [
                {
                    "name": "medinovai-infrastructure",
                    "url": "https://github.com/myonsite-healthcare/medinovai-infrastructure",
                    "tier": 1,
                    "complexity": "high",
                    "source": "local",
                    "description": "Core infrastructure and orchestration platform",
                    "primary_language": "Python",
                    "version": "2.1.0",
                    "module_type": "infrastructure",
                    "healthcare_compliant": true,
                    "ai_integrated": true,
                    "deployment_ready": true,
                    "services_count": 4,
                    "migration_status": "core_platform"
                },
                {
                    "name": "medinovai-AI-standards",
                    "url": "https://github.com/myonsite-healthcare/medinovai-AI-standards",
                    "tier": 2,
                    "complexity": "high",
                    "source": "local",
                    "description": "AI/ML services and standards",
                    "primary_language": "Python",
                    "version": "1.0.0",
                    "module_type": "ai_services",
                    "healthcare_compliant": true,
                    "ai_integrated": true,
                    "deployment_ready": true,
                    "services_count": 27,
                    "migration_status": "migrated"
                },
                {
                    "name": "medinovai-clinical-services",
                    "url": "https://github.com/myonsite-healthcare/medinovai-clinical-services",
                    "tier": 2,
                    "complexity": "high",
                    "source": "local",
                    "description": "Clinical workflow and patient care services",
                    "primary_language": "Python",
                    "version": "1.0.0",
                    "module_type": "clinical_services",
                    "healthcare_compliant": true,
                    "ai_integrated": true,
                    "deployment_ready": true,
                    "services_count": 27,
                    "migration_status": "migrated"
                },
                {
                    "name": "medinovai-security-services",
                    "url": "https://github.com/myonsite-healthcare/medinovai-security-services",
                    "tier": 2,
                    "complexity": "high",
                    "source": "local",
                    "description": "Security and compliance services",
                    "primary_language": "Python",
                    "version": "1.0.0",
                    "module_type": "security_services",
                    "healthcare_compliant": true,
                    "ai_integrated": true,
                    "deployment_ready": true,
                    "services_count": 24,
                    "migration_status": "migrated"
                },
                {
                    "name": "medinovai-data-services",
                    "url": "https://github.com/myonsite-healthcare/medinovai-data-services",
                    "tier": 2,
                    "complexity": "high",
                    "source": "local",
                    "description": "Data management and analytics services",
                    "primary_language": "Python",
                    "version": "1.0.0",
                    "module_type": "data_services",
                    "healthcare_compliant": true,
                    "ai_integrated": true,
                    "deployment_ready": true,
                    "services_count": 16,
                    "migration_status": "migrated"
                },
                {
                    "name": "medinovai-integration-services",
                    "url": "https://github.com/myonsite-healthcare/medinovai-integration-services",
                    "tier": 2,
                    "complexity": "medium",
                    "source": "local",
                    "description": "Integration and API services",
                    "primary_language": "Python",
                    "version": "1.0.0",
                    "module_type": "integration_services",
                    "healthcare_compliant": true,
                    "ai_integrated": true,
                    "deployment_ready": true,
                    "services_count": 17,
                    "migration_status": "migrated"
                },
                {
                    "name": "medinovai-patient-services",
                    "url": "https://github.com/myonsite-healthcare/medinovai-patient-services",
                    "tier": 2,
                    "complexity": "medium",
                    "source": "local",
                    "description": "Patient management and engagement services",
                    "primary_language": "Python",
                    "version": "1.0.0",
                    "module_type": "patient_services",
                    "healthcare_compliant": true,
                    "ai_integrated": true,
                    "deployment_ready": true,
                    "services_count": 7,
                    "migration_status": "migrated"
                },
                {
                    "name": "medinovai-billing",
                    "url": "https://github.com/myonsite-healthcare/medinovai-billing",
                    "tier": 2,
                    "complexity": "medium",
                    "source": "local",
                    "description": "Billing and financial services",
                    "primary_language": "Python",
                    "version": "1.0.0",
                    "module_type": "billing_services",
                    "healthcare_compliant": true,
                    "ai_integrated": true,
                    "deployment_ready": true,
                    "services_count": 4,
                    "migration_status": "migrated"
                },
                {
                    "name": "medinovai-compliance-services",
                    "url": "https://github.com/myonsite-healthcare/medinovai-compliance-services",
                    "tier": 2,
                    "complexity": "high",
                    "source": "local",
                    "description": "Compliance and regulatory services",
                    "primary_language": "Python",
                    "version": "1.0.0",
                    "module_type": "compliance_services",
                    "healthcare_compliant": true,
                    "ai_integrated": true,
                    "deployment_ready": true,
                    "services_count": 7,
                    "migration_status": "migrated"
                },
                {
                    "name": "medinovai-ui-components",
                    "url": "https://github.com/myonsite-healthcare/medinovai-ui-components",
                    "tier": 2,
                    "complexity": "medium",
                    "source": "local",
                    "description": "UI/UX components and services",
                    "primary_language": "JavaScript",
                    "version": "1.0.0",
                    "module_type": "ui_services",
                    "healthcare_compliant": true,
                    "ai_integrated": true,
                    "deployment_ready": true,
                    "services_count": 0,
                    "migration_status": "migrated"
                },
                {
                    "name": "medinovai-healthcare-utilities",
                    "url": "https://github.com/myonsite-healthcare/medinovai-healthcare-utilities",
                    "tier": 2,
                    "complexity": "medium",
                    "source": "local",
                    "description": "Healthcare utility services",
                    "primary_language": "Python",
                    "version": "1.0.0",
                    "module_type": "utility_services",
                    "healthcare_compliant": true,
                    "ai_integrated": true,
                    "deployment_ready": true,
                    "services_count": 9,
                    "migration_status": "migrated"
                },
                {
                    "name": "medinovai-business-services",
                    "url": "https://github.com/myonsite-healthcare/medinovai-business-services",
                    "tier": 2,
                    "complexity": "medium",
                    "source": "local",
                    "description": "Business logic and workflow services",
                    "primary_language": "Python",
                    "version": "1.0.0",
                    "module_type": "business_services",
                    "healthcare_compliant": true,
                    "ai_integrated": true,
                    "deployment_ready": true,
                    "services_count": 0,
                    "migration_status": "migrated"
                },
                {
                    "name": "medinovai-research-services",
                    "url": "https://github.com/myonsite-healthcare/medinovai-research-services",
                    "tier": 2,
                    "complexity": "medium",
                    "source": "local",
                    "description": "Research and analytics services",
                    "primary_language": "Python",
                    "version": "1.0.0",
                    "module_type": "research_services",
                    "healthcare_compliant": true,
                    "ai_integrated": true,
                    "deployment_ready": true,
                    "services_count": 2,
                    "migration_status": "migrated"
                }
            ]
        }
    
    def discover_services(self) -> Dict:
        """Discover services across all repositories"""
        service_discovery = {
            "timestamp": datetime.now().isoformat() + "Z",
            "total_services": 0,
            "repositories": {}
        }
        
        for repo in self.repositories["repositories"]:
            repo_path = self.base_path / repo["name"]
            if repo_path.exists():
                services = self.scan_repository_services(repo_path)
                service_discovery["repositories"][repo["name"]] = {
                    "path": str(repo_path),
                    "services": services,
                    "service_count": len(services)
                }
                service_discovery["total_services"] += len(services)
        
        return service_discovery
    
    def scan_repository_services(self, repo_path: Path) -> List[Dict]:
        """Scan a repository for services"""
        services = []
        services_dir = repo_path / "services"
        
        if services_dir.exists():
            for service_dir in services_dir.iterdir():
                if service_dir.is_dir():
                    service_info = {
                        "name": service_dir.name,
                        "path": str(service_dir),
                        "type": self.detect_service_type(service_dir),
                        "status": "active"
                    }
                    services.append(service_info)
        
        return services
    
    def detect_service_type(self, service_path: Path) -> str:
        """Detect the type of service based on its structure"""
        if (service_path / "app.py").exists():
            return "flask_service"
        elif (service_path / "main.py").exists():
            return "python_service"
        elif (service_path / "package.json").exists():
            return "nodejs_service"
        else:
            return "unknown"
    
    def generate_deployment_config(self) -> Dict:
        """Generate deployment configuration for all services"""
        deployment_config = {
            "timestamp": datetime.now().isoformat() + "Z",
            "environments": ["dev", "stage", "prod"],
            "services": {}
        }
        
        for repo in self.repositories["repositories"]:
            repo_path = self.base_path / repo["name"]
            if repo_path.exists():
                services = self.scan_repository_services(repo_path)
                for service in services:
                    service_name = f"{repo['name']}-{service['name']}"
                    deployment_config["services"][service_name] = {
                        "repository": repo["name"],
                        "service": service["name"],
                        "type": service["type"],
                        "deployment": {
                            "replicas": 2,
                            "resources": {
                                "requests": {"cpu": "100m", "memory": "128Mi"},
                                "limits": {"cpu": "500m", "memory": "512Mi"}
                            },
                            "health_check": {
                                "path": "/health",
                                "port": 5000
                            }
                        }
                    }
        
        return deployment_config
    
    def save_configurations(self):
        """Save all configurations to files"""
        # Save service discovery
        service_discovery = self.discover_services()
        discovery_file = self.base_path / "medinovai-infrastructure" / "service_discovery.json"
        with open(discovery_file, 'w') as f:
            json.dump(service_discovery, f, indent=2)
        
        # Save deployment configuration
        deployment_config = self.generate_deployment_config()
        deployment_file = self.base_path / "medinovai-infrastructure" / "deployment_config.json"
        with open(deployment_file, 'w') as f:
            json.dump(deployment_config, f, indent=2)
        
        # Save updated repository configuration
        with open(self.config_file, 'w') as f:
            json.dump(self.repositories, f, indent=2)
        
        print(f"✅ Configurations saved to:")
        print(f"   - {discovery_file}")
        print(f"   - {deployment_file}")
        print(f"   - {self.config_file}")

def main():
    orchestrator = BMADMasterOrchestrator()
    orchestrator.save_configurations()
    print("🎉 Orchestration configurations updated successfully!")

if __name__ == "__main__":
    main()
EOF

echo "✅ BMAD Master Orchestrator updated"

echo "📋 Creating service discovery configuration..."

# Create service discovery configuration
cat > "$CONFIG_DIR/service_discovery.yaml" << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: medinovai-service-discovery
  namespace: medinovai
data:
  discovery-config.yaml: |
    repositories:
      - name: medinovai-infrastructure
        tier: 1
        services: 4
        type: infrastructure
      - name: medinovai-AI-standards
        tier: 2
        services: 27
        type: ai_services
      - name: medinovai-clinical-services
        tier: 2
        services: 27
        type: clinical_services
      - name: medinovai-security-services
        tier: 2
        services: 24
        type: security_services
      - name: medinovai-data-services
        tier: 2
        services: 16
        type: data_services
      - name: medinovai-integration-services
        tier: 2
        services: 17
        type: integration_services
      - name: medinovai-patient-services
        tier: 2
        services: 7
        type: patient_services
      - name: medinovai-billing
        tier: 2
        services: 4
        type: billing_services
      - name: medinovai-compliance-services
        tier: 2
        services: 7
        type: compliance_services
      - name: medinovai-ui-components
        tier: 2
        services: 0
        type: ui_services
      - name: medinovai-healthcare-utilities
        tier: 2
        services: 9
        type: utility_services
      - name: medinovai-business-services
        tier: 2
        services: 0
        type: business_services
      - name: medinovai-research-services
        tier: 2
        services: 2
        type: research_services
EOF

echo "✅ Service discovery configuration created"

echo "📋 Creating orchestration policies..."

# Create orchestration policies
cat > "$CONFIG_DIR/orchestration_policies.yaml" << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: medinovai-orchestration-policies
  namespace: medinovai
data:
  policies.yaml: |
    orchestration:
      service_discovery:
        interval: 30s
        timeout: 10s
        retry_attempts: 3
      
      deployment:
        strategy: rolling_update
        max_unavailable: 1
        max_surge: 1
        health_check_timeout: 60s
      
      scaling:
        min_replicas: 2
        max_replicas: 10
        target_cpu_utilization: 70
        target_memory_utilization: 80
      
      monitoring:
        metrics_interval: 15s
        log_level: info
        alert_thresholds:
          cpu: 80
          memory: 85
          response_time: 2000ms
      
      security:
        network_policies: true
        pod_security_standards: restricted
        image_scanning: true
        secret_management: true
EOF

echo "✅ Orchestration policies created"

echo "📋 Creating Istio service mesh configuration..."

# Create Istio configuration
cat > "$CONFIG_DIR/istio-service-mesh.yaml" << 'EOF'
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: medinovai-services
  namespace: medinovai
spec:
  hosts:
  - medinovai-services
  http:
  - match:
    - uri:
        prefix: /ai/
    route:
    - destination:
        host: medinovai-ai-standards
        port:
          number: 5000
  - match:
    - uri:
        prefix: /clinical/
    route:
    - destination:
        host: medinovai-clinical-services
        port:
          number: 5000
  - match:
    - uri:
        prefix: /security/
    route:
    - destination:
        host: medinovai-security-services
        port:
          number: 5000
  - match:
    - uri:
        prefix: /data/
    route:
    - destination:
        host: medinovai-data-services
        port:
          number: 5000
  - match:
    - uri:
        prefix: /integration/
    route:
    - destination:
        host: medinovai-integration-services
        port:
          number: 5000
  - match:
    - uri:
        prefix: /patient/
    route:
    - destination:
        host: medinovai-patient-services
        port:
          number: 5000
  - match:
    - uri:
        prefix: /billing/
    route:
    - destination:
        host: medinovai-billing
        port:
          number: 5000
  - match:
    - uri:
        prefix: /compliance/
    route:
    - destination:
        host: medinovai-compliance-services
        port:
          number: 5000
  - match:
    - uri:
        prefix: /ui/
    route:
    - destination:
        host: medinovai-ui-components
        port:
          number: 5000
  - match:
    - uri:
        prefix: /utilities/
    route:
    - destination:
        host: medinovai-healthcare-utilities
        port:
          number: 5000
  - match:
    - uri:
        prefix: /business/
    route:
    - destination:
        host: medinovai-business-services
        port:
          number: 5000
  - match:
    - uri:
        prefix: /research/
    route:
    - destination:
        host: medinovai-research-services
        port:
          number: 5000
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: medinovai-services
  namespace: medinovai
spec:
  host: medinovai-services
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        maxRequestsPerConnection: 10
    circuitBreaker:
      consecutiveErrors: 3
      interval: 30s
      baseEjectionTime: 30s
      maxEjectionPercent: 50
EOF

echo "✅ Istio service mesh configuration created"

echo "📋 Creating monitoring configuration..."

# Create monitoring configuration
cat > "$CONFIG_DIR/monitoring-config.yaml" << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: medinovai-monitoring-config
  namespace: medinovai
data:
  prometheus-rules.yaml: |
    groups:
    - name: medinovai-services
      rules:
      - alert: HighCPUUsage
        expr: rate(container_cpu_usage_seconds_total[5m]) > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage detected"
          description: "Service {{ $labels.service }} has high CPU usage"
      
      - alert: HighMemoryUsage
        expr: container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage detected"
          description: "Service {{ $labels.service }} has high memory usage"
      
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service is down"
          description: "Service {{ $labels.service }} is not responding"
  
  grafana-dashboards.yaml: |
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: medinovai-dashboards
      namespace: medinovai
    data:
      medinovai-overview.json: |
        {
          "dashboard": {
            "title": "MedinovAI Services Overview",
            "panels": [
              {
                "title": "Service Health",
                "type": "stat",
                "targets": [
                  {
                    "expr": "up",
                    "legendFormat": "{{ service }}"
                  }
                ]
              },
              {
                "title": "Request Rate",
                "type": "graph",
                "targets": [
                  {
                    "expr": "rate(http_requests_total[5m])",
                    "legendFormat": "{{ service }}"
                  }
                ]
              },
              {
                "title": "Response Time",
                "type": "graph",
                "targets": [
                  {
                    "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))",
                    "legendFormat": "{{ service }}"
                  }
                ]
              }
            ]
          }
        }
EOF

echo "✅ Monitoring configuration created"

echo "📋 Creating deployment scripts..."

# Create deployment script
cat > "$CONFIG_DIR/deploy-all-services.sh" << 'EOF'
#!/bin/bash

# Deploy All MedinovAI Services
# This script deploys all services across the distributed architecture

set -e

echo "🚀 Deploying all MedinovAI services..."
echo "Timestamp: $(date)"
echo "=========================================="

# Configuration
NAMESPACE="medinovai"
BASE_DIR="/Users/dev1/github"

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Apply configurations
echo "📋 Applying service discovery configuration..."
kubectl apply -f service_discovery.yaml

echo "📋 Applying orchestration policies..."
kubectl apply -f orchestration_policies.yaml

echo "📋 Applying Istio service mesh configuration..."
kubectl apply -f istio-service-mesh.yaml

echo "📋 Applying monitoring configuration..."
kubectl apply -f monitoring-config.yaml

# Deploy services from each repository
repositories=(
    "medinovai-infrastructure"
    "medinovai-AI-standards"
    "medinovai-clinical-services"
    "medinovai-security-services"
    "medinovai-data-services"
    "medinovai-integration-services"
    "medinovai-patient-services"
    "medinovai-billing"
    "medinovai-compliance-services"
    "medinovai-ui-components"
    "medinovai-healthcare-utilities"
    "medinovai-business-services"
    "medinovai-research-services"
)

for repo in "${repositories[@]}"; do
    echo "🚀 Deploying services from $repo..."
    repo_path="$BASE_DIR/$repo"
    
    if [ -d "$repo_path" ]; then
        # Find and apply Kubernetes configurations
        find "$repo_path" -name "*.yaml" -o -name "*.yml" | while read -r config_file; do
            if grep -q "kind:" "$config_file"; then
                echo "   📋 Applying $config_file"
                kubectl apply -f "$config_file" -n $NAMESPACE
            fi
        done
    else
        echo "   ⚠️  Repository $repo not found at $repo_path"
    fi
done

echo "✅ All services deployed successfully!"
echo "🔍 Checking deployment status..."

kubectl get pods -n $NAMESPACE
kubectl get services -n $NAMESPACE
kubectl get virtualservices -n $NAMESPACE

echo "🎉 Deployment completed!"
EOF

chmod +x "$CONFIG_DIR/deploy-all-services.sh"

echo "✅ Deployment script created"

echo "📋 Creating health check script..."

# Create health check script
cat > "$CONFIG_DIR/health-check.sh" << 'EOF'
#!/bin/bash

# Health Check for All MedinovAI Services
# This script performs comprehensive health checks across all services

set -e

echo "🏥 Performing health checks on all MedinovAI services..."
echo "Timestamp: $(date)"
echo "=========================================="

# Configuration
NAMESPACE="medinovai"
BASE_DIR="/Users/dev1/github"

# Function to check service health
check_service_health() {
    local service_name=$1
    local service_url=$2
    
    echo "🔍 Checking $service_name..."
    
    if curl -s -f "$service_url/health" > /dev/null; then
        echo "   ✅ $service_name is healthy"
        return 0
    else
        echo "   ❌ $service_name is unhealthy"
        return 1
    fi
}

# Function to check Kubernetes resources
check_k8s_resources() {
    echo "🔍 Checking Kubernetes resources..."
    
    # Check pods
    echo "   📋 Pod status:"
    kubectl get pods -n $NAMESPACE --no-headers | while read -r line; do
        pod_name=$(echo $line | awk '{print $1}')
        status=$(echo $line | awk '{print $3}')
        if [ "$status" = "Running" ]; then
            echo "     ✅ $pod_name: $status"
        else
            echo "     ❌ $pod_name: $status"
        fi
    done
    
    # Check services
    echo "   📋 Service status:"
    kubectl get services -n $NAMESPACE --no-headers | while read -r line; do
        service_name=$(echo $line | awk '{print $1}')
        endpoints=$(echo $line | awk '{print $2}')
        echo "     📡 $service_name: $endpoints"
    done
}

# Function to check service discovery
check_service_discovery() {
    echo "🔍 Checking service discovery..."
    
    # Check if service discovery is working
    if kubectl get configmap medinovai-service-discovery -n $NAMESPACE > /dev/null 2>&1; then
        echo "   ✅ Service discovery configuration found"
    else
        echo "   ❌ Service discovery configuration missing"
    fi
    
    # Check if orchestration policies are applied
    if kubectl get configmap medinovai-orchestration-policies -n $NAMESPACE > /dev/null 2>&1; then
        echo "   ✅ Orchestration policies applied"
    else
        echo "   ❌ Orchestration policies missing"
    fi
}

# Function to check Istio service mesh
check_istio_mesh() {
    echo "🔍 Checking Istio service mesh..."
    
    # Check virtual services
    if kubectl get virtualservice medinovai-services -n $NAMESPACE > /dev/null 2>&1; then
        echo "   ✅ Virtual service configured"
    else
        echo "   ❌ Virtual service missing"
    fi
    
    # Check destination rules
    if kubectl get destinationrule medinovai-services -n $NAMESPACE > /dev/null 2>&1; then
        echo "   ✅ Destination rules configured"
    else
        echo "   ❌ Destination rules missing"
    fi
}

# Function to check monitoring
check_monitoring() {
    echo "🔍 Checking monitoring setup..."
    
    # Check Prometheus
    if kubectl get pods -n $NAMESPACE | grep prometheus > /dev/null; then
        echo "   ✅ Prometheus is running"
    else
        echo "   ❌ Prometheus is not running"
    fi
    
    # Check Grafana
    if kubectl get pods -n $NAMESPACE | grep grafana > /dev/null; then
        echo "   ✅ Grafana is running"
    else
        echo "   ❌ Grafana is not running"
    fi
}

# Main health check execution
echo "🏥 Starting comprehensive health check..."

check_k8s_resources
check_service_discovery
check_istio_mesh
check_monitoring

echo "✅ Health check completed!"
echo "📊 Summary:"
echo "   - Kubernetes resources: Checked"
echo "   - Service discovery: Checked"
echo "   - Istio service mesh: Checked"
echo "   - Monitoring: Checked"

echo "🎉 All health checks completed!"
EOF

chmod +x "$CONFIG_DIR/health-check.sh"

echo "✅ Health check script created"

echo "📋 Updating repository discovery configuration..."

# Update the comprehensive repository discovery
python3 "$ORCHESTRATOR_FILE"

echo "✅ Repository discovery configuration updated"

echo "=========================================="
echo "🔄 ORCHESTRATION CONFIGURATIONS UPDATED"
echo "=========================================="

echo "📊 SUMMARY:"
echo "   ✅ BMAD Master Orchestrator updated"
echo "   ✅ Service discovery configuration created"
echo "   ✅ Orchestration policies created"
echo "   ✅ Istio service mesh configuration created"
echo "   ✅ Monitoring configuration created"
echo "   ✅ Deployment scripts created"
echo "   ✅ Health check scripts created"
echo "   ✅ Repository discovery updated"

echo ""
echo "📁 Configuration files created:"
echo "   - $CONFIG_DIR/service_discovery.yaml"
echo "   - $CONFIG_DIR/orchestration_policies.yaml"
echo "   - $CONFIG_DIR/istio-service-mesh.yaml"
echo "   - $CONFIG_DIR/monitoring-config.yaml"
echo "   - $CONFIG_DIR/deploy-all-services.sh"
echo "   - $CONFIG_DIR/health-check.sh"

echo ""
echo "🔄 Next step: Enhance documentation and deployment scripts"
echo "🎉 Orchestration configurations updated successfully!"

