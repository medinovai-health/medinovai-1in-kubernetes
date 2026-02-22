# AtlasOS Docker Compose Reference

## File Location

```
medinovai-atlas-os/docker-compose.yml
```

This is a self-contained single-file deployment for the entire AtlasOS stack.

## Profile System

Docker Compose profiles allow selective deployment:

```bash
# Default only (MCP + Vault + DB) — 10 containers
docker compose up -d

# Add runtime — +14 containers
docker compose --profile runtime up -d

# Add connectors — +13 containers
docker compose --profile connectors up -d

# Add compliance — +6 containers
docker compose --profile compliance up -d

# Everything — 42+ containers
docker compose --profile runtime --profile connectors --profile compliance up -d

# With backup sidecar
docker compose --profile runtime --profile connectors --profile compliance --profile backup up -d

# With STOS (silent trial)
docker compose --profile stos up -d
```

## Service Groups

### Default (no profile required)

| Service | Image/Build | Port | Notes |
|---------|-------------|------|-------|
| mcp-core | build: `mcp-servers/` | 3100 | |
| mcp-governor | build: `mcp-servers/` | 3101 | |
| mcp-infrastructure | build: `mcp-servers/` | 3102 | |
| mcp-data | build: `mcp-servers/` | 3103 | |
| mcp-business | build: `mcp-servers/` | 3104 | |
| mcp-devtools | build: `mcp-servers/` | 3105 | |
| mcp-compliance | build: `mcp-servers/` | 3106 | |
| vault | `hashicorp/vault:1.17` | 8200 | Secrets engine |
| vault-init | `hashicorp/vault:1.17` | — | One-shot init |
| user-config-db | `postgres:16-alpine` | 5432 | Persistent DB |

### Runtime Profile

| Service | Build | Port | Dependencies |
|---------|-------|------|-------------|
| event-bus | `services/event-bus/` | 8088 | — |
| skill-engine | `services/skill-engine/` | 8090 | event-bus |
| audit-chain | `services/audit-chain/` | 8084 | event-bus |
| agent-runtime | `services/agent-runtime/` | 8220→8200 | event-bus, memory, mesh, security, governance, vault |
| memory-service | `services/memory-service/` | 8201 | event-bus |
| agent-orchestrator | `services/agent-orchestrator/` | 8202 | agent-runtime, agent-mesh |
| agent-mesh | `services/agent-mesh/` | 8203 | event-bus, security-mesh |
| tenancy-engine | `services/tenancy-engine/` | 8204 | event-bus |
| heartbeat-executor | `services/heartbeat-executor/` | 8205 | event-bus, agent-orchestrator |
| learning-engine | `services/learning-engine/` | 8206 | event-bus, memory-service |
| security-mesh | `services/security-mesh/` | 8207 | event-bus, audit-chain |
| governance-runtime | `services/governance-runtime/` | 8208 | event-bus, audit-chain, security-mesh |
| auth-bridge | `services/auth-bridge/` | 8250 | vault |
| user-config | `services/user-config/` | 8260 | vault, event-bus |

### Connectors Profile

All connectors build from `services/mcp-connectors/{name}/Dockerfile` with `context: .` (repo root).

| Service | Port | Dependencies |
|---------|------|-------------|
| fhir-r4 | 8301 | event-bus, vault |
| hl7-v2 | 8302 | event-bus, vault |
| epic-fhir | 8303 | event-bus, vault |
| cerner-fhir | 8304 | event-bus, vault |
| dicom | 8305 | event-bus, vault |
| redcap | 8306 | event-bus, vault |
| cdisc | 8307 | event-bus, vault |
| terminology | 8308 | event-bus, vault |
| openehr | 8309 | event-bus, vault |
| veeva | 8310 | event-bus, vault |
| salesforce-health | 8311 | event-bus, vault |
| aws-healthlake | 8312 | event-bus, vault |
| azure-health | 8313 | event-bus, vault |

### Compliance Profile

| Service | Port | Volumes |
|---------|------|---------|
| pccp-engine | 8401 | pccp-data |
| breach-notify | 8402 | breach-data |
| e-signatures | 8403 | esig-data |
| hazard-log | 8404 | hazard-data |
| capa-workflow | 8405 | capa-data |
| consent-mgmt | 8406 | consent-data |

## Extension Anchors

The compose file defines YAML anchors for shared config:

```yaml
x-vault-env: &vault-env
  VAULT_ADDR: http://vault:8200
  VAULT_TOKEN: ${VAULT_DEV_TOKEN:-atlasos-dev-root-token}

x-db-env: &db-env
  DATABASE_URL: postgresql://${DB_USER:-atlasos}:${DB_PASSWORD:-atlasos-secure-change-me}@user-config-db:5432/atlasos
```

## Network

All services share a single Docker network:

```yaml
networks:
  default:
    name: atlasos-enterprise
```

## Named Volumes

| Volume | Used By | Purpose |
|--------|---------|---------|
| stos-data | STOS services | Trial data |
| memory-data | memory-service | Agent memory |
| tenancy-data | tenancy-engine | Hierarchy |
| events-data | event-bus | Event log |
| skill-artifacts | skill-engine | Skills |
| audit-data | audit-chain | Audit chain |
| pccp-data | pccp-engine | Change control |
| breach-data | breach-notify | Breaches |
| esig-data | e-signatures | Signatures |
| hazard-data | hazard-log | Hazards |
| capa-data | capa-workflow | CAPAs |
| consent-data | consent-mgmt | Consent |
| auth-data | auth-bridge | Auth state |
| vault-logs | vault | Vault logs |
| postgres-data | user-config-db | PostgreSQL |
| backup-data | backup-agent | Snapshots |
| user-config-data | user-config | User prefs |

## Common Operations

### Build without cache

```bash
docker compose --profile runtime --profile connectors --profile compliance build --no-cache
```

### Force recreate specific service

```bash
docker compose --profile connectors up -d --force-recreate --build fhir-r4
```

### View logs for a service

```bash
docker compose --profile runtime logs -f agent-runtime --tail 50
```

### Scale a service (stateless only)

```bash
docker compose --profile connectors up -d --scale fhir-r4=3
```

### Export volume data

```bash
docker run --rm -v atlasos_memory-data:/data -v $(pwd):/backup alpine \
  tar czf /backup/memory-data-backup.tar.gz -C /data .
```

### Import volume data

```bash
docker run --rm -v atlasos_memory-data:/data -v $(pwd):/backup alpine \
  tar xzf /backup/memory-data-backup.tar.gz -C /data
```
