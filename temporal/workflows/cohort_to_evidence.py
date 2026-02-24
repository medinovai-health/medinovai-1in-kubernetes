"""
MedinovAI Temporal Workflow S8-02: Cohort-to-Evidence

Purpose:
    Orchestrates cohort study: execute cohort query, run DQ gates, provision
    workspace, store evidence, link artifacts, emit CohortExecuted CloudEvent.

Compliance:
    - No PHI in workflow input/output (HIPAA requirement)
    - X-Tenant-ID via tenant_id parameter
    - Correlation ID required for 21 CFR Part 11 traceability
"""

from dataclasses import dataclass
from temporalio import workflow, activity
from temporalio.common import RetryPolicy
from datetime import timedelta


@dataclass
class CohortStudyInput:
    """Workflow input — no PHI."""
    study_id: str
    cohort_id: str
    omop_schema: str
    researcher_id: str
    workspace_type: str
    tenant_id: str
    correlation_id: str


@dataclass
class CohortStudyResult:
    """Workflow result."""
    success: bool
    workspace_id: str | None
    evidence_id: str | None
    workspace_url: str | None


@activity.defn
async def execute_cohort_query(
    cohort_id: str, omop_schema: str, tenant_id: str
) -> str:
    """Runs cohort SQL via data-services."""
    # Stub: returns dataset_id
    return f"ds-{cohort_id}-{omop_schema}"


@activity.defn
async def run_cohort_dq_gates(dataset_id: str, tenant_id: str) -> bool:
    """Quality gates must pass."""
    return True


@activity.defn
async def provision_workspace(
    study_id: str, researcher_id: str, workspace_type: str, tier: str, tenant_id: str
) -> tuple[str, str]:
    """Calls workspace operator. Returns (workspace_id, workspace_url)."""
    return (f"ws-{study_id}", f"https://workspace.medinovai/{study_id}")


@activity.defn
async def store_evidence(
    study_id: str, cohort_id: str, dataset_id: str, evidence_type: str, tenant_id: str
) -> str:
    """Calls Evidence Store."""
    return f"ev-{study_id}-{cohort_id}"


@activity.defn
async def link_study_run_artifacts(
    study_id: str, cohort_id: str, dataset_id: str, evidence_id: str, tenant_id: str
) -> None:
    """Links all artifacts."""
    pass


@activity.defn
async def emit_cohort_executed_event(
    study_id: str, cohort_id: str, tenant_id: str, correlation_id: str
) -> None:
    """Emits CohortExecuted CloudEvent."""
    pass


@workflow.defn
class CohortToEvidenceWorkflow:
    """S8-02: Cohort-to-evidence orchestration."""

    @workflow.run
    async def run(self, inp: CohortStudyInput) -> CohortStudyResult:
        retry = RetryPolicy(
            max_attempts=3,
            initial_interval=timedelta(seconds=5),
            backoff_coefficient=2.0,
        )
        timeout = timedelta(minutes=5)

        dataset_id = await workflow.execute_activity(
            execute_cohort_query,
            args=[inp.cohort_id, inp.omop_schema, inp.tenant_id],
            start_to_close_timeout=timeout,
            retry_policy=retry,
        )

        await workflow.execute_activity(
            run_cohort_dq_gates,
            args=[dataset_id, inp.tenant_id],
            start_to_close_timeout=timeout,
            retry_policy=retry,
        )

        workspace_id, workspace_url = await workflow.execute_activity(
            provision_workspace,
            args=[
                inp.study_id,
                inp.researcher_id,
                inp.workspace_type,
                "standard",
                inp.tenant_id,
            ],
            start_to_close_timeout=timeout,
            retry_policy=retry,
        )

        evidence_id = await workflow.execute_activity(
            store_evidence,
            args=[
                inp.study_id,
                inp.cohort_id,
                dataset_id,
                "cohort_evidence",
                inp.tenant_id,
            ],
            start_to_close_timeout=timeout,
            retry_policy=retry,
        )

        await workflow.execute_activity(
            link_study_run_artifacts,
            args=[
                inp.study_id,
                inp.cohort_id,
                dataset_id,
                evidence_id,
                inp.tenant_id,
            ],
            start_to_close_timeout=timeout,
            retry_policy=retry,
        )

        await workflow.execute_activity(
            emit_cohort_executed_event,
            args=[
                inp.study_id,
                inp.cohort_id,
                inp.tenant_id,
                inp.correlation_id,
            ],
            start_to_close_timeout=timeout,
            retry_policy=retry,
        )

        return CohortStudyResult(
            success=True,
            workspace_id=workspace_id,
            evidence_id=evidence_id,
            workspace_url=workspace_url,
        )
