# MedinovAI Platform — Service Catalog

Copyright 2025-2026 MedinovAI. All Rights Reserved.

**Total Services:** 109 (across 7 deployment tiers)

---

## Summary Table

| Service ID | Repo | Type | Port | Health Endpoint | Tier | Deploy Phase | Dependencies |
|------------|------|------|------|-----------------|------|--------------|--------------|
| **TIER 1 — Security & Secrets Foundation** | | | | | | | |
| medinovai-secrets-manager-bridge | myonsite-healthcare/medinovai-secrets-manager-bridge | python-service | 8000 | /health | critical | phase 1 | vault |
| medinovai-security | myonsite-healthcare/MedinovAI-security | node-service | 9000 | /health | critical | phase 1 | keycloak, postgres-primary, redis-cache, pgbouncer, medinovai-secrets-manager-bridge |
| token-validator _(sub)_ | — | node-service | 9010 | /health | critical | phase 1 | medinovai-security |
| audit-service _(sub)_ | — | node-service | 9011 | /health | critical | phase 1 | medinovai-security |
| tenant-onboarding _(sub)_ | — | node-service | 9012 | /health | critical | phase 1 | medinovai-security |
| policy-engine _(sub)_ | — | node-service | 9013 | /health | critical | phase 1 | medinovai-security |
| medinovai-universal-sign-on | myonsite-healthcare/medinovai-universal-sign-on | python-service | 8000 | /health | critical | phase 1 | postgres-primary, redis-cache, vault, kafka, medinovai-security |
| medinovai-role-based-permissions | myonsite-healthcare/medinovai-role-based-permissions | python-service | 8000 | /healthz | critical | phase 1 | postgres-primary, redis-cache, medinovai-security |
| medinovai-encryption-vault | myonsite-healthcare/medinovai-encryption-vault | python-service | 8000 | /health | critical | phase 1 | vault, medinovai-secrets-manager-bridge |
| medinovai-hipaa-gdpr-guard | myonsite-healthcare/medinovai-hipaa-gdpr-guard | python-service | 8000 | /health | critical | phase 1 | postgres-primary, redis-cache, medinovai-security, medinovai-role-based-permissions |
| medinovai-consent-preference-api | myonsite-healthcare/medinovai-consent-preference-api | python-service | 8000 | /health | high | phase 1 | postgres-primary, redis-cache, medinovai-security, medinovai-hipaa-gdpr-guard |
| medinovai-audit-trail-explorer | myonsite-healthcare/medinovai-audit-trail-explorer | python-service | 8000 | /health | high | phase 1 | postgres-primary, redis-cache, elasticsearch, medinovai-security |
| **TIER 2 — Platform Core Services** | | | | | | | |
| medinovai-registry | myonsite-healthcare/medinovai-registry | node-service | 8080 | /health | critical | phase 2 | postgres-primary, redis-cache, medinovai-security |
| medinovai-data-services | myonsite-healthcare/medinovai-data-services | python-service | 8000 | /health | critical | phase 2 | postgres-primary, postgres-clinical, redis-cache, medinovai-security |
| medinovai-real-time-stream-bus | myonsite-healthcare/medinovai-real-time-stream-bus | node-service | 3000 | /health/ready | critical | phase 2 | kafka, redis-cache, medinovai-security |
| medinovai-configuration-management | myonsite-healthcare/medinovai-configuration-management | python-service | 8000 | /health | high | phase 2 | postgres-primary, redis-cache, medinovai-security |
| medinovai-notification-center | myonsite-healthcare/medinovai-notification-center | node-service | 8080 | /health | high | phase 2 | postgres-primary, redis-cache, rabbitmq, medinovai-security |
| medinovai-aifactory | myonsite-healthcare/medinovai-aifactory | python-service | 8000 | /health | high | phase 2 | postgres-primary, redis-cache, medinovai-security |
| medinovai-api-gateway | myonsite-healthcare/medinovai-api-gateway | node-service | 8080 | /health | critical | phase 2 | medinovai-security, medinovai-role-based-permissions, medinovai-registry |
| medinovai-web-core | myonsite-healthcare/medinovai-web-core | node-service | npm-publish | N/A | high | phase 2 | medinovai-security, medinovai-role-based-permissions |
| medinovai-atlas-engine | myonsite-healthcare/medinovai-atlas-engine | python-service | 8000 | /health | high | phase 2 | postgres-primary, redis-cache, medinovai-security, medinovai-registry |
| **TIER 3 — AI/ML & Clinical Foundation** | | | | | | | |
| medinovai-healthLLM | myonsite-healthcare/medinovai-healthLLM | ml-service | 8000 | /health | critical | phase 3 | postgres-primary, redis-cache, medinovai-security, medinovai-aifactory |
| medinovai-model-service-orchestrator | myonsite-healthcare/MedinovAI-Model-Service-Orchestrator | ml-service | 8000 | /health | high | phase 3 | postgres-primary, redis-cache, kafka, s3-object-store, medinovai-security, medinovai-data-services |
| medinovai-knowledge-graph | myonsite-healthcare/medinovai-knowledge-graph | python-service | 8000 | /health | high | phase 3 | postgres-primary, elasticsearch, medinovai-security, medinovai-data-services |
| medinovai-clinical-decision-support | myonsite-healthcare/medinovai-clinical-decision-support | ml-service | 8000 | /health | critical | phase 3 | medinovai-healthLLM, medinovai-model-service-orchestrator, medinovai-data-services |
| medinovai-patient-services | myonsite-healthcare/medinovai-patient-onboarding | python-service | 8000 | /health | critical | phase 3 | postgres-primary, redis-cache, medinovai-security, medinovai-data-services, medinovai-consent-preference-api |
| medinovai-ai-standards | myonsite-healthcare/MedinovAI-AI-Standards | config-only | N/A | N/A | high | phase 3 | — |
| **TIER 4A — Clinical Services** | | | | | | | |
| medinovai-patient-onboarding | myonsite-healthcare/medinovai-patient-onboarding | python-service | 8000 | /health | high | phase 4 | postgres-primary, redis-cache, medinovai-security, medinovai-patient-services, medinovai-consent-preference-api |
| medinovai-patientmatching | myonsite-healthcare/medinovai-patientmatching | node-service | 8080 | /healthz | high | phase 4 | postgres-primary, elasticsearch, kafka, medinovai-security, medinovai-patient-services |
| medinovai-health-timeline | myonsite-healthcare/medinovai-health-timeline | python-service | 8000 | /health | normal | phase 4 | postgres-primary, redis-cache, medinovai-security, medinovai-data-services, medinovai-patient-services |
| medinovai-care-team-chat | myonsite-healthcare/medinovai-care-team-chat | node-service | 8000 | /health | normal | phase 4 | postgres-primary, redis-cache, medinovai-security, medinovai-notification-center, medinovai-real-time-stream-bus |
| medinovai-smart-scheduler | myonsite-healthcare/medinovai-smart-scheduler | python-service | 8000 | /health | normal | phase 4 | postgres-primary, redis-cache, medinovai-security, medinovai-patient-services |
| medinovai-wait-list-balancer | myonsite-healthcare/medinovai-wait-list-balancer | python-service | 8080 | /healthz | normal | phase 4 | postgres-primary, redis-cache, kafka, medinovai-security, medinovai-smart-scheduler, medinovai-patient-services |
| medinovai-virtual-triage | myonsite-healthcare/medinovai-virtual-triage | python-service | 8000 | /health | high | phase 4 | postgres-primary, redis-cache, medinovai-security, medinovai-healthLLM, medinovai-patient-services |
| medinovai-telehealth-hub | myonsite-healthcare/medinovai-telehealth-hub | node-service | 8080 | /healthz | high | phase 4 | postgres-primary, redis-cache, medinovai-security, medinovai-smart-scheduler, medinovai-notification-center |
| medinovai-remote-vitals-ingest | myonsite-healthcare/medinovai-remote-vitals-ingest | python-service | 8000 | /health | high | phase 4 | postgres-primary, kafka, medinovai-security, medinovai-real-time-stream-bus, medinovai-data-services |
| **TIER 4B — Diagnostic Services** | | | | | | | |
| medinovai-lab-order-router | myonsite-healthcare/medinovai-lab-order-router | python-service | 8000 | /health | high | phase 4 | postgres-primary, redis-cache, medinovai-security, medinovai-data-services |
| medinovai-pathology-ai | myonsite-healthcare/medinovai-pathology-ai | ml-service | 8000 | /health | high | phase 4 | postgres-primary, redis-cache, s3-object-store, medinovai-security, medinovai-model-service-orchestrator |
| medinovai-imaging-viewer | myonsite-healthcare/medinovai-imaging-viewer | python-service | 8000 | /health | normal | phase 4 | postgres-primary, s3-object-store, medinovai-security |
| medinovai-genomics-interpreter | myonsite-healthcare/medinovai-genomics-interpreter | ml-service | 8000 | /health | normal | phase 4 | postgres-primary, medinovai-security, medinovai-model-service-orchestrator |
| medinovai-image-to-text-ocr | myonsite-healthcare/medinovai-image-to-text-ocr | ml-service | 8000 | /health | normal | phase 4 | postgres-primary, s3-object-store, medinovai-security |
| **TIER 4C — AI Services** | | | | | | | |
| medinovai-chatbot | myonsite-healthcare/MedinovAI-Chatbot | ml-service | 8000 | /api/health | high | phase 4 | postgres-primary, redis-cache, mongodb, medinovai-security, medinovai-healthLLM |
| medinovai-ai-scribe | myonsite-healthcare/medinovai-ai-scribe | ml-service | 8000 | /health | high | phase 4 | postgres-primary, redis-cache, medinovai-security, medinovai-healthLLM |
| medinovai-doc-summarizer | myonsite-healthcare/medinovai-doc-summarizer | ml-service | 8000 | /health | normal | phase 4 | postgres-primary, medinovai-security, medinovai-healthLLM, medinovai-knowledge-graph |
| medinovai-natural-language-query | myonsite-healthcare/medinovai-natural-language-query | ml-service | 8000 | /health | normal | phase 4 | postgres-primary, medinovai-security, medinovai-healthLLM, medinovai-data-services |
| medinovai-anomaly-detector | myonsite-healthcare/medinovai-anomaly-detector | ml-service | 8000 | /health | normal | phase 4 | kafka, medinovai-security, medinovai-real-time-stream-bus, medinovai-model-service-orchestrator |
| medinovai-sentiment-monitor | myonsite-healthcare/medinovai-sentiment-monitor | ml-service | 8000 | /health | normal | phase 4 | postgres-primary, redis-cache, medinovai-security, medinovai-data-services |
| medinovai-drug-interaction-checker | myonsite-healthcare/medinovai-drug-interaction-checker | ml-service | 8000 | /health | high | phase 4 | postgres-primary, medinovai-security, medinovai-clinical-decision-support, medinovai-knowledge-graph |
| medinovai-medical-fax-processing | myonsite-healthcare/MedinovAI---Medical-Fax-Processing | ml-service | 8000 | /health | normal | phase 4 | postgres-primary, mongodb, redis-cache, s3-object-store, medinovai-security, medinovai-image-to-text-ocr |
| medinovai-content-translator | myonsite-healthcare/medinovai-content-translator | ml-service | 8000 | /health | normal | phase 4 | medinovai-security, medinovai-healthLLM |
| medinovai-text-to-speech-narrator | myonsite-healthcare/medinovai-text-to-speech-narrator | ml-service | 8000 | /health | normal | phase 4 | medinovai-security |
| medinovai-voice-command-layer | myonsite-healthcare/medinovai-voice-command-layer | ml-service | 8000 | /health | normal | phase 4 | medinovai-security, medinovai-healthLLM |
| **TIER 4D — Medication & Pharmacy** | | | | | | | |
| medinovai-e-prescribe-gateway | myonsite-healthcare/medinovai-e-prescribe-gateway | python-service | 8000 | /health | high | phase 4 | postgres-primary, medinovai-security, medinovai-patient-services, medinovai-drug-interaction-checker |
| medinovai-medication-tracker | myonsite-healthcare/medinovai-medication-tracker | python-service | 8000 | /health | normal | phase 4 | postgres-primary, redis-cache, medinovai-security, medinovai-patient-services, medinovai-data-services |
| **TIER 4E — Research & Clinical Trials** | | | | | | | |
| medinovai-CTMS | myonsite-healthcare/medinovai-CTMS | python-service | 8000 | /health | high | phase 4 | postgres-primary, redis-cache, medinovai-security, medinovai-data-services, medinovai-patient-services |
| medinovai-EDC | myonsite-healthcare/medinovai-EDC | python-service | 8000 | /health | high | phase 4 | postgres-primary, redis-cache, medinovai-security, medinovai-data-services, medinovai-CTMS |
| medinovai-etmf | myonsite-healthcare/medinovai-etmf | python-service | 8000 | /health | normal | phase 4 | postgres-primary, s3-object-store, medinovai-security, medinovai-data-services, medinovai-CTMS |
| medinovai-saes | myonsite-healthcare/medinovai-saes | node-service | 8080 | /api/health | high | phase 4 | postgres-primary, s3-object-store, kafka, medinovai-security, medinovai-patient-services, medinovai-CTMS |
| medinovai-eConsent | myonsite-healthcare/medinovai-eConsent | python-service | 8000 | /health | normal | phase 4 | postgres-primary, medinovai-security, medinovai-EDC, medinovai-consent-preference-api |
| medinovai-ePRO | myonsite-healthcare/medinovai-ePRO | python-service | 8000 | /health | normal | phase 4 | postgres-primary, medinovai-security, medinovai-EDC |
| medinovai-eSource | myonsite-healthcare/medinovai-eSource | python-service | 8000 | /health | normal | phase 4 | postgres-primary, medinovai-security, medinovai-EDC |
| medinovai-eISF | myonsite-healthcare/medinovai-eISF | python-service | 8000 | /health | normal | phase 4 | postgres-primary, s3-object-store, medinovai-security, medinovai-EDC |
| medinovai-iwrs | myonsite-healthcare/medinovai-iwrs | python-service | 8000 | /health | normal | phase 4 | postgres-primary, medinovai-security, medinovai-CTMS |
| medinovai-Pharmacovigilance | myonsite-healthcare/medinovai-Pharmacovigilance | python-service | 8000 | /health | high | phase 4 | postgres-primary, redis-cache, medinovai-security, medinovai-saes |
| medinovai-ResearchSuite | myonsite-healthcare/medinovai-ResearchSuite | python-service | 8000 | /health | normal | phase 4 | postgres-primary, medinovai-security, medinovai-CTMS, medinovai-EDC, medinovai-etmf |
| medinovai-regulatory-submissions | myonsite-healthcare/medinovai-regulatory-submissions | python-service | 8000 | /health | normal | phase 4 | postgres-primary, s3-object-store, medinovai-security, medinovai-etmf, medinovai-CTMS |
| medinovai-RBM | myonsite-healthcare/medinovai-RBM | python-service | 8000 | /health | normal | phase 4 | postgres-primary, medinovai-security, medinovai-CTMS |
| medinovai-reseach-fabric | myonsite-healthcare/medinovai-reseach-fabric | python-service | 8000 | /health | normal | phase 4 | postgres-primary, medinovai-security, medinovai-data-services |
| medinovai-SiteFeasibility | myonsite-healthcare/medinovAI-SiteFeasibility | python-service | 8000 | /health | normal | phase 4 | postgres-primary, medinovai-security, medinovai-CTMS |
| **TIER 4F — Business Services** | | | | | | | |
| medinovai-billing | myonsite-healthcare/medinovai-billing | python-service | 8000 | /health | high | phase 4 | postgres-primary, redis-cache, medinovai-security, medinovai-patient-services, medinovai-data-services |
| medinovai-provider-credentialing | myonsite-healthcare/medinovai-provider-credentialing | python-service | 8000 | /health | normal | phase 4 | postgres-primary, redis-cache, medinovai-security, medinovai-data-services |
| medinovai-credentialing | myonsite-healthcare/Credentialing | node-service | 3000 | /health | normal | phase 4 | postgres-primary, redis-cache, keycloak, medinovai-security, medinovai-data-services |
| medinovai-employee-portal | myonsite-healthcare/Employee-Portal | node-service | 3000 | /health | normal | phase 4 | postgres-primary, redis-cache, medinovai-security, medinovai-role-based-permissions |
| medinovai-subscription | myonsite-healthcare/subscription | python-service | 8000 | /health/ | normal | phase 4 | postgres-primary, redis-cache, medinovai-security |
| medinovai-quality-certification | myonsite-healthcare/medinovai-quality-certification | python-service | 8000 | /health | normal | phase 4 | postgres-primary, medinovai-security, medinovai-data-services |
| medinovai-inventorymanagement | myonsite-healthcare/medinovai-inventorymanagement | python-service | 8000 | /health | normal | phase 4 | postgres-primary, medinovai-security, medinovai-data-services |
| medinovai-mail | myonsite-healthcare/medinovai-mail | python-service | 8000 | /health | normal | phase 4 | redis-cache, medinovai-security |
| medinovai-email-service | myonsite-healthcare/MedinovAI-Email-Service | python-service | 8000 | /health | normal | phase 4 | redis-cache, medinovai-security |
| **TIER 4G — Laboratory Information System** | | | | | | | |
| medinovai-lis | myonsite-healthcare/medinovai-lis | python-service | 8000 | /health | high | phase 4 | postgres-primary, redis-cache, medinovai-security, medinovai-data-services, medinovai-lab-order-router |
| medinovai-lis-platform | myonsite-healthcare/medinovai-lis-platform | python-service | 8000 | /health | normal | phase 4 | postgres-primary, medinovai-lis |
| medinovai-lis-ui | myonsite-healthcare/medinovai-lis-ui | node-service | 3000 | /health | normal | phase 4 | medinovai-lis-platform, medinovai-web-core |
| **TIER 5 — Integration, DevOps & Specialized** | | | | | | | |
| medinovai-edge-cache-cdn | myonsite-healthcare/medinovai-edge-cache-cdn | node-service | 8000 | /health | normal | phase 5 | medinovai-api-gateway |
| medinovai-data-lake-loader | myonsite-healthcare/medinovai-data-lake-loader | python-service | 8000 | /health | normal | phase 5 | kafka, s3-object-store, medinovai-real-time-stream-bus, medinovai-data-services |
| medinovai-feature-flag-console | myonsite-healthcare/medinovai-feature-flag-console | node-service | 8000 | /health | normal | phase 5 | postgres-primary, redis-cache, medinovai-security, medinovai-configuration-management |
| medinovai-canary-rollout-orchestrator | myonsite-healthcare/medinovai-canary-rollout-orchestrator | python-service | 8000 | /health | normal | phase 5 | medinovai-registry |
| medinovai-devops-telemetry | myonsite-healthcare/medinovai-devops-telemetry | python-service | 8000 | /health | normal | phase 5 | prometheus, medinovai-security |
| medinovai-policy-diff-watcher | myonsite-healthcare/medinovai-policy-diff-watcher | python-service | 8000 | /health | normal | phase 5 | postgres-primary, medinovai-security |
| medinovai-etl-designer | myonsite-healthcare/medinovai-etl-designer | python-service | 8000 | /health | normal | phase 5 | postgres-primary, kafka, medinovai-security, medinovai-data-services |
| medinovai-prompt-vault | myonsite-healthcare/medinovai-prompt-vault | python-service | 8000 | /healthz | normal | phase 5 | postgres-primary, redis-cache, rabbitmq, elasticsearch, medinovai-security |
| medinovai-qa-agent-builder | myonsite-healthcare/medinovai-qa-agent-builder | python-service | 8000 | /health | normal | phase 5 | postgres-primary, medinovai-security, medinovai-model-service-orchestrator |
| medinovai-task-kanban | myonsite-healthcare/medinovai-task-kanban | python-service | 8000 | /health | normal | phase 5 | postgres-primary, redis-cache, kafka, medinovai-security, medinovai-notification-center |
| medinovai-guideline-updater | myonsite-healthcare/medinovai-guideline-updater | python-service | 8000 | /health | normal | phase 5 | postgres-primary, rabbitmq, medinovai-security, medinovai-knowledge-graph |
| medinovai-white-label-skinner | myonsite-healthcare/medinovai-white-label-skinner | node-service | 8000 | /health | normal | phase 5 | medinovai-web-core |
| medinovai-accessibility-checker | myonsite-healthcare/medinovai-accessibility-checker | node-service | 8000 | /health | batch | phase 5 | medinovai-security |
| medinovai-governance-templates | myonsite-healthcare/medinovai-governance-templates | python-service | 8000 | /health | normal | phase 5 | postgres-primary, medinovai-security |
| medinovai-risk-management | myonsite-healthcare/medinovai-risk-management | python-service | 8000 | /health | normal | phase 5 | postgres-primary, medinovai-security, medinovai-data-services |
| medinovai-cds | myonsite-healthcare/medinovai-cds | python-service | 8000 | /health | normal | phase 5 | postgres-primary, medinovai-security, medinovai-clinical-decision-support |
| medinovai-developer-portal | myonsite-healthcare/medinovai-developer-portal | node-service | 3000 | /health | normal | phase 5 | medinovai-api-gateway, medinovai-registry |
| medinovai-Livekit | myonsite-healthcare/medinovai-Livekit | node-service | 7880 | /health | normal | phase 5 | redis-cache, medinovai-security |
| **TIER 6 — UI Shell & Master Menu** | | | | | | | |
| medinovai-ui-components | myonsite-healthcare/medinovai-ui-components | node-service | npm-publish | N/A | high | phase 6 | medinovai-web-core |
| medinovai-multimodal-ui-shell | myonsite-healthcare/medinovai-multimodal-ui-shell | node-service | 3000 | /health | high | phase 6 | medinovai-web-core, medinovai-ui-components |
| medinovaios | myonsite-healthcare/medinovaios | node-service | 5173 | / | critical | phase 6 | redis-cache, medinovai-security, medinovai-universal-sign-on, medinovai-role-based-permissions, medinovai-api-gateway, medinovai-registry |

