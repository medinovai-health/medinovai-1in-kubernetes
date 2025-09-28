# service_mesh

Service mesh management and security

## Service Information

- **Service Type:** api
- **Domain:** platform
- **Priority:** high
- **Compliance Level:** hipaa-standard
- **Data Classification:** internal
- **Language:** Node.js
- **Framework:** Express.js
- **Port:** 3145

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
docker build -t medinovai-service-mesh .

# Run container
docker run -p 3145:3145 medinovai-service-mesh
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
- Swagger UI: http://localhost:3145/docs
- Health Check: http://localhost:3145/health
- Readiness Check: http://localhost:3145/ready

## Monitoring

- **Prometheus Port:** 7145
- **Grafana Port:** 7146
- **Swagger Port:** 8145

## Compliance

This service is designed to meet hipaa-standard compliance requirements and handles internal data classification.

## Support

For support, contact platform@medinovai.com
