"""
MedinovAI Temporal Hello-World Worker — Sprint 0 POC

Connects to Temporal server (local or Cloud), registers the HelloWorldWorkflow,
and optionally triggers one execution to validate the full stack.

Usage:
    # Start worker (waits for workflows)
    python temporal/workers/hello_worker.py

    # Start worker AND trigger a test workflow execution
    python temporal/workers/hello_worker.py --trigger

    # Local Temporal server (Docker)
    TEMPORAL_ENVIRONMENT=local python temporal/workers/hello_worker.py --trigger

Environment variables:
    See temporal/.env.temporal.example
"""

import asyncio
import os
import sys
import uuid
import argparse
from temporalio.client import Client, TLSConfig
from temporalio.worker import Worker

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
from workflows.hello_world import HelloWorldWorkflow, say_hello_activity, log_audit_entry

E_TASK_QUEUE = "medinovai-hello-world"
E_WORKFLOW_ID_PREFIX = "medinovai-hello-world-"


async def connect_client() -> Client:
    """Connect to Temporal server based on TEMPORAL_ENVIRONMENT env var."""
    env = os.getenv("TEMPORAL_ENVIRONMENT", "local")

    if env == "local":
        return await Client.connect("localhost:7233", namespace="default")

    namespace = os.environ["TEMPORAL_NAMESPACE"]
    host_url = os.environ["TEMPORAL_HOST_URL"]
    cert_path = os.environ["TEMPORAL_TLS_CERT"]
    key_path = os.environ["TEMPORAL_TLS_KEY"]

    with open(cert_path, "rb") as f:
        client_cert = f.read()
    with open(key_path, "rb") as f:
        client_key = f.read()

    tls_config = TLSConfig(client_cert=client_cert, client_private_key=client_key)
    return await Client.connect(host_url, namespace=namespace, tls=tls_config)


async def run_worker(trigger: bool = False) -> None:
    """Start the Temporal worker and optionally trigger a test workflow."""
    client = await connect_client()
    env = os.getenv("TEMPORAL_ENVIRONMENT", "local")
    print(f"[medinovai-temporal] Connected to Temporal ({env})")

    if trigger:
        # Sprint 0 POC: start worker + trigger workflow in the same process.
        # The worker runs in the background task; the trigger waits for completion.
        correlation_id = str(uuid.uuid4())
        workflow_id = f"{E_WORKFLOW_ID_PREFIX}{correlation_id[:8]}"

        worker = Worker(
            client,
            task_queue=E_TASK_QUEUE,
            workflows=[HelloWorldWorkflow],
            activities=[say_hello_activity, log_audit_entry],
        )
        print(f"[medinovai-temporal] Worker started on task queue: {E_TASK_QUEUE}")

        async with worker:
            result = await client.execute_workflow(
                HelloWorldWorkflow.run,
                args=["MedinovAI Health Data Network", correlation_id],
                id=workflow_id,
                task_queue=E_TASK_QUEUE,
            )

        print(f"[medinovai-temporal] Workflow completed: {workflow_id}")
        print(f"[medinovai-temporal] Result: {result}")
        print(f"[medinovai-temporal] Sprint 0 Exit Criterion #8: PASS — Temporal hello-world completed")
        return

    worker = Worker(
        client,
        task_queue=E_TASK_QUEUE,
        workflows=[HelloWorldWorkflow],
        activities=[say_hello_activity, log_audit_entry],
    )
    print(f"[medinovai-temporal] Worker listening on task queue: {E_TASK_QUEUE}")
    await worker.run()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="MedinovAI Temporal Hello-World Worker")
    parser.add_argument("--trigger", action="store_true", help="Trigger a test workflow and exit")
    args = parser.parse_args()
    asyncio.run(run_worker(trigger=args.trigger))
