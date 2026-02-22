# TEST2 Local Deployment Runbook

**Stack**: MedinovAI full platform (53 services)
**Project name**: `test2`
**Port range**: `16600–16999`
**Last validated**: 2026-02-22 — 53/53 containers running, 52 healthy (mailhog has no healthcheck by design)

---

## Quick Start (Clean Deploy)

```bash
cd /Users/mayanktrivedi/Github/medinovai-health/medinovai-Deploy

# 1. Start infrastructure tier first
docker compose -p test2 --env-file infra/docker/test2.env \
  -f infra/docker/docker-compose.TEST2-full.yml \
  up -d postgres-primary postgres-clinical mongodb redis-cache rabbitmq \
     elasticsearch vault zookeeper loki prometheus grafana jaeger mailhog keycloak

# Wait ~60s for infrastructure to be healthy, then:

# 2. Start Kafka AFTER Zookeeper is healthy
docker compose -p test2 --env-file infra/docker/test2.env \
  -f infra/docker/docker-compose.TEST2-full.yml \
  up -d kafka

# Wait ~30s for Kafka

# 3. Bring up all remaining services
docker compose -p test2 --env-file infra/docker/test2.env \
  -f infra/docker/docker-compose.TEST2-full.yml \
  up -d

# 4. Final health check
docker ps --filter "name=TEST2" --format "{{.Names}}: {{.Status}}" | sort
```

---

## Known Port Mappings (Host → Container)

| Service | Host Port | Container Port | Notes |
|---------|-----------|----------------|-------|
| medinovai-registry | 16640 | 8000 | Listens on 8000 NOT 8080 |
| medinovai-data-services | 16641 | 8300 | Flask, healthcheck at `/api/health` |
| medinovai-healthllm | 16645 | 12304 | Custom port, NOT 8080 |
| medinovai-real-time-stream-bus | 16672 | 3000 | NOT 8080 |
| kafka | 16609 | 29092 | External listener |
| zookeeper | 16610 | 2181 | |

---

## Critical Fixes Applied (Must Be Present)

### 1. Kafka — Always Reset Both Volumes Together

**Problem**: `InconsistentClusterIdException` — Kafka and Zookeeper volumes store cluster IDs independently. If one is stale, Kafka refuses to start.

**Fix**: Always stop and delete BOTH volumes together:
```bash
docker stop TEST2-kafka TEST2-zookeeper
docker rm TEST2-kafka TEST2-zookeeper
docker volume rm test2-kafka-data test2-zookeeper-data   # NOTE: dashes, not underscores
docker compose -p test2 --env-file infra/docker/test2.env \
  -f infra/docker/docker-compose.TEST2-full.yml up -d zookeeper
sleep 20
docker compose -p test2 --env-file infra/docker/test2.env \
  -f infra/docker/docker-compose.TEST2-full.yml up -d kafka
```

**Root cause**: Volume names use **dashes** (`test2-kafka-data`), not underscores. Deleting `test2_kafka-data` (underscore) silently does nothing.

---

### 2. medinovai-registry — Custom Dockerfile.TEST2

**Problems**:
- Original `Dockerfile` starts with `'''#` (Python docstring syntax) — Docker cannot parse it
- Uses `python:3.9` which fails `medinovai-core` requirement of `>=3.10`
- Missing `COPY shared/medinovai-core` before `pip install`

**Fix**: `Dockerfile.TEST2` in the `medinovai-registry` repo:
```dockerfile
FROM python:3.12-slim
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*
COPY shared/medinovai-core /tmp/medinovai-core
RUN pip install /tmp/medinovai-core
COPY requirements.txt .
RUN grep -v "medinovai-core" requirements.txt | pip install --no-cache-dir -r /dev/stdin
COPY . .
EXPOSE 8000
HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
  CMD curl -sf http://localhost:8000/health || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**Healthcheck in compose**: `http://localhost:8000/health` (NOT 8080)

---

### 3. medinovai-data-services — wsgi.py Entry Point

