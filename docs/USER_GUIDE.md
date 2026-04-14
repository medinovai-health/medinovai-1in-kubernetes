# User Guide — medinovai-1in-kubernetes

> (c) 2025 MedinovAI — Empowering human will for cure.
> Sprint 11: Documentation & API Docs

## Getting Started

### Prerequisites

- Python runtime installed
- Docker and Docker Compose
- Access to MedinovAI container registry

### Quick Start

```bash
# Clone the repository
git clone https://github.com/medinovai-health/medinovai-1in-kubernetes.git
cd medinovai-1in-kubernetes

# Start with Docker Compose
docker-compose up -d

# Verify health
curl http://localhost:8080/health
```

### Configuration

Environment variables are managed via `.env` files and HashiCorp Vault.

| Variable | Description | Required |
|----------|-------------|----------|
| `DATABASE_URL` | Database connection string | Yes |
| `REDIS_URL` | Cache connection string | No |
| `VAULT_ADDR` | Vault server address | Yes |
| `LOG_LEVEL` | Logging verbosity | No |
| `OTEL_ENDPOINT` | OpenTelemetry collector | No |

### Development Workflow

1. Create feature branch from `develop`
2. Implement changes with tests
3. Run CI pipeline locally: `make ci`
4. Submit PR for review
5. Auto-merge on approval + CI pass

## Troubleshooting

### Common Issues

| Issue | Solution |
|-------|----------|
| Connection refused | Check Docker containers are running |
| Auth failure | Verify Vault token is valid |
| Slow queries | Check database indexes |
| Memory issues | Increase container limits |

### Support

- Slack: #medinovai-ai-ml engine
- Docs: https://docs.medinovai.com/medinovai-1in-kubernetes
- Issues: https://github.com/medinovai-health/medinovai-1in-kubernetes/issues
