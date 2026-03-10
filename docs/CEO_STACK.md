# AtlasOS Named Assistant Stack Deployment Guide

## Overview

The CEO stack deploys Arjun as one `Named Assistant` inside the broader AtlasOS
four-layer platform:
- **atlas-command**: The executive command center UI for the Arjun named assistant
- **atlas-gateway**: AtlasOS runtime mounted to the live `~/.atlas` state for named assistant execution
- **atlas-ui**: Chat and deployment management interface
- **audit-chain**: Zero-trust hash-chained audit service
- **MCP connectors**: Read-only connectors for vTiger, QuickBooks, Google Workspace, LIS, Mattermost
- **HashiCorp Vault**: Centralized secrets management (never .env)
- **Supporting infra**: PostgreSQL, Redis, ChromaDB, Stirling-PDF

This stack is not the whole AtlasOS architecture. It is the deployment pattern
for one named assistant, backed by shared functional agents, entity agents, and
squad agents running in the AtlasOS environments managed by `medinovai-Deploy`.

## Zero-Trust Architecture

AtlasOS operates under a permanent zero-trust model:

| Autonomous (No Approval) | Requires Human Approval |
|--------------------------|------------------------|
| READ any connected system | SEND external communications |
| ANALYZE data and patterns | WRITE to external systems |
| CORRELATE across systems | DEPLOY code or config |
| ALERT on anomalies | PAY or commit finances |
| PREPARE decisions | DELETE data |
| DRAFT content | MODIFY permissions |
| RESEARCH markets | |
| RECOMMEND with rationale | |

Every action (autonomous or approved) is hash-chained in the audit service.

## Quick Start

```bash
# From medinovai-Deploy root: deploy the Arjun named assistant stack
make ceo-stack

# Check health
make ceo-health

# View logs
make ceo-stack-logs

# Verify audit integrity
make ceo-audit-verify
```

## Services and Ports

| Service | Port | URL |
|---------|------|-----|
| Atlas Command (Arjun UI) | 3000 | http://localhost:3000 |
| Atlas UI (Chat) | 3737 | http://localhost:3737 |
| Atlas Gateway | 18789 | http://localhost:18789 |
| Vault | 8200 | http://localhost:8200 |
| Audit Chain | 8084 | http://localhost:8084 |
| PostgreSQL | 5432 | -- |
| Redis | 6379 | -- |
| ChromaDB | 8003 | -- |
| MCP vTiger | 8090 | http://localhost:8090 |
| MCP QuickBooks | 8091 | http://localhost:8091 |
| MCP Google | 8092 | http://localhost:8092 |
| MCP LIS | 8093 | http://localhost:8093 |
| MCP Mattermost | 8094 | http://localhost:8094 |
| Stirling-PDF | 8083 | http://localhost:8083 |

## First-Time Setup

1. **Deploy the stack**: `make ceo-stack`
2. **Open Atlas Command**: http://localhost:3000
3. **Navigate to Settings**: Click the gear icon or go to /settings
4. **Configure Vault**: Vault auto-initializes in dev mode. For production, configure AppRole auth.
5. **Add integrations**: Enter credentials for each system in the Settings page. They are stored in Vault.
6. **Test connections**: Use "Test Connection" on each integration card.

## Gateway Runtime Source Of Truth

- `ceo-atlas-gateway` is the production owner of port `18789`.
- The gateway container bind-mounts the live host runtime from `~/.atlas`.
- `ATLASOS_CONFIG_PATH` resolves to `~/.atlas/atlasos.json` inside the container.
- `ATLASOS_STATE_DIR` resolves to `~/.atlas/` inside the container.
- The native `com.medinovai.atlas-engine` LaunchAgent is diagnostic-only and should remain disabled in production.
- This stack represents a single named assistant deployment. Employee assistants,
  SOP/protocol/regulation agents, and other entity runtimes should reuse the
  same four-layer AtlasOS architecture rather than fork a separate CEO-only path.

## Configuration

All configuration is done through the Atlas Command UI at `/settings` or through the live
runtime under `~/.atlas` for break-glass recovery. No application secrets should be
committed to the repo.

Environment variables for Docker orchestration only:

| Variable | Default | Purpose |
|----------|---------|---------|
| `VAULT_PORT` | 8200 | Vault port |
| `ATLAS_COMMAND_PORT` | 3000 | Command Center port |
| `ATLAS_UI_PORT` | 3737 | Atlas UI port |
| `ATLAS_GATEWAY_PORT` | 18789 | Gateway port |
| `ATLAS_GATEWAY_UID` | 0 | Container user ID for writing mounted `~/.atlas` state |
| `ATLAS_GATEWAY_GID` | 0 | Container group ID for writing mounted `~/.atlas` state |
| `AUDIT_PORT` | 8084 | Audit service port |
| `AIFACTORY_ENDPOINT` | http://host.docker.internal:5000 | AIFactory endpoint |
| `OLLAMA_HOST` | http://host.docker.internal:11434 | Ollama endpoint |
| `ATLASOS_PATH` | ../../repos/AtlasOS | Path to AtlasOS repo |
| `ATLAS_COMMAND_PATH` | ../../repos/atlas-command | Path to atlas-command repo |

## Audit Trail

Every action is recorded in the hash-chained audit log:

```bash
# Verify chain integrity
make ceo-audit-verify

# Query audit logs
curl http://localhost:8084/audit/query?agent=ops&limit=10

# Export for external review
curl http://localhost:8084/audit/export > audit_export.jsonl
```

## Repo Dependencies

| Repo | Purpose |
|------|---------|
| `medinovai-Deploy` | This repo - deployment orchestration |
| `AtlasOS` (`medinovai-atlas-os`) | Shared agent runtime, audit chain, MCP connectors, healthcare connectors, compliance services, and the four-layer agent model |
| `atlas-command` | CO-CEO Command Center UI |
| `medinovai-security-service` | Vault and Keycloak (production) |

## AtlasOS Full Stack Documentation

The AtlasOS full-stack deployment (42 containers, single compose) is documented in:

| Document | Contents |
|----------|----------|
| [ATLASOS_DEPLOYMENT_GUIDE](atlasos/ATLASOS_DEPLOYMENT_GUIDE.md) | Quick start, profiles, ports, multi-tenant, troubleshooting |
| [ATLASOS_SERVICE_CATALOG](atlasos/ATLASOS_SERVICE_CATALOG.md) | All 42 services, health endpoints, dependency graph |
| [VAULT_SECRETS_ARCHITECTURE](atlasos/VAULT_SECRETS_ARCHITECTURE.md) | Vault setup, per-user secrets, tenant isolation, rotation |
| [DOCKER_COMPOSE_REFERENCE](atlasos/DOCKER_COMPOSE_REFERENCE.md) | Profiles, volumes, common operations |
| [CONNECTOR_DEPLOYMENT_MATRIX](atlasos/CONNECTOR_DEPLOYMENT_MATRIX.md) | 13 healthcare connectors, tools, credentials |
| [DEPLOYMENT_FINDINGS](atlasos/DEPLOYMENT_FINDINGS.md) | Issues encountered, resolutions, production checklist |