---

## Infrastructure Dependencies Matrix

| Infrastructure | Tier 0 Port | Services Using | Count |
|----------------|-------------|-----------------|-------|
| **PostgreSQL (postgres-primary)** | 5432 | Security, USO, RBAC, encryption-vault, hipaa-gdpr-guard, consent-preference-api, audit-trail-explorer, registry, data-services, configuration-management, notification-center, aifactory, atlas-engine, healthLLM, model-service-orchestrator, knowledge-graph, patient-services, + 50+ domain/ops services | 70+ |
| **PostgreSQL (postgres-clinical)** | 5433 | data-services only | 1 |
| **Redis** | 6379 | Security, USO, RBAC, hipaa-gdpr-guard, consent-preference-api, audit-trail-explorer, registry, data-services, configuration-management, notification-center, real-time-stream-bus, aifactory, atlas-engine, + 40+ services | 55+ |
| **Kafka** | 9092 | USO, real-time-stream-bus, patientmatching, wait-list-balancer, remote-vitals-ingest, anomaly-detector, saes, data-lake-loader, etl-designer, task-kanban | 10 |
| **Elasticsearch** | 9200 | audit-trail-explorer, knowledge-graph, patientmatching, prompt-vault | 4 |
| **RabbitMQ** | 5672 | notification-center, prompt-vault, guideline-updater | 3 |
| **MongoDB** | 27017 | chatbot, medical-fax-processing | 2 |
| **S3/Object Store** | N/A | model-service-orchestrator, pathology-ai, imaging-viewer, image-to-text-ocr, medical-fax-processing, etmf, saes, eISF, regulatory-submissions, data-lake-loader | 10 |
| **Vault** | 8200 | secrets-manager-bridge, universal-sign-on, encryption-vault | 3 |
| **Keycloak** | 9080 | security, credentialing | 2 |
| **PgBouncer** | 6432 | security | 1 |
| **Prometheus** | 9090 | devops-telemetry | 1 |
| **Zookeeper** | 2181 | kafka (indirect) | 0 |

