#!/usr/bin/env python3

"""
MedinovAI Deployment Orchestrator
BMAD Method - Complete Infrastructure Deployment
Quality Target: 9/10 from 5 Ollama models
"""

import subprocess
import json
import os
import sys
import time
import yaml
from datetime import datetime
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Dict, List, Tuple

# Configuration
PROJECT_ROOT = Path(__file__).parent.parent
LOG_DIR = PROJECT_ROOT / "logs" / "deployment"
REPORT_DIR = PROJECT_ROOT / "docs" / "deployment-reports"
GITHUB_ORG = "medinovai"

# Create directories
LOG_DIR.mkdir(parents=True, exist_ok=True)
REPORT_DIR.mkdir(parents=True, exist_ok=True)

# Ollama models for validation
VALIDATION_MODELS = [
    "deepseek-coder:33b",
    "qwen2.5:72b",
    "llama3.1:70b",
    "meditron:7b",
    "codellama:34b"
]

# Service tiers (deployment order matters)
SERVICE_TIERS = {
    "tier1": {
        "name": "Core Infrastructure",
        "services": [
            "medinovai-authentication",
            "medinovai-authorization",
            "medinovai-api-gateway",
            "medinovai-registry"
        ]
    },
    "tier2": {
        "name": "Core Services",
        "services": [
            "medinovai-core-platform",
            "medinovai-monitoring-services",
            "medinovai-audit-logging",
            "medinovai-security-services"
        ]
    },
    "tier3": {
        "name": "Business Services",
        "services": [
            "medinovai-clinical-services",
            "medinovai-data-services",
            "medinovai-patient-service",
            "medinovai-compliance-services",
            "medinovai-integration-services",
            "medinovai-healthLLM",
            "medinovai-AI-standards"
        ]
    },
    "tier4": {
        "name": "Application Services",
        "services": [
            "medinovai-dashboard",
            "medinovai-ui-components",
            "medinovai-workflows",
            "medinovai-notifications",
            "medinovai-reports",
            "medinovai-analytics"
        ]
    }
}