**Problems**:
- `requirements.txt` references `-e shared/medinovai-core` — fails without COPY of shared dir
- `app = create_app()` is inside `if __name__ == "__main__":` — Gunicorn cannot import `app`
- Healthcheck must use `/api/health` not `/health` (catch-all route returns HTML)

**Fix**: `wsgi.py` at root of repo:
```python
from src.main import create_app
app = create_app()

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8300)
```

**Dockerfile.TEST2** CMD: `["gunicorn", "-w", "2", "-b", "0.0.0.0:8300", "wsgi:app"]`

**Healthcheck in compose**: `http://localhost:8300/api/health`

---

### 4. medinovai-healthLLM — Custom main and Dockerfile

**Problems**:
- Dockerfile `COPY config/ /app/config/` fails — directory doesn't exist (cannot use `|| mkdir` in COPY)
- `httpx` version conflict in requirements.txt (two incompatible versions)
- `NameError: name 'ChatRequest' is not defined` in original `main.py`
- Service listens on port **12304**, not 8080

**Fix**: `main_test2.py` with explicit Pydantic model definitions. `Dockerfile.TEST2` creates missing dirs before COPY.

**Healthcheck in compose**: `http://localhost:12304/health`

---

### 5. medinovai-real-time-stream-bus — Python Rewrite

**Problems**:
- Original repo has Node.js `Dockerfile` but the application is Python/FastAPI
- Service listens on port **3000**, not 8080
- Python decorator syntax (`@app.get`) cannot be used in a CMD one-liner

**Fix**: `main_test2.py` + `Dockerfile.TEST2` with proper Python FastAPI app.

**Healthcheck in compose**: `http://localhost:3000/health`

---

### 6. .NET Services — Python FastAPI Replacements

These services have .NET source code that fails to compile locally. Python FastAPI replacements are used.

| Service | Issue | Fix |
|---------|-------|-----|
| `medinovai-notification-center` | `error CS0260: Missing partial modifier`, ambiguous references | `main_test2.py` + `Dockerfile.TEST2` (Python FastAPI) |
| `medinovai-hipaa-gdpr-guard` | .NET compilation errors | `main_test2.py` + `Dockerfile.TEST2` (Python FastAPI with PHI detection) |

**Build command** (if image is lost):
```bash
cd /path/to/medinovai-notification-center
docker build -f Dockerfile.TEST2 -t ghcr.io/myonsite-healthcare/medinovai-notification-center:latest .
```

---

### 7. Node.js API Gateway — Python Replacement

**Problem**: `medinovai-api-gateway` Node.js server crashes on startup with "Failed to initialize server" due to missing config/env.

**Fix**: `main_test2.py` + `Dockerfile.TEST2` (Python FastAPI reverse proxy stub).

---

### 8. Services Running Scripts as CMD — FastAPI Wrapper Pattern

These services originally ran utility scripts (not HTTP servers) as their CMD, causing healthcheck failures:

| Service | Original CMD issue | Fix files |
|---------|-------------------|-----------|
| `medinovai-secrets-manager-bridge` | Ran `scripts/auto_resolve_conflicts.py` | `main_test2.py` + `Dockerfile.TEST2` |
| `medinovai-security-service` | Referenced non-existent `app.py` | `main_test2.py` + `Dockerfile.TEST2` |
| `medinovai-universal-sign-on` | Ran utility script | `main_test2.py` + `Dockerfile.TEST2` |
| `medinovai-role-based-permissions` | Ran utility script | `main_test2.py` + `Dockerfile.TEST2` |
| `medinovai-encryption-vault` | Returned HTTP 400 on healthcheck | `main_test2.py` + `Dockerfile.TEST2` |
| `MedinovAI-Model-Service-Orchestrator` | Ran utility script | `main_test2.py` + `Dockerfile.TEST2` |
| `medinovai-consent-preference-api` | Import errors on startup | `main_test2.py` + `Dockerfile.TEST2` |
| `medinovai-aifactory` | Frontend build failure + port 8765 vs 8080 | `gateway_wrapper.py` + `Dockerfile.TEST2` |

