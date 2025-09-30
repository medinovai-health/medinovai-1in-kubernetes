#!/usr/bin/env python3
"""
MedinovAI Deployment Readiness Checker
Validates all repositories for deployment readiness
"""

import os
import json
from pathlib import Path
from typing import Dict, List, Tuple

class DeploymentReadinessChecker:
    def __init__(self):
        self.base_path = Path("/Users/dev1/github")
        self.readiness_criteria = {
            'has_code': 0.3,
            'has_dockerfile': 0.2,
            'has_k8s_config': 0.2,
            'has_health_check': 0.1,
            'has_dependencies': 0.1,
            'has_documentation': 0.1
        }
    
    def check_repository_readiness(self, repo_path: Path) -> Dict:
        """Check if repository is ready for deployment"""
        repo_name = repo_path.name
        checks = {
            'name': repo_name,
            'path': str(repo_path),
            'has_code': self.check_has_code(repo_path),
            'has_dockerfile': self.check_has_dockerfile(repo_path),
            'has_k8s_config': self.check_has_k8s_config(repo_path),
            'has_health_check': self.check_has_health_check(repo_path),
            'has_dependencies': self.check_has_dependencies(repo_path),
            'has_documentation': self.check_has_documentation(repo_path),
            'readiness_score': 0.0,
            'deployment_ready': False
        }
        
        # Calculate readiness score
        total_score = 0.0
        for check, weight in self.readiness_criteria.items():
            if checks[check]:
                total_score += weight
        
        checks['readiness_score'] = total_score
        checks['deployment_ready'] = total_score >= 0.7  # 70% threshold
        
        return checks
    
    def check_has_code(self, repo_path: Path) -> bool:
        """Check if repository has substantial code"""
        code_files = list(repo_path.glob("**/*.py")) + \
                    list(repo_path.glob("**/*.js")) + \
                    list(repo_path.glob("**/*.ts")) + \
                    list(repo_path.glob("**/*.go"))
        return len(code_files) >= 5
    
    def check_has_dockerfile(self, repo_path: Path) -> bool:
        """Check if repository has Dockerfile"""
        return (repo_path / "Dockerfile").exists()
    
    def check_has_k8s_config(self, repo_path: Path) -> bool:
        """Check if repository has Kubernetes configuration"""
        k8s_dirs = ["k8s", "deploy", "kubernetes", "manifests"]
        return any((repo_path / k8s_dir).exists() for k8s_dir in k8s_dirs)
    
    def check_has_health_check(self, repo_path: Path) -> bool:
        """Check if repository has health check endpoint"""
        # Look for health check patterns in code
        for code_file in repo_path.glob("**/*.py"):
            try:
                content = code_file.read_text()
                if any(pattern in content.lower() for pattern in 
                      ['/health', 'health_check', 'healthcheck']):
                    return True
            except:
                continue
        return False
    
    def check_has_dependencies(self, repo_path: Path) -> bool:
        """Check if repository has dependency management"""
        dependency_files = ["requirements.txt", "package.json", "go.mod", "Pipfile"]
        return any((repo_path / dep_file).exists() for dep_file in dependency_files)
    
    def check_has_documentation(self, repo_path: Path) -> bool:
        """Check if repository has documentation"""
        doc_files = ["README.md", "README.rst", "docs/", "documentation/"]
        return any((repo_path / doc_file).exists() for doc_file in doc_files)
    
    def assess_all_repositories(self) -> Dict:
        """Assess readiness of all MedinovAI repositories"""
        results = {
            'total_repositories': 0,
            'ready_repositories': 0,
            'not_ready_repositories': 0,
            'repositories': [],
            'summary': {}
        }
        
        # Find all MedinovAI repositories
        medinovai_repos = list(self.base_path.glob("*medinovai*"))
        results['total_repositories'] = len(medinovai_repos)
        
        for repo_path in medinovai_repos:
            if repo_path.is_dir():
                readiness = self.check_repository_readiness(repo_path)
                results['repositories'].append(readiness)
                
                if readiness['deployment_ready']:
                    results['ready_repositories'] += 1
                else:
                    results['not_ready_repositories'] += 1
        
        # Generate summary
        results['summary'] = {
            'readiness_percentage': (results['ready_repositories'] / results['total_repositories']) * 100,
            'average_score': sum(r['readiness_score'] for r in results['repositories']) / len(results['repositories']),
            'needs_placeholder_code': results['not_ready_repositories']
        }
        
        return results
    
    def generate_readiness_report(self, results: Dict) -> str:
        """Generate human-readable readiness report"""
        report = f"""
# 📊 MedinovAI Deployment Readiness Report

## Summary
- **Total Repositories**: {results['total_repositories']}
- **Ready for Deployment**: {results['ready_repositories']} ({results['summary']['readiness_percentage']:.1f}%)
- **Not Ready**: {results['not_ready_repositories']}
- **Average Readiness Score**: {results['summary']['average_score']:.2f}/1.0

## Repository Status

### ✅ Ready for Deployment
"""
        
        for repo in results['repositories']:
            if repo['deployment_ready']:
                report += f"- **{repo['name']}** (Score: {repo['readiness_score']:.2f})\n"
        
        report += "\n### ❌ Not Ready for Deployment\n"
        
        for repo in results['repositories']:
            if not repo['deployment_ready']:
                missing = []
                if not repo['has_code']:
                    missing.append("Code")
                if not repo['has_dockerfile']:
                    missing.append("Dockerfile")
                if not repo['has_k8s_config']:
                    missing.append("K8s Config")
                if not repo['has_health_check']:
                    missing.append("Health Check")
                if not repo['has_dependencies']:
                    missing.append("Dependencies")
                if not repo['has_documentation']:
                    missing.append("Documentation")
                
                report += f"- **{repo['name']}** (Score: {repo['readiness_score']:.2f}) - Missing: {', '.join(missing)}\n"
        
        return report

if __name__ == "__main__":
    checker = DeploymentReadinessChecker()
    results = checker.assess_all_repositories()
    
    # Save results
    with open("deployment_readiness_report.json", "w") as f:
        json.dump(results, f, indent=2)
    
    # Generate and save report
    report = checker.generate_readiness_report(results)
    with open("deployment_readiness_report.md", "w") as f:
        f.write(report)
    
    print("📊 Deployment readiness assessment completed")
    print(f"✅ Ready: {results['ready_repositories']}/{results['total_repositories']}")
    print(f"📋 Report saved: deployment_readiness_report.md")


