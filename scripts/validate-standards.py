#!/usr/bin/env python3
"""
MedinovAI Standards Validation Script
Validates repositories against MedinovAI Comprehensive Standards v2.0.0
"""

import os
import sys
import yaml
import json
import subprocess
from pathlib import Path
from typing import Dict, List, Any, Optional
from dataclasses import dataclass

@dataclass
class ValidationResult:
    """Validation result for a single check"""
    check_name: str
    passed: bool
    message: str
    severity: str = "error"  # error, warning, info

@dataclass
class RepositoryValidation:
    """Complete validation result for a repository"""
    repo_path: str
    repo_name: str
    overall_score: float
    results: List[ValidationResult]
    passed: bool

class MedinovAIStandardsValidator:
    """Validates repositories against MedinovAI standards"""
    
    def __init__(self, repo_path: str):
        self.repo_path = Path(repo_path)
        self.repo_name = self.repo_path.name
        self.medinovai_dir = self.repo_path / ".medinovai"
        self.results: List[ValidationResult] = []
    
    def validate_all(self) -> RepositoryValidation:
        """Run all validation checks"""
        self.results = []
        
        # Core standards validation
        self._validate_medinovai_directory()
        self._validate_standards_yml()
        self._validate_registry_config()
        self._validate_data_services_config()
        self._validate_dockerfile()
        self._validate_cicd_workflows()
        self._validate_health_checks()
        self._validate_monitoring()
        self._validate_security()
        self._validate_documentation()
        
        # Calculate overall score
        total_checks = len(self.results)
        passed_checks = sum(1 for r in self.results if r.passed)
        overall_score = (passed_checks / total_checks * 100) if total_checks > 0 else 0
        
        # Determine if repository passed (80% or higher)
        passed = overall_score >= 80
        
        return RepositoryValidation(
            repo_path=str(self.repo_path),
            repo_name=self.repo_name,
            overall_score=overall_score,
            results=self.results,
            passed=passed
        )
    
    def _add_result(self, check_name: str, passed: bool, message: str, severity: str = "error"):
        """Add a validation result"""
        self.results.append(ValidationResult(
            check_name=check_name,
            passed=passed,
            message=message,
            severity=severity
        ))
    
    def _validate_medinovai_directory(self):
        """Validate .medinovai directory exists"""
        if self.medinovai_dir.exists():
            self._add_result(
                "medinovai_directory",
                True,
                ".medinovai directory exists",
                "info"
            )
        else:
            self._add_result(
                "medinovai_directory",
                False,
                ".medinovai directory missing",
                "error"
            )
    
    def _validate_standards_yml(self):
        """Validate standards.yml configuration"""
        standards_file = self.medinovai_dir / "standards.yml"
        
        if not standards_file.exists():
            self._add_result(
                "standards_yml_exists",
                False,
                "standards.yml file missing",
                "error"
            )
            return
        
        try:
            with open(standards_file) as f:
                config = yaml.safe_load(f)
            
            # Check required fields
            required_fields = ["repository", "standards", "timeouts", "monitoring", "compliance"]
            missing_fields = [field for field in required_fields if field not in config]
            
            if missing_fields:
                self._add_result(
                    "standards_yml_structure",
                    False,
                    f"Missing required fields: {', '.join(missing_fields)}",
                    "error"
                )
            else:
                self._add_result(
                    "standards_yml_structure",
                    True,
                    "standards.yml has all required fields",
                    "info"
                )
            
            # Check specific configurations
            if config.get("standards", {}).get("registry_integration"):
                self._add_result(
                    "registry_integration_enabled",
                    True,
                    "Registry integration enabled",
                    "info"
                )
            else:
                self._add_result(
                    "registry_integration_enabled",
                    False,
                    "Registry integration not enabled",
                    "error"
                )
            
            if config.get("standards", {}).get("data_services_required"):
                self._add_result(
                    "data_services_required",
                    True,
                    "Data services integration required",
                    "info"
                )
            else:
                self._add_result(
                    "data_services_required",
                    False,
                    "Data services integration not required",
                    "error"
                )
            
            if config.get("timeouts", {}).get("dynamic"):
                self._add_result(
                    "dynamic_timeouts_enabled",
                    True,
                    "Dynamic timeouts enabled",
                    "info"
                )
            else:
                self._add_result(
                    "dynamic_timeouts_enabled",
                    False,
                    "Dynamic timeouts not enabled",
                    "warning"
                )
                
        except yaml.YAMLError as e:
            self._add_result(
                "standards_yml_valid",
                False,
                f"Invalid YAML in standards.yml: {e}",
                "error"
            )
        except Exception as e:
            self._add_result(
                "standards_yml_read",
                False,
                f"Error reading standards.yml: {e}",
                "error"
            )
    
    def _validate_registry_config(self):
        """Validate registry configuration"""
        registry_file = self.medinovai_dir / "registry-config.yml"
        
        if not registry_file.exists():
            self._add_result(
                "registry_config_exists",
                False,
                "registry-config.yml file missing",
                "error"
            )
            return
        
        try:
            with open(registry_file) as f:
                config = yaml.safe_load(f)
            
            # Check registry name
            registry_name = config.get("registry", {}).get("name")
            if registry_name == "medinovai-registry":
                self._add_result(
                    "registry_name_correct",
                    True,
                    "Registry name is correct",
                    "info"
                )
            else:
                self._add_result(
                    "registry_name_correct",
                    False,
                    f"Registry name should be 'medinovai-registry', got '{registry_name}'",
                    "error"
                )
            
            # Check security settings
            if config.get("images", {}).get("security_scan"):
                self._add_result(
                    "security_scan_enabled",
                    True,
                    "Security scanning enabled",
                    "info"
                )
            else:
                self._add_result(
                    "security_scan_enabled",
                    False,
                    "Security scanning not enabled",
                    "warning"
                )
                
        except Exception as e:
            self._add_result(
                "registry_config_valid",
                False,
                f"Error reading registry-config.yml: {e}",
                "error"
            )
    
    def _validate_data_services_config(self):
        """Validate data services configuration"""
        data_services_file = self.medinovai_dir / "data-services-config.yml"
        
        if not data_services_file.exists():
            self._add_result(
                "data_services_config_exists",
                False,
                "data-services-config.yml file missing",
                "error"
            )
            return
        
        try:
            with open(data_services_file) as f:
                config = yaml.safe_load(f)
            
            # Check if data services are required
            if config.get("data_services", {}).get("required"):
                self._add_result(
                    "data_services_required",
                    True,
                    "Data services integration required",
                    "info"
                )
            else:
                self._add_result(
                    "data_services_required",
                    False,
                    "Data services integration not required",
                    "error"
                )
            
            # Check encryption settings
            compliance = config.get("compliance", {})
            if compliance.get("encryption_at_rest") and compliance.get("encryption_in_transit"):
                self._add_result(
                    "encryption_enabled",
                    True,
                    "Encryption at rest and in transit enabled",
                    "info"
                )
            else:
                self._add_result(
                    "encryption_enabled",
                    False,
                    "Encryption not fully enabled",
                    "error"
                )
            
            # Check audit logging
            if compliance.get("audit_logging"):
                self._add_result(
                    "audit_logging_enabled",
                    True,
                    "Audit logging enabled",
                    "info"
                )
            else:
                self._add_result(
                    "audit_logging_enabled",
                    False,
                    "Audit logging not enabled",
                    "warning"
                )
                
        except Exception as e:
            self._add_result(
                "data_services_config_valid",
                False,
                f"Error reading data-services-config.yml: {e}",
                "error"
            )
    
    def _validate_dockerfile(self):
        """Validate Dockerfile compliance"""
        dockerfile_path = self.repo_path / "Dockerfile"
        
        if not dockerfile_path.exists():
            self._add_result(
                "dockerfile_exists",
                False,
                "Dockerfile missing",
                "error"
            )
            return
        
        try:
            with open(dockerfile_path) as f:
                dockerfile_content = f.read()
            
            # Check for MedinovAI base image
            if "medinovai/base" in dockerfile_content:
                self._add_result(
                    "medinovai_base_image",
                    True,
                    "Using MedinovAI base image",
                    "info"
                )
            else:
                self._add_result(
                    "medinovai_base_image",
                    False,
                    "Not using MedinovAI base image",
                    "error"
                )
            
            # Check for non-root user
            if "USER medinovai" in dockerfile_content or "USER" in dockerfile_content:
                self._add_result(
                    "non_root_user",
                    True,
                    "Using non-root user",
                    "info"
                )
            else:
                self._add_result(
                    "non_root_user",
                    False,
                    "Not using non-root user",
                    "warning"
                )
            
            # Check for health check
            if "HEALTHCHECK" in dockerfile_content:
                self._add_result(
                    "health_check",
                    True,
                    "Health check configured",
                    "info"
                )
            else:
                self._add_result(
                    "health_check",
                    False,
                    "Health check not configured",
                    "warning"
                )
                
        except Exception as e:
            self._add_result(
                "dockerfile_read",
                False,
                f"Error reading Dockerfile: {e}",
                "error"
            )
    
    def _validate_cicd_workflows(self):
        """Validate CI/CD workflows"""
        workflows_dir = self.repo_path / ".github" / "workflows"
        
        if not workflows_dir.exists():
            self._add_result(
                "workflows_directory",
                False,
                ".github/workflows directory missing",
                "error"
            )
            return
        
        # Check for required workflow files
        required_workflows = ["ci.yml", "cd.yml", "standards-validation.yml"]
        for workflow in required_workflows:
            workflow_file = workflows_dir / workflow
            if workflow_file.exists():
                self._add_result(
                    f"workflow_{workflow}",
                    True,
                    f"{workflow} workflow exists",
                    "info"
                )
            else:
                self._add_result(
                    f"workflow_{workflow}",
                    False,
                    f"{workflow} workflow missing",
                    "error"
                )
    
    def _validate_health_checks(self):
        """Validate health check implementation"""
        health_file = self.repo_path / "src" / "health.py"
        
        if health_file.exists():
            self._add_result(
                "health_check_implementation",
                True,
                "Health check implementation exists",
                "info"
            )
        else:
            self._add_result(
                "health_check_implementation",
                False,
                "Health check implementation missing",
                "warning"
            )
    
    def _validate_monitoring(self):
        """Validate monitoring configuration"""
        monitoring_dir = self.repo_path / "monitoring"
        
        if monitoring_dir.exists():
            self._add_result(
                "monitoring_directory",
                True,
                "Monitoring directory exists",
                "info"
            )
            
            # Check for Prometheus config
            prometheus_config = monitoring_dir / "prometheus.yml"
            if prometheus_config.exists():
                self._add_result(
                    "prometheus_config",
                    True,
                    "Prometheus configuration exists",
                    "info"
                )
            else:
                self._add_result(
                    "prometheus_config",
                    False,
                    "Prometheus configuration missing",
                    "warning"
                )
        else:
            self._add_result(
                "monitoring_directory",
                False,
                "Monitoring directory missing",
                "warning"
            )
    
    def _validate_security(self):
        """Validate security configurations"""
        # Check for security-related files
        security_files = [
            "SECURITY.md",
            ".gitignore",
            ".medinovai-ignore"
        ]
        
        for security_file in security_files:
            file_path = self.repo_path / security_file
            if file_path.exists():
                self._add_result(
                    f"security_{security_file}",
                    True,
                    f"{security_file} exists",
                    "info"
                )
            else:
                self._add_result(
                    f"security_{security_file}",
                    False,
                    f"{security_file} missing",
                    "warning"
                )
    
    def _validate_documentation(self):
        """Validate documentation"""
        # Check for required documentation files
        required_docs = ["README.md", "CHANGELOG.md", "LICENSE"]
        
        for doc in required_docs:
            doc_path = self.repo_path / doc
            if doc_path.exists():
                self._add_result(
                    f"doc_{doc}",
                    True,
                    f"{doc} exists",
                    "info"
                )
            else:
                self._add_result(
                    f"doc_{doc}",
                    False,
                    f"{doc} missing",
                    "warning"
                )

