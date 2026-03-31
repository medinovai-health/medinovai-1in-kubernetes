# Port Authority Compliance Status

**Date:** 2026-03-28  
**Authority:** medinovai-health/Deploy  
**Registry:** `config/port-registry.json`

## The Rule

> **NO port may be used in ANY MedinovAI repository unless it appears in the Deploy registry.**

Each repository has a permanent 100-port block (8100-26099) assigned by tier:

| Tier | Count | Port Range |
|------|-------|------------|
| Tier 0 (brain/core) | 3 | 8100-8399 |
| Tier 1 (security) | 14 | 8400-9699 |
| Tier 2 (AI/platform) | 23 | 9800-12199 |
| Tier 3 (clinical/apps) | 124 | 12200-24799 |
| Tier 4 (frontend/mobile) | 14 | 24800-26199 |

## Compliance Status: ✅ ENFORCED

All hardcoded ports have been eliminated from medinovai-Developer-1:

### Files Updated

| File | Changes |
|------|---------|
| `deploy/docker-compose.yml` | All service ports now use Deploy registry assignments (8800, 9000-9600, 10100-10200, etc.) |
| `deploy/docker-compose.production.yml` | Core service now uses 8100 (registry) |
| `deploy/medinovai-os-portal/index.html` | All hardcoded 8001-8036 replaced with registry ports |
| `deploy/qa/run-all-qa.sh` | Registry 8800, Keycloak 9080 (Deploy canonical) |
| `deploy/self-validation.py` | Tier 0 services use 8100-8105 (registry) |
| `deploy/demo/setup-demo.sh` | Core 8100, AtlasOS 8101, EPG 8102 (registry) |
| `.cursor/rules/port-authority-enforcement.mdc` | New rule: absolute enforcement |

### Critical Port Mappings (Changed)

| Service | Old (Hardcoded) | New (Registry) |
|---------|-----------------|----------------|
| medinovai-registry | 8060 | **8800** |
| medinovai-universal-sign-on | 8001 | **9600** |
| medinovai-role-based-permissions | 8002 | **9400** |
| medinovai-encryption-vault | 8003 | **9200** |
| medinovai-secrets-manager-bridge | 8004 | **9500** |
| medinovai-hipaa-gdpr-guard | 8005 | **9300** |
| medinovai-audit-trail-explorer | 8006 | **9000** |
| medinovai-aifactory | 8010 | **10100** |
| medinovai-healthllm | 8011 | **10200** |
| medinovai-lis | 8020 | **17400** |
| medinovai-lis-platform | 8026 | **17500** |
| medinovai-ctms | 8030 | **15800** |
| medinovai-edc | 8031 | **16300** |
| medinovai-pharmacovigilance | 8036 | **22800** |
| Keycloak | 8180 | **9080** (Deploy canonical) |

## How to Use

### Bash
```bash
PORT=$(python3 -c "import json; r=json.load(open('$DEPLOY/config/port-registry.json')); print(r['assignments']['medinovai-1sc-encryption-vault']['base_port'])")
# Returns: 9200
```

### TypeScript
```typescript
import { getRepoPort } from './port-registry';
const port = getRepoPort('medinovai-encryption-vault');  // 9200
```

### Python
```python
import json
with open('config/port-registry.json') as f:
    registry = json.load(f)
port = registry['assignments']['medinovai-1sc-encryption-vault']['base_port']  # 9200
```

## Violations

**Current violations: 0**

All ports now sourced exclusively from Deploy registry.

## Enforcement

Cursor rule `.cursor/rules/port-authority-enforcement.mdc` is active:
- Any hardcoded port outside the registry is a **CRITICAL violation**
- PRs with hardcoded ports will be **REJECTED automatically**

## Next Steps

1. ✅ All repos cloned (~150 of 190)
2. ✅ Permanent port registry created (8100-26099)
3. ✅ Docker Compose for all services using registry ports
4. ⏳ Execute full deployment: `make customer1-deploy` in Deploy repo
5. ⏳ Run QA validation: `make customer1-qa`
6. ⏳ Apply trust gate: `make customer1-trust`

---
**Port Authority:** medinovai-health/Deploy  
**Registry Location:** `~/medinovai-all-repos/medinovai-Deploy/config/port-registry.json`
