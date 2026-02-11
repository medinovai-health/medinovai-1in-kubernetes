# Integration Map: Real-Time Stream Bus

This document maps the dependencies and integration points for the MedinovAI Real-Time Stream Bus.

## 1. Upstream Dependencies

The service relies on the following upstream systems:

| Dependency | Purpose | Failure Impact |
| --- | --- | --- |
| **Auth Service** | JWT validation & decoding | High (all requests fail) |
| **Config Service** | Loading stream configurations | Medium (new streams unavailable) |
| **Message Broker** | Core event persistence/transport | High (all events lost) |

## 2. Downstream Consumers

The following services are known consumers of the data streams:

| Consumer | Consumed Streams | Integration Pattern |
| --- | --- | --- |
| **Patient Monitoring UI** | `patient-vitals`, `device-alerts` | Server-Sent Events (SSE) |
| **Clinical Decision Support** | `patient-vitals`, `lab-results` | Webhook Subscription |
| **Data Lake Ingestion** | `*` (all streams) | Direct Message Broker Topic |

## 3. Event Bus Integration

The service interacts with the central event bus (Kafka) via the following topics:

- **Published Topics:** `patient-vitals`, `device-telemetry`, `audit-logs`
- **Consumed Topics:** `system-commands` (for administrative actions)

## 4. Shared Data Models

To ensure interoperability, the service adheres to the following data models:

- **FHIR R4 Resources:** For all clinical data (e.g., `Observation`, `Patient`).
- **Internal Event Schema:** A standardized wrapper for all event payloads.

## 5. Resilience & Fault Tolerance

### Circuit Breaker

- **Configuration:** `Failure threshold: 5 consecutive failures`, `Reset timeout: 30 seconds`
- **Applies to:** All upstream service calls.

### Retry Policies

- **Configuration:** `Exponential backoff (100ms, 200ms, 400ms)`, `Max retries: 3`
- **Applies to:** Message broker connection attempts.

## 6. Health Checks

The `/health` endpoint reports the status of the following dependencies:

- Connectivity to the primary Message Broker cluster.
- Status of the connection to the Auth Service.
