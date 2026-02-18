# MedinovAI Platform Dependency Chart

**Version:** 2.0.0  
**Copyright © 2025–2026 MedinovAI. All Rights Reserved.**

*Generated from config/dependency-graph.json*

---

## Overview

This document provides a comprehensive visual dependency chart for the MedinovAI healthcare platform—a 200+ service ecosystem spanning seven deployment tiers (Tier 0 through Tier 6). The chart defines deployment order, cross-tier dependencies, and parallelization strategies. All MedinovAI application services depend on the Security & Secrets Foundation (Tier 1), which must be deployed first and sequentially. Domain services (Tier 4) and integration services (Tier 5) are highly parallelizable across sub-groups. The UI Shell & Master Menu (Tier 6) is deployed last as the unified SSO entry point.

---

## Full ASCII Dependency Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                    TIER 0 — BARE INFRASTRUCTURE                                      │
│                                         (Deploy in parallel)                                         │
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                     │
│  ┌─────────────┐ ┌─────────┐ ┌───────┐ ┌───────┐ ┌────────┐ ┌──────────┐ ┌───────┐ ┌───────┐       │
│  │ PostgreSQL  │ │  Redis  │ │ Kafka │ │  MDB  │ │  ES   │ │ RabbitMQ │ │ Vault │ │  S3   │       │
│  └──────┬──────┘ └────┬────┘ └───┬───┘ └───┬───┘ └───┬────┘ └────┬────┘ └───┬─────┘ └───┬───┘       │
│         │             │          │         │         │           │          │           │          │
│  ┌──────┴──────┐ ┌────┴────┐ ┌───┴───┐     │     ┌───┴─────┐     │           │           │          │
│  │  Keycloak   │ │PgBouncer│ │Zookpr │     │     │         │     │           │           │          │
│  └──────┬──────┘ └────┬────┘ └───────┘     │     │         │     │           │           │          │
│         │             │                    │     │         │     │           │           │          │
│  ┌──────┴─────────────────────────────────┴─────┴─────────┴─────┴───────────┴───────────┴──────┐   │
│  │  Prometheus │ Grafana │ Loki │ Alertmanager │ Jaeger                                         │   │
│  └─────────────────────────────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                              │
                                              ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                        TIER 1 — SECURITY & SECRETS FOUNDATION (Sequential)                            │
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                     │
│  1 ──► medinovai-secrets-manager-bridge (Vault)                                                       │
│  2 ──► medinovai-security (Keycloak, PG, Redis, PgBouncer, secrets-bridge)                           │
│  3 ──► medinovai-universal-sign-on (PG, Redis, Vault, Kafka, security)                                │
│  4 ──► medinovai-role-based-permissions (PG, Redis, security)                                        │
│  5 ──► medinovai-encryption-vault (Vault, secrets-bridge)                                             │
│  6 ──► medinovai-hipaa-gdpr-guard (PG, Redis, security, RBAC)                                        │
│  7 ──► medinovai-consent-preference-api (PG, Redis, security, hipaa-guard)                           │
│  8 ──► medinovai-audit-trail-explorer (PG, Redis, ES, security)                                      │
│                                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                              │
                                              ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                           TIER 2 — PLATFORM CORE (Sequential)                                         │
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                     │
│  1 ──► medinovai-registry         6 ──► medinovai-aifactory                                         │
│  2 ──► medinovai-data-services   7 ──► medinovai-api-gateway (security, RBAC, registry)              │
│  3 ──► medinovai-real-time-stream-bus  8 ──► medinovai-web-core (npm)                                │
│  4 ──► medinovai-configuration-management  9 ──► medinovai-atlas-engine                              │
│  5 ──► medinovai-notification-center                                                                 │
│                                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                              │
                                              ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                      TIER 3 — AI/ML & CLINICAL FOUNDATION (Parallel Groups)                           │
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                     │
│  ┌── GROUP 1 (parallel) ─────────────────────────────────────────────────────────────────────────┐  │
│  │  medinovai-healthLLM │ medinovai-model-service-orchestrator │ medinovai-knowledge-graph        │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────┘  │
│  ┌── GROUP 2 (parallel) ─────────────────────────────────────────────────────────────────────────┐  │
│  │  medinovai-clinical-decision-support │ medinovai-patient-services                             │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────┘  │
│  ┌── GROUP 3 (config only) ───────────────────────────────────────────────────────────────────────┐  │
│  │  medinovai-ai-standards                                                                            │  │
│  └──────────────────────────────────────────────────────────────────────────────────────────────┘  │
│                                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                              │
                                              ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                           TIER 4 — DOMAIN SERVICES (6 Parallel Sub-Groups)                            │
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                     │
│  4A Clinical (9)    4B Diagnostics (5)   4C AI (11)    4D Medication (2)   4E Research (15)        │
│  ├ patient-onboard   ├ lab-order-router   ├ chatbot     ├ e-prescribe        ├ CTMS                │
│  ├ patientmatching   ├ pathology-ai        ├ ai-scribe   └ medication-tracker ├ EDC                │
│  ├ health-timeline   ├ imaging-viewer      ├ doc-summarizer       ...         ├ etmf, saes...      │
│  ├ care-team-chat    ├ genomics-interpr    ├ natural-lang-query               └ SiteFeasibility    │
│  ├ smart-scheduler   └ image-to-text-ocr  └ ... 11 svcs                                             │
│  └ ... 9 svcs                                                                                       │
│                                                                                                     │
│  4F Business (9)    4G LIS (3)                                                                       │
│  ├ billing          ├ medinovai-lis                                                               │
│  ├ provider-cred    ├ medinovai-lis-platform                                                       │
│  └ ... 9 svcs       └ medinovai-lis-ui                                                              │
│                                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                              │
                                              ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                    TIER 5 — INTEGRATION & SPECIALIZED (18 services, all parallel)                     │
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                     │
│  edge-cache-cdn │ data-lake-loader │ feature-flag-console │ canary-rollout │ devops-telemetry        │
│  policy-diff-watcher │ etl-designer │ prompt-vault │ qa-agent-builder │ task-kanban                   │
│  guideline-updater │ white-label-skinner │ accessibility-checker │ governance-templates              │
│  risk-management │ cds │ developer-portal │ Livekit                                                   │
│                                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
                                              │
                                              ▼
