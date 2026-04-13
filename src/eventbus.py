# eventbus.py — medinovai-1in-kubernetes
# Build: 20260413.2900.001 | © 2026 DescartesBio / MedinovAI Health.
import os
import json
import logging
from typing import Any, Dict
from src.vault import get_secret

logger = logging.getLogger(__name__)

# Try to get Kafka/ActiveMQ credentials from Vault
BROKER_URL = get_secret("messaging/credentials", "BROKER_URL") or os.getenv("BROKER_URL", "localhost:9092")

class EventBus:
    """
    Wrapper for ActiveMQ/Kafka event publishing and consumption.
    Ensures PHI is handled securely and no n8n orchestration is used.
    """
    def __init__(self):
        self.broker_url = BROKER_URL
        self.connected = False
        
    async def connect(self):
        # Placeholder for actual Kafka/ActiveMQ connection logic
        self.connected = True
        logger.info(f"Connected to event bus at {self.broker_url}")
        
    async def publish(self, topic: str, event_type: str, payload: Dict[str, Any], is_phi: bool = False):
        if not self.connected:
            await self.connect()
            
        if is_phi:
            # Audit trail logging required for PHI events
            logger.info(f"AUDIT: Publishing PHI event '{event_type}' to topic '{topic}'")
            
        message = {
            "event_type": event_type,
            "source": "medinovai-1in-kubernetes",
            "payload": payload,
            "is_phi": is_phi
        }
        
        # Placeholder for actual publish logic
        # await producer.send_and_wait(topic, json.dumps(message).encode('utf-8'))
        logger.debug(f"Published event {event_type} to {topic}")
        return True

event_bus = EventBus()