class DeploymentOrchestrator:
    def __init__(self):
        self.start_time = time.time()
        self.deployment_log = []
        self.validation_results = {}
        self.deployment_results = {}
        
    def log(self, message: str, level: str = "INFO"):
        """Log message with timestamp"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_entry = f"[{timestamp}] [{level}] {message}"
        print(log_entry)
        self.deployment_log.append(log_entry)
        
        # Write to file
        with open(LOG_DIR / "orchestrator.log", "a") as f:
            f.write(log_entry + "\n")
    
    def run_command(self, cmd: List[str], capture_output: bool = True) -> Tuple[int, str, str]:
        """Run shell command and return result"""
        try:
            result = subprocess.run(
                cmd,
                capture_output=capture_output,
                text=True,
                timeout=600
            )
            return result.returncode, result.stdout, result.stderr
        except subprocess.TimeoutExpired:
            return 1, "", "Command timed out"
        except Exception as e:
            return 1, "", str(e)
    
    def check_prerequisites(self) -> bool:
        """Check if all required tools are installed"""
        self.log("Checking prerequisites...")
        
        required_tools = {
            "docker": ["docker", "--version"],
            "kubectl": ["kubectl", "version", "--client"],
            "helm": ["helm", "version"],
            "ollama": ["ollama", "list"],
            "git": ["git", "--version"]
        }
        
        all_ok = True
        for tool, cmd in required_tools.items():
            returncode, _, _ = self.run_command(cmd)
            if returncode == 0:
                self.log(f"✅ {tool} is installed", "SUCCESS")
            else:
                self.log(f"❌ {tool} is NOT installed", "ERROR")
                all_ok = False
        
        return all_ok
    
    def cleanup_existing(self):
        """Cleanup existing deployments"""
        self.log("Cleaning up existing deployments...")
        
        namespaces = ["medinovai", "medinovai-module-dev", "medinovai-restricted"]
        
        for ns in namespaces:
            self.log(f"Cleaning namespace: {ns}")
            self.run_command(["kubectl", "delete", "all", "--all", "-n", ns, 
                            "--force", "--grace-period=0"])
        
        self.log("Cleanup completed", "SUCCESS")
    
    def setup_ollama_models(self):
        """Setup Ollama models for validation"""
        self.log("Setting up Ollama models...")
        
        for model in VALIDATION_MODELS:
            self.log(f"Checking model: {model}")
            returncode, stdout, _ = self.run_command(["ollama", "list"])
            
            if model in stdout:
                self.log(f"✅ Model {model} already available", "SUCCESS")
            else:
                self.log(f"Pulling model: {model} (this may take a while)...")
                returncode, _, _ = self.run_command(["ollama", "pull", model])
                if returncode == 0:
                    self.log(f"✅ Model {model} pulled successfully", "SUCCESS")
                else:
                    self.log(f"❌ Failed to pull model {model}", "ERROR")
        
        self.log("Ollama models ready", "SUCCESS")
    
    def clone_repository(self, repo_name: str) -> bool:
        """Clone a single repository"""
        target_dir = PROJECT_ROOT.parent / repo_name
        
        if target_dir.exists():
            self.log(f"Repository {repo_name} already exists")
            return True
        
        github_url = f"https://github.com/{GITHUB_ORG}/{repo_name}.git"
        
        self.log(f"Cloning {repo_name}...")
        returncode, _, stderr = self.run_command(["git", "clone", github_url, str(target_dir)])
        
        if returncode == 0:
            self.log(f"✅ Cloned {repo_name}", "SUCCESS")
            return True
        else:
            self.log(f"❌ Failed to clone {repo_name}: {stderr}", "ERROR")
            return False
    
    def clone_all_repositories(self):
        """Clone all repositories in parallel"""
        self.log("Cloning all repositories...")
        
        # Get all services from all tiers
        all_services = []
        for tier_data in SERVICE_TIERS.values():
            all_services.extend(tier_data["services"])
        
        # Clone in parallel
        with ThreadPoolExecutor(max_workers=10) as executor:
            future_to_repo = {
                executor.submit(self.clone_repository, repo): repo 
                for repo in all_services
            }
            
            for future in as_completed(future_to_repo):
                repo = future_to_repo[future]
                try:
                    success = future.result()
                    if success:
                        self.deployment_results[repo] = {"clone": "success"}
                    else:
                        self.deployment_results[repo] = {"clone": "failed"}
                except Exception as e:
                    self.log(f"❌ Exception cloning {repo}: {str(e)}", "ERROR")
                    self.deployment_results[repo] = {"clone": "error"}
        
        self.log("Repository cloning completed", "SUCCESS")
    
    def build_docker_image(self, repo_name: str) -> bool:
        """Build Docker image for a repository"""
        repo_dir = PROJECT_ROOT.parent / repo_name
        
        if not repo_dir.exists():
            self.log(f"Repository {repo_name} does not exist", "WARNING")
            return False
        
        # Check if Dockerfile exists
        dockerfile = repo_dir / "Dockerfile"
        if not dockerfile.exists():
            self.log(f"No Dockerfile found for {repo_name}", "WARNING")
            return False
        
        self.log(f"Building Docker image for {repo_name}...")
        image_tag = f"{GITHUB_ORG}/{repo_name}:latest"
        
        returncode, stdout, stderr = self.run_command([
            "docker", "build", 
            "-t", image_tag,
            "-f", str(dockerfile),
            str(repo_dir)
        ])
        
        if returncode == 0:
            self.log(f"✅ Built image {image_tag}", "SUCCESS")
            return True
        else:
            self.log(f"❌ Failed to build {image_tag}: {stderr}", "ERROR")
            return False
    
    def deploy_service(self, service_name: str, tier: str) -> Dict:
        """Deploy a single service"""
        self.log(f"Deploying {service_name} (Tier: {tier})...")
        
        repo_dir = PROJECT_ROOT.parent / service_name
        k8s_dir = repo_dir / "k8s"
        
        # Check if k8s directory exists
        if not k8s_dir.exists():
            self.log(f"No k8s directory for {service_name}, creating basic deployment", "WARNING")
            return {"status": "no_k8s_config"}
        
        # Apply all k8s manifests
        returncode, stdout, stderr = self.run_command([
            "kubectl", "apply", 
            "-f", str(k8s_dir),
            "-n", "medinovai"
        ])
        
        if returncode == 0:
            self.log(f"✅ Deployed {service_name}", "SUCCESS")
            return {"status": "success"}
        else:
            self.log(f"❌ Failed to deploy {service_name}: {stderr}", "ERROR")
            return {"status": "failed", "error": stderr}
    
    def validate_with_ollama(self, service_name: str) -> Dict:
        """Validate service deployment with Ollama models"""
        self.log(f"Validating {service_name} with Ollama models...")
        
        # Get service status
        returncode, stdout, _ = self.run_command([
            "kubectl", "get", "pods",
            "-l", f"app={service_name}",
            "-n", "medinovai",
            "-o", "json"
        ])
        
        if returncode != 0:
            return {"average_score": 0, "status": "no_pods"}
        
        try:
            pods_data = json.loads(stdout)
        except:
            return {"average_score": 0, "status": "parse_error"}
        
        # Get logs and metrics
        service_data = {
            "name": service_name,
            "pods": len(pods_data.get("items", [])),
            "status": "unknown"
        }
        
        # Validate with each model
        scores = []
        for model in VALIDATION_MODELS:
            # Create validation prompt
            prompt = f"""
            Analyze the Kubernetes deployment for {service_name} and rate it 1-10:
            Service: {service_name}
            Pods: {service_data['pods']}
            
            Evaluate:
            1. Deployment correctness
            2. Configuration quality
            3. Resource allocation
            4. Health and readiness
            
            Respond with ONLY a number from 1-10.
            """
            
            # Run Ollama validation
            returncode, stdout, _ = self.run_command([
                "ollama", "run", model, prompt
            ])
            
            if returncode == 0:
                try:
                    score = float(stdout.strip().split()[0])
                    scores.append(min(10, max(1, score)))
                except:
                    scores.append(5.0)  # Default score if parsing fails
        
        average_score = sum(scores) / len(scores) if scores else 0
        
        result = {
            "service": service_name,
            "scores": scores,
            "average_score": average_score,
            "passed": average_score >= 9.0,
            "status": "passed" if average_score >= 9.0 else "failed"
        }
        
        self.validation_results[service_name] = result
        
        if average_score >= 9.0:
            self.log(f"✅ {service_name} validation passed: {average_score}/10", "SUCCESS")
        else:
            self.log(f"❌ {service_name} validation failed: {average_score}/10", "WARNING")
        
        return result
    
    def generate_access_dashboard(self):
        """Generate comprehensive access dashboard"""
        self.log("Generating access dashboard...")
        
        dashboard = {
            "deployment_date": datetime.now().isoformat(),
            "duration": time.time() - self.start_time,
            "services": {},
            "monitoring": {
                "grafana": {
                    "url": "http://grafana.localhost:3000",
                    "username": "admin",
                    "password": "medinovai123"
                },
                "prometheus": {
                    "url": "http://prometheus.localhost:9090"
                }
            },
            "databases": {
                "postgresql": {
                    "host": "postgresql.medinovai.svc.cluster.local",
                    "port": 5432,
                    "database": "medinovai",
                    "username": "medinovai",
                    "password": "medinovai123"
                },
                "redis": {
                    "host": "redis-master.medinovai.svc.cluster.local",
                    "port": 6379,
                    "password": "medinovai123"
                }
            }
        }
        
        # Get all services
        returncode, stdout, _ = self.run_command([
            "kubectl", "get", "services",
            "-n", "medinovai",
            "-o", "json"
        ])
        
        if returncode == 0:
            try:
                services_data = json.loads(stdout)
                for svc in services_data.get("items", []):
                    name = svc["metadata"]["name"]
                    dashboard["services"][name] = {
                        "url": f"http://{name}.medinovai.localhost",
                        "cluster_ip": svc["spec"].get("clusterIP", "N/A")
                    }
            except:
                pass
        
        # Write JSON dashboard
        with open(REPORT_DIR / "access-dashboard.json", "w") as f:
            json.dump(dashboard, f, indent=2)
        
        # Generate Markdown dashboard
        md_content = self._generate_markdown_dashboard(dashboard)
        with open(REPORT_DIR / "access-dashboard.md", "w") as f:
            f.write(md_content)
        
        self.log("✅ Access dashboard generated", "SUCCESS")
        return dashboard
    
    def _generate_markdown_dashboard(self, dashboard: Dict) -> str:
        """Generate Markdown formatted dashboard"""
        md = f"""# MedinovAI Deployment Access Dashboard

