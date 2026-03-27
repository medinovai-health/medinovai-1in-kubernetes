# Multi-Tenant Configuration — medinovai-infrastructure

**Standard:** `medinovai-ai-standards/ARCHITECTURE.md` | Dim 17
**Deployment Regions:** US, EU, Canada, India, UK, GCC
**Isolation Model:** Row-level security (primary) + Schema-level (PHI-sensitive)

---

## Tenant Identity

Every authenticated request carries a `tenant_id` in the JWT claims:

```json
{
  "sub": "user-uuid",
  "tenant_id": "org-uuid",
  "tenant_tier": "enterprise|standard|starter",
  "region": "us-east-1|eu-west-1|ca-central-1|ap-south-1|eu-west-2|me-south-1",
  "roles": ["clinician", "admin"],
  "iat": 1711540800,
  "exp": 1711541700
}
```

## Tenant Propagation

### Middleware (FastAPI)

```python
from fastapi import Request, HTTPException
from starlette.middleware.base import BaseHTTPMiddleware

class TenantMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, mos_request: Request, mos_call_next):
        mos_tenant_id = mos_request.state.jwt_claims.get("tenant_id")
        if not mos_tenant_id:
            raise HTTPException(status_code=401, detail="Missing tenant context")
        mos_request.state.tenant_id = mos_tenant_id
        mos_response = await mos_call_next(mos_request)
        return mos_response
```

### Database Query Filter

```python
# ALWAYS add tenant filter — never query without it
async def mos_getResourcesForTenant(mos_tenant_id: str, mos_db: AsyncSession):
    return await mos_db.execute(
        select(Resource)
        .where(Resource.tenant_id == mos_tenant_id)
        .where(Resource.deleted_at.is_(None))
    )
```

## Data Residency

| Region Code | AWS Region | Data Stays In | Law |
|-------------|-----------|---------------|-----|
| `us-east-1` | US East (N. Virginia) | USA | HIPAA |
| `eu-west-1` | EU (Ireland) | EU | GDPR |
| `ca-central-1` | Canada | Canada | PIPEDA |
| `ap-south-1` | India (Mumbai) | India | DPDP Act 2023 |
| `eu-west-2` | UK (London) | UK | UK DPA 2018 |
| `me-south-1` | Bahrain | GCC | Local |

Cross-border transfer requires explicit tenant consent and DPA.

## Tenant Feature Flags

```python
E_TIER_FEATURES = {
    "enterprise": ["advanced_analytics", "custom_workflows", "api_access", "sso"],
    "standard":   ["basic_analytics", "api_access"],
    "starter":    [],
}

def mos_hasFeature(mos_tenant_tier: str, mos_feature: str) -> bool:
    return mos_feature in E_TIER_FEATURES.get(mos_tenant_tier, [])
```

## Tenant Isolation Checklist

- [ ] `tenant_id` extracted from JWT on every request
- [ ] All DB queries include `WHERE tenant_id = :tenant_id`
- [ ] Background jobs scoped to tenant (no cross-tenant batch jobs)
- [ ] Cache keys prefixed with `tenant_id`
- [ ] Uploaded files stored in tenant-isolated S3 prefix
- [ ] Logging includes `tenant_id` (never logs PHI)
- [ ] Audit trail records `tenant_id` on every action
- [ ] Error responses never leak other tenant's data

## Tenant Onboarding/Offboarding

See `medinovai-onboarding-service` for the automated tenant lifecycle workflow.

Offboarding checklist:
- [ ] Export tenant data (GDPR Article 20 portability)
- [ ] Delete all tenant data after retention period
- [ ] Revoke all auth tokens
- [ ] Disable tenant in identity provider
- [ ] Archive audit logs (7-year retention for Tier 1)
