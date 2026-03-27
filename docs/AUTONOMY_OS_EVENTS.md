# AutonomyOS Event Wiring — medinovai-infrastructure

**Standard:** `medinovai-ai-standards/ARCHITECTURE.md` | Dim 11
**Platform:** AutonomyOS 12-Engine Platform | ActiveMQ messaging
**Tier:** 2

---

## Event Architecture

This service participates in the AutonomyOS event mesh via ActiveMQ.

### Message Format

All events follow the platform event envelope:

```json
{
  "eventId":      "uuid-v4",
  "eventType":    "Entity.Action",
  "eventVersion": "1.0",
  "source":       "medinovai-infrastructure",
  "tenantId":     "uuid",
  "correlationId": "uuid",
  "timestamp":    "ISO8601",
  "payload":      {}
}
```

### Event Naming Convention

`{Entity}{Action}` — PascalCase, no dots in name

Examples: `TaskStateChanged`, `PatientConsentGranted`, `ClinicalDecisionCreated`

---

## Events Published by This Service

| Event | Trigger | Payload Fields | Subscribers |
|-------|---------|---------------|-------------|
| TODO  | TODO    | TODO          | TODO        |

**Instructions:** Document all domain events this service emits.

---

## Events Consumed by This Service

| Event | Source Service | Handler | Action |
|-------|---------------|---------|--------|
| TODO  | TODO          | TODO    | TODO   |

**Instructions:** Document all events this service subscribes to.

---

## ActiveMQ Integration

```python
# Platform ActiveMQ client
from medinovai_platform.messaging import EventPublisher, EventSubscriber

E_BROKER_URL = os.getenv("E_ACTIVEMQ_URL", "tcp://activemq.medinovai.health:61616")
E_DLQ_PREFIX = "DLQ."

# Publisher
mos_publisher = EventPublisher(broker_url=E_BROKER_URL, service="medinovai-infrastructure")

async def mos_publishEvent(mos_event_type: str, mos_payload: dict, mos_tenant_id: str):
    await mos_publisher.publish(
        event_type=mos_event_type,
        payload=mos_payload,
        tenant_id=mos_tenant_id,
        correlation_id=mos_get_current_trace_id()
    )

# Subscriber with dead-letter queue
mos_subscriber = EventSubscriber(
    broker_url=E_BROKER_URL,
    queue="medinovai-infrastructure.events",
    dlq=f"{E_DLQ_PREFIX}medinovai-infrastructure.events",
    service="medinovai-infrastructure"
)

@mos_subscriber.handler("TaskStateChanged")
async def mos_onTaskStateChanged(mos_event: dict):
    # Idempotent processing — check event_id for duplicates
    if await mos_isDuplicate(mos_event["eventId"]):
        return
    # Process event
    pass
```

## Dead Letter Queue Strategy

Failed messages go to `DLQ.medinovai-infrastructure.events`:
- Retry 3 times with exponential backoff (1s, 4s, 16s)
- After 3 failures → DLQ + PagerDuty alert
- DLQ reviewed daily; manual requeue after investigation

## AutonomyOS Engine Participation

| Engine | Participation | Description |
|--------|--------------|-------------|
| Parser Engine | TODO | Does this service parse incoming clinical/contract data? |
| Compiler Engine | TODO | Does this service compile/aggregate data for decisions? |
| Follow-up Engine | TODO | Does this service trigger follow-up workflows? |
| Billing Engine | TODO | Does this service participate in billing events? |

Update `atlasos.yaml` → `events.publishes` and `events.subscribes` after completing this doc.
