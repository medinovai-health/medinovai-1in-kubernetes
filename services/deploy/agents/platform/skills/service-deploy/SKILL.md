# Skill: Service Deploy

## Purpose

Deploy a MedinovAI service to a target environment using the appropriate deployment strategy (canary, blue-green, or rolling).

## Trigger

- CI/CD pipeline: After successful build and staging verification
- Manual request: "Deploy {service} to {environment}"
- Webhook: Release event from service repository

## Inputs

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| service | string | Yes | Service name (matches services/registry/*.manifest.json) |
| environment | string | Yes | Target environment |
| image_tag | string | No | Docker image tag (default: latest release) |
| strategy | string | No | Override deploy strategy (canary, blue-green, rolling) |

## Steps

1. **Load manifest**: Read service manifest for dependencies, resources, strategy
2. **Pre-flight**: Verify dependencies are healthy, deploy window is valid
3. **Record previous version**: Save current version for rollback
4. **Deploy**: Execute deployment strategy
5. **Health check**: Verify new version is healthy
6. **Monitor** (canary only): Watch error rate for canary duration
7. **Promote or rollback**: Based on monitoring results
8. **Notify**: Post deployment status

## Outputs

```json
{
  "status": "ok|error|rolled_back",
  "service": "api-gateway",
  "environment": "production",
  "version": "v1.2.3",
  "previous_version": "v1.2.2",
  "strategy": "canary",
  "duration_seconds": 720,
  "rollback_available": true
}
```

## Failure Modes

| Failure | Response |
|---------|----------|
| Dependency service unhealthy | Abort deploy, alert |
| Image pull fails | Check registry auth, retry once |
| Health check fails post-deploy | Auto-rollback |
| Canary error rate exceeds threshold | Auto-rollback |
| Deploy timeout | Check pod status, alert |

## Approval Requirements

- Staging: No approval needed
- Production (standard services): Eng lead approval via deploy pipeline
- Production (critical tier): Eng lead + CTO approval
- Production (clinical services): Eng lead + CMO approval (GOV-10)
