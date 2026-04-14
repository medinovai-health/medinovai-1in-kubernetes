# Structured Logging Configuration
# Sprint 8: Observability & Monitoring

import logging
import json
import sys
from datetime import datetime, timezone


class StructuredFormatter(logging.Formatter):
    """JSON structured log formatter for observability pipelines."""

    def format(self, record):
        log_entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
            "service": "medinovai-1in-kubernetes",
            "version": "1.0.0",
        }
        if record.exc_info and record.exc_info[0]:
            log_entry["exception"] = {
                "type": record.exc_info[0].__name__,
                "message": str(record.exc_info[1]),
            }
        if hasattr(record, "correlation_id"):
            log_entry["correlation_id"] = record.correlation_id
        if hasattr(record, "user_id"):
            log_entry["user_id"] = record.user_id
        return json.dumps(log_entry)


def setup_logging(level=logging.INFO):
    """Configure structured logging for the service."""
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(StructuredFormatter())
    root = logging.getLogger()
    root.setLevel(level)
    root.addHandler(handler)
    return root


# Correlation ID middleware
class CorrelationContext:
    """Thread-local correlation ID for request tracing."""
    _correlation_id = None

    @classmethod
    def set(cls, correlation_id: str):
        cls._correlation_id = correlation_id

    @classmethod
    def get(cls) -> str:
        return cls._correlation_id or "unknown"
