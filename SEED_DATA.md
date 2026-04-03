# MedinovAI Infrastructure - Seed Data

## SuperAdmin Credentials

After seeding, the following SuperAdmin account is created:

| Field | Value |
|-------|-------|
| **Username** | `superadmin` |
| **Email** | `admin@medinovai.com` |
| **Password** | `MedinovAI-Dev-2025!` |
| **Role** | admin (realm-admin) |

## Seeding Commands

### Local Development (Docker Compose)

```bash
# After starting services, seed the data
curl -X POST http://localhost:8300/seed/initialize \
  -H "Content-Type: application/json" \
  -d '{
    "tenant_id": "default",
    "admin_email": "admin@medinovai.com",
    "admin_username": "superadmin",
    "admin_password": "MedinovAI-Dev-2025!"
  }'
```

### Kubernetes

```bash
# Deploy the seed job
kubectl apply -f services/security-service/k8s/seed-job.yaml

# Or use the init.sh script which includes seeding
./init.sh k8s
kubectl apply -f services/security-service/k8s/seed-job.yaml

# Check seed status
kubectl logs -n medinovai-services job/medinovai-security-service-seed
```

## Seed API Endpoints

- `POST /seed/initialize` - Create SuperAdmin and initial roles/permissions
- `GET /seed/superadmin` - Get SuperAdmin credentials info
- `GET /seed/status` - Check seeding status
- `POST /seed/reset` - Reset all data (destructive, requires `confirm=true`)

## Default Roles Created

1. **SuperAdmin** - Full system access
2. **InfrastructureAdmin** - Infrastructure management
3. **Developer** - Development access
4. **Viewer** - Read-only access

## Default Permissions

- `infra:read`, `infra:write`, `infra:admin`
- `security:read`, `security:write`, `security:admin`
- `monitoring:read`, `monitoring:write`
- `users:read`, `users:write`, `users:admin`

## Testing Credentials

Use these credentials to test the infrastructure portal:

```bash
# Access the security service login
curl http://localhost:8300/login

# Or login via API
curl -X POST http://localhost:8300/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "superadmin",
    "password": "MedinovAI-Dev-2025!",
    "client_id": "admin-cli"
  }'
```

## Infrastructure Portal URLs

After deployment, access the services at:

| Service | URL | Credentials |
|---------|-----|-------------|
| Security Service | http://localhost:8300 | Via Keycloak SSO |
| Infrastructure Portal | http://localhost:3000 | Via Security Service |
| Keycloak | http://localhost:8081 | admin/admin123 |
| Grafana | http://localhost:4250 | OAuth via Security Service |
| Kibana | http://localhost:4251 | OAuth via Security Service |
| Registry | http://localhost:4200 | Token auth |
