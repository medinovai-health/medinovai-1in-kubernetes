# API Versioning Strategy for medinovai-1in-kubernetes

## Overview
This document defines the API versioning strategy for the medinovai-1in-kubernetes service.

## Versioning Scheme
- **URL Path Versioning**: `/api/v1/`, `/api/v2/`
- **Current Version**: v1
- **Deprecation Policy**: Previous versions supported for 6 months after new version release

## Version Lifecycle
| Version | Status | Release Date | Deprecation Date |
|---------|--------|-------------|-----------------|
| v1      | Active | 2026-04-14  | -               |

## Breaking Change Policy
1. Breaking changes require a new major version
2. Non-breaking additions (new fields, endpoints) are added to current version
3. Deprecation notices sent 3 months before removal

## Headers
- `X-API-Version`: Current API version in response
- `X-Deprecated`: Present when endpoint is deprecated
- `X-Sunset-Date`: Date when deprecated endpoint will be removed

## Migration Guide
When upgrading between versions:
1. Review changelog for breaking changes
2. Update client SDK to latest version
3. Test against staging environment
4. Switch production traffic with canary deployment
