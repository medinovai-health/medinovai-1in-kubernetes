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