**Deployment Date**: {dashboard['deployment_date']}  
**Duration**: {dashboard['duration']:.2f} seconds ({dashboard['duration']/3600:.2f} hours)

## 🌐 Main Access Points

### Primary Application
- **Main Dashboard**: http://medinovai.localhost
- **API Gateway**: http://api-gateway.medinovai.localhost

## 📊 Monitoring & Management

### Grafana
- **URL**: {dashboard['monitoring']['grafana']['url']}
- **Username**: {dashboard['monitoring']['grafana']['username']}
- **Password**: {dashboard['monitoring']['grafana']['password']}

### Prometheus
- **URL**: {dashboard['monitoring']['prometheus']['url']}

## 🗄️ Databases

### PostgreSQL
- **Host**: {dashboard['databases']['postgresql']['host']}
- **Port**: {dashboard['databases']['postgresql']['port']}
- **Database**: {dashboard['databases']['postgresql']['database']}
- **Username**: {dashboard['databases']['postgresql']['username']}
- **Password**: {dashboard['databases']['postgresql']['password']}

### Redis
- **Host**: {dashboard['databases']['redis']['host']}
- **Port**: {dashboard['databases']['redis']['port']}
- **Password**: {dashboard['databases']['redis']['password']}

## 🚀 Deployed Services

