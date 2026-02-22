# AtlasOS Full-Stack Deployment Guide

**Last verified**: 2026-02-22 — 42 containers, all healthy
**Source repo**: `medinovai-health/medinovai-atlas-os` (branch: `feature/atlasos-full-implementation`)
**Deploy repo**: `medinovai-health/medinovai-deploy`

---

## Architecture Overview

AtlasOS is a multi-tenant, healthcare-grade agentic AI platform deployed as a single Docker Compose stack with profile-based service grouping:

```
┌─────────────────────────────────────────────────────────────────┐
│                    Single Docker Compose Stack                   │
├─────────────┬──────────────┬──────────────┬────────────────────┤
│  Default    │   Runtime    │  Connectors  │    Compliance      │
│  (always)   │   profile    │   profile    │     profile        │
├─────────────┼──────────────┼──────────────┼────────────────────┤
│ 7 MCP Srvrs │ Agent Runtime│ FHIR R4      │ PCCP Engine        │
│ Vault       │ Memory Svc   │ HL7 v2       │ Breach Notify      │
│ Vault-Init  │ Tenancy Eng  │ Epic FHIR    │ E-Signatures       │
│ PostgreSQL  │ Event Bus    │ Cerner FHIR  │ Hazard Log         │
│             │ Skill Engine │ DICOM        │ CAPA Workflow      │
│             │ Audit Chain  │ REDCap       │ Consent Mgmt       │
│             │ Agent Mesh   │ CDISC/SDTM   │                    │
│             │ Orchestrator │ Terminology  │                    │
│             │ Heartbeat    │ OpenEHR      │                    │
│             │ Learning Eng │ Veeva Vault  │                    │
│             │ Security Mesh│ Salesforce HC│                    │
│             │ Governance   │ AWS HLake    │                    │
│             │ Auth Bridge  │ Azure Health │                    │
│             │ User Config  │              │                    │
└─────────────┴──────────────┴──────────────┴────────────────────┘
```

**Total services**: 42 containers across 4 profile groups

---

## Quick Start

```bash
# Clone the AtlasOS repo
git clone https://github.com/medinovai-health/medinovai-atlas-os.git
cd medinovai-atlas-os
git checkout feature/atlasos-full-implementation

# Start default services (MCP + Vault + PostgreSQL)
docker compose up -d

# Start runtime (agent swarm)
docker compose --profile runtime up -d

# Start healthcare connectors
docker compose --profile connectors up -d --build

# Start compliance services
docker compose --profile compliance up -d --build

# OR start everything at once
docker compose --profile runtime --profile connectors --profile compliance up -d --build

# Check status
docker compose --profile runtime --profile connectors --profile compliance ps
```

---

## Docker Compose Profiles

| Profile | Services | Purpose |
|---------|----------|---------|
| *(default)* | 7 MCP servers, Vault, vault-init, PostgreSQL | Core platform |
| `runtime` | 14 agent services + user-config | Agent swarm runtime |
| `connectors` | 13 healthcare connectors | External system integration |
| `compliance` | 6 regulatory services | Healthcare compliance |
| `backup` | backup-agent sidecar | Automated volume backups |
| `stos` | 11 silent trial services | Clinical trial OS |

### Common Commands

```bash
# Full stack start
make runtime-all

# Health check
make runtime-health
make connectors-health
make compliance-health

# Stop everything (data preserved)
docker compose --profile runtime --profile connectors --profile compliance down

# Destroy (WARNING: removes volumes)
docker compose --profile runtime --profile connectors --profile compliance down -v
```

---

## Port Registry

### Core Infrastructure

| Port | Service | Purpose |
|------|---------|---------|
| 3100 | mcp-core | Core MCP server |
| 3101 | mcp-governor | Governance MCP |
| 3102 | mcp-infrastructure | Infrastructure MCP |
| 3103 | mcp-data | Data MCP |
| 3104 | mcp-business | Business MCP |
| 3105 | mcp-devtools | DevTools MCP |
| 3106 | mcp-compliance | Compliance MCP |
| 5432 | user-config-db | PostgreSQL (user/tenant data) |
| 8200 | vault | HashiCorp Vault (secrets) |

### Agent Swarm Runtime

| Port | Service | Purpose |
|------|---------|---------|
| 8084 | audit-chain | Hash-chained audit log |
| 8088 | event-bus | Pub/sub event fabric |
| 8090 | skill-engine | SKILL.md parser and executor |
| 8201 | memory-service | 4-network vector memory |
| 8202 | agent-orchestrator | Fleet lifecycle, kill switch |
| 8203 | agent-mesh | Agent-to-agent communication |
| 8204 | tenancy-engine | SAES hierarchy enforcement |
| 8205 | heartbeat-executor | Health check execution |
| 8206 | learning-engine | Performance tracking |
| 8207 | security-mesh | Cryptographic identity |
| 8208 | governance-runtime | GOV-01 to GOV-11 enforcement |
| 8220 | agent-runtime | Core agent brain (host port) |
| 8250 | auth-bridge | OIDC/SAML bridge |
| 8260 | user-config | Per-user config + Vault secrets |

