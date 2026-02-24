"""
MedinovAI Infrastructure — Workspace Idle Shutdown Monitor
Task Reference: S4-02
Version: 1.0.0
Date: 2026-02-24

Async background task that checks all running workspaces for heartbeat.
If no heartbeat response for idle_timeout_minutes, calls DELETE /api/v1/workspaces/{workspace_id}.
Logs all timeout events (no PHI).

The workspace pod must expose GET /heartbeat. This monitor runs every 5 minutes.
"""

import asyncio
import os
from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List

import httpx
import structlog
from kubernetes import client, config

logger = structlog.get_logger("medinovai.workspace.heartbeat_monitor")

E_NAMESPACE_PREFIX = "medinovai-ws-"
E_IDLE_TIMEOUT_MINUTES = int(os.getenv("WORKSPACE_IDLE_TIMEOUT_MINUTES", "60"))
E_CHECK_INTERVAL_SECONDS = int(os.getenv("HEARTBEAT_CHECK_INTERVAL", "300"))  # 5 minutes
E_OPERATOR_URL = os.getenv("WORKSPACE_OPERATOR_URL", "http://localhost:8080")
E_HEARTBEAT_PATH = "/heartbeat"


def _load_k8s_config() -> None:
    """Load Kubernetes config (in-cluster or kubeconfig)."""
    try:
        config.load_incluster_config()
    except config.ConfigException:
        try:
            config.load_kube_config()
        except config.ConfigException:
            pass


async def _get_workspace_pod_url(workspace_id: str, namespace: str) -> str | None:
    """
    Get the URL to reach the workspace pod's heartbeat endpoint.
    Uses port-forward or direct pod IP. For simplicity, we use the operator's
    workspace URL pattern: operator may proxy to workspace pods.
    In production, this would use K8s service discovery.
    """
    v1 = client.CoreV1Api()
    try:
        pods = v1.list_namespaced_pod(
            namespace=namespace,
            label_selector="app=workspace",
        )
        for pod in pods.items:
            if pod.status.phase == "Running" and pod.status.pod_ip:
                # Pod has /heartbeat - we'd need to port-forward or use service
                # For now, use service URL: http://workspace.{namespace}.svc.cluster.local:80/heartbeat
                return f"http://workspace.{namespace}.svc.cluster.local{E_HEARTBEAT_PATH}"
        return None
    except Exception:
        return None


async def _check_heartbeat(url: str, timeout: float = 5.0) -> bool:
    """Call GET /heartbeat on workspace. Return True if 2xx response."""
    try:
        async with httpx.AsyncClient(timeout=timeout) as client_:
            r = await client_.get(url)
            return 200 <= r.status_code < 300
    except Exception:
        return False


async def _get_workspaces_with_last_heartbeat() -> List[Dict[str, Any]]:
    """
    Get all workspace namespaces and their last heartbeat time.
    Uses a simple file or in-memory store. For production, use Redis/DB.
    """
    v1 = client.CoreV1Api()
    workspaces = []
    try:
        ns_list = v1.list_namespace()
        for ns in ns_list.items:
            if not ns.metadata.name.startswith(E_NAMESPACE_PREFIX):
                continue
            workspace_id = ns.metadata.name.replace(E_NAMESPACE_PREFIX, "")
            tenant_id = (ns.metadata.labels or {}).get("medinovai/tenant-id", "")
            workspaces.append({
                "workspace_id": workspace_id,
                "namespace": ns.metadata.name,
                "tenant_id": tenant_id,
            })
    except Exception as exc:
        logger.warning("heartbeat_monitor_list_failed", error=str(exc)[:200])
    return workspaces


async def _terminate_workspace(workspace_id: str, tenant_id: str) -> bool:
    """Call DELETE /api/v1/workspaces/{workspace_id} via operator API."""
    url = f"{E_OPERATOR_URL.rstrip('/')}/api/v1/workspaces/{workspace_id}"
    try:
        async with httpx.AsyncClient(timeout=30.0) as client_:
            r = await client_.delete(url, headers={"X-Tenant-ID": tenant_id or "default"})
            return 200 <= r.status_code < 300
    except Exception as exc:
        logger.error("heartbeat_terminate_failed",
                     workspace_id=workspace_id, error=str(exc)[:200])
        return False


# In-memory store for last heartbeat time (workspace_id -> datetime)
_last_heartbeat: Dict[str, datetime] = {}


async def _run_heartbeat_check() -> None:
    """
    Check all workspaces. For each:
    1. Try GET /heartbeat on workspace pod
    2. If success, update last_heartbeat[workspace_id]
    3. If failure and last_heartbeat is older than idle_timeout_minutes, terminate
    """
    _load_k8s_config()
    workspaces = await _get_workspaces_with_last_heartbeat()
    now = datetime.now(tz=timezone.utc)
    timeout_threshold = now - timedelta(minutes=E_IDLE_TIMEOUT_MINUTES)

    for ws in workspaces:
        workspace_id = ws["workspace_id"]
        namespace = ws["namespace"]
        tenant_id = ws["tenant_id"]

        url = await _get_workspace_pod_url(workspace_id, namespace)
        if not url:
            # Can't reach pod - might be starting. Don't terminate.
            continue

        alive = await _check_heartbeat(url)
        if alive:
            _last_heartbeat[workspace_id] = now
            continue

        last = _last_heartbeat.get(workspace_id)
        if last is None:
            _last_heartbeat[workspace_id] = now
            continue

        if last < timeout_threshold:
            logger.info("workspace_idle_timeout",
                        workspace_id=workspace_id,
                        namespace=namespace,
                        tenant_id=tenant_id,
                        idle_minutes=E_IDLE_TIMEOUT_MINUTES,
                        last_heartbeat=last.isoformat())
            if await _terminate_workspace(workspace_id, tenant_id):
                _last_heartbeat.pop(workspace_id, None)
                logger.info("workspace_terminated_idle",
                            workspace_id=workspace_id, tenant_id=tenant_id)


async def run_monitor_loop() -> None:
    """Run the heartbeat monitor loop every E_CHECK_INTERVAL_SECONDS."""
    logger.info("heartbeat_monitor_started",
                interval_sec=E_CHECK_INTERVAL_SECONDS,
                idle_timeout_min=E_IDLE_TIMEOUT_MINUTES)
    while True:
        try:
            await _run_heartbeat_check()
        except Exception as exc:
            logger.error("heartbeat_monitor_error", error=str(exc)[:300])
        await asyncio.sleep(E_CHECK_INTERVAL_SECONDS)


def main() -> None:
    """Entry point for running the monitor as a standalone process."""
    asyncio.run(run_monitor_loop())


if __name__ == "__main__":
    main()
