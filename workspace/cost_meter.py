"""
MedinovAI Infrastructure — Workspace Cost Metering
Task Reference: S4-05
Version: 1.0.0
Date: 2026-02-24

Track CPU-hours and GB-hours per workspace per tenant.
Prometheus gauges: medinovai_workspace_cpu_hours_total, medinovai_workspace_gb_hours_total.
Postgres schema: workspace_usage table.
Pricing: Tier 1=$0.50/hr, Tier 2=$1.00/hr, Tier 3=$2.00/hr, Tier 4=$4.00/hr
"""

import os
from datetime import datetime, timezone
from typing import Any, Dict, Optional

import structlog
from fastapi import FastAPI, Header, HTTPException
from prometheus_client import Gauge, generate_latest
from pydantic import BaseModel, Field
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import NullPool

logger = structlog.get_logger("medinovai.workspace.cost_meter")

app = FastAPI(title="MedinovAI Workspace Cost Meter", version="1.0.0")

# Prometheus gauges
E_CPU_HOURS_GAUGE = Gauge(
    "medinovai_workspace_cpu_hours_total",
    "Total CPU-hours consumed by workspace",
    ["workspace_id", "tenant_id", "org_id"],
)
E_GB_HOURS_GAUGE = Gauge(
    "medinovai_workspace_gb_hours_total",
    "Total GB-hours (memory) consumed by workspace",
    ["workspace_id", "tenant_id", "org_id"],
)

# Tier pricing $/hour
E_TIER_PRICING = {1: 0.50, 2: 1.00, 3: 2.00, 4: 4.00}

E_DB_URL = os.getenv(
    "WORKSPACE_METER_DB_URL",
    "postgresql+asyncpg://medinovai:medinovai_pass@localhost:5432/medinovai_workspace",
)

WORKSPACE_USAGE_SCHEMA = """
CREATE TABLE IF NOT EXISTS workspace_usage (
    id SERIAL PRIMARY KEY,
    workspace_id VARCHAR(64) NOT NULL,
    tenant_id VARCHAR(63) NOT NULL,
    org_id VARCHAR(63) DEFAULT '',
    cpu_hours DECIMAL(12, 4) NOT NULL DEFAULT 0,
    gb_hours DECIMAL(12, 4) NOT NULL DEFAULT 0,
    cost_usd DECIMAL(10, 2) NOT NULL DEFAULT 0,
    billed_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    tier INT DEFAULT 1,
    UNIQUE(workspace_id, tenant_id)
);
CREATE INDEX IF NOT EXISTS idx_workspace_usage_tenant ON workspace_usage(tenant_id);
CREATE INDEX IF NOT EXISTS idx_workspace_usage_workspace ON workspace_usage(workspace_id);
"""

_engine = None
_session_factory = None


def _get_engine():
    global _engine, _session_factory
    if _engine is None:
        _engine = create_async_engine(E_DB_URL, poolclass=NullPool)
        _session_factory = async_sessionmaker(
            _engine, class_=AsyncSession, expire_on_commit=False
        )
    return _engine, _session_factory


def _get_conn(tenant_id: str) -> str:
    if not tenant_id or tenant_id.strip() == "":
        raise HTTPException(status_code=400, detail="X-Tenant-ID header is required")
    return tenant_id


class RecordUsageRequest(BaseModel):
    """Request to record usage (called by operator or external collector)."""

    workspace_id: str = Field(..., min_length=1)
    cpu_hours: float = Field(0.0, ge=0)
    gb_hours: float = Field(0.0, ge=0)
    tier: int = Field(1, ge=1, le=4)
    org_id: str = Field("", max_length=63)


@app.on_event("startup")
async def startup():
    """Ensure workspace_usage table exists."""
    engine, _ = _get_engine()
    async with engine.begin() as conn:
        for stmt in WORKSPACE_USAGE_SCHEMA.strip().split(";"):
            stmt = stmt.strip()
            if stmt:
                try:
                    await conn.execute(text(stmt))
                except Exception:
                    pass


