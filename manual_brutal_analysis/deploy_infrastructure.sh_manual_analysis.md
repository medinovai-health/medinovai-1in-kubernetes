# BRUTAL MANUAL ANALYSIS: deploy_infrastructure.sh

**Analysis Date:** Thu Sep 25 15:36:54 EDT 2025
**File Path:** scripts/deploy_infrastructure.sh
**File Size:**    15813 bytes
**Lines:**      704

## CRITICAL ISSUES FOUND


### SECURITY VULNERABILITIES
- **CRITICAL**: Hardcoded credentials found
2:export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-$(openssl rand -base64 32)}"
3:export MONGO_PASSWORD="${MONGO_PASSWORD:-$(openssl rand -base64 32)}"
4:export RABBITMQ_PASSWORD="${RABBITMQ_PASSWORD:-$(openssl rand -base64 32)}"
7:if [[ -z "$POSTGRES_PASSWORD" || -z "$MONGO_PASSWORD" || -z "$RABBITMQ_PASSWORD" ]]; then
14:export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-$(openssl rand -base64 32)}"
15:export MONGO_PASSWORD="${MONGO_PASSWORD:-$(openssl rand -base64 32)}"
16:export RABBITMQ_PASSWORD="${RABBITMQ_PASSWORD:-$(openssl rand -base64 32)}"
19:if [[ -z "$POSTGRES_PASSWORD" || -z "$MONGO_PASSWORD" || -z "$RABBITMQ_PASSWORD" ]]; then
26:export POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-$(openssl rand -base64 32)}"
27:export MONGO_PASSWORD="${MONGO_PASSWORD:-$(openssl rand -base64 32)}"
28:export RABBITMQ_PASSWORD="${RABBITMQ_PASSWORD:-$(openssl rand -base64 32)}"
31:if [[ -z "$POSTGRES_PASSWORD" || -z "$MONGO_PASSWORD" || -z "$RABBITMQ_PASSWORD" ]]; then
113:    # Deploy External Secrets Operator
114:    log_info "Deploying External Secrets Operator..."
115:    helm repo add external-secrets https://charts.external-secrets.io
117:    helm upgrade --install external-secrets external-secrets/external-secrets \
118:        --namespace external-secrets \
156:  POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-$(openssl rand -base64 32)}
305:        - name: MONGO_INITDB_ROOT_PASSWORD
529:    max_tokens: 2048
682:    echo "  🏗️  Core Infrastructure: ArgoCD, External Secrets, cert-manager, External DNS"

### CODE QUALITY ISSUES
- **MEDIUM**: Missing 'set -u' for undefined variable handling
- **LOW**: Unquoted variables found