┌─────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                       TIER 6 — UI SHELL & MASTER MENU (Sequential, deploy LAST)                      │
├─────────────────────────────────────────────────────────────────────────────────────────────────────┤
│                                                                                                     │
│  1 ──► medinovai-ui-components (npm)                                                                  │
│  2 ──► medinovai-multimodal-ui-shell                                                                  │
│  3 ──► medinovaios — Master Menu (unified SSO entry and BAC portal)                                   │
│                                                                                                     │
└─────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Detailed Per-Tier Dependency Tables

### Tier 0 — Bare Infrastructure

| Component       | Type        | Port  | Health Check                 | Depends On     |
|----------------|-------------|-------|-----------------------------|----------------|
| postgres-primary | infrastructure | 5432 | pg_isready                 | —              |
| postgres-clinical | infrastructure | 5433 | pg_isready                | —              |
| redis-cache    | infrastructure | 6379 | redis-cli ping             | —              |
| kafka          | infrastructure | 9092 | kafka-topics --list        | zookeeper      |
| zookeeper      | infrastructure | 2181 | echo ruok \| nc            | —              |
| mongodb        | infrastructure | 27017 | mongosh ping               | —              |
| elasticsearch  | infrastructure | 9200 | GET /_cluster/health       | —              |
| rabbitmq       | infrastructure | 5672 | rabbitmq-diagnostics ping  | —              |
| vault          | infrastructure | 8200 | GET /v1/sys/health         | postgres-primary |
| s3-object-store | infrastructure | —   | aws s3 ls                  | —              |
| keycloak       | infrastructure | 9080 | GET /health/ready          | postgres-primary |
| pgbouncer      | infrastructure | 6432 | psql SELECT 1              | postgres-primary |
| prometheus     | monitoring  | 9090 | GET /-/healthy             | —              |
| grafana        | monitoring  | 3000 | GET /api/health            | prometheus     |
| loki           | monitoring  | 3100 | GET /ready                  | —              |
| alertmanager   | monitoring  | 9093 | GET /-/healthy             | prometheus     |
| jaeger         | monitoring  | 16686 | GET /                      | —              |

