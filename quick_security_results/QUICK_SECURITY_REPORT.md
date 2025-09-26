# QUICK SECURITY SCAN REPORT
Generated: Thu Sep 25 15:28:51 EDT 2025

## Files Scanned
./medinovai-deployment/services/healthllm/main.py
./medinovai-deployment/services/api-gateway/auth.py
./medinovai-deployment/services/api-gateway/rate_limiting.py
./medinovai-deployment/services/api-gateway/logging_config.py
./medinovai-deployment/services/api-gateway/main.py
./medinovai-deployment/services/api-gateway/validation.py
./validation_configs/validation_swarm_1_config.json
./validation_configs/validation_agent_1_1.sh
./istio-port-management.yaml
./traefik-config/traefik.yml
./traefik-config/traefik-simple.yml
./.pre-commit-config.yaml
./optimized_analysis_results/critical/deepseek_r1_70b_analysis_latest_error_handling_deploy_infrastructure.sh
./optimized_analysis_results/critical/deepseek_r1_70b_analysis_latest_security_vulnerabilities_deploy_infrastructure.sh
./optimized_analysis_results/critical/qwen2_5_72b_code_quality_main.py
./optimized_analysis_results/critical/qwen2_5_72b_performance_issues_main.py
./optimized_analysis_results/critical/deepseek_r1_70b_analysis_latest_architecture_problems_package.json
./optimized_analysis_results/critical/deepseek_r1_70b_analysis_latest_configuration_errors_main.py
./optimized_analysis_results/critical/qwen2_5_72b_dependency_issues_package.json
./optimized_analysis_results/critical/deepseek_r1_70b_analysis_latest_documentation_gaps_main.py

## Critical Files Analyzed
scripts/deploy_infrastructure.sh
scripts/master_deployment.sh
medinovai-deployment/services/api-gateway/main.py
medinovai-deployment/services/healthllm/main.py
istio-gateway-config.yaml
package.json

## Models Used
deepseek-coder-6.7b-analysis:latest
llama3.1:8b-analysis
codellama:7b-analysis

## Security Pattern Scan Results

### argocd-appset.yaml_security_scan.txt

SECURITY SCAN REPORT
File: ./medinovai-infrastructure-standards/platform/addons/argocd-appset.yaml
Date: Thu Sep 25 15:15:27 EDT 2025
========================================

No obvious security patterns found.

### auth.py_security_scan.txt

SECURITY SCAN REPORT
File: ./medinovai-deployment/services/api-gateway/auth.py
Date: Thu Sep 25 15:28:48 EDT 2025
========================================

No obvious security patterns found.

### clustersecretstore-aws.yaml_security_scan.txt

SECURITY SCAN REPORT
File: ./medinovai-infrastructure-standards/platform/addons/secretstores/clustersecretstore-aws.yaml
Date: Thu Sep 25 15:15:26 EDT 2025
========================================

No obvious security patterns found.

### clustersecretstore-azure.yaml_security_scan.txt

SECURITY SCAN REPORT
File: ./medinovai-infrastructure-standards/platform/addons/secretstores/clustersecretstore-azure.yaml
Date: Thu Sep 25 15:15:27 EDT 2025
========================================

No obvious security patterns found.

### clustersecretstore-gcp.yaml_security_scan.txt

SECURITY SCAN REPORT
File: ./medinovai-infrastructure-standards/platform/addons/secretstores/clustersecretstore-gcp.yaml
Date: Thu Sep 25 15:15:27 EDT 2025
========================================

No obvious security patterns found.

### deepseek_r1_70b_analysis_latest_architecture_problems_package.json_security_scan.txt

SECURITY SCAN REPORT
File: ./optimized_analysis_results/critical/deepseek_r1_70b_analysis_latest_architecture_problems_package.json
Date: Thu Sep 25 15:28:50 EDT 2025
========================================

No obvious security patterns found.

### deepseek_r1_70b_analysis_latest_configuration_errors_main.py_security_scan.txt

SECURITY SCAN REPORT
File: ./optimized_analysis_results/critical/deepseek_r1_70b_analysis_latest_configuration_errors_main.py
Date: Thu Sep 25 15:28:50 EDT 2025
========================================

No obvious security patterns found.

### deepseek_r1_70b_analysis_latest_documentation_gaps_main.py_security_scan.txt

