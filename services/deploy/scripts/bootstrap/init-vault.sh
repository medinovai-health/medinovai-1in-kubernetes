#!/usr/bin/env bash
# ─── init-vault.sh ────────────────────────────────────────────────────────────
# Initialize HashiCorp Vault for the MedinovAI platform.
#
# Idempotent: safe to re-run on every bootstrap. Checks existing state before
# enabling engines or creating roles.
#
# Usage:
#   bash scripts/bootstrap/init-vault.sh                    # Docker Compose dev
#   bash scripts/bootstrap/init-vault.sh --mode k8s         # K8s (port-forward first)
#   bash scripts/bootstrap/init-vault.sh --seed-only        # Re-seed secrets only
#
# Prerequisites (Docker Compose dev):
#   1. Vault container must be running and healthy (docker compose up -d vault)
#   2. VAULT_ADDR and VAULT_TOKEN must be set (or defaults used)
#   3. Source .env before running: set -a && source infra/docker/.env && set +a
#
# Vault dev mode root token default: medinovai-dev-token
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

MODE="compose"
SEED_ONLY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --mode)       MODE="$2"; shift 2 ;;
        --seed-only)  SEED_ONLY=true; shift ;;
        *)            echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ── Configuration ─────────────────────────────────────────────────────────────
VAULT_ADDR="${VAULT_ADDR:-http://localhost:8200}"
VAULT_TOKEN="${VAULT_TOKEN:-${VAULT_DEV_ROOT_TOKEN:-medinovai-dev-token}}"
export VAULT_ADDR VAULT_TOKEN

# Block dev tokens in non-dev environments
if [[ "${ENVIRONMENT:-dev}" != "dev" && "$VAULT_TOKEN" == "medinovai-dev-token" ]]; then
    echo "FATAL: Cannot use dev token in ${ENVIRONMENT}. Set VAULT_TOKEN explicitly."
    exit 1
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
ok()   { echo "  ✓ $*"; }
log()  { echo "▸ $*"; }
warn() { echo "  ⚠ $*"; }

vault_cmd() { vault "$@" 2>/dev/null; }

engine_enabled() {
    vault secrets list -format=json 2>/dev/null | grep -q "\"$1/\""
}

auth_enabled() {
    vault auth list -format=json 2>/dev/null | grep -q "\"$1/\""
}

secret_exists() {
    vault kv get "$1" &>/dev/null
}

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║       Vault Initialization — MedinovAI Platform             ║"
echo "║       Mode: $MODE"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# ── Wait for Vault ─────────────────────────────────────────────────────────────
log "Waiting for Vault to be ready at $VAULT_ADDR..."
for i in $(seq 1 30); do
    if vault status -address="$VAULT_ADDR" &>/dev/null; then
        ok "Vault is ready"
        break
    fi
    if [[ $i -eq 30 ]]; then
        echo "ERROR: Vault not ready after 30s. Ensure the vault container is running."
        exit 1
    fi
    printf "."
    sleep 1
done
echo ""

if [[ "$SEED_ONLY" == "false" ]]; then

# ── Step 1: Enable KV v2 secrets engine ───────────────────────────────────────
log "Step 1/4 — KV v2 secrets engine"
if engine_enabled "medinovai-secrets"; then
    ok "KV v2 already enabled at medinovai-secrets/"
else
    vault secrets enable -path=medinovai-secrets kv-v2
    ok "KV v2 enabled at medinovai-secrets/"
fi

# ── Step 2: Enable AppRole auth (Docker Compose / non-K8s services) ──────────
log "Step 2/4 — AppRole auth method"
if auth_enabled "approle"; then
    ok "AppRole already enabled"
else
    vault auth enable approle
    ok "AppRole auth enabled"
fi