### Healthcare Connectors

| Port | Service | Protocol/Standard |
|------|---------|-------------------|
| 8301 | fhir-r4 | FHIR R4 REST API |
| 8302 | hl7-v2 | HL7 v2 (ADT, ORU, MLLP) |
| 8303 | epic-fhir | Epic FHIR + SMART Backend |
| 8304 | cerner-fhir | Cerner/Oracle FHIR + SMART |
| 8305 | dicom | DICOMweb (WADO-RS, QIDO-RS) |
| 8306 | redcap | REDCap REST API |
| 8307 | cdisc | CDISC Library, SDTM/ADaM |
| 8308 | terminology | FHIR $lookup/$translate/$expand |
| 8309 | openehr | OpenEHR REST (AQL, compositions) |
| 8310 | veeva | Veeva Vault documents/trials |
| 8311 | salesforce-health | Health Cloud SOQL |
| 8312 | aws-healthlake | FHIR R4 HealthLake datastore |
| 8313 | azure-health | Azure FHIR R4 |

### Compliance Services

| Port | Service | Standard |
|------|---------|----------|
| 8401 | pccp-engine | FDA/MDR change control |
| 8402 | breach-notify | HIPAA breach management |
| 8403 | e-signatures | 21 CFR Part 11 |
| 8404 | hazard-log | ISO 14971 risk management |
| 8405 | capa-workflow | ISO 13485 CAPA lifecycle |
| 8406 | consent-mgmt | GDPR/HIPAA/DPDPA consent |

---

## Secrets Management (HashiCorp Vault)

### Architecture

All secrets flow through HashiCorp Vault. No `.env` files for application secrets.

```
┌──────────────┐    ┌─────────────┐    ┌──────────────────┐
│ User Config  │───▶│   Vault     │───▶│ KV v2 Engine     │
│ Service      │    │  (port 8200)│    │ medinovai-secrets/│
│ (port 8260)  │    └─────────────┘    └──────────────────┘
└──────────────┘          ▲
                          │
┌──────────────┐          │
│ All 13       │──────────┘
│ Connectors   │  (VAULT_ADDR + VAULT_TOKEN env vars)
└──────────────┘
```

### Secret Paths

| Path | Contents |
|------|----------|
| `medinovai-secrets/data/atlasos/config` | Global AtlasOS config |
| `medinovai-secrets/data/atlasos/users/{tenant_id}/{user_id}` | Per-user secrets |
| `medinovai-secrets/data/atlasos/connectors/{connector_id}` | Connector credentials |

### Environment Variables

Every service receives:

```yaml
VAULT_ADDR: http://vault:8200
VAULT_TOKEN: ${VAULT_DEV_TOKEN:-atlasos-dev-root-token}
```

### Production Vault Setup

For production, replace dev mode with AppRole auth:

```bash
# Enable AppRole
vault auth enable approle

# Create policy
vault policy write atlasos-read - <<EOF
path "medinovai-secrets/data/atlasos/*" {
  capabilities = ["read", "list"]
}
EOF

# Create role
vault write auth/approle/role/atlasos \
  token_policies="atlasos-read" \
  token_ttl=1h \
  token_max_ttl=4h

# Get role_id and secret_id for each service
vault read auth/approle/role/atlasos/role-id
vault write -f auth/approle/role/atlasos/secret-id
```

---

## Per-User Config Preservation

### How It Works

Each user's configuration is stored in two layers:

1. **Non-secret preferences** (locale, theme, settings): File-backed JSON on a Docker named volume (`user-config-data`)
2. **Secret keys/tokens** (API keys, EHR tokens, passwords): Stored in Vault KV v2

### API Reference

```bash
# Store user config (secrets auto-routed to Vault)
curl -X PUT http://localhost:8260/users/{user_id}/config \
  -H "Content-Type: application/json" \
  -d '{
    "tenant_id": "nhs_trust_a",
    "locale": "en-GB",
    "theme": "dark",
    "secret_api_key": "sk-xxx",
    "ehr_token": "epic-token-xxx"
  }'

# Retrieve config (secrets excluded)
curl http://localhost:8260/users/{user_id}/config?tenant_id=nhs_trust_a

# Retrieve specific secret from Vault
curl http://localhost:8260/users/{user_id}/secrets/{key}?tenant_id=nhs_trust_a

# List all users for a tenant
curl http://localhost:8260/users?tenant_id=nhs_trust_a

# Export all configs for a tenant
curl http://localhost:8260/export?tenant_id=nhs_trust_a

# Delete user config + Vault secrets
curl -X DELETE http://localhost:8260/users/{user_id}/config?tenant_id=nhs_trust_a
```

### Secret Auto-Routing Rules

