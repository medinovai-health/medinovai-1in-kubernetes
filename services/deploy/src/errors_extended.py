"""
Extended E_SAFE_DEFAULT error handling for business logic.
Deployment Service (medinovai-deploy) — Tier 2

This module extends shared/errors.py with domain-specific exception
classes and a middleware that catches all unhandled errors, logs them
with correlation IDs, and returns safe 503 responses.
"""
import functools
import logging
import traceback
import uuid
from typing import Any, Callable, TypeVar

mos_logger = logging.getLogger(__name__)

# ── Domain-specific error codes ──────────────────────────────────

E_DEPLOY_VALIDATION  = "DEPLOY_ERR_400_VALIDATION"
E_DEPLOY_NOT_FOUND   = "DEPLOY_ERR_404_NOT_FOUND"
E_DEPLOY_CONFLICT    = "DEPLOY_ERR_409_CONFLICT"
E_DEPLOY_DEPENDENCY  = "DEPLOY_ERR_502_DEPENDENCY"
E_DEPLOY_SAFE_DEFAULT = "DEPLOY_ERR_503_SAFE_DEFAULT"
E_DEPLOY_RATE_LIMIT  = "DEPLOY_ERR_429_RATE_LIMIT"
E_DEPLOY_AUTHZ       = "DEPLOY_ERR_403_AUTHORIZATION"


class MedinovAIBaseError(Exception):
    """Base error for all Deployment Service exceptions."""
    def __init__(self, mos_code: str, mos_message: str,
                 mos_details: dict | None = None,
                 mos_httpStatus: int = 500):
        self.mos_code = mos_code
        self.mos_message = mos_message
        self.mos_details = mos_details or {}
        self.mos_httpStatus = mos_httpStatus
        super().__init__(mos_message)

    def to_response(self, mos_correlationId: str | None = None):
        return {
            "error_code": self.mos_code,
            "message": self.mos_message,
            "correlation_id": mos_correlationId or str(uuid.uuid4()),
            "details": self.mos_details,
        }


class ValidationError(MedinovAIBaseError):
    def __init__(self, mos_message: str, mos_details: dict | None = None):
        super().__init__(E_DEPLOY_VALIDATION, mos_message, mos_details, 400)

class NotFoundError(MedinovAIBaseError):
    def __init__(self, mos_resource: str, mos_id: str):
        super().__init__(E_DEPLOY_NOT_FOUND,
                         f"{mos_resource} not found",
                         {"resource": mos_resource, "id": mos_id}, 404)

class ConflictError(MedinovAIBaseError):
    def __init__(self, mos_message: str, mos_details: dict | None = None):
        super().__init__(E_DEPLOY_CONFLICT, mos_message, mos_details, 409)

class DependencyError(MedinovAIBaseError):
    def __init__(self, mos_service: str, mos_message: str):
        super().__init__(E_DEPLOY_DEPENDENCY,
                         f"Dependency failure: {mos_service}",
                         {"service": mos_service, "detail": mos_message}, 502)

class AuthorizationError(MedinovAIBaseError):
    def __init__(self, mos_action: str, mos_resource: str):
        super().__init__(E_DEPLOY_AUTHZ,
                         "Insufficient permissions",
                         {"action": mos_action, "resource": mos_resource}, 403)

class RateLimitError(MedinovAIBaseError):
    def __init__(self, mos_limit: int, mos_windowSec: int):
        super().__init__(E_DEPLOY_RATE_LIMIT,
                         f"Rate limit exceeded: {mos_limit}/{mos_windowSec}s",
                         {"limit": mos_limit, "window_seconds": mos_windowSec}, 429)


# ── Safe-default decorator ───────────────────────────────────────

F = TypeVar("F", bound=Callable[..., Any])

def mos_safeDefault(func: F) -> F:
    """
    Decorator: catches ALL unhandled exceptions and returns a safe 503.
    Known MedinovAIBaseError subclasses pass through with their status.
    Unknown exceptions are logged with full traceback + correlation ID,
    but the response only shows a generic error (no PHI/PII leak).
    """
    @functools.wraps(func)
    async def mos_wrapper(*args: Any, **kwargs: Any) -> Any:
        mos_correlationId = str(uuid.uuid4())
        try:
            return await func(*args, **kwargs)
        except MedinovAIBaseError as e:
            mos_logger.warning(
                "Domain error [%s] %s correlation=%s",
                e.mos_code, e.mos_message, mos_correlationId,
            )
            return e.to_response(mos_correlationId), e.mos_httpStatus
        except Exception:
            # E_SAFE_DEFAULT: never expose internals
            mos_logger.error(
                "UNHANDLED ERROR correlation=%s\n%s",
                mos_correlationId, traceback.format_exc(),
            )
            return {
                "error_code": E_DEPLOY_SAFE_DEFAULT,
                "message": "An internal error occurred. "
                           "Please contact support with correlation ID.",
                "correlation_id": mos_correlationId,
            }, 503
    return mos_wrapper  # type: ignore