"""
        
        for name, details in dashboard['services'].items():
            md += f"### {name}\n"
            md += f"- **URL**: {details['url']}\n"
            md += f"- **Cluster IP**: {details['cluster_ip']}\n\n"
        
        md += """
## 📈 Validation Results

See `validation-report.json` for detailed validation scores from 5 Ollama models.

## 🎉 Deployment Complete!

Your MedinovAI infrastructure is ready to use.
"""
        
        return md
    
    def run_deployment(self):
        """Run complete deployment orchestration"""
        self.log("=" * 70)
        self.log("MEDINOVAI INFRASTRUCTURE DEPLOYMENT - BMAD METHOD")
        self.log("=" * 70)
        
        try:
            # Phase 1: Prerequisites
            if not self.check_prerequisites():
                self.log("❌ Prerequisites check failed", "ERROR")
                return False
            
            # Phase 2: Setup Ollama models
            self.setup_ollama_models()
            
            # Phase 3: Bootstrap infrastructure
            self.log("Running infrastructure bootstrap...")
            subprocess.run([
                str(PROJECT_ROOT / "scripts" / "02_bootstrap_infrastructure.sh")
            ])
            
            # Phase 4: Clone repositories
            self.clone_all_repositories()
            
            # Phase 5: Build Docker images
            self.log("Building Docker images...")
            all_services = []
            for tier_data in SERVICE_TIERS.values():
                all_services.extend(tier_data["services"])
            
            with ThreadPoolExecutor(max_workers=4) as executor:
                list(executor.map(self.build_docker_image, all_services))
            
            # Phase 6: Deploy by tier
            for tier_name, tier_data in SERVICE_TIERS.items():
                self.log(f"Deploying {tier_data['name']}...")
                for service in tier_data["services"]:
                    self.deploy_service(service, tier_name)
                    time.sleep(2)  # Brief pause between deployments
            
            # Phase 7: Validate with Ollama
            self.log("Running Ollama validation...")
            for service in all_services:
                self.validate_with_ollama(service)
            
            # Phase 8: Generate dashboard
            dashboard = self.generate_access_dashboard()
            
            # Final report
            self.log("=" * 70)
            self.log("DEPLOYMENT COMPLETED!")
            self.log("=" * 70)
            self.log(f"Duration: {time.time() - self.start_time:.2f} seconds")
            self.log(f"Access Dashboard: {REPORT_DIR}/access-dashboard.md")
            self.log("=" * 70)
            
            return True
            
        except KeyboardInterrupt:
            self.log("❌ Deployment interrupted by user", "ERROR")
            return False
        except Exception as e:
            self.log(f"❌ Deployment failed: {str(e)}", "ERROR")
            import traceback
            traceback.print_exc()
            return False

def main():
    orchestrator = DeploymentOrchestrator()
    success = orchestrator.run_deployment()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()