def validate_repository(repo_path: str) -> RepositoryValidation:
    """Validate a single repository"""
    validator = MedinovAIStandardsValidator(repo_path)
    return validator.validate_all()

def validate_all_repositories(base_path: str = "/Users/dev1/github") -> List[RepositoryValidation]:
    """Validate all MedinovAI repositories"""
    results = []
    base_path = Path(base_path)
    
    # Find all MedinovAI repositories
    for repo_path in base_path.glob("medinovai-*"):
        if repo_path.is_dir():
            print(f"Validating repository: {repo_path.name}")
            result = validate_repository(str(repo_path))
            results.append(result)
    
    return results

def print_validation_report(results: List[RepositoryValidation]):
    """Print comprehensive validation report"""
    print("\n" + "="*80)
    print("MEDINOVAI STANDARDS VALIDATION REPORT")
    print("="*80)
    
    total_repos = len(results)
    passed_repos = sum(1 for r in results if r.passed)
    failed_repos = total_repos - passed_repos
    
    print(f"\nSUMMARY:")
    print(f"  Total Repositories: {total_repos}")
    print(f"  Passed: {passed_repos}")
    print(f"  Failed: {failed_repos}")
    print(f"  Success Rate: {(passed_repos/total_repos*100):.1f}%")
    
    # Overall quality score
    if results:
        avg_score = sum(r.overall_score for r in results) / len(results)
        print(f"  Average Quality Score: {avg_score:.1f}/100")
        
        if avg_score >= 90:
            print(f"  Quality Rating: EXCELLENT (10/10)")
        elif avg_score >= 80:
            print(f"  Quality Rating: GOOD (8-9/10)")
        elif avg_score >= 70:
            print(f"  Quality Rating: ACCEPTABLE (6-7/10)")
        else:
            print(f"  Quality Rating: NEEDS IMPROVEMENT (<6/10)")
    
    print("\n" + "-"*80)
    print("DETAILED RESULTS:")
    print("-"*80)
    
    for result in results:
        status = "✅ PASS" if result.passed else "❌ FAIL"
        print(f"\n{status} {result.repo_name} (Score: {result.overall_score:.1f}/100)")
        
        # Group results by severity
        errors = [r for r in result.results if r.severity == "error" and not r.passed]
        warnings = [r for r in result.results if r.severity == "warning" and not r.passed]
        info = [r for r in result.results if r.passed]
        
        if errors:
            print("  ERRORS:")
            for error in errors:
                print(f"    ❌ {error.check_name}: {error.message}")
        
        if warnings:
            print("  WARNINGS:")
            for warning in warnings:
                print(f"    ⚠️  {warning.check_name}: {warning.message}")
        
        if info:
            print(f"  PASSED CHECKS: {len(info)}")
    
    print("\n" + "="*80)
    print("RECOMMENDATIONS:")
    print("="*80)
    
    if failed_repos > 0:
        print("1. Run the migration script to fix common issues:")
        print("   ./scripts/migrate-to-standards.sh")
        print()
        print("2. Focus on repositories with scores below 80%")
        print()
        print("3. Address all ERROR level issues first")
        print()
        print("4. Consider WARNING level issues for improvement")
    
    if avg_score >= 90:
        print("🎉 Excellent! All repositories meet high quality standards.")
    elif avg_score >= 80:
        print("👍 Good progress! Minor improvements needed.")
    else:
        print("⚠️  Significant improvements needed to meet standards.")

def main():
    """Main function"""
    if len(sys.argv) > 1:
        # Validate specific repository
        repo_path = sys.argv[1]
        result = validate_repository(repo_path)
        print_validation_report([result])
    else:
        # Validate all repositories
        results = validate_all_repositories()
        print_validation_report(results)
        
        # Exit with appropriate code
        failed_repos = sum(1 for r in results if not r.passed)
        sys.exit(0 if failed_repos == 0 else 1)

if __name__ == "__main__":
    main()