---

### Tier 1 — Security & Secrets Foundation

| # | Service                         | Depends On (Infra)              | Depends On (Services)                      |
|---|---------------------------------|----------------------------------|-------------------------------------------|
| 1 | medinovai-secrets-manager-bridge | Vault                           | —                                         |
| 2 | medinovai-security             | Keycloak, PostgreSQL, Redis, PgBouncer | medinovai-secrets-manager-bridge    |
| 3 | medinovai-universal-sign-on    | PostgreSQL, Redis, Vault, Kafka  | medinovai-security                        |
| 4 | medinovai-role-based-permissions | PostgreSQL, Redis             | medinovai-security                        |
| 5 | medinovai-encryption-vault     | Vault                           | medinovai-secrets-manager-bridge          |
| 6 | medinovai-hipaa-gdpr-guard      | PostgreSQL, Redis               | medinovai-security, medinovai-role-based-permissions |
| 7 | medinovai-consent-preference-api | PostgreSQL, Redis              | medinovai-security, medinovai-hipaa-gdpr-guard |
| 8 | medinovai-audit-trail-explorer  | PostgreSQL, Redis, Elasticsearch | medinovai-security                       |

---

### Tier 2 — Platform Core

| # | Service                         | Depends On (Infra)                  | Depends On (Services)          |
|---|---------------------------------|-------------------------------------|--------------------------------|
| 1 | medinovai-registry             | PostgreSQL, Redis                   | medinovai-security             |
| 2 | medinovai-data-services       | PostgreSQL, postgres-clinical, Redis | medinovai-security             |
| 3 | medinovai-real-time-stream-bus | Kafka, Redis                        | medinovai-security             |
| 4 | medinovai-configuration-management | PostgreSQL, Redis               | medinovai-security             |
| 5 | medinovai-notification-center  | PostgreSQL, Redis, RabbitMQ         | medinovai-security             |
| 6 | medinovai-aifactory           | PostgreSQL, Redis                   | medinovai-security             |
| 7 | medinovai-api-gateway         | —                                   | security, RBAC, registry       |
| 8 | medinovai-web-core            | —                                   | security, RBAC (npm library)   |
| 9 | medinovai-atlas-engine        | PostgreSQL, Redis                   | medinovai-security, registry   |

---

### Tier 3 — AI/ML & Clinical Foundation

| Group | Service                         | Depends On (Infra)                      | Depends On (Services)                              |
|-------|---------------------------------|-----------------------------------------|---------------------------------------------------|
| 1     | medinovai-healthLLM             | PostgreSQL, Redis                       | medinovai-security, medinovai-aifactory           |
| 1     | medinovai-model-service-orchestrator | PostgreSQL, Redis, Kafka, S3       | medinovai-security, medinovai-data-services       |
| 1     | medinovai-knowledge-graph      | PostgreSQL, Elasticsearch               | medinovai-security, medinovai-data-services       |
| 2     | medinovai-clinical-decision-support | PostgreSQL, Redis                  | healthLLM, model-orchestrator, data-services      |
| 2     | medinovai-patient-services     | PostgreSQL, Redis                       | security, data-services, consent-preference-api   |
| 3     | medinovai-ai-standards         | —                                      | — (config only)                                   |

---

### Tier 4 — Domain Services (Summary by Sub-Group)

| Sub-Group | Name                 | Services | Deploy Order |
|-----------|----------------------|----------|--------------|
| 4A        | Clinical             | 9        | patient-onboarding → patientmatching → health-timeline → care-team-chat → smart-scheduler → wait-list-balancer → virtual-triage → telehealth-hub → remote-vitals-ingest |
| 4B        | Diagnostics          | 5        | lab-order-router → pathology-ai → imaging-viewer → genomics-interpreter → image-to-text-ocr |
| 4C        | AI Services          | 11       | chatbot → ai-scribe → doc-summarizer → natural-language-query → anomaly-detector → sentiment-monitor → drug-interaction-checker → medical-fax-processing → content-translator → text-to-speech-narrator → voice-command-layer |
| 4D        | Medication & Pharmacy| 2        | e-prescribe-gateway → medication-tracker |
| 4E        | Research & Clinical Trials | 15 | CTMS → EDC → etmf → saes → eConsent → ePRO → eSource → eISF → iwrs → Pharmacovigilance → ResearchSuite → regulatory-submissions → RBM → reseach-fabric → SiteFeasibility |
| 4F        | Business             | 9        | billing → provider-credentialing → credentialing → employee-portal → subscription → quality-certification → inventorymanagement → mail → email-service |
| 4G        | LIS Platform         | 3        | medinovai-lis → medinovai-lis-platform → medinovai-lis-ui |

