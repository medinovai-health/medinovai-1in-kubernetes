# MedinovAI Security Service

Central authentication and authorization service for the MedinovAI Infrastructure. Provides SSO (Single Sign-On) via Keycloak OIDC integration, RBAC, audit logging, and token validation for all infrastructure services.

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   User Browser  │────▶│  Security Service │────▶│    Keycloak     │
│                 │◀────│   (FastAPI)       │◀────│   (OIDC)        │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                               │
                               ▼
                    ┌──────────────────┐
                    │ Infrastructure   │
                    │ Services         │
                    │ (Grafana, Kibana,│
                    │  Registry, etc.)  │
                    └──────────────────┘
```

## Features

- **SSO Gateway**: OIDC integration with Keycloak for unified authentication
- **Token Validation**: JWT token introspection for all services
- **RBAC**: Role-based access control with fine-grained permissions
- **Audit Logging**: Structured audit events for all security actions
- **Field Security**: PHI/PII field-level protection
- **AI Agent Auth**: Authentication for AI agents with scoped permissions
- **Ollama Only**: Uses local Ollama models exclusively (no external AI APIs)

## Quick Start

### Local Development (Docker Compose)

```bash
# From repository root
./init.sh docker

# Or manually:
cd services/security-service
docker-compose up -d
```

Services will be available at:
- Security Service: http://localhost:8300
- Keycloak: http://localhost:8081 (admin/admin123)

### Kubernetes Deployment

```bash
# From repository root
./init.sh k8s

# Or manually:
kubectl apply -f services/security-service/k8s/
```

## Configuration

Environment variables (see `k8s/configmap.yaml`):

| Variable | Description | Default |
|----------|-------------|---------|
| `KEYCLOAK_URL` | Keycloak internal URL | `http://medinovai-keycloak.medinovai-security:8080` |
| `KEYCLOAK_REALM` | Keycloak realm | `medinovai` |
| `DATABASE_URL` | PostgreSQL connection | `postgresql+asyncpg://postgres:postgres123@localhost:5432/security` |
| `REDIS_URL` | Redis connection | `redis://:redis123@localhost:6379/0` |
| `AIFACTORY_URL` | Ollama endpoint (Tailscale) | `http://100.106.54.9:8082/v1` |
| `USE_LOCAL_OLLAMA_ONLY` | Disable external AI APIs | `true` |

## API Endpoints

### Authentication
- `POST /auth/login` - User login (returns tokens)
- `POST /auth/validate` - Validate access token
- `POST /auth/logout` - Logout user

### Token Validation
- `POST /validate` - Validate token and return user info

### RBAC
- `GET /rbac/roles` - List available roles
- `GET /rbac/permissions` - List available permissions
- `POST /rbac/check` - Check user permission

### Audit
- `POST /audit/log` - Log audit event
- `GET /audit/events` - Query audit events

### Health
- `GET /health` - Service health check
- `GET /ready` - Readiness probe
- `GET /` - Service info

## Integration with Infrastructure Services

### 1. Dashboard (medinovaios)

The infrastructure portal at `services/deploy/services/medinovaios` integrates with the security service for SSO:

```typescript
// Service catalog entry
{
  id: 'security-service',
  name: 'Security Service',
  externalUrl: url(8300),
  healthPath: '/health',
  requiresAuth: false,
}
```

### 2. Protected Services

Services can use the auth middleware for protection:

```python
from app.middleware.auth import require_auth, get_current_user

@app.get("/protected")
async def protected_endpoint(user: dict = Depends(get_current_user)):
    return {"message": f"Hello {user['email']}"}
```

### 3. Grafana OAuth

Configure Grafana to use the security service as an OAuth provider:

```ini
[auth.generic_oauth]
enabled = true
name = MedinovAI
allow_sign_up = true
client_id = grafana
client_secret = <secret>
scopes = openid profile email
auth_url = http://medinovai-security-service:8000/auth/login
api_url = http://medinovai-security-service:8000/auth/validate
token_url = http://keycloak:8080/realms/medinovai/protocol/openid-connect/token
```

## Testing

Run Playwright tests:

```bash
# Start services
./init.sh docker

# Run tests
npx playwright test tests/security-service.spec.js
```

## Security Notes

- All tokens are httpOnly cookies (XSS protection)
- Network policies restrict cross-namespace access
- Health checks do not require authentication
- PHI-sensitive endpoints use field-level encryption
- Local Ollama only (no external AI service calls)

## Directory Structure

```
services/security-service/
├── app/
│   ├── main.py              # FastAPI entry point
│   ├── config.py            # Environment configuration
│   ├── routers/             # API endpoints
│   │   ├── auth.py          # Authentication
│   │   ├── token_validator.py
│   │   ├── rbac.py          # RBAC
│   │   ├── audit.py         # Audit logging
│   │   └── ...
│   ├── middleware/          # Auth middleware
│   │   └── auth.py          # For other services
│   └── static/
│       └── login.html       # Login UI
├── k8s/                     # Kubernetes manifests
├── tests/                   # Test suites
├── Dockerfile
├── docker-compose.yml       # Local development
└── requirements.txt
```

## License

Part of the MedinovAI Infrastructure. Proprietary - All rights reserved.
