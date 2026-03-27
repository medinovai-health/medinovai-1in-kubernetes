"""
Health check endpoints with real dependency wiring.
Deployment Service (medinovai-deploy) — Tier 2

Endpoints:
    /health       — basic liveness
    /health/ready — readiness with DB, cache, queue checks
    /health/live  — Kubernetes liveness probe
"""
import asyncio
import logging
import os
import time
from datetime import datetime, timezone
from typing import Any

E_SERVICE_NAME = "medinovai-deploy"
E_SERVICE_VERSION = os.getenv("SERVICE_VERSION", "1.0.0")

mos_logger = logging.getLogger(__name__)


async def mos_checkDatabase() -> dict[str, Any]:
    """Check database connectivity and query latency."""
    mos_start = time.monotonic()
    try:
        mos_dbUrl = os.getenv("DATABASE_URL", "")
        if not mos_dbUrl:
            return {"status": "unconfigured", "latency_ms": 0}
        # Attempt connection check
        import asyncpg  # type: ignore
        mos_conn = await asyncio.wait_for(
            asyncpg.connect(mos_dbUrl), timeout=5.0
        )
        await mos_conn.fetchval("SELECT 1")
        await mos_conn.close()
        mos_latency = (time.monotonic() - mos_start) * 1000
        return {"status": "healthy", "latency_ms": round(mos_latency, 2)}
    except ImportError:
        return {"status": "driver_missing", "latency_ms": 0}
    except asyncio.TimeoutError:
        return {"status": "timeout", "latency_ms": 5000}
    except Exception as e:
        mos_latency = (time.monotonic() - mos_start) * 1000
        mos_logger.warning("DB health check failed: %s", type(e).__name__)
        return {"status": "unhealthy", "error": type(e).__name__,
                "latency_ms": round(mos_latency, 2)}


async def mos_checkCache() -> dict[str, Any]:
    """Check Redis/Memcached connectivity."""
    mos_start = time.monotonic()
    try:
        mos_redisUrl = os.getenv("REDIS_URL", "")
        if not mos_redisUrl:
            return {"status": "unconfigured", "latency_ms": 0}
        import redis.asyncio as aioredis  # type: ignore
        mos_client = aioredis.from_url(mos_redisUrl, socket_timeout=3)
        await mos_client.ping()
        await mos_client.aclose()
        mos_latency = (time.monotonic() - mos_start) * 1000
        return {"status": "healthy", "latency_ms": round(mos_latency, 2)}
    except ImportError:
        return {"status": "driver_missing", "latency_ms": 0}
    except Exception as e:
        mos_latency = (time.monotonic() - mos_start) * 1000
        return {"status": "unhealthy", "error": type(e).__name__,
                "latency_ms": round(mos_latency, 2)}


async def mos_checkQueue() -> dict[str, Any]:
    """Check message queue (ActiveMQ/RabbitMQ) connectivity."""
    mos_start = time.monotonic()
    try:
        mos_amqpUrl = os.getenv("AMQP_URL", "")
        if not mos_amqpUrl:
            return {"status": "unconfigured", "latency_ms": 0}
        import aio_pika  # type: ignore
        mos_conn = await asyncio.wait_for(
            aio_pika.connect_robust(mos_amqpUrl), timeout=5.0
        )
        await mos_conn.close()
        mos_latency = (time.monotonic() - mos_start) * 1000
        return {"status": "healthy", "latency_ms": round(mos_latency, 2)}
    except ImportError:
        return {"status": "driver_missing", "latency_ms": 0}
    except Exception as e:
        mos_latency = (time.monotonic() - mos_start) * 1000
        return {"status": "unhealthy", "error": type(e).__name__,
                "latency_ms": round(mos_latency, 2)}


async def mos_healthCheck() -> dict[str, Any]:
    """Basic liveness — always returns 200 if process is running."""
    return {
        "status": "healthy",
        "service": E_SERVICE_NAME,
        "version": E_SERVICE_VERSION,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


async def mos_readinessCheck() -> dict[str, Any]:
    """Readiness check — verifies all dependencies are reachable."""
    mos_checks = await asyncio.gather(
        mos_checkDatabase(),
        mos_checkCache(),
        mos_checkQueue(),
        return_exceptions=True,
    )
    mos_deps = {
        "database": mos_checks[0] if not isinstance(mos_checks[0], Exception)
                    else {"status": "error", "error": str(mos_checks[0])},
        "cache":    mos_checks[1] if not isinstance(mos_checks[1], Exception)
                    else {"status": "error", "error": str(mos_checks[1])},
        "queue":    mos_checks[2] if not isinstance(mos_checks[2], Exception)
                    else {"status": "error", "error": str(mos_checks[2])},
    }
    mos_allHealthy = all(
        d.get("status") in ("healthy", "unconfigured", "driver_missing")
        for d in mos_deps.values()
    )
    return {
        "status": "ready" if mos_allHealthy else "not_ready",
        "service": E_SERVICE_NAME,
        "version": E_SERVICE_VERSION,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "dependencies": mos_deps,
    }


async def mos_livenessCheck() -> dict[str, Any]:
    """Kubernetes liveness — lightweight, no dependency checks."""
    return {
        "status": "alive",
        "service": E_SERVICE_NAME,
        "uptime_seconds": round(time.monotonic(), 2),
    }
