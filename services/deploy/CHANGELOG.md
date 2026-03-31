# Changelog

All notable changes to the MedinovAI Deploy system will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-03-09

### Changed
- Reframed deployment guidance around the canonical AtlasOS four-layer model: named assistants, functional agents, entity agents, and squad agents
- Updated four-environment and CEO stack documentation so employee assistants and SOP/protocol/regulation agents follow the shared AtlasOS runtime pattern
- Clarified the runtime role of `entity-lifecycle-gateway` for database-backed entity agents across all environments
- Aligned repository version metadata between `package.json` and `medinovai.manifest.yaml`

## [0.1.0] - 2026-02-17

### Added
- Initial repository structure with full directory layout
- Migrated Atlas autonomous brain architecture from AtlasOS
- Migrated AI governance framework (GOV-01 through GOV-10)
- 7 deploy agent workspaces: platform, eng, security, data, ai-ml, supervisor, guardian
- 10+ agent skills: infra-provision, service-deploy, health-audit, cost-optimize, drift-remediate, ci-monitor, pr-review, dependency-planner, pipeline-doctor, release-manager
- Greenfield instantiation script (15-step checkpointed process)
- 7 GitHub Actions workflows: CI, deploy-staging, deploy-production, infra-plan, security-scan, drift-detection, nightly-health (placeholder)
- 4 Lobster approval-gated workflows: deploy, infra-change, AI model validation, disaster recovery
- 6 service deployment manifests: api-gateway, auth-service, clinical-engine, data-pipeline, ai-inference, notification-service
- Terraform networking module (VPC, subnets, NAT, security groups, flow logs)
- Kubernetes base manifests (namespaces, network policies, resource quotas)
- 3 Docker base images (python-service, node-service, ml-service)
- Deployment scripts: deploy_service, deploy_all, rollback, promote_canary
- Maintenance scripts: drift_check, rotate_secrets, cert_renewal, db_backup
- Monitoring scripts: health_check_all, setup_monitoring
- Validation scripts: validate_compliance, smoke_test
- Bootstrap scripts: prerequisites, instantiate, init-cloud-account, init-secrets
- Comprehensive documentation: INSTANTIATION_GUIDE, CICD_PIPELINE, DISASTER_RECOVERY, MONITORING_STACK
- Cursor rules: deploy-safety, infra-conventions
- Service manifest JSON schema
- GitHub issue templates for infrastructure requests
