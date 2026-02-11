# API Specification: MedinovAI Infrastructure Service

## 1. Overview

- **Service Name**: medinovai-infrastructure
- **Version**: 1.0.0
- **Base URL**: `https://api.medinovai.com/v1/infrastructure`

This service is responsible for the programmatic provisioning, management, and monitoring of the underlying infrastructure resources for the MedinovAI platform.

## 2. Authentication

All API requests must be authenticated using **OAuth 2.0 with JWT Bearer Tokens**. Clients must obtain a token from the `medinovai-identity-service` and include it in the `Authorization` header.

```
Authorization: Bearer <JWT_TOKEN>
```

## 3. Rate Limiting

- **Standard Access**: 100 requests per minute per client.
- **Internal/Privileged Access**: 1000 requests per minute per service.

Exceeding the rate limit will result in a `429 Too Many Requests` error.

## 4. Error Handling

Errors are reported using the **RFC 7807 Problem Details for HTTP APIs** format.

```json
{
  "type": "https://errors.medinovai.com/infrastructure/provisioning-failed",
  "title": "Infrastructure Provisioning Failed",
  "status": 500,
  "detail": "Failed to provision the requested Kubernetes cluster in AWS us-east-1.",
  "instance": "/v1/infrastructure/provision/trace-id-xyz"
}
```

## 5. Pagination

All list-based endpoints use **cursor-based pagination**. The `next_cursor` from a response should be used in the `cursor` query parameter of the subsequent request.

## 6. FHIR R4 Compliance

While this is an infrastructure API and does not directly handle PHI, all provisioned environments (e.g., databases, compute instances) are configured by default to meet the security and auditing requirements necessary for hosting FHIR R4 compliant applications and data stores.

## 7. Endpoints

### `POST /v1/infrastructure/provision`

Provisions a new infrastructure resource.

- **Request Body**: `ProvisionRequest` object specifying resource type (e.g., `k8s-cluster`, `postgres-db`), region, size, and other configuration details.
- **Response**: `202 Accepted` with a `ProvisioningJob` object.

### `GET /v1/infrastructure/resources/{resource_id}`

Retrieves the status and details of a specific resource.

- **Response**: `Resource` object.

### `DELETE /v1/infrastructure/resources/{resource_id}`

Decommissions an active infrastructure resource.

- **Response**: `202 Accepted` with a `DecommissioningJob` object.

### `GET /v1/infrastructure/resources`

Lists all provisioned resources for the authenticated principal.

- **Response**: A paginated list of `Resource` objects.

### `POST /v1/infrastructure/resources/{resource_id}/actions/rotate-credentials`

Initiates a credential rotation process for a resource.

- **Response**: `202 Accepted`.

## 8. Webhooks

Clients can subscribe to asynchronous notifications for long-running operations.

- `provisioning.complete`: Sent when a resource is successfully provisioned.
- `provisioning.failed`: Sent when a provisioning job fails.
- `resource.health.degraded`: Sent when a resource's health check status changes to degraded.
