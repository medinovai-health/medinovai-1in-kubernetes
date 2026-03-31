# medinovai-real-time-stream-bus

Kafka-based event backbone for the MedinovAI platform. Provides a REST proxy for services that cannot use Kafka natively, plus Python and Node SDKs.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![API Version](https://img.shields.io/badge/api-v1-green)
![Status](https://img.shields.io/badge/status-stable-brightgreen)

---

## Overview

The stream bus is the platform event backbone. It provides:

- **Kafka broker** — KRaft mode (no Zookeeper)
- **Schema Registry** — Event validation
- **REST proxy** — HTTP API for publish/subscribe (port 3140)
- **SDKs** — Python and Node.js clients

---

## Quick Start

```bash
# Start Kafka + Schema Registry + REST proxy
docker compose up -d

# Publish an event
curl -X POST http://localhost:3140/publish/stream-bus.test \
  -H "Content-Type: application/json" \
  -d '{"event":{"event_type":"test","timestamp":"2025-01-01T00:00:00Z","source":"cli","tenant_id":"default"}}'

# List topics
curl http://localhost:3140/topics

# Long-poll subscribe
curl "http://localhost:3140/subscribe/stream-bus.test/my-group?timeout_ms=5000"
```

---

## Topic Naming

Topics follow the pattern `stream-bus.<event_type>` when using the `/events` endpoint without an explicit topic. For `POST /publish/{topic}`, use any valid Kafka topic name.

| Event Type              | Topic                     | Description                    |
|-------------------------|---------------------------|--------------------------------|
| `iam_user_created`      | `stream-bus.iam_user_created` | IAM user created               |
| `iam_role_assigned`     | `stream-bus.iam_role_assigned` | Role assigned to user          |
| `git_push`              | `stream-bus.git_push`     | Git push event                 |
| `git_pr_merged`         | `stream-bus.git_pr_merged`| Pull request merged            |
| `deploy_tier_completed` | `stream-bus.deploy_tier_completed` | Deployment tier finished |
| `infra_node_alert`      | `stream-bus.infra_node_alert` | Infrastructure node alert  |
| `argocd_sync_failed`    | `stream-bus.argocd_sync_failed` | ArgoCD sync failure       |
| `agent_provisioned`     | `stream-bus.agent_provisioned` | Agent provisioned         |
| `cluster_action_requested` | `stream-bus.cluster_action_requested` | Cluster action requested |

---

## Event Schema

All events must include:

| Field         | Type   | Required | Description                     |
|---------------|--------|----------|---------------------------------|
| `event_type`  | string | Yes      | Event identifier                |
| `timestamp`   | string | Yes      | ISO8601 timestamp               |
| `source`      | string | Yes      | Emitting service                |
| `tenant_id`   | string | Yes      | Tenant identifier               |
| `correlation_id` | string | No   | Request correlation ID          |
| `payload`     | object | No       | Event-specific data             |

---

## REST API

| Method | Path                         | Description                      |
|--------|------------------------------|----------------------------------|
| GET    | `/health`                    | Health check                     |
| GET    | `/ready`                     | Readiness check                  |
| GET    | `/topics`                    | List Kafka topics                |
| POST   | `/publish/{topic}`           | Publish event to topic           |
| POST   | `/events`                    | Batch publish (webhook-friendly) |
| GET    | `/subscribe/{topic}/{group}` | Long-poll consumer               |

### Publish

```bash
POST /publish/stream-bus.iam_user_created
Content-Type: application/json

{
  "event": {
    "event_type": "iam_user_created",
    "timestamp": "2025-02-19T12:00:00Z",
    "source": "iam-service",
    "tenant_id": "tenant-001",
    "correlation_id": "req-123",
    "payload": {
      "user_id": "u-1",
      "email": "user@example.com",
      "display_name": "Alice"
    }
  }
}
```

### Subscribe (Long-Poll)

```bash
GET /subscribe/stream-bus.iam_user_created/my-consumer-group?timeout_ms=5000
```

Returns:

```json
{
  "topic": "stream-bus.iam_user_created",
  "group": "my-consumer-group",
  "messages": [
    {
      "key": "tenant-001",
      "partition": 0,
      "offset": 42,
      "payload": { ... }
    }
  ]
}
```

---

## Dead-Letter Handling

Malformed events (invalid JSON, missing required fields, schema violations) are sent to the `stream-bus.dead-letter` topic with:

- `original_topic`
- `error` message
- `raw_payload`
- `timestamp`

---

## Python SDK

```python
from stream_bus import StreamBusClient, publish, subscribe

# Standalone functions
publish("stream-bus.git_push", {
    "event_type": "git_push",
    "timestamp": "2025-02-19T12:00:00Z",
    "source": "webhook-receiver",
    "tenant_id": "tenant-001",
    "payload": {"repo": "my-repo", "branch": "main"}
}, tenant_id="tenant-001")

# Client with defaults
client = StreamBusClient(tenant_id="tenant-001")
client.publish("stream-bus.deploy_tier_completed", {
    "event_type": "deploy_tier_completed",
    "payload": {"tier": 1, "status": "success"}
})

# Subscribe (blocks)
def handle(msg):
    print(msg)

import threading
stop = threading.Event()
subscribe("stream-bus.git_push", "my-group", handle, stop_event=stop)
# Signal stop.set() in another thread to exit
```

### Installation

```bash
cd sdks/python && pip install -e .
# or add to requirements: medinovai-stream-bus (when published)
```

---

## Node SDK

```javascript
const { StreamBusClient, publish, subscribe } = require('@medinovai/stream-bus');

// Standalone
await publish('stream-bus.git_push', {
  event_type: 'git_push',
  timestamp: new Date().toISOString(),
  source: 'webhook',
  tenant_id: 'default',
  payload: { repo: 'my-repo', branch: 'main' }
});

// Client
const client = new StreamBusClient({ tenantId: 'tenant-001' });
await client.publish('stream-bus.agent_provisioned', {
  event_type: 'agent_provisioned',
  payload: { agent_id: 'a-1', agent_type: 'platform' }
});

// Subscribe
const ac = new AbortController();
subscribe('stream-bus.git_push', 'my-group', (msg) => console.log(msg), {
  stopSignal: ac.signal
});
// ac.abort() to stop
```

### Installation

```bash
cd sdks/node && npm install
```

---

## Event Catalog

| Schema File                  | Event Type                  | Payload Keys                                      |
|-----------------------------|-----------------------------|---------------------------------------------------|
| `iam_user_created.json`     | `iam_user_created`          | user_id, email, display_name, created_by          |
| `iam_role_assigned.json`    | `iam_role_assigned`         | user_id, role_id, role_name, assigned_by, scope   |
| `git_push.json`             | `git_push`                  | repo, branch, commit_sha, pusher, ref             |
| `git_pr_merged.json`        | `git_pr_merged`             | repo, pr_number, base_branch, merged_by           |
| `deploy_tier_completed.json`| `deploy_tier_completed`     | tier, status, duration_seconds, services_deployed|
| `infra_node_alert.json`     | `infra_node_alert`          | node_name, alert_type, severity, message          |
| `argocd_sync_failed.json`   | `argocd_sync_failed`        | application, namespace, error_message             |
| `agent_provisioned.json`    | `agent_provisioned`         | agent_id, agent_type, repo, environment           |
| `cluster_action_requested.json` | `cluster_action_requested` | action, cluster_name, requested_by, parameters    |

---

## Kubernetes Deployment

The REST proxy runs in the `medinovai` namespace. Kafka is expected at `kafka.infra.svc.cluster.local:9092`.

```bash
kubectl apply -f k8s/deployment.yaml
```

---

## Environment Variables

| Variable                   | Default              | Description           |
|----------------------------|----------------------|-----------------------|
| `KAFKA_BOOTSTRAP_SERVERS`  | `localhost:9092`     | Kafka bootstrap       |
| `PORT`                     | `3140`               | REST proxy port       |
| `SERVICE_NAME`             | `medinovai-real-time-stream-bus` | Service name |
| `STREAM_BUS_URL`           | `http://localhost:3140` | SDK default base URL |

---

## Versioning

- **Service:** 1.0.0
- **API:** v1
- **Schema:** 1.0.0