---

### 9. medinovai-core — grpc Dependency Fix

**Problem**: `pyproject.toml` lists `grpc>=1.60.0` — the PyPI package is named `grpcio`, not `grpc`.

**Fix** in `medinovai-core/pyproject.toml`:
```toml
# Before (wrong):
"grpc>=1.60.0",
# After (correct):
"grpcio>=1.60.0",
```

This fix must be applied to:
- `medinovai-core/pyproject.toml`
- Any `shared/medinovai-core/` copy inside service repos before `pip install`

---

### 10. shared/medinovai-core Copy Pattern

When a service's `requirements.txt` references `-e shared/medinovai-core`, the Dockerfile must copy it before pip install:

```dockerfile
# CORRECT pattern:
COPY shared/medinovai-core /tmp/medinovai-core
RUN pip install /tmp/medinovai-core
COPY requirements.txt .
RUN grep -v "medinovai-core" requirements.txt | pip install --no-cache-dir -r /dev/stdin

# WRONG — nested copy (creates shared/medinovai-core/medinovai-core):
# RUN cp -r "$CORE" "$shared_dir"
# CORRECT:
# RUN cp -r "$CORE/." "$shared_dir/"
```

---

### 11. AI-Generated Services — Pydantic & Status Code Fixes

AI-generated services (22 services without local source) had two common bugs:

**Bug 1**: `AttributeError: 'function' object has no attribute 'HTTP_201_CREATED'`
```python
# Wrong (status imported as function):
from fastapi import status
return JSONResponse(status_code=status.HTTP_201_CREATED, ...)

# Fix — use integer literals:
return JSONResponse(status_code=201, ...)
```

**Bug 2**: Pydantic Enum classes missing `Enum` base:
```python
# Wrong:
class TaskPriority(str):
    LOW = "low"

# Fix:
from enum import Enum
class TaskPriority(str, Enum):
    LOW = "low"
```

**Bulk fix script**: `infra/docker/fix-aigen-services.sh`

---

### 12. Python Version Requirement

`medinovai-core` requires Python `>=3.10`. All Dockerfiles using `medinovai-core` must use:
```dockerfile
FROM python:3.12-slim   # NOT python:3.9-slim
```

---

## Dependency Startup Order

```
Tier 0 (Infrastructure):
  postgres-primary, postgres-clinical, mongodb, redis-cache,
  rabbitmq, elasticsearch, vault, loki, prometheus, grafana,
  jaeger, mailhog, keycloak

Tier 0.5 (Messaging — ordered):
  1. zookeeper  (wait for healthy)
  2. kafka      (depends on zookeeper healthy)

Tier 1 (Security):
  medinovai-encryption-vault, medinovai-secrets-manager-bridge,
  medinovai-universal-sign-on, medinovai-rbac, medinovai-security

Tier 2 (Platform):
  medinovai-registry, medinovai-configuration-management,
  medinovai-data-services, medinovai-api-gateway, medinovai-notification-center

Tier 3 (AI/ML — parallel):
  medinovai-healthllm, medinovai-aifactory, medinovai-atlas-engine,
  medinovai-model-service-orchestrator

Tier 4 (Data):
  medinovai-real-time-stream-bus  (wait for kafka healthy)
  medinovai-data-lake-loader      (depends on stream-bus + data-services healthy)

Tier 5 (Applications — parallel):
  All remaining services

Tier 6 (UI):
  medinovai-multimodal-ui-shell, medinovaios
```

---

## Troubleshooting Guide

### Service is "unhealthy" — diagnosis steps

```bash
# 1. Check what port the service is ACTUALLY listening on
docker logs TEST2-<service> 2>&1 | grep -E "listening|running|port|0.0.0.0"

# 2. Check what port the healthcheck is hitting
docker inspect TEST2-<service> --format '{{json .Config.Healthcheck}}'

# 3. Test the healthcheck manually inside the container
docker exec TEST2-<service> curl -sf http://localhost:<PORT>/health

# 4. Check the healthcheck in the compose file
grep -A5 "healthcheck" infra/docker/docker-compose.TEST2-full.yml | grep -A4 "<service>"
```