---

### Tier 5 — Integration & Specialized (18 services)

| Service                         | Depends On (Infra)                    | Depends On (Services)                        |
|---------------------------------|--------------------------------------|----------------------------------------------|
| medinovai-edge-cache-cdn        | —                                    | medinovai-api-gateway                         |
| medinovai-data-lake-loader      | Kafka, S3                             | real-time-stream-bus, data-services           |
| medinovai-feature-flag-console  | PostgreSQL, Redis                     | security, configuration-management            |
| medinovai-canary-rollout-orchestrator | —                               | registry                                      |
| medinovai-devops-telemetry      | Prometheus                            | security                                      |
| medinovai-policy-diff-watcher   | PostgreSQL                            | security                                      |
| medinovai-etl-designer          | PostgreSQL, Kafka                     | security, data-services                       |
| medinovai-prompt-vault          | PostgreSQL, Redis, RabbitMQ, ES       | security                                      |
| medinovai-qa-agent-builder      | PostgreSQL                            | security, model-service-orchestrator           |
| medinovai-task-kanban           | PostgreSQL, Redis, Kafka              | security, notification-center                 |
| medinovai-guideline-updater     | PostgreSQL, RabbitMQ                  | security, knowledge-graph                     |
| medinovai-white-label-skinner   | —                                     | medinovai-web-core                            |
| medinovai-accessibility-checker | —                                     | security                                      |
| medinovai-governance-templates  | PostgreSQL                            | security                                      |
| medinovai-risk-management       | PostgreSQL                            | security, data-services                       |
| medinovai-cds                   | PostgreSQL                            | security, clinical-decision-support           |
| medinovai-developer-portal      | —                                     | api-gateway, registry                         |
| medinovai-Livekit               | Redis                                 | security                                      |

---

### Tier 6 — UI Shell & Master Menu

| # | Service                     | Deploy Type  | Depends On (Services)                                  |
|---|-----------------------------|--------------|--------------------------------------------------------|
| 1 | medinovai-ui-components     | npm-publish  | medinovai-web-core                                     |
| 2 | medinovai-multimodal-ui-shell | node-service | medinovai-web-core, medinovai-ui-components            |
| 3 | medinovaios                 | node-service | security, universal-sign-on, RBAC, api-gateway, registry |

---

## Critical Path Diagram (Minimum Viable Deployment)

The following 12 components form the **minimum viable deployment path**—deploy in this exact order:

```
    ┌──────────────────┐
    │  postgres-primary │
    └────────┬─────────┘
             │
    ┌────────┴───────────────────────────┐
    │                                     │
    ▼                                     ▼
┌─────────────┐                    ┌──────────┐
│  redis-cache│                    │  keycloak │
└──────┬──────┘                    └────┬─────┘
       │                                 │
       │                                 ▼
       │                          ┌──────────┐
       │                          │  vault   │
       │                          └────┬─────┘
       │                               │
       └───────────────┬───────────────┘
                       │
                       ▼
         ┌─────────────────────────────┐
         │ medinovai-secrets-manager-   │
         │         bridge               │
         └──────────────┬───────────────┘
                        │
                        ▼
              ┌─────────────────────┐
              │  medinovai-security │
              └──────────┬──────────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              │
  ┌───────────────┐ ┌─────────────┐    │
  │ universal-    │ │ role-based- │    │
  │ sign-on       │ │ permissions │    │
  └───────┬───────┘ └──────┬──────┘    │
          │                │          │
          └────────┬────────┴──────────┘
                   │
                   ▼
          ┌─────────────────┐
          │ medinovai-      │
          │ registry        │
          └────────┬────────┘
                   │
          ┌────────┼────────┐
          │        │        │
          ▼        ▼        │
  ┌───────────┐ ┌───────┐   │
  │data-svcs  │ │api-   │   │
  │           │ │gateway│   │
  └─────┬─────┘ └───┬───┘   │
        │           │       │
        └─────┬─────┴───────┘
              │
              ▼
       ┌─────────────┐
       │ medinovaios │  ◄── Master Menu (SSO entry)
       └─────────────┘

   CRITICAL PATH: 12 steps in exact order
```

