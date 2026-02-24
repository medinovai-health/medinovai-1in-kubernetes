"""
MedinovAI Temporal Unified Worker — All Sprint 8 Production Workflows

Registers all 6 production workflows and their activities:
  S8-01 Partner Onboarding
  S8-02 Cohort-to-Evidence
  S8-03 Model Lifecycle
  S8-04 Incident Response
  S8-05 Data Refresh
  S8-06 Consent Cascade

Usage:
    python temporal/workers/all_workflows_worker.py

Environment variables:
    TEMPORAL_HOST     — Temporal server address (default: localhost:7233)
    TEMPORAL_NAMESPACE — Namespace (default: medinovai-prod)
"""

import asyncio
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))

from temporalio.client import Client
from temporalio.worker import Worker

# Workflows
from workflows.partner_onboarding import (
    PartnerOnboardingWorkflow,
    validate_partner_registration,
    provision_connector,
    run_initial_dq_check,
    setup_data_sharing_agreement,
    notify_partner_onboard_complete,
)
from workflows.cohort_to_evidence import (
    CohortToEvidenceWorkflow,
    execute_cohort_query,
    run_cohort_dq_gates,
    provision_workspace,
    store_evidence,
    link_study_run_artifacts,
    emit_cohort_executed_event,
)
from workflows.model_lifecycle import (
    ModelLifecycleWorkflow,
    register_model,
    run_model_evaluation,
    await_dual_approval,
    deploy_canary,
    monitor_canary_metrics,
    promote_to_production,
    rollback_model,
    emit_deployment_event,
)
from workflows.incident_response import (
    IncidentResponseWorkflow,
    observe_incident,
    orient_classify,
    decide_response,
    act_execute_playbook,
    verify_resolution,
    record_post_mortem,
)
from workflows.data_refresh import (
    DataRefreshWorkflow,
    check_connector_health,
    trigger_connector_sync,
    await_sync_completion,
    apply_deidentification,
    run_refresh_dq_gates,
    publish_dataset_release,
    emit_dataset_published_event,
)
from workflows.consent_cascade import (
    ConsentCascadeWorkflow,
    validate_revocation_request,
    identify_affected_records,
    revoke_pii_vault_entries,
    remove_from_cohort_definitions,
    audit_cascade_completion,
    emit_consent_revoked_event,
)

E_TASK_QUEUE = "medinovai-production"


async def connect_client() -> Client:
    """Connect to Temporal server via env vars."""
    host = os.getenv("TEMPORAL_HOST", "localhost:7233")
    namespace = os.getenv("TEMPORAL_NAMESPACE", "medinovai-prod")
    return await Client.connect(host, namespace=namespace)


async def run_worker() -> None:
    """Start the unified worker with all 6 workflows."""
    client = await connect_client()
    print(f"[medinovai-temporal] Connected to {os.getenv('TEMPORAL_HOST', 'localhost:7233')}")
    print(f"[medinovai-temporal] Namespace: {os.getenv('TEMPORAL_NAMESPACE', 'medinovai-prod')}")

    workflows = [
        PartnerOnboardingWorkflow,
        CohortToEvidenceWorkflow,
        ModelLifecycleWorkflow,
        IncidentResponseWorkflow,
        DataRefreshWorkflow,
        ConsentCascadeWorkflow,
    ]

    activities = [
        validate_partner_registration,
        provision_connector,
        run_initial_dq_check,
        setup_data_sharing_agreement,
        notify_partner_onboard_complete,
        execute_cohort_query,
        run_cohort_dq_gates,
        provision_workspace,
        store_evidence,
        link_study_run_artifacts,
        emit_cohort_executed_event,
        register_model,
        run_model_evaluation,
        await_dual_approval,
        deploy_canary,
        monitor_canary_metrics,
        promote_to_production,
        rollback_model,
        emit_deployment_event,
        observe_incident,
        orient_classify,
        decide_response,
        act_execute_playbook,
        verify_resolution,
        record_post_mortem,
        check_connector_health,
        trigger_connector_sync,
        await_sync_completion,
        apply_deidentification,
        run_refresh_dq_gates,
        publish_dataset_release,
        emit_dataset_published_event,
        validate_revocation_request,
        identify_affected_records,
        revoke_pii_vault_entries,
        remove_from_cohort_definitions,
        audit_cascade_completion,
        emit_consent_revoked_event,
    ]

    worker = Worker(
        client,
        task_queue=E_TASK_QUEUE,
        workflows=workflows,
        activities=activities,
    )

    print(f"[medinovai-temporal] Worker listening on task queue: {E_TASK_QUEUE}")
    print(f"[medinovai-temporal] Registered {len(workflows)} workflows, {len(activities)} activities")
    await worker.run()


if __name__ == "__main__":
    asyncio.run(run_worker())
