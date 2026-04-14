# Health Check Endpoints
# Sprint 8: Observability & Monitoring

from datetime import datetime, timezone
from typing import Dict, Any
import os
import psutil


def liveness_check() -> Dict[str, Any]:
    """Liveness probe - is the process alive and responsive?"""
    return {
        "status": "ok",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "service": "medinovai-1in-kubernetes",
        "uptime_seconds": psutil.Process(os.getpid()).create_time(),
    }


def readiness_check(dependencies: Dict[str, callable] = None) -> Dict[str, Any]:
    """Readiness probe - can the service accept traffic?"""
    checks = {}
    all_healthy = True

    if dependencies:
        for name, check_fn in dependencies.items():
            try:
                check_fn()
                checks[name] = {"status": "ok"}
            except Exception as e:
                checks[name] = {"status": "error", "message": str(e)}
                all_healthy = False

    return {
        "status": "ok" if all_healthy else "degraded",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "service": "medinovai-1in-kubernetes",
        "checks": checks,
    }


def metrics_summary() -> Dict[str, Any]:
    """Basic runtime metrics for monitoring."""
    process = psutil.Process(os.getpid())
    return {
        "cpu_percent": process.cpu_percent(),
        "memory_mb": process.memory_info().rss / 1024 / 1024,
        "threads": process.num_threads(),
        "open_files": len(process.open_files()),
    }
