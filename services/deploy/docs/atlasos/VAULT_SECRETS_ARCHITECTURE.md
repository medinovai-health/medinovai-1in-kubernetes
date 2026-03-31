# AtlasOS Vault Secrets Architecture

## Overview

All AtlasOS secrets are managed through HashiCorp Vault. No secrets in `.env` files, no secrets in Docker Compose environment blocks, no secrets in source code.

```
┌────────────────────────────────────────────────────────────┐
│                    HashiCorp Vault                          │
│                    (KV v2 Engine)                           │
│                                                            │
│  medinovai-secrets/                                        │
│  ├── data/atlasos/config/         ← global config          │
│  ├── data/atlasos/users/          ← per-user secrets       │
│  │   ├── {tenant_id}/                                      │
│  │   │   ├── {user_id}            ← API keys, tokens       │
│  │   │   └── ...                                           │
│  │   └── ...                                               │
│  ├── data/atlasos/connectors/     ← connector credentials  │
│  │   ├── fhir_r4                                           │
│  │   ├── epic_fhir                                         │
│  │   ├── cerner_fhir                                       │
│  │   └── ...                                               │
│  └── data/atlasos/compliance/     ← compliance secrets     │
│      ├── esig_signing_key                                  │
│      └── breach_notification_creds                         │
└────────────────────────────────────────────────────────────┘
```

## How Secrets Are Delivered

### 1. Service-Level (Connectors, Compliance)

Each service receives `VAULT_ADDR` and `VAULT_TOKEN` as environment variables:

```yaml
environment:
  - VAULT_ADDR=http://vault:8200
  - VAULT_TOKEN=${VAULT_DEV_TOKEN:-atlasos-dev-root-token}
```

Services use the Vault HTTP API or `hvac` Python client to read secrets at runtime.

### 2. Per-User Secrets

The `user-config` service (port 8260) acts as a proxy:

1. Client sends config with mixed data: `{"theme": "dark", "secret_api_key": "sk-xxx"}`
2. Service separates secrets from preferences using naming conventions
3. Preferences → file-backed JSON (Docker volume)
4. Secrets → Vault KV v2 at `medinovai-secrets/data/atlasos/users/{tenant}/{user}`

### 3. Auto-Secret Detection

Fields are classified as secrets if they match:

| Pattern | Examples |
|---------|----------|
| `secret_*` | `secret_api_key`, `secret_webhook_url` |
| `*_key` | `encryption_key`, `api_key` |
| `*_token` | `ehr_token`, `access_token`, `refresh_token` |
| `*_password` | `db_password`, `smtp_password` |

## Vault Initialization

### Dev Mode (Default)

Vault runs in dev mode with an in-memory backend. The `vault-init` sidecar:

1. Waits for Vault to be healthy
2. Enables `kv-v2` at `medinovai-secrets/`
3. Exits

```yaml
vault-init:
  command: |
    vault secrets enable -path=medinovai-secrets kv-v2 2>/dev/null || true
```

### Production Mode

For production, Vault should run with:

1. **File or Consul storage backend** (not in-memory)
2. **AppRole authentication** (not root token)
3. **Auto-unseal** (AWS KMS, GCP KMS, or Transit)
4. **TLS enabled**
5. **Audit logging enabled**

```bash
# Enable audit log
vault audit enable file file_path=/vault/logs/audit.log

# Create read-only policy for AtlasOS services
vault policy write atlasos-read - <<EOF
path "medinovai-secrets/data/atlasos/*" {
  capabilities = ["read", "list"]
}
EOF

# Create read-write policy for user-config service
vault policy write atlasos-user-config - <<EOF
path "medinovai-secrets/data/atlasos/users/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "medinovai-secrets/data/atlasos/config/*" {
  capabilities = ["read", "list"]
}
EOF

# Enable AppRole
vault auth enable approle

# Create AppRole for connectors (read-only)
vault write auth/approle/role/atlasos-connector \
  token_policies="atlasos-read" \
  token_ttl=1h \
  token_max_ttl=4h

# Create AppRole for user-config (read-write)
vault write auth/approle/role/atlasos-user-config \
  token_policies="atlasos-user-config" \
  token_ttl=1h \
  token_max_ttl=4h
```

## Secret Rotation

### Manual Rotation

```bash
# Rotate a connector's credentials
curl -X POST http://localhost:8200/v1/medinovai-secrets/data/atlasos/connectors/epic_fhir \
  -H "X-Vault-Token: ${VAULT_TOKEN}" \
  -d '{"data": {"client_id": "new-id", "private_key": "new-key"}}'

# Connector will pick up new credentials on next circuit-breaker reset
```

### Automated Rotation (Production)

Use Vault's built-in rotation or integrate with `medinovai-Deploy/scripts/maintenance/rotate_secrets.sh`.

## Backup and Recovery

### Vault Data

In dev mode, Vault data is in-memory and lost on restart. For persistence:

1. Use the `backup` profile to snapshot running state
2. Or switch to file/Consul storage for production

### User Config Data

```bash
# Export all configs for a tenant
curl http://localhost:8260/export?tenant_id=nhs_trust_a > backup_nhs_trust_a.json

# Vault secrets are backed up when vault-data volume is snapshotted
```

## Tenant-Scoped Access Control

Each tenant's secrets are physically separated in Vault:

```
medinovai-secrets/data/atlasos/users/
├── nhs_trust_a/           ← Tenant A's users
│   ├── dr_smith           ← Dr. Smith's API keys, tokens
│   └── nurse_jones        ← Nurse Jones' API keys, tokens
├── private_hospital_b/    ← Tenant B's users (completely separate)
│   └── dr_patel
└── research_org_c/        ← Tenant C
    └── researcher_1
```

Vault policies can restrict access per tenant:

```hcl
path "medinovai-secrets/data/atlasos/users/nhs_trust_a/*" {
  capabilities = ["read", "list"]
}
```

## Audit Trail

Every Vault access is logged when audit is enabled:

```bash
vault audit enable file file_path=/vault/logs/audit.log
```

Additionally, the `user-config` service publishes events to the event-bus:

| Event | Trigger |
|-------|---------|
| `user_config.updated` | Config or secret stored/updated |
| `user_config.deleted` | Config and secrets deleted |

These events flow to the audit-chain for hash-chained immutable logging.