**Ordered list:**
1. postgres-primary  
2. redis-cache  
3. keycloak  
4. vault  
5. medinovai-secrets-manager-bridge  
6. medinovai-security  
7. medinovai-universal-sign-on  
8. medinovai-role-based-permissions  
9. medinovai-registry  
10. medinovai-data-services  
11. medinovai-api-gateway  
12. medinovaios  

---

## Parallelization Strategy Notes

| Tier | Strategy | Notes |
|------|----------|-------|
| **Tier 0** | Full parallel | All infrastructure components can be provisioned concurrently. Note: Vault, Keycloak, PgBouncer require postgres-primary first. |
| **Tier 1** | Sequential | Security foundation must deploy in strict order—secrets-bridge → security → USO/RBAC → hipaa-guard → consent-api → audit-trail. |
| **Tier 2** | Sequential | Platform core depends on Tier 1; within tier, deploy_order defines sequence (registry before api-gateway, etc.). |
| **Tier 3** | Parallel groups | Group 1 (healthLLM, model-orchestrator, knowledge-graph) can run in parallel; Group 2 (CDS, patient-services) after Group 1. |
| **Tier 4** | Sub-group parallel | 4A–4G sub-groups are independent; deploy each sub-group's deploy_order sequentially within the group. |
| **Tier 5** | Full parallel | All 18 integration/specialized services can deploy concurrently once Tiers 1–4 are healthy. |
| **Tier 6** | Sequential | UI components → multimodal-ui-shell → medinovaios. medinovaios must deploy last as the single entry point. |

**Optimization tips:**
- Tier 4 sub-groups (4A–4G) can run in parallel with different release trains.
- Tier 5 has no internal dependencies; maximize parallelism.
- Critical path (12 services) should be validated before expanding.

---

## Cross-Tier Dependency Edge Listing

Edges from MedinovAI services to infrastructure or lower-tier services:

### Tier 1 → Tier 0
- secrets-manager-bridge → vault  
- security → keycloak, postgres-primary, redis-cache, pgbouncer  
- universal-sign-on → postgres-primary, redis-cache, vault, kafka  
- role-based-permissions → postgres-primary, redis-cache  
- encryption-vault → vault  
- hipaa-gdpr-guard → postgres-primary, redis-cache  
- consent-preference-api → postgres-primary, redis-cache  
- audit-trail-explorer → postgres-primary, redis-cache, elasticsearch  

### Tier 2 → Tier 1
- registry, data-services, stream-bus, config-mgmt, notification-center, aifactory, atlas-engine → security  
- api-gateway → security, role-based-permissions, registry  
- web-core → security, role-based-permissions  

### Tier 3 → Tier 2
- healthLLM → security, aifactory  
- model-service-orchestrator → security, data-services  
- knowledge-graph → security, data-services  
- clinical-decision-support → healthLLM, model-orchestrator, data-services  
- patient-services → security, data-services, consent-preference-api  

### Tier 4 → Tier 3 / Tier 2
- Most domain services depend on security, data-services, patient-services, and/or Tier 3 AI services (healthLLM, model-orchestrator, knowledge-graph, clinical-decision-support).  

### Tier 5 → Tiers 2–4
- Services depend on api-gateway, registry, data-services, stream-bus, configuration-management, notification-center, model-orchestrator, knowledge-graph, clinical-decision-support, web-core.  

### Tier 6 → Tier 1–2
- medinovaios → security, universal-sign-on, role-based-permissions, api-gateway, registry  

---

*Document generated from config/dependency-graph.json. Schema: dependency_graph.schema.json. Last updated: 2026-02-17.*
