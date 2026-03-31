# Standard Event Schema

All webhook payloads sent to MedinovAI Atlas hooks should conform to this schema for consistent routing, logging, and debugging.

## Schema

```json
{
  "event_type": "namespace.event_name",
  "occurred_at": "ISO-8601 timestamp",
  "source": "system_name",
  "entity": {
    "type": "entity_type",
    "id": "entity_id"
  },
  "data": {}
}
```

## Field Definitions

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `event_type` | string | Yes | Dot-separated event identifier: `{source}.{object}.{action}` |
| `occurred_at` | string | Yes | ISO-8601 timestamp of when the event happened |
| `source` | string | Yes | System that generated the event |
| `entity.type` | string | Yes | Type of the affected entity (ticket, deal, invoice, etc.) |
| `entity.id` | string | Yes | Unique identifier for the entity in the source system |
| `data` | object | Yes | Full event payload from the source system (pass-through) |

## Naming Conventions

### event_type
Use the pattern: `{source}.{object}.{action}`

```
support.ticket.created
support.ticket.updated
support.ticket.resolved
sales.deal.stage_changed
sales.lead.created
finance.invoice.received
finance.payment.succeeded
finance.payment.failed
eng.pr.opened
eng.pr.merged
eng.ci.failed
eng.ci.succeeded
ops.incident.opened
ops.incident.resolved
```

### source
Use lowercase, no spaces:
```
zendesk, intercom, freshdesk     → ticketing
hubspot, salesforce, pipedrive   → CRM
stripe, quickbooks, xero         → finance
github, gitlab, bitbucket        → code
slack, email, webhook            → communication
pagerduty, opsgenie, datadog     → monitoring
```

## Examples

### Support ticket created (from Zendesk)
```json
{
  "event_type": "support.ticket.created",
  "occurred_at": "2026-02-14T14:30:00Z",
  "source": "zendesk",
  "entity": {
    "type": "ticket",
    "id": "T-45678"
  },
  "data": {
    "subject": "Cannot access dashboard after password reset",
    "requester_email": "jane@acme.com",
    "priority": "high",
    "tags": ["login", "password"],
    "description": "After resetting my password, I can no longer log in..."
  }
}
```

### Sales deal stage changed (from HubSpot)
```json
{
  "event_type": "sales.deal.stage_changed",
  "occurred_at": "2026-02-14T10:15:00Z",
  "source": "hubspot",
  "entity": {
    "type": "deal",
    "id": "deal_12345"
  },
  "data": {
    "deal_name": "Acme Corp — Enterprise Plan",
    "old_stage": "qualification",
    "new_stage": "proposal",
    "amount": 50000,
    "owner": "bob@company.com"
  }
}
```

### Payment failed (from Stripe)
```json
{
  "event_type": "finance.payment.failed",
  "occurred_at": "2026-02-14T08:00:00Z",
  "source": "stripe",
  "entity": {
    "type": "invoice",
    "id": "in_1234567890"
  },
  "data": {
    "customer_id": "cus_ABC123",
    "amount": 2500,
    "currency": "usd",
    "failure_code": "card_declined",
    "failure_message": "Your card was declined.",
    "attempt_count": 2,
    "next_retry_at": "2026-02-17T08:00:00Z"
  }
}
```

### CI pipeline failed (from GitHub Actions)
```json
{
  "event_type": "eng.ci.failed",
  "occurred_at": "2026-02-14T11:05:32Z",
  "source": "github",
  "entity": {
    "type": "ci_run",
    "id": "run_987654321"
  },
  "data": {
    "repo": "company/main-app",
    "branch": "feature/user-auth",
    "commit": "abc123def456",
    "author": "alice",
    "failing_step": "test",
    "url": "https://github.com/company/main-app/actions/runs/987654321"
  }
}
```

### PR opened (from GitHub)
```json
{
  "event_type": "eng.pr.opened",
  "occurred_at": "2026-02-14T09:30:00Z",
  "source": "github",
  "entity": {
    "type": "pull_request",
    "id": "456"
  },
  "data": {
    "repo": "company/main-app",
    "title": "Add session timeout handling",
    "author": "alice",
    "base_branch": "main",
    "head_branch": "feature/session-timeout",
    "additions": 245,
    "deletions": 18,
    "files_changed": 8,
    "url": "https://github.com/company/main-app/pull/456"
  }
}
```

## Using the Event Normalizer

For systems that don't natively produce this schema, use the included normalizer script:

```bash
# Normalize a GitHub webhook payload
echo '<raw_github_payload>' | python3 scripts/normalize_event.py --json-in --source github

# Normalize a Stripe event
echo '<raw_stripe_payload>' | python3 scripts/normalize_event.py --json-in --source stripe

# Normalize a HubSpot webhook
echo '<raw_hubspot_payload>' | python3 scripts/normalize_event.py --json-in --source hubspot

# Unknown source (wraps in generic schema)
echo '<any_json>' | python3 scripts/normalize_event.py --json-in --source custom_system
```

Supported normalizers: `github`, `stripe`, `hubspot`, `intercom`. Add new ones in `scripts/normalize_event.py`.

## Hook Routing

Events are routed to agents based on the hook path:

| Hook Path | Agent | Event Types |
|-----------|-------|-------------|
| `/hooks/ticket` | support | `support.*` |
| `/hooks/sales` | sales | `sales.*` |
| `/hooks/incident` | ops | `ops.incident.*` |
| `/hooks/gmail` | ops | `email.*` |
| `/hooks/invoice` | finance | `finance.invoice.*` |
| `/hooks/payment` | finance | `finance.payment.*` |
| `/hooks/pr` | eng | `eng.pr.*` |
| `/hooks/ci` | eng | `eng.ci.*` |

## Logging

Every event received by the gateway is logged. Additionally, agents should store processed events in their workspace:

```
workspace/outputs/events/{YYYY-MM-DD}/{event_type}_{entity_id}.json
```

This creates an auditable event ledger per agent.