# ── Step 3: Enable Kubernetes auth (K8s pods) ─────────────────────────────────
log "Step 3/4 — Kubernetes auth method"
if [[ "$MODE" == "k8s" ]]; then
    if auth_enabled "kubernetes"; then
        ok "Kubernetes auth already enabled"
    else
        vault auth enable kubernetes
        # Configure K8s auth — requires the vault pod to be running in cluster
        # or KUBERNETES_SERVICE_HOST to be set
        K8S_HOST="${KUBERNETES_SERVICE_HOST:-https://kubernetes.default.svc}"
        vault write auth/kubernetes/config \
            kubernetes_host="$K8S_HOST" \
            disable_iss_validation=true
        ok "Kubernetes auth enabled and configured"
    fi
else
    ok "Kubernetes auth skipped (compose mode)"
fi

# ── Step 4: Per-service Vault policies ────────────────────────────────────────
log "Step 4/4 — Per-service policies"

write_policy() {
    local name="$1"
    local path="$2"
    vault policy write "$name" - <<EOF
path "medinovai-secrets/data/$path" {
  capabilities = ["read"]
}
path "medinovai-secrets/metadata/$path" {
  capabilities = ["read"]
}
EOF
    ok "Policy: $name → medinovai-secrets/$path"
}

write_policy "infra-postgres"        "infra/postgres"
write_policy "infra-redis"           "infra/redis"
write_policy "keycloak-deploy"       "keycloak/deploy"
write_policy "keycloak-medinovaios"  "keycloak/medinovaios"
write_policy "lis-keycloak"          "lis/keycloak"
write_policy "lis-mysql"             "lis/mysql"
write_policy "lis-jwt"               "lis/jwt"
write_policy "registry"              "registry/*"
write_policy "cortex"                "cortex/*"
write_policy "sales"                 "sales/*"
write_policy "notification-service"  "notification-service/*"
write_policy "api-gateway"           "infra/*"
write_policy "auth-service"          "keycloak/*"
write_policy "clinical-engine"       "infra/*"
write_policy "data-pipeline"         "infra/*"
write_policy "ai-inference"          "infra/*"
write_policy "medinovaios"           "keycloak/medinovaios"

# ── AppRole: create roles per service ────────────────────────────────────────
create_approle() {
    local name="$1"
    local policies="$2"
    local sid_ttl="0"
    local num_uses="0"
    if [[ "${ENVIRONMENT:-dev}" != "dev" ]]; then
        sid_ttl="24h"
        num_uses="100"
    fi
    vault write "auth/approle/role/$name" \
        secret_id_ttl="$sid_ttl" \
        token_num_uses="$num_uses" \
        token_ttl=1h \
        token_max_ttl=4h \
        token_policies="$policies"
    ok "AppRole role: $name (policies: $policies)"
}

create_approle "postgres"             "infra-postgres"
create_approle "redis"                "infra-redis"
create_approle "keycloak-deploy"      "keycloak-deploy"
create_approle "medinovaios"          "keycloak-medinovaios"
create_approle "lis-keycloak"         "lis-keycloak"
create_approle "lis-api"              "lis-keycloak,lis-mysql,lis-jwt"
create_approle "registry"             "registry"
create_approle "cortex"               "cortex"
create_approle "sales"                "sales"
create_approle "notification-service" "notification-service"
create_approle "api-gateway"          "api-gateway"
create_approle "auth-service"         "auth-service"

# ── K8s auth: bind service accounts to policies ──────────────────────────────
if [[ "$MODE" == "k8s" ]]; then
    bind_k8s_role() {
        local name="$1"
        local ns="$2"
        local policies="$3"
        vault write "auth/kubernetes/role/$name" \
            bound_service_account_names="$name" \
            bound_service_account_namespaces="$ns" \
            policies="$policies" \
            ttl=1h
        ok "K8s role: $name in $ns"
    }

    bind_k8s_role "api-gateway"          "medinovai-services"  "api-gateway"
    bind_k8s_role "auth-service"         "medinovai-services"  "auth-service"
    bind_k8s_role "clinical-engine"      "medinovai-services"  "clinical-engine"
    bind_k8s_role "data-pipeline"        "medinovai-services"  "data-pipeline"
    bind_k8s_role "notification-service" "medinovai-services"  "notification-service"
    bind_k8s_role "ai-inference"         "medinovai-ai"        "ai-inference"
    bind_k8s_role "medinovaios"          "medinovai-os"        "medinovaios"
