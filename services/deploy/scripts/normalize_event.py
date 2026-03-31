#!/usr/bin/env python3
"""
normalize_event.py — Normalize incoming webhook payloads to the standard event schema.

Usage:
    echo '<raw_payload>' | python3 normalize_event.py --json-in --source hubspot
    echo '<raw_payload>' | python3 normalize_event.py --json-in --source github
    echo '<raw_payload>' | python3 normalize_event.py --json-in --source stripe

Standard event schema:
{
    "event_type": "namespace.event_name",
    "occurred_at": "ISO-8601",
    "source": "system_name",
    "entity": { "type": "entity_type", "id": "entity_id" },
    "data": { <original payload> }
}

Add new normalizers as you integrate new systems.
"""

import json
import sys
from datetime import datetime, timezone


def parse_args():
    """Parse command line arguments."""
    source = "unknown"
    for i, arg in enumerate(sys.argv):
        if arg == "--source" and i + 1 < len(sys.argv):
            source = sys.argv[i + 1]
    return source


def parse_input():
    """Read JSON input from stdin when --json-in is passed."""
    if "--json-in" not in sys.argv:
        print(json.dumps({
            "status": "error",
            "error": "Missing --json-in flag. Pipe JSON to stdin.",
        }))
        sys.exit(1)

    try:
        return json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(json.dumps({
            "status": "error",
            "error": f"Invalid JSON input: {e}",
        }))
        sys.exit(1)


def normalize_github(payload):
    """Normalize GitHub webhook payloads."""
    action = payload.get("action", "unknown")
    event_type = "github"

    if "pull_request" in payload:
        pr = payload["pull_request"]
        return {
            "event_type": f"github.pull_request.{action}",
            "occurred_at": pr.get("updated_at", datetime.now(timezone.utc).isoformat()),
            "source": "github",
            "entity": {
                "type": "pull_request",
                "id": str(pr.get("number", "")),
                "repo": payload.get("repository", {}).get("full_name", ""),
            },
            "data": payload,
        }

    if "issue" in payload:
        issue = payload["issue"]
        return {
            "event_type": f"github.issue.{action}",
            "occurred_at": issue.get("updated_at", datetime.now(timezone.utc).isoformat()),
            "source": "github",
            "entity": {
                "type": "issue",
                "id": str(issue.get("number", "")),
                "repo": payload.get("repository", {}).get("full_name", ""),
            },
            "data": payload,
        }

    if "check_run" in payload or "check_suite" in payload:
        return {
            "event_type": f"github.ci.{action}",
            "occurred_at": datetime.now(timezone.utc).isoformat(),
            "source": "github",
            "entity": {
                "type": "ci_run",
                "id": str(payload.get("check_run", payload.get("check_suite", {})).get("id", "")),
            },
            "data": payload,
        }

    return make_generic("github", payload)


def normalize_stripe(payload):
    """Normalize Stripe webhook payloads."""
    event_type = payload.get("type", "unknown")
    obj = payload.get("data", {}).get("object", {})

    entity_type = event_type.split(".")[0] if "." in event_type else "unknown"

    return {
        "event_type": f"stripe.{event_type}",
        "occurred_at": datetime.fromtimestamp(
            payload.get("created", 0), tz=timezone.utc
        ).isoformat() if payload.get("created") else datetime.now(timezone.utc).isoformat(),
        "source": "stripe",
        "entity": {
            "type": entity_type,
            "id": obj.get("id", ""),
        },
        "data": payload,
    }


def normalize_hubspot(payload):
    """Normalize HubSpot webhook payloads."""
    # HubSpot sends arrays of events
    events = payload if isinstance(payload, list) else [payload]
    if not events:
        return make_generic("hubspot", payload)

    event = events[0]
    return {
        "event_type": f"hubspot.{event.get('subscriptionType', 'unknown')}",
        "occurred_at": datetime.fromtimestamp(
            event.get("occurredAt", 0) / 1000, tz=timezone.utc
        ).isoformat() if event.get("occurredAt") else datetime.now(timezone.utc).isoformat(),
        "source": "hubspot",
        "entity": {
            "type": event.get("subscriptionType", "").split(".")[0] if event.get("subscriptionType") else "unknown",
            "id": str(event.get("objectId", "")),
        },
        "data": payload,
    }


def normalize_intercom(payload):
    """Normalize Intercom webhook payloads."""
    topic = payload.get("topic", "unknown")
    item = payload.get("data", {}).get("item", {})

    return {
        "event_type": f"intercom.{topic}",
        "occurred_at": payload.get("created_at", datetime.now(timezone.utc).isoformat()),
        "source": "intercom",
        "entity": {
            "type": item.get("type", "unknown"),
            "id": item.get("id", ""),
        },
        "data": payload,
    }


def make_generic(source, payload):
    """Fallback: wrap any unknown payload in the standard schema."""
    return {
        "event_type": f"{source}.unknown",
        "occurred_at": datetime.now(timezone.utc).isoformat(),
        "source": source,
        "entity": {"type": "unknown", "id": ""},
        "data": payload,
    }


NORMALIZERS = {
    "github": normalize_github,
    "stripe": normalize_stripe,
    "hubspot": normalize_hubspot,
    "intercom": normalize_intercom,
}


def main():
    source = parse_args()
    payload = parse_input()

    normalizer = NORMALIZERS.get(source, lambda p: make_generic(source, p))
    normalized = normalizer(payload)

    output = {
        "status": "ok",
        "normalized_event": normalized,
    }

    print(json.dumps(output, indent=2))


if __name__ == "__main__":
    main()
