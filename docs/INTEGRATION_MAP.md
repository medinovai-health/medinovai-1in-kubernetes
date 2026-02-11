# Integration and Dependency Map

## 1. Upstream Dependencies

- **Kubernetes API Server:** For managing and orchestrating containerized applications.
- **Prometheus:** For collecting performance and health metrics.
- **Docker Registry:** For storing and retrieving container images.

## 2. Downstream Consumers

- **CI/CD Pipeline (e.g., Jenkins, GitLab CI):** To trigger and manage deployments.
- **Developer Dashboard:** To provide visibility into the status of deployments.

## 3. Event Bus Topics

- **`canary.deployment.events`:** A centralized topic for all deployment-related events.

## 4. Shared Data Models

- **Deployment Configuration:** A standardized schema for defining canary deployment parameters.

## 5. Circuit Breaker and Retry Policies

- **Circuit Breaker:** Implemented for all external API calls to prevent cascading failures.
- **Retry Policy:** A 3-retry policy with exponential backoff is used for transient errors.

## 6. Health Checks

- **Liveness Probe:** `/healthz`
- **Readiness Probe:** `/readyz`
