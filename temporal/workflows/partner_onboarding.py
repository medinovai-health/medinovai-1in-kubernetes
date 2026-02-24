"""
MedinovAI Temporal Workflow S8-01: Partner Onboarding

Purpose:
    Orchestrates partner onboarding: validate registration, provision connector,
    run DQ check, setup DUA, notify and emit DataIngested CloudEvent.

Compliance:
    - No PHI in workflow input/output (HIPAA requirement)
    - X-Tenant-ID via tenant_id parameter
    - Correlation ID required for 21 CFR Part 11 traceability
"""

from dataclasses import dataclass
from datetime import datetime, timedelta
from temporalio import workflow, activity
from temporalio.common import RetryPolicy


@dataclass
class PartnerOnboardingInput:
    """Workflow input — no PHI, only IDs and tokens."""
    partner_id: str
    tenant_id: str
    connector_type: str
    connector_config: dict
    correlation_id: str


@dataclass
class PartnerOnboardingResult:
    """Workflow result."""
    success: bool
    connector_id: str | None
    dq_score: float | None
    onboarded_at: str


@activity.defn
async def validate_partner_registration(partner_id: str, tenant_id: str) -> bool:
    """Validates org exists in medinovai-registry."""
    # Stub: call medinovai-registry API
    return True


@activity.defn
async def provision_connector(
    partner_id: str, connector_type: str, config: dict, tenant_id: str
) -> str:
    """Calls connector framework POST /api/v1/connectors."""
    # Stub: returns connector_id
    return f"conn-{partner_id}-{connector_type}"


@activity.defn
async def run_initial_dq_check(connector_id: str, tenant_id: str) -> float:
    """Calls DQ gates POST /api/v1/omop/dq/run."""
    # Stub: returns DQ score 0.0-1.0
    return 0.95


@activity.defn
async def setup_data_sharing_agreement(
    partner_id: str, dua_template: str, tenant_id: str
) -> str:
    """Creates DUA record."""
    # Stub: returns dua_id
    return f"dua-{partner_id}"


@activity.defn
async def notify_partner_onboard_complete(
    partner_id: str, tenant_id: str, correlation_id: str
) -> None:
    """Sends notification + emits DataIngested CloudEvent."""
    pass


@workflow.defn
class PartnerOnboardingWorkflow:
    """S8-01: Partner onboarding orchestration."""

    @workflow.run
    async def run(self, inp: PartnerOnboardingInput) -> PartnerOnboardingResult:
        retry = RetryPolicy(
            max_attempts=3,
            initial_interval=timedelta(seconds=5),
            backoff_coefficient=2.0,
        )
        timeout = timedelta(minutes=5)

        await workflow.execute_activity(
            validate_partner_registration,
            args=[inp.partner_id, inp.tenant_id],
            start_to_close_timeout=timeout,
            retry_policy=retry,
        )

        connector_id = await workflow.execute_activity(
            provision_connector,
            args=[inp.partner_id, inp.connector_type, inp.connector_config, inp.tenant_id],
            start_to_close_timeout=timeout,
            retry_policy=retry,
        )

        dq_score = await workflow.execute_activity(
            run_initial_dq_check,
            args=[connector_id, inp.tenant_id],
            start_to_close_timeout=timeout,
            retry_policy=retry,
        )

        dua_template = inp.connector_config.get("dua_template", "default")
        await workflow.execute_activity(
            setup_data_sharing_agreement,
            args=[inp.partner_id, dua_template, inp.tenant_id],
            start_to_close_timeout=timeout,
            retry_policy=retry,
        )

        await workflow.execute_activity(
            notify_partner_onboard_complete,
            args=[inp.partner_id, inp.tenant_id, inp.correlation_id],
            start_to_close_timeout=timeout,
            retry_policy=retry,
        )

        return PartnerOnboardingResult(
            success=True,
            connector_id=connector_id,
            dq_score=dq_score,
            onboarded_at=datetime.utcnow().isoformat() + "Z",
        )
