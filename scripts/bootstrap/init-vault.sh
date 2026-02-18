#!/usr/bin/env bash
# ─── init-vault.sh ────────────────────────────────────────────────────────────
# Deploy and initialize HashiCorp Vault in K3s for the entire MedinovAI platform.
#
# Usage:
#   bash scripts/bootstrap/init-vault.sh              # Deploy + initialize
#   bash scripts/bootstrap/init-vault.sh --seed        # Seed secrets interactively
#   bash scripts/bootstrap/init-vault.sh --unseal      # Unseal only
#   bash scripts/bootstrap/init-vault.sh --status      # Check status
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
DEPLOY_HOME="${DEPLOY_HOME:-$HOME/.medinovai-deploy}"
VAULT_DIR="$DEPLOY_HOME/vault"

ACTION="deploy"
for arg in "$@"; do
    case "$arg" in
        --seed)   ACTION="seed" ;;
        --unseal) ACTION="unseal" ;;
        --status) ACTION="status" ;;
    esac
done

mkdir -p "$VAULT_DIR"
log() { echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1"; }

# ─── Deploy Vault via Helm ──────────────────────────────────────────────────
deploy_vault() {
    log "Deploying HashiCorp Vault to K3s..."

    if helm list -n vault 2>/dev/null | grep -q "vault"; then
        log "Vault already installed. Checking status..."
        kubectl get pods -n vault --no-headers 2>/dev/null
        return 0
    fi

    helm repo add hashicorp https://helm.releases.hashicorp.com 2>/dev/null || true
    helm repo update hashicorp 2>/dev/null

    local values_file="$REPO_ROOT/infra/kubernetes/vault/values.yaml"
    if [ -f "$values_file" ]; then
        helm install vault hashicorp/vault \
            --namespace vault \
            --create-namespace \
            -f "$values_file" \
            --wait --timeout 5m
    else
        helm install vault hashicorp/vault \
            --namespace vault \
            --create-namespace \
            --set "server.standalone.enabled=true" \
            --set "server.dataStorage.size=10Gi" \
            --set "server.dataStorage.storageClass=longhorn" \
            --set "server.auditStorage.enabled=true" \
            --set "server.auditStorage.size=5Gi" \
            --set "server.auditStorage.storageClass=longhorn" \
            --set "injector.enabled=true" \
            --set "ui.enabled=true" \
            --wait --timeout 5m
    fi

    log "Vault pods deployed. Waiting for pod to be ready..."
    kubectl wait --for=condition=Ready pod/vault-0 -n vault --timeout=120s 2>/dev/null || true
}

# ─── Initialize Vault ───────────────────────────────────────────────────────
initialize_vault() {
    log "Checking Vault initialization status..."

    local init_status
    init_status=$(kubectl exec vault-0 -n vault -- vault status -format=json 2>/dev/null | jq -r '.initialized' 2>/dev/null || echo "false")

    if [ "$init_status" = "true" ]; then
        log "Vault already initialized."
        return 0
    fi

    log "Initializing Vault (5 key shares, 3 threshold)..."
    local init_output
    init_output=$(kubectl exec vault-0 -n vault -- vault operator init \
        -key-shares=5 \
        -key-threshold=3 \
        -format=json)

    echo "$init_output" > "$VAULT_DIR/init-keys.json"
    chmod 600 "$VAULT_DIR/init-keys.json"

    log "Vault initialized. Keys saved to $VAULT_DIR/init-keys.json"
    log "CRITICAL: Back up init-keys.json securely. Loss = permanent data loss."

    unseal_vault
}

# ─── Unseal Vault ────────────────────────────────────────────────────────────
unseal_vault() {
    log "Unsealing Vault..."

    if [ ! -f "$VAULT_DIR/init-keys.json" ]; then
        log "ERROR: No init keys found at $VAULT_DIR/init-keys.json"
        exit 1
    fi

    local sealed
    sealed=$(kubectl exec vault-0 -n vault -- vault status -format=json 2>/dev/null | jq -r '.sealed' 2>/dev/null || echo "true")

    if [ "$sealed" = "false" ]; then
        log "Vault already unsealed."
        return 0
    fi

    for i in 0 1 2; do
        local key
        key=$(jq -r ".unseal_keys_b64[$i]" "$VAULT_DIR/init-keys.json")
        kubectl exec vault-0 -n vault -- vault operator unseal "$key" >/dev/null 2>&1
    done

    log "Vault unsealed."
}

# ─── Configure Vault ────────────────────────────────────────────────────────
configure_vault() {
    log "Configuring Vault for MedinovAI platform..."

    local root_token
    root_token=$(jq -r '.root_token' "$VAULT_DIR/init-keys.json")

    kubectl exec vault-0 -n vault -- sh -c "
        export VAULT_TOKEN='$root_token'

        # Enable KV v2 secrets engine
        vault secrets enable -path=medinovai-secrets -version=2 kv 2>/dev/null || true

        # Enable audit log
        vault audit enable file file_path=/vault/audit/audit.log 2>/dev/null || true

        # Enable Kubernetes auth
        vault auth enable kubernetes 2>/dev/null || true
        vault write auth/kubernetes/config \
            kubernetes_host='https://\$KUBERNETES_SERVICE_HOST:\$KUBERNETES_SERVICE_PORT' 2>/dev/null || true

        # ─── Policies ─────────────────────────────────────────────────────
        # AtlasOS read policy
        vault policy write atlasos-read - <<'POLICY'
path \"medinovai-secrets/data/atlasos/*\" {
  capabilities = [\"read\", \"list\"]
}
path \"medinovai-secrets/data/infra/*\" {
  capabilities = [\"read\"]
}
POLICY

        # Platform services read policy
        vault policy write platform-read - <<'POLICY'
path \"medinovai-secrets/data/platform/*\" {
  capabilities = [\"read\", \"list\"]
}
path \"medinovai-secrets/data/infra/*\" {
  capabilities = [\"read\"]
}
POLICY

        # Security services policy
        vault policy write security-read - <<'POLICY'
path \"medinovai-secrets/data/security/*\" {
  capabilities = [\"read\", \"list\"]
}
POLICY

        # Clinical services policy
        vault policy write clinical-read - <<'POLICY'
path \"medinovai-secrets/data/clinical/*\" {
  capabilities = [\"read\", \"list\"]
}
path \"medinovai-secrets/data/infra/postgres-clinical\" {
  capabilities = [\"read\"]
}
POLICY

        # AI/ML services policy
        vault policy write ai-ml-read - <<'POLICY'
path \"medinovai-secrets/data/ai-ml/*\" {
  capabilities = [\"read\", \"list\"]
}
POLICY

        # Admin policy
        vault policy write deploy-admin - <<'POLICY'
path \"medinovai-secrets/*\" {
  capabilities = [\"create\", \"read\", \"update\", \"delete\", \"list\"]
}
POLICY

        # ─── Kubernetes Auth Roles ───────────────────────────────────────
        vault write auth/kubernetes/role/atlasos \
            bound_service_account_names=atlasos \
            bound_service_account_namespaces=medinovai-services,medinovai-ai \
            policies=atlasos-read \
            ttl=1h

        vault write auth/kubernetes/role/platform-services \
            bound_service_account_names='*' \
            bound_service_account_namespaces=medinovai-services \
            policies=platform-read \
            ttl=1h

        vault write auth/kubernetes/role/security-services \
            bound_service_account_names='*' \
            bound_service_account_namespaces=medinovai-security \
            policies=security-read \
            ttl=1h

        vault write auth/kubernetes/role/clinical-services \
            bound_service_account_names='*' \
            bound_service_account_namespaces=medinovai-clinical \
            policies=clinical-read \
            ttl=1h

        vault write auth/kubernetes/role/ai-ml-services \
            bound_service_account_names='*' \
            bound_service_account_namespaces=medinovai-ai \
            policies=ai-ml-read \
            ttl=1h
    "

    log "Vault configured with policies and Kubernetes auth roles."
}

# ─── Seed secrets ────────────────────────────────────────────────────────────
seed_secrets() {
    log "Seeding secrets into Vault..."

    local root_token
    root_token=$(jq -r '.root_token' "$VAULT_DIR/init-keys.json")

    export VAULT_ADDR="http://127.0.0.1:8200"

    # Port-forward Vault
    kubectl port-forward svc/vault -n vault 8200:8200 &>/dev/null &
    local pf_pid=$!
    sleep 3

    export VAULT_TOKEN="$root_token"

    # Read from existing .env if available
    local env_file=""
    if [ -f "$HOME/.atlas/.env" ]; then
        env_file="$HOME/.atlas/.env"
        log "Reading secrets from $env_file"
    elif [ -f "$REPO_ROOT/config/.env.example" ]; then
        env_file="$REPO_ROOT/config/.env.example"
        log "Using .env.example as template (values will be placeholders)"
    fi

    # Helper to put a secret, reading from env file or prompting
    put_secret() {
        local vault_path="$1"
        shift
        local kv_pairs=()
        for pair in "$@"; do
            local key="${pair%%=*}"
            local default="${pair#*=}"
            local value=""

            if [ -n "$env_file" ]; then
                value=$(grep "^${key}=" "$env_file" 2>/dev/null | head -1 | cut -d'=' -f2- | sed 's/^["'"'"']//;s/["'"'"']$//' || echo "")
            fi

            if [ -z "$value" ] || [ "$value" = "$default" ]; then
                value="$default"
            fi

            kv_pairs+=("${key}=${value}")
        done

        vault kv put "medinovai-secrets/${vault_path}" "${kv_pairs[@]}" 2>/dev/null && \
            log "  ✓ medinovai-secrets/${vault_path}" || \
            log "  ✗ medinovai-secrets/${vault_path} FAILED"
    }

    log ""
    log "─── Infrastructure secrets ───"
    put_secret "infra/postgres-primary" \
        "POSTGRES_URL=postgresql://medinovai:changeme@postgres-primary:5432/medinovai" \
        "POSTGRES_PASSWORD=changeme"

    put_secret "infra/postgres-clinical" \
        "POSTGRES_URL=postgresql://clinical:changeme@postgres-clinical:5432/clinical" \
        "POSTGRES_PASSWORD=changeme"

    put_secret "infra/redis" \
        "REDIS_URL=redis://redis-cache:6379"

    put_secret "infra/kafka" \
        "KAFKA_BROKERS=kafka:9092"

    put_secret "infra/elasticsearch" \
        "ELASTICSEARCH_URL=http://elasticsearch:9200"

    put_secret "infra/mongodb" \
        "MONGODB_URL=mongodb://mongodb:27017/medinovai"

    log ""
    log "─── Security secrets ───"
    put_secret "security/keycloak" \
        "KEYCLOAK_ADMIN=admin" \
        "KEYCLOAK_ADMIN_PASSWORD=changeme" \
        "KEYCLOAK_URL=http://keycloak:8080"

    put_secret "security/jwt" \
        "JWT_SECRET=changeme-generate-a-real-secret"

    log ""
    log "─── AtlasOS secrets ───"
    put_secret "atlasos/anthropic" "ANTHROPIC_API_KEY=sk-ant-changeme"
    put_secret "atlasos/openai" "OPENAI_API_KEY=sk-changeme"
    put_secret "atlasos/google-ai" "GOOGLE_AI_API_KEY=changeme"
    put_secret "atlasos/slack" "SLACK_APP_TOKEN=xapp-changeme" "SLACK_BOT_TOKEN=xoxb-changeme"
    put_secret "atlasos/hooks" "HOOKS_TOKEN=changeme"
    put_secret "atlasos/threecx" \
        "THREECX_HOST=changeme" \
        "THREECX_CLIENT_ID=changeme" \
        "THREECX_CLIENT_SECRET=changeme" \
        "THREECX_EXTENSION=changeme" \
        "THREECX_DID=changeme"
    put_secret "atlasos/whatsapp" \
        "WA_PHONE_NUMBER_ID=changeme" \
        "WA_ACCESS_TOKEN=changeme" \
        "WA_VERIFY_TOKEN=changeme"
    put_secret "atlasos/voice" \
        "ELEVENLABS_API_KEY=changeme" \
        "DEEPGRAM_API_KEY=changeme"
    put_secret "atlasos/crm" "CRM_API_KEY=changeme" "CRM_API_URL=changeme"
    put_secret "atlasos/ticketing" "TICKETS_API_KEY=changeme" "TICKETS_API_URL=changeme"
    put_secret "atlasos/accounting" "ACCOUNTING_API_KEY=changeme"
    put_secret "atlasos/gmail" "GMAIL_SERVICE_ACCOUNT_JSON={}" "GMAIL_WATCH_EMAIL=changeme"
    put_secret "atlasos/stirling-pdf" "STIRLING_PDF_API_KEY=atlas-stirling-key"
    put_secret "atlasos/arena" "ARENA_RECORDING_ENCRYPTION_KEY=changeme"

    log ""
    log "─── AI/ML secrets ───"
    put_secret "ai-ml/aifactory" "AIFACTORY_ENDPOINT=http://aifactory:5000"
    put_secret "ai-ml/ollama" "OLLAMA_HOST=http://ollama:11434"

    log ""
    log "─── Platform secrets ───"
    put_secret "platform/github" "GITHUB_WEBHOOK_SECRET=changeme"
    put_secret "platform/notification" "SMTP_HOST=changeme" "SMTP_USER=changeme" "SMTP_PASSWORD=changeme"

    # Clean up port-forward
    kill $pf_pid 2>/dev/null || true

    log ""
    log "Secret seeding complete."
    log "IMPORTANT: Replace 'changeme' values with real secrets:"
    log "  vault kv put medinovai-secrets/atlasos/anthropic ANTHROPIC_API_KEY=sk-ant-real-key"
}

# ─── Status ─────────────────────────────────────────────────────────────────
show_status() {
    log "Vault status:"
    kubectl exec vault-0 -n vault -- vault status 2>/dev/null || log "ERROR: Cannot reach Vault"
}

# ─── Main ─────────────────────────────────────────────────────────────────────
log "╔══════════════════════════════════════════════════════════════╗"
log "║     MedinovAI Deploy — HashiCorp Vault Setup                 ║"
log "╚══════════════════════════════════════════════════════════════╝"

case "$ACTION" in
    deploy)
        deploy_vault
        initialize_vault
        configure_vault
        log ""
        log "Vault ready. To seed secrets: bash $0 --seed"
        ;;
    seed)
        seed_secrets
        ;;
    unseal)
        unseal_vault
        ;;
    status)
        show_status
        ;;
esac
