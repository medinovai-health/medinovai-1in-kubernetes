# AtlasOS Named Deployment Identity — Deployment Guide

**Date:** 2026-03-10  
**Source:** `medinovai-health/medinovai-atlas-os` (design doc: `docs/DESIGN_NAMED_DEPLOYMENT_IDENTITY.md`)  
**Status:** Implemented in AtlasOS v5.x  

---

## Overview

Every AtlasOS deployment carries a **named identity** — a human-readable name for the organization that owns the instance. This identity propagates through all 50+ services, the UI, API responses, audit logs, and inter-service calls.

When deploying AtlasOS through medinovai-Deploy, the instance identity is configured via environment variables injected into the Docker Compose stacks.

---

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `ATLASOS_INSTANCE_ID` | `ins_default` | Immutable machine identifier (auto-generated at install) |
| `ATLASOS_INSTANCE_NAME` | `medinovai` | DNS-safe deployment name (e.g. `acme-health`) |
| `ATLASOS_DISPLAY_NAME` | `MedinovAI` | Human-readable org name for UI and prompts |
| `ATLASOS_DEFAULT_TENANT` | `medinovai` | Default tenant ID when `X-Tenant-ID` header is absent |
| `ATLASOS_ENVIRONMENT` | `development` | `development`, `staging`, or `production` |

These are defined in `envs/base.env` and can be overridden in per-environment files (`envs/dev.env`, `envs/staging.env`, `envs/prod.env`).

---

## Configuring a New Deployment

### Option A: Via AtlasOS Install Script

```bash
cd ~/Github/medinovai-health/AtlasOS
bash scripts/install_atlasos.sh --name acme-health --org "Acme Health Systems"
```

This generates `config/instance.yaml` and appends to `.env`. The medinovai-Deploy env files should then be updated to match.

### Option B: Via medinovai-Deploy Environment Files

Edit `envs/base.env` (or the appropriate per-environment file):

```bash
ATLASOS_INSTANCE_ID=ins_a1b2c3d4
ATLASOS_INSTANCE_NAME=acme-health
ATLASOS_DISPLAY_NAME=Acme Health Systems
ATLASOS_DEFAULT_TENANT=acme-health
ATLASOS_ENVIRONMENT=production
```

Then activate the environment:

```bash
./scripts/env-manager.sh activate prod --all
```

### Option C: Kubernetes / Helm

Set in `values.yaml` or as ConfigMap entries:

```yaml
instance:
  id: "ins_a1b2c3d4"
  name: "acme-health"
  displayName: "Acme Health Systems"
  defaultTenant: "acme-health"
  environment: "production"
```

---

## Verification

After deployment, verify the instance identity:

```bash
# Check any service health endpoint
curl -s http://localhost:8000/health | jq '{instance_id, instance_name, environment}'

# Check the UI instance API
curl -s http://localhost:3737/api/instance | jq '{instance_name, display_name, environment}'
```

Expected output:
```json
{
  "instance_id": "ins_a1b2c3d4",
  "instance_name": "acme-health",
  "environment": "production"
}
```

---

## How It Works

1. Environment variables are set in `envs/*.env` files
2. `env-manager.sh` activates the environment, which loads the vars
3. Docker Compose `x-instance-env` anchor in AtlasOS distributes vars to all 50+ containers
4. Each Python service reads vars via `lib/instance_identity.py`
5. Each UI component reads vars via `GET /api/instance` and the `InstanceProvider` React context
6. Health endpoints, audit logs, SDK calls, and inter-service headers all carry the instance identity

---

## Backward Compatibility

Existing MedinovAI deployments require zero changes. All variables default to the current values (`medinovai` / `MedinovAI`). The instance identity auto-generates on first boot if not configured.

---

## Reference

- Full design document: `AtlasOS/docs/DESIGN_NAMED_DEPLOYMENT_IDENTITY.md`
- Instance config template: `AtlasOS/config/instance.yaml.template`
- JSON schema: `AtlasOS/schemas/instance_identity.schema.json`
- Runtime module: `AtlasOS/lib/instance_identity.py`
- Database migration: `AtlasOS/services/migrations/sql/011_instance_identity.sql`