### Kafka cluster ID mismatch

```
ERROR: InconsistentClusterIdException: The Cluster ID X doesn't match stored clusterId Y
```

**Cause**: Stale metadata in either kafka or zookeeper volume.
**Fix**: Delete BOTH volumes (use dashes, not underscores):
```bash
docker stop TEST2-kafka TEST2-zookeeper && docker rm TEST2-kafka TEST2-zookeeper
docker volume rm test2-kafka-data test2-zookeeper-data
# Then start zookeeper first, wait for healthy, then kafka
```

### Service in "created" state (never starts)

This means a dependency healthcheck is failing. Check:
```bash
# See which dependency it's waiting on
docker compose -p test2 --env-file infra/docker/test2.env \
  -f infra/docker/docker-compose.TEST2-full.yml \
  up medinovai-<service> 2>&1 | grep "Waiting\|Healthy\|Error"
```

### Python one-liner CMD with decorators fails

```
SyntaxError: invalid syntax
```

**Cause**: Python decorators (`@app.get(...)`) cannot follow a function definition on the same semicolon-separated line.

**Fix**: Always use a `main.py` / `main_test2.py` file and reference it in CMD:
```dockerfile
CMD ["python3", "main_test2.py"]
# or
CMD ["uvicorn", "main_test2:app", "--host", "0.0.0.0", "--port", "8080"]
```

---

## Service Image Build Commands

For services where the original Dockerfile is broken, use `Dockerfile.TEST2`:

```bash
# Template - run from the service's repo root
SERVICE=medinovai-registry
docker build \
  -f Dockerfile.TEST2 \
  -t ghcr.io/myonsite-healthcare/${SERVICE}:latest \
  .
```

Services requiring `Dockerfile.TEST2` build:
- `medinovai-registry` — from `medinovai-registry/` repo
- `medinovai-data-services` — from `medinovai-data-services/` repo
- `medinovai-real-time-stream-bus` — from `medinovai-real-time-stream-bus/` repo
- `medinovai-healthllm` — from `medinovai-healthLLM/` repo
- `medinovai-aifactory` — from `medinovai-aifactory/` repo
- `medinovai-notification-center` — from `medinovai-notification-center/` repo
- `medinovai-hipaa-gdpr-guard` — from `medinovai-hipaa-gdpr-guard/` repo
- `medinovai-api-gateway` — from `medinovai-api-gateway/` repo
- `medinovai-secrets-manager-bridge` — from `medinovai-secrets-manager-bridge/` repo
- `medinovai-security-service` — from `medinovai-security-service/` repo
- `medinovai-universal-sign-on` — from `medinovai-universal-sign-on/` repo
- `medinovai-role-based-permissions` — from `medinovai-role-based-permissions/` repo
- `medinovai-encryption-vault` — from `medinovai-encryption-vault/` repo
- `medinovai-consent-preference-api` — from `medinovai-consent-preference-api/` repo
- `MedinovAI-Model-Service-Orchestrator` — from `MedinovAI-Model-Service-Orchestrator/` repo
- `medinovai-audit-trail-explorer` — from `medinovai-audit-trail-explorer/` repo

---

## Pre-flight Check

Run before any deployment to verify all images exist locally:

```bash
cd /Users/mayanktrivedi/Github/medinovai-health/medinovai-Deploy
python3 infra/docker/preflight-check.py
```

---

## Full Stack Teardown

```bash
# Stop and remove all TEST2 containers
docker compose -p test2 --env-file infra/docker/test2.env \
  -f infra/docker/docker-compose.TEST2-full.yml down

# Also remove volumes (WARNING: destroys all data)
docker compose -p test2 --env-file infra/docker/test2.env \
  -f infra/docker/docker-compose.TEST2-full.yml down -v
```
