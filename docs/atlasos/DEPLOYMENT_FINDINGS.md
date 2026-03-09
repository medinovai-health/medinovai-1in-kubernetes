# AtlasOS Deployment Findings & Lessons Learned

> Scope note: this document records findings from the older AtlasOS-local compose
> stack. The authoritative deployment path has since moved to
> `medinovai-Deploy/scripts/env-manager.sh` and the layered compose files under
> `medinovai-Deploy/infra/docker/compose/`.

**Date**: 2026-02-22
**Deploy type**: Docker Compose (local, single-node)
**Branch**: `feature/atlasos-full-implementation` on `medinovai-atlas-os`

---

## Issues Encountered and Resolutions

### 1. Gunicorn 22+ Breaks `module:object.attr` Syntax

**Problem**: All 13 healthcare connectors used gunicorn CMD like:
```
CMD ["gunicorn", "fhir_r4.connector:connector.app"]
```
Gunicorn 22+ changed the app loader — nested attribute access (`connector.app`) is no longer parsed.

**Error**: `Failed to parse 'connector.app' as an attribute name or function call.`

**Fix**: Added `app = connector.app` at module level in every `connector.py`, then changed CMD to:
```
CMD ["gunicorn", "fhir_r4.connector:app"]
```

**Lesson**: Always use flat module-level exports for gunicorn. Never rely on `object.attribute` in the app specifier.

### 2. Dockerfile COPY Path vs Build Context Mismatch

**Problem**: Several connector Dockerfiles used paths relative to their own directory:
```dockerfile
COPY base_connector.py .
COPY connector.py .
```
But `docker-compose.yml` set `context: .` (repo root), making these paths invalid.

**Error**: `failed to compute cache key: "/cerner_fhir/connector.py": not found`

**Fix**: Standardized all Dockerfiles to use repo-root-relative paths:
```dockerfile
COPY services/mcp-connectors/base_connector.py /app/services/mcp-connectors/
COPY services/mcp-connectors/fhir_r4/ /app/services/mcp-connectors/fhir_r4/
```

**Lesson**: When `docker-compose.yml` uses `context: .`, all `COPY` paths in Dockerfiles must be relative to the repo root.

### 3. Missing hl7_v2 Dockerfile

**Problem**: `services/mcp-connectors/hl7_v2/Dockerfile` was never created during initial implementation.

**Error**: `failed to read dockerfile: open Dockerfile: no such file or directory`

**Fix**: Created the Dockerfile following the standardized pattern.

**Lesson**: When generating multiple similar services, verify every required file exists before deployment.

### 4. Vault Port Conflict with Agent Runtime

**Problem**: Both Vault and agent-runtime were configured to use port 8200.

**Error**: `Bind for 0.0.0.0:8200 failed: port is already allocated`

**Fix**: Remapped agent-runtime host port to 8220: `ports: ["8220:8200"]`

**Lesson**: When adding infrastructure services (Vault, DB) to an existing compose file, check for port collisions with application services.

### 5. Vault Dev Mode + Local Config Conflict

**Problem**: Vault was configured with both `VAULT_DEV_*` env vars AND `VAULT_LOCAL_CONFIG` with a TCP listener on 8200. Dev mode already binds 8200, so the local config listener caused a bind conflict.

**Error**: `Error initializing listener of type tcp: listen tcp4 0.0.0.0:8200: bind: address already in use`

**Fix**: Removed `VAULT_LOCAL_CONFIG` — dev mode handles its own listener.

**Lesson**: Vault dev mode is self-contained. Don't add listener config when using dev mode.

### 6. Healthcheck Uses `curl` in Slim Python Images

**Problem**: Initial healthchecks used `curl` which isn't installed in `python:3.12-slim`.

**Error**: `exec: "curl": executable file not found in $PATH`

**Fix**: All healthchecks now use:
```yaml
test: ["CMD-SHELL", "python3 -c \"import urllib.request; urllib.request.urlopen('http://localhost:PORT/health')\""]
```

**Lesson**: Always use tools available in the base image for healthchecks. For Python images, use `urllib`.

### 7. Multi-Worker Gunicorn with File-Backed Store

**Problem**: `user-config` service ran with `-w 2` (2 workers). Worker A handled the PUT (wrote to memory + disk), but Worker B handled the GET (empty memory, no disk reload).

**Error**: Config stored successfully but immediate GET returned 404.

**Fix**: Changed to single worker with threads (`-w 1 --threads 4`) and added disk reload fallback in `get()`.

**Lesson**: File-backed state stores cannot use multi-process workers. Use single worker + threads, or switch to a shared database.

### 8. Vault KV v2 Read Path Requires `/data/` Prefix

**Problem**: Writing to KV v2 uses `medinovai-secrets/data/path`, but the read code used `medinovai-secrets/path` (without `/data/`).

**Error**: Vault returned 404 for secret reads.

**Fix**: Both read and write paths now include `/data/` in the path.

**Lesson**: Vault KV v2 API always requires `/data/` in the path for both reads and writes.

---

## Production Readiness Checklist

| Item | Status | Notes |
|------|--------|-------|
| All 42 containers healthy | DONE | Verified 2026-02-22 |
| Vault secrets integration | DONE | Dev mode, needs AppRole for prod |
| Per-user config persistence | DONE | File-backed + Vault |
| Named volume preservation | DONE | 17 named volumes |
| Backup sidecar | DONE | 6-hour cycle, backup profile |
| Healthcheck standardization | DONE | All use python3 urllib |
| Port conflict resolution | DONE | Agent-runtime on 8220 |
| Connector COPY path fix | DONE | All use repo-root paths |
| Gunicorn CMD fix | DONE | All use flat :app export |

### Still Needed for Production

| Item | Priority | Owner |
|------|----------|-------|
| Switch Vault to production mode (AppRole, TLS, file storage) | High | Platform |
| Replace file-backed stores with PostgreSQL | High | Platform |
| Add TLS termination (Traefik/Nginx) | High | Platform |
| Configure real connector credentials | High | Clinical |
| Enable Vault audit logging | High | Security |
| Set up monitoring (Prometheus + Grafana) | Medium | Ops |
| Configure backup to external storage (S3/MinIO) | Medium | Ops |
| Load testing (concurrent multi-tenant) | Medium | QA |
| Penetration testing | Medium | Security |
| K8s migration (via medinovai-Deploy K3s) | Low | Platform |

---

## Resource Usage (42 Containers)

Approximate resource usage on Mac Studio (M2 Ultra, 192GB RAM):

| Resource | Usage |
|----------|-------|
| CPU | ~5-8% idle |
| Memory | ~8-12 GB |
| Disk (images) | ~15 GB |
| Disk (volumes) | <1 GB (empty) |
| Network | `atlasos-enterprise` bridge |