Fields matching these patterns are automatically stored in Vault (not on disk):

| Pattern | Example |
|---------|---------|
| `secret_*` | `secret_api_key` |
| `*_key` | `encryption_key` |
| `*_token` | `ehr_token`, `access_token` |
| `*_password` | `db_password` |

Everything else is stored as non-secret preferences on the persistent volume.

---

## Data Preservation Across Updates

### Named Docker Volumes

All persistent data uses named Docker volumes that survive container rebuilds and image updates:

| Volume | Mounted By | Contents |
|--------|-----------|----------|
| `vault-logs` | vault | Vault audit logs |
| `postgres-data` | user-config-db | PostgreSQL data |
| `user-config-data` | user-config | Per-user JSON configs |
| `memory-data` | memory-service | Agent memory vectors |
| `tenancy-data` | tenancy-engine | SAES hierarchy |
| `events-data` | event-bus | Event store |
| `audit-data` | audit-chain | Audit hash chain |
| `skill-artifacts` | skill-engine | Compiled skills |
| `stos-data` | STOS services | Trial data |
| `pccp-data` | pccp-engine | Change control records |
| `breach-data` | breach-notify | Breach records |
| `esig-data` | e-signatures | Electronic signatures |
| `hazard-data` | hazard-log | Hazard records |
| `capa-data` | capa-workflow | CAPA records |
| `consent-data` | consent-mgmt | Consent records |
| `backup-data` | backup-agent | Volume snapshots |

### Backup Strategy

The `backup-agent` sidecar (profile: `backup`) runs every 6 hours:

```bash
# Start backup agent
docker compose --profile backup up -d backup-agent

# Backups stored in the backup-data volume
# Each backup is timestamped: {service}_{YYYYMMDD_HHMMSS}/
```

### Safe Update Procedure

```bash
# 1. Back up all volumes
docker compose --profile backup up -d backup-agent
# Wait for first backup cycle or trigger manually

# 2. Pull new images / rebuild
docker compose --profile runtime --profile connectors --profile compliance build

# 3. Rolling restart (one profile at a time)
docker compose up -d                                           # Default services
docker compose --profile runtime up -d                         # Runtime
docker compose --profile connectors up -d                      # Connectors
docker compose --profile compliance up -d                      # Compliance

# 4. Verify
docker compose --profile runtime --profile connectors --profile compliance ps
```

**All named volumes are preserved during `docker compose down`**. Only `docker compose down -v` removes them.

---

## Multi-Tenant Architecture

### SAES Hierarchy

```
System (medinovai)
├── Tenant (nhs_trust_a)
│   ├── Department (radiology)
│   │   ├── Study (trial_001)
│   │   │   ├── User (dr_smith)
│   │   │   │   └── Patient (patient_001)
│   │   │   └── User (nurse_jones)
│   │   └── Study (trial_002)
│   └── Department (cardiology)
└── Tenant (private_hospital_b)
    └── ...
```

### Tenant Isolation Rules

1. **Config isolation**: User configs are scoped by `tenant_id` — no cross-tenant access
2. **Secret isolation**: Vault paths include `{tenant_id}/{user_id}` — physical separation
3. **Memory isolation**: Memory service enforces tenant-scoped queries
4. **Connector isolation**: Each connector validates `tenant_id` before data access
5. **Event isolation**: Event bus tags all events with `tenant_id` for filtering

---

## Troubleshooting

### Container shows "unhealthy"

All healthchecks use `python3 -c "import urllib.request; ..."`. If a container shows unhealthy:

```bash
# Check if the service actually responds
curl http://localhost:{PORT}/health

# Check logs
docker logs atlasos-{service}-1 --tail 20

# Force recreate to pick up healthcheck changes
docker compose --profile {profile} up -d --force-recreate {service}
```

### Vault connection issues

```bash
# Check Vault is running
curl http://localhost:8200/v1/sys/health

# Check secrets engine
curl -H "X-Vault-Token: atlasos-dev-root-token" \
  http://localhost:8200/v1/sys/mounts | python3 -m json.tool
```

### Port conflicts

```bash
# Check what's using a port
lsof -i :{PORT}

# Key conflict to watch: Vault (8200) vs agent-runtime (mapped to 8220 on host)
```

---

## Integration with medinovai-Deploy

This deployment is self-contained within the AtlasOS repo's `docker-compose.yml`. For production K3s deployment managed by medinovai-Deploy:

- Kubernetes manifests: `AtlasOS/infra/kubernetes/`
- Helm integration: Through `medinovai-Deploy/infra/kubernetes/services/atlasos/`
- Vault policies: `medinovai-Deploy/infra/kubernetes/vault/policies/atlasos-read.hcl`
- CEO Stack: `medinovai-Deploy/infra/docker/docker-compose.ceo.yml`

The AtlasOS `docker-compose.yml` is designed to run independently for development and testing, while the medinovai-Deploy orchestration handles production K3s deployment.