fi

fi # end if not seed-only

# ── Seed secrets into Vault KV v2 ─────────────────────────────────────────────
log "Seeding secrets into Vault KV v2..."
echo ""
echo "  Secrets are seeded from environment variables."
echo "  Make sure you have sourced your .env file before running this script."
echo ""

seed_secret() {
    local path="$1"
    shift
    if secret_exists "medinovai-secrets/$path"; then
        ok "Already exists: medinovai-secrets/$path (skipping)"
        return
    fi
    vault kv put "medinovai-secrets/$path" "$@"
    ok "Seeded: medinovai-secrets/$path"
}

# Infrastructure
[[ -n "${POSTGRES_PASSWORD:-}" ]] && \
    seed_secret "infra/postgres" password="${POSTGRES_PASSWORD}"
[[ -n "${REDIS_PASSWORD:-}" ]] && \
    seed_secret "infra/redis" password="${REDIS_PASSWORD}"

# Keycloak (Deploy stack)
[[ -n "${KEYCLOAK_ADMIN_PASSWORD:-}" ]] && \
    seed_secret "keycloak/deploy" \
        admin_password="${KEYCLOAK_ADMIN_PASSWORD}" \
        db_password="${POSTGRES_PASSWORD:-}"

# Keycloak (medinovaiOS client)
[[ -n "${KEYCLOAK_CLIENT_SECRET:-}" ]] && \
    seed_secret "keycloak/medinovaios" \
        client_secret="${KEYCLOAK_CLIENT_SECRET}"

# LIS Keycloak
[[ -n "${LIS_KC_ADMIN_PASSWORD:-}" ]] && \
    seed_secret "lis/keycloak" \
        admin_password="${LIS_KC_ADMIN_PASSWORD}" \
        db_password="${LIS_KC_DB_PASSWORD:-}" \
        client_secret="${LIS_KC_CLIENT_SECRET:-}"

# LIS MySQL
[[ -n "${LIS_MYSQL_ROOT_PASSWORD:-}" ]] && \
    seed_secret "lis/mysql" \
        root_password="${LIS_MYSQL_ROOT_PASSWORD}" \
        user_password="${LIS_MYSQL_PASSWORD:-}"

# LIS JWT
[[ -n "${LIS_JWT_SECRET:-}" ]] && \
    seed_secret "lis/jwt" secret="${LIS_JWT_SECRET}"

echo ""
log "Writing AppRole credentials to infra/docker/.env (gitignored)..."

ENV_FILE="$(dirname "$0")/../../infra/docker/.env"

append_approle_creds() {
    local role="$1"
    local role_id
    local secret_id
    role_id=$(vault read -field=role_id "auth/approle/role/$role/role-id" 2>/dev/null || true)
    secret_id=$(vault write -field=secret_id -f "auth/approle/role/$role/secret-id" 2>/dev/null || true)
    if [[ -n "$role_id" && -n "$secret_id" ]]; then
        local var_prefix
        var_prefix=$(echo "$role" | tr '[:lower:]-' '[:upper:]_')
        grep -q "${var_prefix}_VAULT_ROLE_ID" "$ENV_FILE" 2>/dev/null || \
            echo "${var_prefix}_VAULT_ROLE_ID=${role_id}" >> "$ENV_FILE"
        grep -q "${var_prefix}_VAULT_SECRET_ID" "$ENV_FILE" 2>/dev/null || \
            echo "${var_prefix}_VAULT_SECRET_ID=${secret_id}" >> "$ENV_FILE"
        ok "AppRole creds for $role written to .env"
    fi
}

append_approle_creds "medinovaios"
append_approle_creds "api-gateway"
append_approle_creds "auth-service"
append_approle_creds "notification-service"
append_approle_creds "registry"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   Vault initialization complete.                             ║"
echo "║   Vault UI: http://localhost:8200  token: \$VAULT_DEV_ROOT_TOKEN"
echo "╚══════════════════════════════════════════════════════════════╝"
