# API Contracts (v1)

This document outlines the API contracts for the `medinovai-canary-rollout-orchestrator` service. All endpoints are prefixed with `/api/v1`.

## Authentication

All API requests must be authenticated using a valid JWT token provided in the `Authorization` header as a Bearer token.

`Authorization: Bearer <JWT_TOKEN>`

## Versioning

The API is versioned using a URL prefix (`/api/v1`). The current version is `v1`.

## Rate Limiting

To ensure service stability, rate limiting is applied. The default rate limit is 100 requests per minute per client IP address.

## Error Codes

| Status Code | Error Code          | Description                                      |
|-------------|---------------------|--------------------------------------------------|
| 400         | `BAD_REQUEST`       | The request was malformed or invalid.            |
| 401         | `UNAUTHORIZED`      | The request is missing a valid authentication token. |
| 403         | `FORBIDDEN`         | The client is not authorized to perform the action. |
| 404         | `NOT_FOUND`         | The requested resource was not found.            |
| 429         | `TOO_MANY_REQUESTS` | The client has exceeded the rate limit.          |
| 500         | `INTERNAL_SERVER_ERROR` | An unexpected error occurred on the server.      |

## Endpoints

### 1. Initiate Canary Rollout

- **Endpoint:** `POST /api/v1/rollouts`
- **Description:** Initiates a new canary rollout for a specified service.

**Request Body:**

```json
{
  "serviceName": "my-service",
  "serviceVersion": "1.2.0",
  "canaryPercentage": 10,
  "steps": 5,
  "stepInterval": 60
}
```

**Response Body (201 Created):**

```json
{
  "rolloutId": "c1a2b3d4-e5f6-7890-1234-567890abcdef",
  "status": "in_progress",
  "createdAt": "2026-02-10T12:00:00Z"
}
```

### 2. Get Rollout Status

- **Endpoint:** `GET /api/v1/rollouts/{id}`
- **Description:** Retrieves the status and details of a specific canary rollout.

**Response Body (200 OK):**

```json
{
  "rolloutId": "c1a2b3d4-e5f6-7890-1234-567890abcdef",
  "serviceName": "my-service",
  "serviceVersion": "1.2.0",
  "status": "in_progress",
  "canaryPercentage": 50,
  "currentStep": 3,
  "totalSteps": 5,
  "createdAt": "2026-02-10T12:00:00Z",
  "updatedAt": "2026-02-10T12:15:00Z"
}
```

### 3. Promote Canary Rollout

- **Endpoint:** `POST /api/v1/rollouts/{id}/promote`
- **Description:** Manually promotes the canary version to the primary version, shifting 100% of traffic to it.

**Response Body (200 OK):**

```json
{
  "rolloutId": "c1a2b3d4-e5f6-7890-1234-567890abcdef",
  "status": "promoted",
  "message": "Rollout promoted successfully."
}
```

### 4. Rollback Canary Rollout

- **Endpoint:** `POST /api/v1/rollouts/{id}/rollback`
- **Description:** Rolls back the canary deployment, shifting all traffic back to the previous stable version.

**Response Body (200 OK):**

```json
{
  "rolloutId": "c1a2b3d4-e5f6-7890-1234-567890abcdef",
  "status": "rolled_back",
  "message": "Rollout rolled back successfully."
}
```
