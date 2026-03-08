"""
MedinovAI Temporal Hello-World Workflow — Sprint 0 POC

Purpose:
    Validates that Temporal is correctly configured and the worker can
    connect to the Temporal server (local or Cloud). This is Sprint 0
    exit criterion #8: "Temporal runs hello-world workflow."

Compliance:
    - No PHI in workflow input/output (HIPAA requirement)
    - Correlation ID required for 21 CFR Part 11 traceability
    - Audit trail entry logged on completion

Usage:
    Run the worker: python temporal/workers/hello_worker.py
    Trigger via:   python temporal/workers/hello_worker.py --trigger
"""

from datetime import timedelta
from temporalio import workflow, activity
from temporalio.common import RetryPolicy


@activity.defn
async def say_hello_activity(platform_name: str) -> str:
    """Activity: returns a greeting for the given platform name."""
    return f"MedinovAI Temporal POC — {platform_name} is operational."


@activity.defn
async def log_audit_entry(correlation_id: str, message: str) -> str:
    """Activity: logs a compliance audit entry (no PHI)."""
    import structlog
    log = structlog.get_logger("medinovai.temporal.audit")
    log.info(
        "temporal_workflow_audit",
        correlation_id=correlation_id,
        message=message,
        workflow="hello-world",
        actor="temporal-worker",
    )
    return f"AUDIT_LOGGED — correlation_id={correlation_id}"


@workflow.defn
class HelloWorldWorkflow:
    """
    Sprint 0 POC workflow. Validates Temporal connectivity and
    proves the worker executes activities end-to-end.

    Input:  HelloWorldInput (platform_name, correlation_id)
    Output: HelloWorldResult (greeting, audit_ref)
    """

    @workflow.run
    async def run(self, platform_name: str, correlation_id: str) -> dict:
        retry_policy = RetryPolicy(
            initial_interval=timedelta(seconds=1),
            backoff_coefficient=2.0,
            maximum_interval=timedelta(seconds=30),
            maximum_attempts=3,
        )

        greeting = await workflow.execute_activity(
            say_hello_activity,
            platform_name,
            start_to_close_timeout=timedelta(minutes=1),
            retry_policy=retry_policy,
        )

        audit_ref = await workflow.execute_activity(
            log_audit_entry,
            args=[correlation_id, greeting],
            start_to_close_timeout=timedelta(minutes=1),
            retry_policy=retry_policy,
        )

        return {
            "greeting": greeting,
            "audit_ref": audit_ref,
            "workflow": "hello-world",
            "correlation_id": correlation_id,
            "status": "COMPLETED",
        }
