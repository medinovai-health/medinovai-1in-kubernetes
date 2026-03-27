"""
MedinovAI Error Handling Module — medinovai-infrastructure
Domain: Infrastructure Management

Standard: medinovai-ai-standards/CODING_STANDARDS.md
Constants use E_ prefix, variables use mos_ prefix.

Implements:
  - E_SAFE_DEFAULT pattern (fail-safe on unhandled errors)
  - Structured error codes (MED-XXXX)
  - HIPAA-safe error messages (no PHI in error payloads)
  - Correlation-ID propagation for distributed tracing
"""
from __future__ import annotations

import logging
import uuid
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Optional

mos_logger = logging.getLogger("medinovai-infrastructure")


# ── Error Codes ──────────────────────────────────────────────────

class E_ERROR_CODE(str, Enum):
    """Structured error codes — MED-XXXX format."""
    E_UNKNOWN            = "MED-0000"
    E_VALIDATION         = "MED-1001"
    E_AUTH_FAILED        = "MED-2001"
    E_AUTH_EXPIRED       = "MED-2002"
    E_FORBIDDEN          = "MED-2003"
    E_NOT_FOUND          = "MED-3001"
    E_CONFLICT           = "MED-3002"
    E_RATE_LIMITED       = "MED-4001"
    E_UPSTREAM_TIMEOUT   = "MED-5001"
    E_UPSTREAM_ERROR     = "MED-5002"
    E_DATABASE_ERROR     = "MED-5003"
    E_ENCRYPTION_ERROR   = "MED-5004"
    E_PHI_ACCESS_DENIED  = "MED-6001"
    E_AUDIT_FAILURE      = "MED-6002"
    E_SAFE_DEFAULT       = "MED-9999"


# ── Error Classes ────────────────────────────────────────────────

@dataclass
class MedinovAIError(Exception):
    """Base error class with HIPAA-safe messaging."""
    mos_code: E_ERROR_CODE = E_ERROR_CODE.E_UNKNOWN
    mos_message: str = "An unexpected error occurred"
    mos_correlationId: str = field(default_factory=lambda: str(uuid.uuid4()))
    mos_details: Optional[dict[str, Any]] = None
    mos_httpStatus: int = 500

    def __post_init__(self):
        super().__init__(self.mos_message)
        # HIPAA: Never include PHI in log messages
        mos_logger.error(
            "error_code=%s correlation_id=%s http_status=%d message=%s",
            self.mos_code.value,
            self.mos_correlationId,
            self.mos_httpStatus,
            self.mos_message,
        )

    def to_response(self) -> dict:
        """Return HIPAA-safe error response (no PHI)."""
        return {
            "error": {
                "code": self.mos_code.value,
                "message": self.mos_message,
                "correlationId": self.mos_correlationId,
            }
        }


class ValidationError(MedinovAIError):
    """Input validation failure."""
    mos_code: E_ERROR_CODE = E_ERROR_CODE.E_VALIDATION
    mos_httpStatus: int = 400


class AuthenticationError(MedinovAIError):
    """Authentication failure — token invalid or expired."""
    mos_code: E_ERROR_CODE = E_ERROR_CODE.E_AUTH_FAILED
    mos_httpStatus: int = 401


class ForbiddenError(MedinovAIError):
    """Authorization failure — insufficient permissions."""
    mos_code: E_ERROR_CODE = E_ERROR_CODE.E_FORBIDDEN
    mos_httpStatus: int = 403


class NotFoundError(MedinovAIError):
    """Resource not found."""
    mos_code: E_ERROR_CODE = E_ERROR_CODE.E_NOT_FOUND
    mos_httpStatus: int = 404


class PHIAccessDeniedError(MedinovAIError):
    """PHI access denied — requires explicit authorization."""
    mos_code: E_ERROR_CODE = E_ERROR_CODE.E_PHI_ACCESS_DENIED
    mos_httpStatus: int = 403


class SafeDefaultError(MedinovAIError):
    """E_SAFE_DEFAULT — unhandled error triggers safe fallback."""
    mos_code: E_ERROR_CODE = E_ERROR_CODE.E_SAFE_DEFAULT
    mos_message: str = "Service entered safe-default mode"
    mos_httpStatus: int = 503


# ── Safe-Default Handler ─────────────────────────────────────────

def mos_safeDefault(mos_func):
    """Decorator: catch all exceptions → SafeDefaultError.

    In healthcare, silent failures kill. This ensures every unhandled
    exception returns a clear, auditable E_SAFE_DEFAULT response.
    """
    import functools

    @functools.wraps(mos_func)
    def mos_wrapper(*args, **kwargs):
        try:
            return mos_func(*args, **kwargs)
        except MedinovAIError:
            raise  # Already structured — propagate
        except Exception as mos_ex:
            mos_logger.critical(
                "SAFE_DEFAULT_TRIGGERED func=%s error=%s",
                mos_func.__name__,
                type(mos_ex).__name__,
            )
            raise SafeDefaultError(
                mos_message=f"Unhandled error in {mos_func.__name__}",
                mos_details={"original_error": type(mos_ex).__name__},
            ) from mos_ex

    return mos_wrapper


# ── Correlation-ID middleware helper ─────────────────────────────

def mos_getCorrelationId(mos_headers: Optional[dict] = None) -> str:
    """Extract or generate correlation ID for distributed tracing."""
    if mos_headers:
        for mos_h in ["X-Correlation-ID", "X-Request-ID", "traceparent"]:
            if mos_h in mos_headers:
                return mos_headers[mos_h]
    return str(uuid.uuid4())
