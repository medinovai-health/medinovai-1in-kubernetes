# medinovai-Deploy — AtlasOS Agent Operating Rules

**Module:** medinovai-Deploy
**Category:** ai-ml
**Managed by:** AtlasOS Autonomous Operations

## Identity

This repository is managed by AtlasOS agents. All operations are observable,
auditable, and subject to approval gates for critical actions.

## Agent Configuration

Agent definitions: `config/atlasos/agents/`
Event triggers: `config/atlasos/events/`
Squad membership: `config/atlasos/squads/`

## OODA Protocol

All agents follow Observe-Orient-Decide-Act:
1. **Observe**: Capture error type, context, and blast radius
2. **Orient**: Classify as transient, structural, or logic
3. **Decide**: Retry (transient), escalate (structural), fix (logic)
4. **Act**: Execute with full audit logging

## Approval Gates

Critical actions require human approval. See `config/atlasos/agents/` for tier assignments.

---

## TEST2 Local Deployment

Full 53-service greenfield Docker Compose stack. Port range: **16600–16999**.

### Quick Start (No Cursor Required)

```bash
cd /path/to/medinovai-Deploy

# One command does everything:
make test2-up

# Or step by step:
make test2-preflight        # Validate before deploying
make test2-network          # Create TEST2-network
make test2-up-infra         # Databases, caches, monitoring
make test2-wait             # Wait for infra to be healthy
make test2-kafka-reset      # Only if Kafka has issues
docker compose -p test2 --env-file infra/docker/test2.env \
  -f infra/docker/docker-compose.TEST2-full.yml up -d
make test2-wait             # Wait for all services
make test2-smoke            # Validate all endpoints
```

### Operations Reference

| Command | Purpose |
|---------|---------|
| `make test2-up` | Full tiered deploy with preflight + smoke tests |
| `make test2-down` | Stop all containers (keep data volumes) |
| `make test2-down-volumes` | Stop + delete all volumes (⚠️ data loss) |
| `make test2-status` | Health summary for all 53 services |
| `make test2-diagnose` | Auto-triage unhealthy containers |
| `make test2-diagnose-all` | Full report including healthy ones |
| `make test2-logs` | Follow all service logs |
| `make test2-logs-svc SVC=<name>` | Logs for one service |
| `make test2-kafka-reset` | Fix InconsistentClusterIdException |
| `make test2-rebuild` | Rebuild all 16 Dockerfile.TEST2 images |
| `make test2-rebuild-svc SVC=<name>` | Rebuild and restart one service |
| `make test2-smoke` | Run smoke tests against live stack |
| `make test2-preflight` | Run pre-flight validation only |
| `make test2-help` | Show all test2-* make targets |

### Critical: Kafka Cluster ID

`KAFKA_CLUSTER_ID` must be set in `infra/docker/test2.env`.
It is already set. If you see `InconsistentClusterIdException`:

```bash
make test2-kafka-reset
# This stops kafka + zookeeper, removes BOTH volumes (with DASHES not underscores):
#   test2-kafka-data
#   test2-zookeeper-data
# Then restarts zookeeper first (waits 25s), then kafka.
```

Volume names use **DASHES**: `test2-kafka-data` (NOT `test2_kafka_data`).

### Non-Standard Healthcheck Ports

These services do NOT serve `/health` on port 8080:

| Service | Healthcheck URL |
|---------|----------------|
| `medinovai-registry` | `http://localhost:8000/health` |
| `medinovai-data-services` | `http://localhost:8300/api/health` |
| `medinovai-healthllm` | `http://localhost:12304/health` |
| `medinovai-real-time-stream-bus` | `http://localhost:3000/health` |

### Services Requiring Dockerfile.TEST2

16 services have broken or missing original Dockerfiles.
All have `Dockerfile.TEST2` committed in their respective repos.
All have `build:` directives in `docker-compose.TEST2-full.yml`.

Rebuild all:  `make test2-rebuild`
Rebuild one:  `make test2-rebuild-svc SVC=<compose-service-name>`

