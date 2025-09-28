# load_balancing

Load balancing and traffic management

## Service Information

- **Service Type:** api
- **Domain:** platform
- **Priority:** critical
- **Compliance Level:** hipaa-standard
- **Data Classification:** internal
- **Language:** Node.js
- **Framework:** Express.js
- **Port:** 3185

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
docker build -t medinovai-load-balancing .

# Run container
docker run -p 3185:3185 medinovai-load-balancing
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
- Swagger UI: http://localhost:3185/docs
- Health Check: http://localhost:3185/health
- Readiness Check: http://localhost:3185/ready

## Monitoring

- **Prometheus Port:** 7185
- **Grafana Port:** 7186
- **Swagger Port:** 8185

## Compliance

This service is designed to meet hipaa-standard compliance requirements and handles internal data classification.

## Support

For support, contact platform@medinovai.com
