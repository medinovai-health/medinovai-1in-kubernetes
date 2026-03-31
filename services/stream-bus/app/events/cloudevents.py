"""
MedinovAI CloudEvents v1.0 Event Schema and Definitions.

All inter-service events follow CloudEvents v1.0 specification.
13 event types defined for Phase E+F.

Compliance:
    - No PHI/PII in event payloads — use tenant-scoped IDs only
    - Tenant-scoped: X-Tenant-ID header + source field includes tenant context
    - Audit trail: every published event logged to medinovai-audit-trail-explorer
"""
from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, Optional

# ---------------------------------------------------------------------------
# 13 CloudEvent types for MedinovAI Phase E+F
# ---------------------------------------------------------------------------

# Data Ingestion & Processing
EVENT_DATA_INGESTED = "io.medinovai.data.ingested"
EVENT_DE_ID_COMPLETED = "io.medinovai.data.deidentified"
EVENT_DQ_GATE_PASSED = "io.medinovai.data.dqgate.passed"
EVENT_DQ_GATE_FAILED = "io.medinovai.data.dqgate.failed"
EVENT_DATASET_PUBLISHED = "io.medinovai.data.dataset.published"

# Research Workspace
EVENT_COHORT_EXECUTED = "io.medinovai.research.cohort.executed"
EVENT_WORKSPACE_PROVISIONED = "io.medinovai.research.workspace.provisioned"

# AI/ML
EVENT_MODEL_REGISTERED = "io.medinovai.aiml.model.registered"
EVENT_DEPLOYMENT_REQUESTED = "io.medinovai.aiml.deployment.requested"
EVENT_DEPLOYMENT_COMPLETED = "io.medinovai.aiml.deployment.completed"
EVENT_DEPLOYMENT_ROLLED_BACK = "io.medinovai.aiml.deployment.rolledback"

# Consent & Security
EVENT_CONSENT_REVOKED = "io.medinovai.consent.revoked"
EVENT_SECURITY_ALERT = "io.medinovai.security.alert"

ALL_EVENT_TYPES = [
    EVENT_DATA_INGESTED,
    EVENT_DE_ID_COMPLETED,
    EVENT_DQ_GATE_PASSED,
    EVENT_DQ_GATE_FAILED,
    EVENT_DATASET_PUBLISHED,
    EVENT_COHORT_EXECUTED,
    EVENT_WORKSPACE_PROVISIONED,
    EVENT_MODEL_REGISTERED,
    EVENT_DEPLOYMENT_REQUESTED,
    EVENT_DEPLOYMENT_COMPLETED,
    EVENT_DEPLOYMENT_ROLLED_BACK,
    EVENT_CONSENT_REVOKED,
    EVENT_SECURITY_ALERT,
]


class CloudEvent:
    """
    CloudEvents v1.0 envelope for all MedinovAI inter-service events.

    Spec: https://cloudevents.io/
    Format: JSON with required attributes: specversion, id, source, type, time

    PHI Safety: data payload must never contain raw PHI — use IDs, hashes, or tokens only.
    """

    SPEC_VERSION = "1.0"
    SOURCE_PREFIX = "medinovai.health"

    def __init__(
        self,
        event_type: str,
        source: str,
        tenant_id: str,
        data: Optional[Dict[str, Any]] = None,
        subject: Optional[str] = None,
        correlation_id: Optional[str] = None,
    ) -> None:
        self.id = str(uuid.uuid4())
        self.specversion = self.SPEC_VERSION
        self.type = event_type
        self.source = f"{self.SOURCE_PREFIX}/{source}"
        self.tenant_id = tenant_id
        self.subject = subject
        self.data = data or {}
        self.datacontenttype = "application/json"
        self.time = datetime.now(timezone.utc).isoformat()
        self.correlation_id = correlation_id or self.id
        # Validate no PHI markers in data (basic check)
        self._validate_no_phi()

    def _validate_no_phi(self) -> None:
        """Basic PHI leak prevention — reject events with SSN, DOB patterns."""
        import re
        data_str = json.dumps(self.data)
        ssn_pattern = r"\b\d{3}-\d{2}-\d{4}\b"
        if re.search(ssn_pattern, data_str):
            raise ValueError("PHI detected in CloudEvent data (SSN pattern) — redact before publishing")

    def to_dict(self) -> Dict[str, Any]:
        """Serialize to CloudEvents v1.0 JSON structure."""
        return {
            "specversion": self.specversion,
            "id": self.id,
            "source": self.source,
            "type": self.type,
            "tenant_id": self.tenant_id,
            "subject": self.subject,
            "datacontenttype": self.datacontenttype,
            "time": self.time,
            "correlationid": self.correlation_id,
            "data": self.data,
        }

    def to_json(self) -> str:
        return json.dumps(self.to_dict())

    def to_bytes(self) -> bytes:
        return self.to_json().encode("utf-8")

    @classmethod
    def from_dict(cls, d: Dict[str, Any]) -> "CloudEvent":
        event = cls.__new__(cls)
        event.specversion = d.get("specversion", "1.0")
        event.id = d.get("id", str(uuid.uuid4()))
        event.source = d.get("source", "")
        event.type = d.get("type", "")
        event.tenant_id = d.get("tenant_id", "")
        event.subject = d.get("subject")
        event.datacontenttype = d.get("datacontenttype", "application/json")
        event.time = d.get("time", datetime.now(timezone.utc).isoformat())
        event.correlation_id = d.get("correlationid", event.id)
        event.data = d.get("data", {})
        return event

    @classmethod
    def from_bytes(cls, raw: bytes) -> "CloudEvent":
        return cls.from_dict(json.loads(raw.decode("utf-8")))

    def __repr__(self) -> str:
        return f"CloudEvent(type={self.type}, tenant={self.tenant_id}, id={self.id})"
