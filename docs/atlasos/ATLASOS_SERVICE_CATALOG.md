# AtlasOS Service Catalog

**Total services**: 42 containers in single Docker Compose stack
**Source**: `medinovai-health/medinovai-atlas-os` (branch: `feature/atlasos-full-implementation`)
**Verified**: 2026-02-22

---

## Service Inventory

### Default Profile (Always Running)

| Service | Port | Type | Health | Build Context |
|---------|------|------|--------|---------------|
| mcp-core | 3100 | python | /health | `mcp-servers/Dockerfile` |
| mcp-governor | 3101 | python | /health | `mcp-servers/Dockerfile` |
| mcp-infrastructure | 3102 | python | /health | `mcp-servers/Dockerfile` |
| mcp-data | 3103 | python | /health | `mcp-servers/Dockerfile` |
| mcp-business | 3104 | python | /health | `mcp-servers/Dockerfile` |
| mcp-devtools | 3105 | python | /health | `mcp-servers/Dockerfile` |
| mcp-compliance | 3106 | python | /health | `mcp-servers/Dockerfile` |
| vault | 8200 | hashicorp/vault:1.17 | /v1/sys/health | image |
| vault-init | — | hashicorp/vault:1.17 | one-shot | image |
| user-config-db | 5432 | postgres:16-alpine | pg_isready | image |

### Runtime Profile

| Service | Port | Type | Health | Volumes |
|---------|------|------|--------|---------|
| event-bus | 8088 | python | /health | events-data |
| skill-engine | 8090 | python | /health | skill-artifacts |
| audit-chain | 8084 | python | /health | audit-data |
| agent-runtime | 8220→8200 | python | /health | — |
| memory-service | 8201 | python | /health | memory-data |
| agent-orchestrator | 8202 | python | /health | — |
| agent-mesh | 8203 | python | /health | — |
| tenancy-engine | 8204 | python | /health | tenancy-data |
| heartbeat-executor | 8205 | python | /health | — |
| learning-engine | 8206 | python | /health | — |
| security-mesh | 8207 | python | /health | — |
| governance-runtime | 8208 | python | /health | — |
| auth-bridge | 8250 | python | /health | auth-data |
| user-config | 8260 | python | /health | user-config-data |

### Connectors Profile

| Service | Port | Protocol | Vault | PHI Boundary |
|---------|------|----------|-------|--------------|
| fhir-r4 | 8301 | FHIR R4 REST | yes | yes |
| hl7-v2 | 8302 | HL7 v2 / MLLP | yes | yes |
| epic-fhir | 8303 | Epic FHIR + SMART | yes | yes |
| cerner-fhir | 8304 | Cerner FHIR + SMART | yes | yes |
| dicom | 8305 | DICOMweb | yes | yes |
| redcap | 8306 | REDCap REST | yes | yes |
| cdisc | 8307 | CDISC Library | yes | yes |
| terminology | 8308 | FHIR Terminology | yes | no |
| openehr | 8309 | OpenEHR REST | yes | yes |
| veeva | 8310 | Veeva Vault REST | yes | no |
| salesforce-health | 8311 | SOQL / Health Cloud | yes | yes |
| aws-healthlake | 8312 | AWS FHIR R4 | yes | yes |
| azure-health | 8313 | Azure FHIR R4 | yes | yes |

### Compliance Profile

| Service | Port | Standard | Persistence |
|---------|------|----------|-------------|
| pccp-engine | 8401 | FDA/MDR PCCP | pccp-data |
| breach-notify | 8402 | HIPAA Breach | breach-data |
| e-signatures | 8403 | 21 CFR Part 11 | esig-data |
| hazard-log | 8404 | ISO 14971 | hazard-data |
| capa-workflow | 8405 | ISO 13485 | capa-data |
| consent-mgmt | 8406 | GDPR/HIPAA/DPDPA | consent-data |

---

## Dependency Graph

```
vault ────────┬──────────────────────────────────────────────┐
              │                                              │
        vault-init                                     user-config-db
              │
              ▼
       ┌──────────────┐
       │  event-bus    │◄──── all connectors
       │  (8088)       │◄──── all compliance
       └──────┬───────┘◄──── all runtime services
              │
    ┌─────────┼──────────────┐
    ▼         ▼              ▼
memory-svc  tenancy-eng  skill-engine
 (8201)      (8204)       (8090)
    │         │              │
    ▼         ▼              ▼
agent-runtime ◄── agent-mesh ◄── agent-orchestrator
   (8220)        (8203)          (8202)
                                    │
                              ┌─────┼─────┐
                              ▼     ▼     ▼
                          security governance heartbeat
                           (8207)   (8208)    (8205)
```

---

## Health Check Endpoints

All services expose `/health` returning JSON:

```json
{
  "status": "ok",
  "service": "service-name",
  "vault": "ok|unreachable"
}
```

Connector health includes additional fields:

```json
{
  "status": "ok",
  "connector": "fhir_r4",
  "vault": "ok",
  "circuit": "closed|open|half-open",
  "credentials": "vault|local_store|empty"
}
```

### Bulk Health Check

```bash
for port in 3100 3101 3102 3103 3104 3105 3106 \
            8084 8088 8090 8200 8201 8202 8203 8204 8205 8206 8207 8208 8220 8250 8260 \
            8301 8302 8303 8304 8305 8306 8307 8308 8309 8310 8311 8312 8313 \
            8401 8402 8403 8404 8405 8406; do
  status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:$port/health 2>/dev/null)
  echo "Port $port: $status"
done
```

---

## Environment Variables

### Required for Production

| Variable | Default | Purpose |
|----------|---------|---------|
| `VAULT_DEV_TOKEN` | `atlasos-dev-root-token` | Vault root token (dev mode) |
| `DB_USER` | `atlasos` | PostgreSQL username |
| `DB_PASSWORD` | `atlasos-secure-change-me` | PostgreSQL password |
| `LLM_ENDPOINT` | `http://ai-orchestrator:8000` | LLM inference endpoint |

### Connector-Specific (Stored in Vault)

Each connector retrieves credentials from Vault at runtime. Store them via:

```bash
# Example: Store Epic FHIR credentials
curl -X POST http://localhost:8200/v1/medinovai-secrets/data/atlasos/connectors/epic_fhir \
  -H "X-Vault-Token: atlasos-dev-root-token" \
  -d '{
    "data": {
      "client_id": "epic-client-id",
      "private_key": "-----BEGIN RSA PRIVATE KEY-----\n...",
      "base_url": "https://fhir.epic.com/interconnect-fhir-oauth/api/FHIR/R4"
    }
  }'
```

---

## Governance Controls

All 11 GOV controls are enforced by the governance-runtime service (port 8208):

| Control | Endpoint | Purpose |
|---------|----------|---------|
| GOV-01 | POST /models/register | Model risk register |
| GOV-02 | POST /validation/run | Pre-deployment validation |
| GOV-03 | POST /bias/test | Bias testing |
| GOV-04 | GET /override/status | Human override pathways |
| GOV-05 | POST /explainability/check | Explainability standards |
| GOV-06 | GET /monitoring/drift | Performance monitoring |
| GOV-07 | POST /lineage/record | Data lineage tracking |
| GOV-08 | POST /vendor/register | Vendor accountability |
| GOV-09 | POST /incidents/report | Incident response |
| GOV-10 | POST /board/approval | Cross-functional oversight |
| GOV-11 | GET /enforcement/status | Enforcement verification |