---

## Service Type Distribution

| Type | Count | Percentage | Typical Use |
|------|-------|------------|-------------|
| **python-service** | 58 | 53% | Data, security, business logic, ETL, research, clinical |
| **node-service** | 32 | 29% | API gateway, real-time, notifications, UI, streaming |
| **ml-service** | 18 | 17% | AI/ML inference, healthLLM, CDS, chatbot, pathology |
| **config-only** | 1 | 1% | AI standards configuration |
| **npm-publish** | 2 | — | Web core, UI components (library, not runtime) |
| **Total (runtime services)** | 109 | 100% | |

---

## Port Allocation Map

| Port Range | Usage | Services |
|------------|-------|----------|
| **3000** | Node/React apps | real-time-stream-bus, credentialing, employee-portal, lis-ui, developer-portal, multimodal-ui-shell |
| **5173** | Vite (medinovaios) | medinovaios (Master Menu) |
| **8000** | Python/ML default | 60+ services |
| **8080** | Node API default | registry, notification-center, api-gateway, patientmatching, wait-list-balancer, telehealth-hub, lab-order-router, lis, saes |
| **7880** | Livekit WebRTC | medinovai-Livekit |
| **9000** | Security main | medinovai-security |
| **9010–9013** | Security sub-services | token-validator, audit-service, tenant-onboarding, policy-engine |
| **N/A** | npm-publish / config-only | medinovai-web-core, medinovai-ui-components, medinovai-ai-standards |

