# Architecture

## Overview

The `medinovai-real-time-stream-bus` is a central component of the MedinovAI ecosystem, responsible for managing and routing real-time data streams between various microservices. It acts as a high-performance, scalable, and reliable message broker, ensuring that data is delivered efficiently and securely.

## Architecture Diagram

```
+---------------------------+
| MedinovAI Platform        |
+---------------------------+
        | (HTTPS/WSS)
        v
+---------------------------+
|   medinovai-real-time-    |
|       stream-bus          |
+---------------------------+
        | (Internal RPC/Events)
        v
+---------------------------+      +---------------------------+
| Other MedinovAI Services  |----->|   medinovai-auth-service  |
+---------------------------+      +---------------------------+

```

## Technology Stack

- **Language:** Node.js
- **Framework:** Express.js (or similar)
- **Messaging:** WebSockets, Redis Pub/Sub
- **Containerization:** Docker
- **Deployment:** Docker Compose, Kubernetes (planned)

## Directory Structure

```
/docs
  ARCHITECTURE.md
  API_CONTRACTS.md
/tests
  README.md
/app
  /controllers
  /services
  /utils
  index.js
.env.example
Dockerfile
Makefile
package.json
```

## Data Flow

1. **Ingestion:** Data is ingested from various MedinovAI services and the main platform via secure WebSocket connections or REST API endpoints.
2. **Processing:** The service can perform lightweight processing, such as validation and enrichment, before routing the data.
3. **Routing:** Based on predefined rules and topics, the data is published to the appropriate Redis channels.
4. **Egress:** Downstream services subscribe to the Redis channels to receive the data streams they need.

## Dependencies on other MedinovAI services

- **medinovai-auth-service:** For authenticating and authorizing incoming connections and API requests.
- **MedinovAI Platform:** The main platform that interacts with this service to send and receive real-time data.

## API Contracts Summary

A detailed description of the API contracts can be found in [API_CONTRACTS.md](API_CONTRACTS.md).

## Security (HIPAA)

- **Encryption:** All data is encrypted in transit using TLS/WSS and at rest.
- **Access Control:** All incoming connections and API requests are authenticated and authorized by the `medinovai-auth-service`.
- **Auditing:** All significant events are logged for auditing purposes.

## Deployment

The service is deployed as a Docker container. The deployment process is managed through a `Makefile` and can be orchestrated using Docker Compose for local development and Kubernetes for production environments.

## Scaling Strategy

The service is designed to be horizontally scalable. Multiple instances of the service can be run behind a load balancer to handle high volumes of traffic. Redis Pub/Sub provides a scalable and resilient messaging backbone.
