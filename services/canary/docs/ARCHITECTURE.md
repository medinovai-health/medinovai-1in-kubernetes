# Architecture

## Overview

The `medinovai-canary-rollout-orchestrator` is a critical service within the MedinovAI ecosystem responsible for managing the canary rollout of new service versions. Its primary purpose is to ensure safe and reliable deployments by gradually shifting traffic to new releases while monitoring for errors and performance degradation. This service will coordinate with the MedinovAI platform and other services to manage the lifecycle of canary releases, from initiation to promotion or rollback.

## Architecture Diagram

```
+---------------------------------------+
| MedinovAI Platform (UI/API Gateway)   |
+---------------------------------------+
                 |
                 | 1. Initiate Canary Rollout
                 v
+---------------------------------------+
| Canary Rollout Orchestrator           |
|---------------------------------------|
| - Rollout Controller                  |
| - Health Monitor                      |
| - Traffic Shifter                     |
| - State Store (Redis)                 |
+---------------------------------------+
     |          |         |           |
     | 2. Get   | 3. Set  | 4. Monitor| 5. Update
     | Service  | Traffic | Health    | Rollout
     | Metadata | Rules   |           | Status
     v          v         v           v
+----------+ +---------+ +-----------+ +------------------+
| Service  | | K8s API | | Prometheus| | Auth Service     |
| Registry | | Server  | |           | |                  |
+----------+ +---------+ +-----------+ +------------------+

```

## Technology Stack

| Component                 | Technology        |
|---------------------------|-------------------|
| Language                  | Node.js (TypeScript) |
| Framework                 | Express.js        |
| State Store               | Redis             |
| API Gateway               | (Not specified)   |
| Containerization          | Docker            |
| Orchestration             | Kubernetes        |
| Monitoring                | Prometheus        |
| Authentication            | JWT (via Auth Service) |

## Directory Structure

```
/
├── docs/
│   ├── ARCHITECTURE.md
│   └── API_CONTRACTS.md
├── tests/
│   └── README.md
├── .env.example
├── Makefile
├── ... (other project files)
```

## Data Flow

1.  A user or an automated process initiates a canary rollout via the MedinovAI Platform UI or API Gateway.
2.  The Canary Rollout Orchestrator receives the request and fetches metadata for the service to be updated from the Service Registry.
3.  The orchestrator interacts with the Kubernetes API Server to deploy the new (canary) version of the service and configures traffic shifting rules (e.g., using a service mesh like Istio or Linkerd).
4.  The Health Monitor continuously queries Prometheus to check the health of the canary deployment (e.g., error rates, latency).
5.  Based on the health checks, the Rollout Controller decides whether to incrementally increase traffic to the canary, promote it to the primary version, or roll it back.
6.  The orchestrator updates the rollout status in its state store (Redis) and reports back to the MedinovAI Platform.
7.  All interactions with other MedinovAI services are authenticated via the Auth Service.

## Dependencies on other MedinovAI services

- **MedinovAI Platform:** Provides the user interface and API gateway for initiating and monitoring rollouts.
- **MedinovAI Auth Service:** Provides JWT-based authentication and authorization for all API requests.
- **Service Registry:** (Assumed) A central registry for discovering other MedinovAI services.
- **Prometheus:** Provides metrics for monitoring the health of canary deployments.

## API Contracts Summary

See [API_CONTRACTS.md](API_CONTRACTS.md) for detailed API specifications.

## Security (HIPAA)

As this service does not directly handle Protected Health Information (PHI), HIPAA compliance is not a primary concern. However, all communication with other services is secured using TLS, and access to the API is restricted through JWT-based authentication to ensure that only authorized users and services can initiate or manage rollouts.

## Deployment

The service is containerized using Docker and deployed to a Kubernetes cluster. A Makefile provides convenient targets for building and running the Docker image.

## Scaling Strategy

The Canary Rollout Orchestrator is a stateless service (with state offloaded to Redis), which allows for horizontal scaling. Multiple instances of the orchestrator can be run to handle high-availability and load. The number of replicas can be automatically scaled based on CPU and memory usage.
