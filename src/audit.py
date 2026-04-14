# audit.py — medinovai-1in-kubernetes
# Build: 20260413.3000.001 | © 2026 DescartesBio / MedinovAI Health.
import json
import logging
import datetime
from typing import Any, Dict
from src.eventbus import event_bus

logger = logging.getLogger(__name__)

async def log_audit_event(action: str, actor_id: str, resource_id: str, resource_type: str, details: Dict[str, Any], is_phi: bool = False):
    """
    HIPAA-compliant structured audit logging pipeline.
    Sends audit events to the centralized Kafka audit topic.
    """
    audit_payload = {
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z",
        "action": action,
        "actor_id": actor_id,
        "resource_id": resource_id,
        "resource_type": resource_type,
        "service": "medinovai-1in-kubernetes",
        "details": details,
        "is_phi": is_phi
    }
    
    # 1. Local structured log (fallback/debug)
    logger.info(f"AUDIT_EVENT: {json.dumps(audit_payload)}")
    
    # 2. Centralized audit topic via Event Bus
    try:
        await event_bus.publish(
            topic="audit.logs.central",
            event_type="audit_event",
            payload=audit_payload,
            is_phi=is_phi
        )
    except Exception as e:
        logger.error(f"CRITICAL: Failed to publish audit event to central bus: {e}")
        # In a strict compliance environment, we might want to halt or queue locally