SECURITY SCAN REPORT
File: ./optimized_analysis_results/critical/deepseek_r1_70b_analysis_latest_documentation_gaps_main.py
Date: Thu Sep 25 15:28:50 EDT 2025
========================================

No obvious security patterns found.

### deepseek_r1_70b_analysis_latest_error_handling_deploy_infrastructure.sh_security_scan.txt

SECURITY SCAN REPORT
File: ./optimized_analysis_results/critical/deepseek_r1_70b_analysis_latest_error_handling_deploy_infrastructure.sh
Date: Thu Sep 25 15:28:50 EDT 2025
========================================

No obvious security patterns found.

### deepseek_r1_70b_analysis_latest_security_vulnerabilities_deploy_infrastructure.sh_security_scan.txt

SECURITY SCAN REPORT
File: ./optimized_analysis_results/critical/deepseek_r1_70b_analysis_latest_security_vulnerabilities_deploy_infrastructure.sh
Date: Thu Sep 25 15:28:50 EDT 2025
========================================

No obvious security patterns found.

### istio-port-management.yaml_security_scan.txt

SECURITY SCAN REPORT
File: ./istio-port-management.yaml
Date: Thu Sep 25 15:28:49 EDT 2025
========================================

No obvious security patterns found.

### logging_config.py_security_scan.txt

SECURITY SCAN REPORT
File: ./medinovai-deployment/services/api-gateway/logging_config.py
Date: Thu Sep 25 15:28:49 EDT 2025
========================================

No obvious security patterns found.

### main.py_security_scan.txt

SECURITY SCAN REPORT
File: ./medinovai-deployment/services/api-gateway/main.py
Date: Thu Sep 25 15:28:49 EDT 2025
========================================

No obvious security patterns found.

### qwen2_5_72b_code_quality_main.py_security_scan.txt

SECURITY SCAN REPORT
File: ./optimized_analysis_results/critical/qwen2_5_72b_code_quality_main.py
Date: Thu Sep 25 15:28:50 EDT 2025
========================================

No obvious security patterns found.

### qwen2_5_72b_dependency_issues_package.json_security_scan.txt

SECURITY SCAN REPORT
File: ./optimized_analysis_results/critical/qwen2_5_72b_dependency_issues_package.json
Date: Thu Sep 25 15:28:50 EDT 2025
========================================

No obvious security patterns found.

### qwen2_5_72b_performance_issues_main.py_security_scan.txt

SECURITY SCAN REPORT
File: ./optimized_analysis_results/critical/qwen2_5_72b_performance_issues_main.py
Date: Thu Sep 25 15:28:50 EDT 2025
========================================

No obvious security patterns found.

### rate_limiting.py_security_scan.txt

SECURITY SCAN REPORT
File: ./medinovai-deployment/services/api-gateway/rate_limiting.py
Date: Thu Sep 25 15:28:48 EDT 2025
========================================

No obvious security patterns found.

### traefik-simple.yml_security_scan.txt

SECURITY SCAN REPORT
File: ./traefik-config/traefik-simple.yml
Date: Thu Sep 25 15:28:49 EDT 2025
========================================

No obvious security patterns found.

### traefik.yml_security_scan.txt

SECURITY SCAN REPORT
File: ./traefik-config/traefik.yml
Date: Thu Sep 25 15:28:49 EDT 2025
========================================

No obvious security patterns found.

### validation.py_security_scan.txt

SECURITY SCAN REPORT
File: ./medinovai-deployment/services/api-gateway/validation.py
Date: Thu Sep 25 15:28:49 EDT 2025
========================================

No obvious security patterns found.

### validation_agent_1_1.sh_security_scan.txt

SECURITY SCAN REPORT
File: ./validation_configs/validation_agent_1_1.sh
Date: Thu Sep 25 15:28:49 EDT 2025
========================================

No obvious security patterns found.

### validation_swarm_1_config.json_security_scan.txt

SECURITY SCAN REPORT
File: ./validation_configs/validation_swarm_1_config.json
Date: Thu Sep 25 15:28:49 EDT 2025
========================================

No obvious security patterns found.

### values.yaml_security_scan.txt

SECURITY SCAN REPORT
File: ./medinovai-infrastructure-standards/platform/charts/kyverno/values.yaml
Date: Thu Sep 25 15:15:28 EDT 2025
========================================

No obvious security patterns found.

## Model Analysis Results

