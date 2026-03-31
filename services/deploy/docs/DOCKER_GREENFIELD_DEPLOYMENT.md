# Docker Greenfield Deployment — Full Local Stack

Complete plan and reference for deploying MedinovAI on a single machine via Docker Compose. Designed for restart and crash resilience.

---

## Overview

| Component | Purpose |
|-----------|---------|
| **docker-compose.dev.yml** | All services with named volumes, restart policies, healthchecks |
| **scripts/backup.sh** | DB dump + volume export to `~/medinovai-backups/medinovai-Deploy/` |
| **scripts/restore.sh** | Restore from backup |
| **scripts/seed.sh** | Fresh environment from zero |
| **scripts/bootstrap/instantiate-docker.sh** | Full greenfield instantiation |

---

## Architecture

### Service Stack

| Service | Port | Volume | Restart |
|---------|------|--------|---------|
| postgres | 5432 | postgres-data | unless-stopped |
| redis | 6379 | redis-data | unless-stopped |
| prometheus | 9090 | prometheus-data | unless-stopped |
| grafana | 3000 | grafana-data | unless-stopped |
| mailhog | 1025, 8025 | — | unless-stopped |
| localstack | 4566 | localstack-data | unless-stopped |

### Resilience Features

- **Named volumes** for all persistent data (postgres, redis, prometheus, grafana, localstack)
- **Restart: unless-stopped** on every service
- **Healthchecks** for postgres, redis, prometheus, grafana
- **depends_on + condition: service_healthy** (grafana waits for prometheus)
- **Redis AOF** (`--appendonly yes`) for crash-safe persistence

---

## Quick Start

```bash
# 1. Full greenfield (interactive)
make docker-instantiate
# or
bash scripts/bootstrap/instantiate-docker.sh

# 2. Dry-run first
bash scripts/bootstrap/instantiate-docker.sh --dry-run

# 3. Resume from failure
bash scripts/bootstrap/instantiate-docker.sh --resume
```

---

## Backup & Restore

### Backup (run before any infra change)

```bash
make docker-backup
# or
bash scripts/backup.sh
```

Output: `~/medinovai-backups/medinovai-Deploy/{db,volumes,config}/`

### Restore

```bash
# From specific dump
bash scripts/restore.sh --from-dump ~/medinovai-backups/medinovai-Deploy/db/medinovai_YYYYMMDDTHHMMSSZ.sql

# From latest dump
bash scripts/restore.sh --from-latest
```

### Seed (fresh from zero)

```bash
make docker-seed
# or
bash scripts/seed.sh

# With full reset (drops volumes)
bash scripts/seed.sh --reset
```

---

## Verification Checklist

| Check | Command |
|-------|---------|
| Postgres | `docker exec medinovai-postgres pg_isready -U medinovai` |
| Redis | `docker exec medinovai-redis redis-cli -a localdev ping` |
| Prometheus | `curl http://localhost:9090/-/healthy` |
| Grafana | `curl http://localhost:3000/api/health` |
| Restart test | `docker compose -f infra/docker/docker-compose.dev.yml restart` — all services return healthy |

---

## Environment Variables

Create `infra/docker/.env` (or use project root `.env`) to override:

| Variable | Default | Purpose |
|----------|---------|---------|
| POSTGRES_PASSWORD | localdev | Postgres password |
| REDIS_PASSWORD | localdev | Redis auth |
| GRAFANA_ADMIN_PASSWORD | admin | Grafana admin |

---

## File Reference

| File | Purpose |
|------|---------|
| `infra/docker/docker-compose.dev.yml` | Compose definition |
| `scripts/backup.sh` | Backup DB + volumes |
| `scripts/restore.sh` | Restore from backup |
| `scripts/seed.sh` | Fresh seed + migrations |
| `scripts/bootstrap/instantiate-docker.sh` | Full bootstrap |
| `docs/DOCKER_GREENFIELD_DEPLOYMENT.md` | This document |

---

## Adding MedinovAI App Services

The six application services (auth-service, api-gateway, etc.) are defined in `services/registry/` and use Kubernetes in production. To run them locally via Docker:

1. Build or pull images for each service
2. Add service definitions to `docker-compose.dev.yml` following the dependency order:
   - auth-service → notification-service → data-pipeline → clinical-engine → ai-inference → api-gateway
3. Wire `depends_on` with `condition: service_healthy`
4. Set `DATABASE_URL`, `REDIS_URL` from postgres/redis services

See `docs/INSTANTIATION_GUIDE.md` for service dependency details.

---

## Maintenance

- **Backup before changes**: Always run `scripts/backup.sh` before modifying compose or running seed --reset
- **Backup location**: Must be outside Docker at `~/medinovai-backups/medinovai-Deploy/`
- **Time Machine**: Enable on macOS for additional protection (per backup strategy)

---

*Last updated: 2026-02-17. Part of medinovai-Deploy.*
