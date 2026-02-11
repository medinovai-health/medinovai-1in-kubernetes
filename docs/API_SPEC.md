# API Specification: Real-Time Stream Bus v1.0.0

## 1. Overview

This document outlines the API for the MedinovAI Real-Time Stream Bus, a service designed for high-throughput, low-latency streaming of healthcare data, including clinical events, device metrics, and operational logs.

- **Service Name:** Real-Time Stream Bus
- **Version:** 1.0.0
- **Base URL Pattern:** `/api/v1/stream-bus`

## 2. Authentication

All endpoints are secured using an OAuth 2.0 Client Credentials flow, with access tokens issued as JSON Web Tokens (JWT). The JWT must be included in the `Authorization` header of all requests.

```
Authorization: Bearer <JWT_ACCESS_TOKEN>
```

## 3. Rate Limiting

To ensure service stability, the following rate limits are enforced:

| Client Type | Rate Limit |
| --- | --- |
| Standard (External) | 100 requests/minute |
| Internal (Trusted) | 1000 requests/minute |

## 4. Endpoints

### 4.1. `POST /events`

Ingests a new event into a specified stream.

**Request Body:**

```json
{
  "streamId": "patient-vitals-stream-123",
  "eventType": "vitals-update",
  "payload": {
    "patientId": "PID-456",
    "heartRate": 78,
    "bloodPressure": "120/80"
  }
}
```

**Response (202 Accepted):**

```json
{
  "status": "queued",
  "eventId": "evt-f9b2c3d4e5f6"
}
```

### 4.2. `GET /events/{streamId}`

Subscribes to an event stream using Server-Sent Events (SSE).

**Response (200 OK with `text/event-stream`):**

```
event: vitals-update
data: {"patientId":"PID-456","heartRate":78,"bloodPressure":"120/80"}

event: message
data: Keep-alive
```

### 4.3. `GET /streams`

Lists all available event streams.

**Response (200 OK):**

```json
{
  "data": [
    {
      "streamId": "patient-vitals-stream-123",
      "description": "Real-time vitals for ICU patients"
    }
  ],
  "pagination": {
    "nextCursor": null
  }
}
```

### 4.4. `POST /streams`

Creates a new event stream.

**Request Body:**

```json
{
  "streamId": "new-telemetry-stream",
  "description": "Telemetry data from new devices"
}
```

**Response (201 Created):**

```json
{
  "streamId": "new-telemetry-stream",
  "status": "created"
}
```

### 4.5. `DELETE /streams/{streamId}`

Deletes an event stream.

**Response (204 No Content):**

## 5. Error Handling

Errors are returned in RFC 7807 format.

```json
{
  "type": "/errors/invalid-request",
  "title": "Invalid Request Body",
  "status": 400,
  "detail": "'streamId' is a required field."
}
```

## 6. Pagination

Cursor-based pagination is used for all list endpoints. The `nextCursor` value from a response should be used in the `cursor` query parameter of the next request.

## 7. FHIR R4 Compliance

Where applicable, event payloads are encouraged to align with FHIR R4 resources. For example, patient vitals should be structured as a FHIR `Observation` resource.

## 8. Webhooks

Webhook notifications can be configured for stream events. The payload will match the event schema defined in section 4.1.
