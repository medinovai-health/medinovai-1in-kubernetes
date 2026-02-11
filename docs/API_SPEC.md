# API Specification: Canary Rollout Orchestrator v1.0

## 1. Introduction

This document provides a comprehensive specification for the Canary Rollout Orchestrator API. This service is responsible for managing the lifecycle of canary deployments, allowing for gradual rollouts of new application versions while minimizing risk.

- **Service Name:** Canary Rollout Orchestrator
- **Version:** 1.0
- **Base URL Pattern:** `https://api.medinovai.com/orchestrator/v1`

## 2. Authentication

All API requests must be authenticated using **OAuth 2.0 with JWT Bearer Tokens**. Clients must include an `Authorization` header with a valid JWT token.

```
Authorization: Bearer <your_jwt_token>
```

## 3. Rate Limiting

To ensure service stability, the following rate limits are enforced:

- **Standard Access:** 100 requests per minute.
- **Internal/Privileged Access:** 1000 requests per minute.

Exceeding the rate limit will result in a `429 Too Many Requests` error.

## 4. Error Handling

Errors are reported using the **RFC 7807 Problem Details for HTTP APIs** format. The response body will contain a JSON object with the following fields:

- `type`: A URI that identifies the problem type.
- `title`: A short, human-readable summary of the problem.
- `status`: The HTTP status code.
- `detail`: A human-readable explanation specific to this occurrence of the problem.

## 5. Pagination

All list-based endpoints support **cursor-based pagination**. The following query parameters are used:

- `limit`: The maximum number of items to return (default: 20, max: 100).
- `after`: The cursor for the next page of results.

## 6. FHIR R4 Compliance

While this service does not directly handle patient data, it is designed to integrate with FHIR R4 compliant systems. All data models and schemas are designed with FHIR compatibility in mind.

## 7. API Endpoints

### 7.1. Deployments

#### `POST /deployments`

Create a new canary deployment.

**Request Body:**

```json
{
  "applicationName": "patient-portal-api",
  "version": "v2.1.0",
  "canaryPercentage": 10,
  "durationMinutes": 60
}
```

**Response (201 Created):**

```json
{
  "deploymentId": "d-1234567890",
  "status": "in_progress",
  "createdAt": "2026-02-11T12:00:00Z"
}
```

#### `GET /deployments`

List all deployments.

**Response (200 OK):**

```json
{
  "data": [
    {
      "deploymentId": "d-1234567890",
      "applicationName": "patient-portal-api",
      "version": "v2.1.0",
      "status": "in_progress",
      "createdAt": "2026-02-11T12:00:00Z"
    }
  ],
  "pagination": {
    "nextCursor": "c-abcdef123456"
  }
}
```

#### `GET /deployments/{deploymentId}`

Get the status of a specific deployment.

**Response (200 OK):**

```json
{
  "deploymentId": "d-1234567890",
  "applicationName": "patient-portal-api",
  "version": "v2.1.0",
  "status": "in_progress",
  "canaryPercentage": 10,
  "durationMinutes": 60,
  "createdAt": "2026-02-11T12:00:00Z"
}
```

#### `POST /deployments/{deploymentId}/promote`

Promote the canary to 100% production traffic.

**Response (202 Accepted):**

```json
{
  "deploymentId": "d-1234567890",
  "status": "promoting"
}
```

#### `POST /deployments/{deploymentId}/rollback`

Rollback the canary deployment.

**Response (202 Accepted):**

```json
{
  "deploymentId": "d-1234567890",
  "status": "rolling_back"
}
```

#### `GET /deployments/{deploymentId}/metrics`

Get performance metrics for a canary deployment.

**Response (200 OK):**

```json
{
  "deploymentId": "d-1234567890",
  "metrics": {
    "requestCount": 10000,
    "errorRate": 0.01,
    "latencyP95": 120
  }
}
```

## 8. Webhooks

This service can send webhooks for the following events:

- `deployment.started`
- `deployment.succeeded`
- `deployment.failed`
- `deployment.promoted`
- `deployment.rolled_back`

**Webhook Payload:**

```json
{
  "eventId": "evt-12345",
  "eventType": "deployment.succeeded",
  "timestamp": "2026-02-11T13:00:00Z",
  "data": {
    "deploymentId": "d-1234567890",
    "applicationName": "patient-portal-api",
    "version": "v2.1.0"
  }
}
```
