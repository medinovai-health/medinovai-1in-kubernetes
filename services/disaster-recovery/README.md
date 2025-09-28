# disaster_recovery

Disaster recovery orchestration and management

## Service Information

- **Service Type:** api
- **Domain:** platform
- **Priority:** critical
- **Compliance Level:** hipaa-critical
- **Data Classification:** internal
- **Language:** Node.js
- **Framework:** Express.js
- **Port:** 3144

## Team Information

- **Maintainer:** Platform Team
- **Team:** platform
- **Email:** platform@medinovai.com

## Quick Start

### Prerequisites

- Node.js 18+
- Docker (optional)
- Kubernetes (optional)

### Local Development

```bash
# Install dependencies
npm install

# Start development server
npm run dev

# Run tests
npm test

# Run linting
npm run lint
```

### Docker

```bash
# Build image
docker build -t medinovai-disaster-recovery .

# Run container
docker run -p 3144:3144 medinovai-disaster-recovery
```

### Kubernetes

```bash
# Deploy to development
kubectl apply -f k8s/development/

# Deploy to staging
kubectl apply -f k8s/staging/

# Deploy to production
kubectl apply -f k8s/production/
```

## API Documentation

Once the service is running, visit:
- Swagger UI: http://localhost:3144/docs
- Health Check: http://localhost:3144/health
- Readiness Check: http://localhost:3144/ready

## Monitoring

- **Prometheus Port:** 7144
- **Grafana Port:** 7145
- **Swagger Port:** 8144

## Compliance

This service is designed to meet hipaa-critical compliance requirements and handles internal data classification.

## Support

For support, contact platform@medinovai.com