| Compose Service | Repo | Reason for Override |
|----------------|------|---------------------|
| `medinovai-registry` | `medinovai-registry` | Dockerfile starts with `'''#` (Python docstring) |
| `medinovai-data-services` | `medinovai-data-services` | `-e shared/medinovai-core` without copy; `create_app()` inside `__main__` |
| `medinovai-real-time-stream-bus` | `medinovai-real-time-stream-bus` | Node.js Dockerfile for Python service; port 3000 |
| `medinovai-healthllm` | `medinovai-healthLLM` | Missing dirs; httpx conflict; port 12304 |
| `medinovai-aifactory` | `medinovai-aifactory` | Frontend npm build fails; port 8765 vs 8080 |
| `medinovai-notification-center` | `medinovai-notification-center` | .NET compilation errors |
| `medinovai-hipaa-gdpr-guard` | `medinovai-hipaa-gdpr-guard` | .NET compilation errors |
| `medinovai-api-gateway` | `medinovai-api-gateway` | Node.js server crashes on init |
| `medinovai-secrets-manager-bridge` | `medinovai-secrets-manager-bridge` | CMD ran utility script, not HTTP server |
| `medinovai-security` | `medinovai-security-service` | CMD ran utility script |
| `medinovai-universal-sign-on` | `medinovai-universal-sign-on` | CMD ran utility script |
| `medinovai-role-based-permissions` | `medinovai-role-based-permissions` | CMD ran utility script |
| `medinovai-encryption-vault` | `medinovai-encryption-vault` | CMD ran utility script |
| `medinovai-consent-preference-api` | `medinovai-consent-preference-api` | CMD ran utility script |
| `medinovai-audit-trail-explorer` | `medinovai-audit-trail-explorer` | CMD ran utility script |
| `medinovai-model-service-orchestrator` | `MedinovAI-Model-Service-Orchestrator` | CMD ran utility script |

### medinovai-core Dependency Rules

- **Python version**: must be `python:3.12-slim` or `>=3.10`
- **grpcio vs grpc**: use `grpcio>=1.60.0` in `pyproject.toml` (NOT `grpc`)
- **Copy pattern** in Dockerfile.TEST2:
  ```dockerfile
  COPY shared/medinovai-core /tmp/medinovai-core
  RUN pip install /tmp/medinovai-core
  RUN grep -v "medinovai-core" requirements.txt | pip install --no-cache-dir -r /dev/stdin
  ```

### Common Python Bugs Fixed in AI-Generated Services

1. `AttributeError: status.HTTP_201_CREATED` → Use `201` integer directly
2. Pydantic Enum: `class Foo(str):` → must be `class Foo(str, Enum):`
3. Prometheus import: add `prometheus_client` to `requirements_test2.txt`
4. CMD one-liners with decorators → move to proper `main_test2.py` file

### Deployment Tiers (startup order)

```
Tier 0 Infra:      postgres-primary, postgres-clinical, redis-cache, mongodb,
                   rabbitmq, elasticsearch, vault, zookeeper
Tier 0 Monitoring: prometheus, grafana, loki, jaeger, mailhog
Tier 0 Auth:       keycloak (after postgres-primary healthy)
Tier 0 Messaging:  kafka (after zookeeper healthy)
Tier 1 Security:   secrets-manager-bridge, security, USO, RBAC, encryption-vault,
                   hipaa-gdpr-guard, consent-api, audit-trail
Tier 2 Platform:   registry, data-services, stream-bus, config-mgmt,
                   notification-center, aifactory, api-gateway, atlas-engine
Tier 3 AI/ML:      healthllm, model-orchestrator, knowledge-graph, cds-engine,
                   patient-services
Tier 5 Apps:       edge-cdn, data-lake, feature-flags, canary, devops-telemetry,
                   policy-watcher, etl-designer, prompt-vault, qa-agent, task-kanban,
                   guideline-updater, governance-templates, risk-mgmt, cds, dev-portal
Tier 6 UI:         multimodal-ui-shell, medinovaios
```

### Key Service URLs

| Service | URL |
|---------|-----|
| API Gateway | http://localhost:16676 |
| MedinovAI OS | http://localhost:16731 |
| Keycloak Admin | http://localhost:16620/admin |
| Grafana | http://localhost:16631 |
| Prometheus | http://localhost:16630 |
| Elasticsearch | http://localhost:16616 |
| Vault | http://localhost:16619 |
| Jaeger | http://localhost:16634 |
| RabbitMQ Mgmt | http://localhost:16618 |
| MailHog | http://localhost:16623 |

### Files

| File | Purpose |
|------|---------|
| `infra/docker/docker-compose.TEST2-full.yml` | Full stack definition |
| `infra/docker/test2.env` | Environment variables (gitignored) |
| `infra/docker/test2.env.example` | Template — copy to test2.env |
| `infra/docker/test2-deploy.sh` | Master deploy script |
| `infra/docker/preflight-check.py` | Pre-deployment validation |
| `infra/docker/health-wait.py` | Wait for all services to be healthy |
| `infra/docker/test2-smoke-test.py` | Post-deploy endpoint validation |
| `infra/docker/test2-diagnose.sh` | Auto-triage unhealthy containers |
| `infra/docker/build-all-test2.sh` | Rebuild all Dockerfile.TEST2 images |
| `docs/TEST2-DEPLOYMENT-RUNBOOK.md` | Full deployment runbook |
