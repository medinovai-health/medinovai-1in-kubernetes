# Four-Environment Deployment Guide

**Owner:** medinovai-Deploy
**Date:** 2026-03-09
**Status:** Active

---

## Overview

medinovai-Deploy is the single repo for launching and managing all MedinovAI
environments. Four fully independent environments (dev, qa, staging, prod) can
run simultaneously on the same host via Docker Compose with port offsets. Each
environment should host the same AtlasOS four-layer topology: `Named
Assistants`, `Functional Agents`, `Entity Agents`, and `Squad Agents`.

## Repo Ownership

| Concern | Repo | What Lives There |
|---|---|---|
| Compose files, env files, env-manager | **medinovai-Deploy** (this repo) | `infra/docker/compose/`, `envs/`, `scripts/env-manager.sh` |
| Keycloak config, realm overlays | **medinovai-security-service** | `config/environments/`, `scripts/bootstrap_environment.py` |
| Service source code, migrations | **AtlasOS** + each service repo | `services/`, `lib/`, `config/` |
| K8s manifests (cloud) | **medinovai-infrastructure** | Terraform, Helm, ArgoCD |

## Quick Start

```bash
cd ~/Github/medinovai-health/medinovai-Deploy

# Start dev environment (core services)
make env-start ENV=dev LAYERS=core

# Start dev environment (all 96 services)
make env-start ENV=dev LAYERS=all

# Bootstrap Keycloak + DB
make env-bootstrap ENV=dev

# Check status
make env-status

# Stop
make env-stop ENV=dev
```

## Compose Layers

| Layer | File | Services |
|---|---|---|
| Infrastructure | `docker-compose.base.yml` | PostgreSQL, Keycloak, Redis, Vault, RabbitMQ, Traefik |
| AtlasOS Core | `docker-compose.atlasos-core.yml` | OODA Brain, Service Registry, Squad Manager, Health Probe, Fleet Monitor, Event Bus, Audit Chain |
| Agent Runtime | `docker-compose.atlasos-agents.yml` | Agent Platform, Brain, Invocation Gateway, Entity Lifecycle, Memory, Skills, Heartbeat, Learning, Tenancy, Tools, Sessions, Cron |
| Governance | `docker-compose.atlasos-governance.yml` | Governance Runtime, Security Mesh, Change Authority, Compliance, AI Guardian, Rule Compiler |
| AI/ML | `docker-compose.atlasos-ai.yml` | AIFactory Gateway, Ollama, MCP Gateway, Self-Learning, Cognitive Arch, Predictive Analytics, Multi-Modal, Self-Healing |
| Observability | `docker-compose.observability.yml` | Prometheus, Loki, Tempo, Grafana |

## Agent Topology

Each environment deploys the same canonical AtlasOS layers:

| Agent Layer | Runtime Representation |
|---|---|
| Named Assistants | User-facing assistants such as Arjun/CEO and future employee-specific assistants |
| Functional Agents | Shared domain services and workspaces for finance, compliance, recruiting, security, operations, and similar domains |
| Entity Agents | Database-backed runtime instances provisioned by `entity-lifecycle-gateway` for employees, SOPs, protocols, regulations, clinics, customers, patients, and other governed entities |
| Squad Agents | Specialist workers used for execution, evaluation, routing, and escalations under functional supervision |

Operational rule: employee agents and SOP/protocol/regulation agents are entity
classes, not ad-hoc workspace sprawl. Only named assistants and selected
functional agents should require long-lived workspace customizations.

## Environment Files

All in `envs/`:
- `base.env` — shared defaults (DB user, LLM routing, storage backends)
- `dev.env` — dev ports (base offset), dev passwords, AUTH_ENABLED=false
- `qa.env` — QA ports (+1000 offset), AUTH_ENABLED=true
- `staging.env` — staging ports (+2000 offset), production-like
- `prod.env.example` — production template (+3000 offset), secrets from Vault

## Port Allocation

See: `medinovai-security-service/docs/FOUR_ENVIRONMENT_ARCHITECTURE.md`

## Future: medinovai-registry

All config and secrets will eventually be federated through the `medinovai-registry`
service. For now, env files in this repo are the canonical source.
