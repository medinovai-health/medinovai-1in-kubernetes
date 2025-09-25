# QUICK SECURITY SCAN REPORT
Generated: Thu Sep 25 15:15:28 EDT 2025

## Files Scanned
./medinovai-deployment/services/healthllm/main.py
./medinovai-deployment/services/api-gateway/main.py
./validation_configs/validation_swarm_1_config.json
./validation_configs/validation_agent_1_1.sh
./istio-port-management.yaml
./traefik-config/traefik.yml
./traefik-config/traefik-simple.yml
./.pre-commit-config.yaml
./medinovai-infrastructure-standards/platform/addons/secretstores/clustersecretstore-aws.yaml
./medinovai-infrastructure-standards/platform/addons/secretstores/clustersecretstore-gcp.yaml
./medinovai-infrastructure-standards/platform/addons/secretstores/clustersecretstore-azure.yaml
./medinovai-infrastructure-standards/platform/addons/argocd-appset.yaml
./medinovai-infrastructure-standards/platform/charts/loki/values.yaml
./medinovai-infrastructure-standards/platform/charts/kube-prometheus-stack/values.yaml
./medinovai-infrastructure-standards/platform/charts/external-dns/values.yaml
./medinovai-infrastructure-standards/platform/charts/cert-manager/values.yaml
./medinovai-infrastructure-standards/platform/charts/envoy-gateway/values.yaml
./medinovai-infrastructure-standards/platform/charts/tempo/values.yaml
./medinovai-infrastructure-standards/platform/charts/external-secrets/values.yaml
./medinovai-infrastructure-standards/platform/charts/kyverno/values.yaml

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

### istio-port-management.yaml_security_scan.txt

SECURITY SCAN REPORT
File: ./istio-port-management.yaml
Date: Thu Sep 25 15:15:26 EDT 2025
========================================

No obvious security patterns found.

### main.py_security_scan.txt

SECURITY SCAN REPORT
File: ./medinovai-deployment/services/api-gateway/main.py
Date: Thu Sep 25 15:15:26 EDT 2025
========================================

No obvious security patterns found.

### traefik-simple.yml_security_scan.txt

SECURITY SCAN REPORT
File: ./traefik-config/traefik-simple.yml
Date: Thu Sep 25 15:15:26 EDT 2025
========================================

No obvious security patterns found.

### traefik.yml_security_scan.txt

SECURITY SCAN REPORT
File: ./traefik-config/traefik.yml
Date: Thu Sep 25 15:15:26 EDT 2025
========================================

No obvious security patterns found.

### validation_agent_1_1.sh_security_scan.txt

SECURITY SCAN REPORT
File: ./validation_configs/validation_agent_1_1.sh
Date: Thu Sep 25 15:15:26 EDT 2025
========================================

No obvious security patterns found.

### validation_swarm_1_config.json_security_scan.txt

SECURITY SCAN REPORT
File: ./validation_configs/validation_swarm_1_config.json
Date: Thu Sep 25 15:15:26 EDT 2025
========================================

No obvious security patterns found.

### values.yaml_security_scan.txt

SECURITY SCAN REPORT
File: ./medinovai-infrastructure-standards/platform/charts/kyverno/values.yaml
Date: Thu Sep 25 15:15:28 EDT 2025
========================================

No obvious security patterns found.

## Model Analysis Results