@app.get("/health", summary="Health check")
async def health() -> Dict[str, str]:
    return {"status": "healthy", "service": "medinovai-workspace-cost-meter"}


@app.get("/metrics", summary="Prometheus metrics")
async def metrics() -> bytes:
    """Prometheus scrape endpoint."""
    return generate_latest()


@app.post("/api/v1/workspaces/usage", summary="Record workspace usage (internal)")
async def record_usage(
    body: RecordUsageRequest,
    x_tenant_id: str = Header(..., alias="X-Tenant-ID"),
) -> Dict[str, Any]:
    """Record CPU-hours and GB-hours for a workspace. Updates Prometheus gauges."""
    _get_conn(x_tenant_id)
    _, session_factory = _get_engine()
    now = datetime.now(tz=timezone.utc)
    cost_usd = body.cpu_hours * E_TIER_PRICING.get(body.tier, 0.50)

    async with session_factory() as session:
        await session.execute(
            text("""
                INSERT INTO workspace_usage (workspace_id, tenant_id, org_id, cpu_hours, gb_hours, cost_usd, billed_at, tier)
                VALUES (:workspace_id, :tenant_id, :org_id, :cpu_hours, :gb_hours, :cost_usd, :billed_at, :tier)
                ON CONFLICT (workspace_id, tenant_id)
                DO UPDATE SET
                    cpu_hours = workspace_usage.cpu_hours + EXCLUDED.cpu_hours,
                    gb_hours = workspace_usage.gb_hours + EXCLUDED.gb_hours,
                    cost_usd = workspace_usage.cost_usd + EXCLUDED.cost_usd,
                    billed_at = EXCLUDED.billed_at
            """),
            {
                "workspace_id": body.workspace_id,
                "tenant_id": x_tenant_id,
                "org_id": body.org_id,
                "cpu_hours": body.cpu_hours,
                "gb_hours": body.gb_hours,
                "cost_usd": cost_usd,
                "billed_at": now,
                "tier": body.tier,
            },
        )
        await session.commit()

    E_CPU_HOURS_GAUGE.labels(
        workspace_id=body.workspace_id,
        tenant_id=x_tenant_id,
        org_id=body.org_id or "default",
    ).inc(body.cpu_hours)
    E_GB_HOURS_GAUGE.labels(
        workspace_id=body.workspace_id,
        tenant_id=x_tenant_id,
        org_id=body.org_id or "default",
    ).inc(body.gb_hours)

    return {"status": "recorded", "workspace_id": body.workspace_id, "cost_usd": cost_usd}


@app.get("/api/v1/workspaces/{workspace_id}/cost", summary="Get workspace cost (S4-05)")
async def get_workspace_cost(
    workspace_id: str,
    x_tenant_id: str = Header(..., alias="X-Tenant-ID"),
) -> Dict[str, Any]:
    """
    Returns current usage + estimated cost for workspace.
    """
    _get_conn(x_tenant_id)
    _, session_factory = _get_engine()

    async with session_factory() as session:
        result = await session.execute(
            text("""
                SELECT cpu_hours, gb_hours, cost_usd, tier, billed_at
                FROM workspace_usage
                WHERE workspace_id = :workspace_id AND tenant_id = :tenant_id
            """),
            {"workspace_id": workspace_id, "tenant_id": x_tenant_id},
        )
        row = result.fetchone()

    if not row:
        return {
            "workspace_id": workspace_id,
            "cpu_hours": 0.0,
            "gb_hours": 0.0,
            "cost_usd": 0.0,
            "estimated_hourly_rate": E_TIER_PRICING.get(1, 0.50),
            "tier": 1,
        }

    cpu_hours, gb_hours, cost_usd, tier, billed_at = row
    return {
        "workspace_id": workspace_id,
        "cpu_hours": float(cpu_hours or 0),
        "gb_hours": float(gb_hours or 0),
        "cost_usd": float(cost_usd or 0),
        "estimated_hourly_rate": E_TIER_PRICING.get(tier or 1, 0.50),
        "tier": tier or 1,
        "last_billed_at": billed_at.isoformat() if billed_at else None,
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8081)
