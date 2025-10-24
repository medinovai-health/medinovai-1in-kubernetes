# Versioning Implementation Guide

**Service:** medinovai-infrastructure  
**Date:** 2025-10-24  
**Status:** ✅ Versioning Implemented

---

## Overview

This document describes the versioning implementation for medinovai-infrastructure, including API versioning, schema versioning, and version compatibility management.

## Version Information

| Component | Version | Status |
|:----------|:--------|:-------|
| **Service** | 1.0.0 | Stable |
| **API** | v1 | Stable |
| **Schema** | 1.0.0 | Current |

## API Versioning

### Version Endpoint

**Endpoint:** `GET /api/version`

**Response:**
```json
{
  "service": "medinovai-infrastructure",
  "version": "1.0.0",
  "apiVersion": "v1",
  "buildDate": "2025-10-24T10:00:00Z",
  "gitCommit": "abc123",
  "status": "stable",
  "dependencies": {
    "medinovai-api": "^1.0.0"
  },
  "capabilities": []
}
```

### Version Headers

All API requests (except `/api/version`) must include version headers:

**Request Headers:**
- `X-Client-Version`: Client version (SemVer) - **Required**
- `X-Required-API-Version`: Required API version range (SemVer range) - Optional

**Response Headers:**
- `X-Server-Version`: Server version (SemVer)
- `X-API-Version`: API version (v1, v2, etc.)
- `X-Compatible`: Compatibility status (true/false)

**Example:**
```bash
curl -H "X-Client-Version: 1.0.0" \
     -H "X-Required-API-Version: ^1.0.0" \
     https://medinovai-infrastructure.medinovai.com/api/v1/data
```

### Version Compatibility

**Compatibility Rules:**
1. **Major version must match** - Breaking changes increment major version
2. **Minor version must be >=** - New features increment minor version
3. **Patch version is flexible** - Bug fixes increment patch version

**Examples:**
- ✅ Client 1.0.0 + Server 1.0.0 = Compatible
- ✅ Client 1.2.0 + Server 1.5.0 = Compatible
- ✅ Client 1.5.0 + Server 1.2.0 = Compatible
- ❌ Client 1.0.0 + Server 2.0.0 = Incompatible
- ❌ Client 2.0.0 + Server 1.0.0 = Incompatible

## Schema Versioning

### Schema Version Tracking

Database schema versions are tracked in the `schema_version` table:

```sql
CREATE TABLE schema_version (
  id SERIAL PRIMARY KEY,
  schema_id VARCHAR(100) NOT NULL,
  version VARCHAR(20) NOT NULL,
  applied_at TIMESTAMP NOT NULL DEFAULT NOW(),
  applied_by VARCHAR(100) NOT NULL,
  migration_name VARCHAR(255) NOT NULL,
  checksum VARCHAR(64) NOT NULL,
  execution_time_ms INTEGER,
  success BOOLEAN NOT NULL DEFAULT TRUE,
  error_message TEXT,
  CONSTRAINT unique_schema_version UNIQUE (schema_id, version)
);
```

### Migration Process

1. **Create migration** - Generate migration file with version number
2. **Test locally** - Run migration in development environment
3. **Review changes** - Code review for schema changes
4. **Deploy to staging** - Test in staging environment
5. **Deploy to production** - Apply migration with rollback plan

## Deployment

### Version Tagging

All releases are tagged with semantic versioning:

```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### Environment Variables

Set these environment variables for version tracking:

```bash
SERVICE_NAME=medinovai-infrastructure
VERSION=1.0.0
BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_COMMIT=$(git rev-parse --short HEAD)
```

### CI/CD Integration

Update CI/CD pipeline to include version information:

```yaml
# .github/workflows/deploy.yml
env:
  SERVICE_NAME: medinovai-infrastructure
  VERSION: ${{ github.ref_name }}
  BUILD_DATE: ${{ github.event.head_commit.timestamp }}
  GIT_COMMIT: ${{ github.sha }}
```

## Testing

### Unit Tests

Run unit tests for version logic:

```bash
npm test tests/unit/version.test.ts
# or
pytest tests/test_version.py
```

### Integration Tests

Run integration tests for version headers:

```bash
npm test tests/integration/versionHeaders.test.ts
# or
pytest tests/integration/test_version_headers.py
```

### E2E Tests

Run end-to-end tests for versioned API:

```bash
npm test tests/e2e/versionedAPI.test.ts
# or
pytest tests/e2e/test_versioned_api.py
```

## Monitoring

### Version Metrics

Monitor these version-related metrics:

- **Version incompatibility rate** - % of requests with version errors
- **Version distribution** - Client version distribution
- **Deprecated API usage** - Usage of deprecated endpoints
- **Migration success rate** - % of successful schema migrations

### Alerts

Set up alerts for:

- High version incompatibility rate (>1%)
- Deprecated API usage after sunset date
- Schema migration failures
- Version endpoint downtime

## Migration Guide

### For Clients

When upgrading to a new version:

1. **Check compatibility** - Review CHANGELOG for breaking changes
2. **Update client** - Update client library to new version
3. **Test integration** - Run integration tests
4. **Deploy gradually** - Use canary deployment
5. **Monitor errors** - Watch for version incompatibility errors

### For Service

When releasing a new version:

1. **Update version** - Increment version in package.json
2. **Update CHANGELOG** - Document all changes
3. **Update contract** - Update OpenAPI contract
4. **Run tests** - Ensure all tests pass
5. **Deploy** - Deploy with version tag

## Troubleshooting

### Version Incompatibility Error

**Error:**
```json
{
  "error": "Version incompatibility",
  "message": "Client version 1.0.0 is not compatible with required API version ^2.0.0"
}
```

**Solution:**
- Upgrade client to compatible version
- Check CHANGELOG for migration guide
- Contact support if needed

### Missing Version Header

**Error:**
```json
{
  "error": "Missing X-Client-Version header",
  "message": "All API requests must include X-Client-Version header"
}
```

**Solution:**
- Add `X-Client-Version` header to all requests
- Use client library that automatically adds headers

## References

- [MedinovAI Versioning System](../../../architecture-catalog/docs/MEDINOVAI_VERSIONING_SYSTEM.md)
- [API Versioning Architecture](../../../medinovai-api/docs/VERSIONING_ARCHITECTURE.md)
- [Semantic Versioning](https://semver.org/)
- [OpenAPI Specification](https://swagger.io/specification/)

---

**Last Updated:** 2025-10-24  
**Version:** 1.0.0