### Port Collision Notes

- **8000**: Shared by many Python/ML services; in Kubernetes each service runs in its own pod/container, so port 8000 is scoped per service.
- **8080**: Shared by several Node services; same pod isolation applies.
- **3000**: Shared by Node/React dev servers; production typically uses ingress and single external port.

---

## Health Endpoint Standards

| Endpoint | Usage | Status Codes | Response Format |
|----------|-------|--------------|------------------|
| **/health** | Liveness + readiness (default) | 200 = healthy, 503 = unhealthy | `{"status":"ok"}` or `{"healthy":true}` |
| **/healthz** | Kubernetes-style health | 200 = healthy, 503 = unhealthy | Same as /health |
| **/health/ready** | Readiness only (e.g., stream-bus) | 200 = ready to accept traffic | `{"ready":true}` |
| **/api/health** | API-specific health (chatbot, saes) | 200 = healthy | JSON with service name and version |
| **/** | Root (medinovaios SPA) | 200 = serving | HTML page |
| **N/A** | config-only / npm-publish | No HTTP server | — |

### Validation Script

Health checks are run by `scripts/validation/health_check_tier.sh`. Each tier validates all services in that tier before proceeding to the next deployment phase.

---

## Critical Path (Minimum Viable Deployment)

The following 12 components must be deployed in exact order for the platform to function:

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

*Generated from `config/dependency-graph.json`. For deployment order and validation, see `scripts/validation/` and `docs/INSTANTIATION_GUIDE.md`.*
