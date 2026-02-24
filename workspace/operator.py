"""
MedinovAI Infrastructure — K8s Workspace Provisioning Service
Task Reference: S4-01, S4-02
Version: 1.0.0
Date: 2026-02-24

FastAPI service that provisions Jupyter/RStudio/VSCode workspaces via Kubernetes API.
Creates: Namespace medinovai-ws-{workspace_id}, Deployment, Service, PVC.
NOT a full K8s operator CRD — uses kubernetes Python client for kubectl-style API calls.

Workspace tiers:
- Tier 1 (Basic): 2 CPU, 4GB RAM, 10GB storage — Jupyter only
- Tier 2 (Standard): 4 CPU, 8GB RAM, 20GB storage — Jupyter + RStudio
- Tier 3 (Advanced): 8 CPU, 16GB RAM, 50GB storage — all types
- Tier 4 (Dedicated): 16 CPU, 32GB RAM, 100GB storage — all types
"""

import os
import uuid
from typing import Any, Dict, Literal, Optional

import structlog
from fastapi import FastAPI, Header, HTTPException
from kubernetes import client, config
from kubernetes.client.rest import ApiException
from pydantic import BaseModel, Field

logger = structlog.get_logger("medinovai.workspace.operator")

app = FastAPI(title="MedinovAI Workspace Operator", version="1.0.0")

# Tier resource definitions
E_TIER_SPECS = {
    1: {"cpu": "2", "memory": "4Gi", "storage": "10Gi", "types": ["jupyter"]},
    2: {"cpu": "4", "memory": "8Gi", "storage": "20Gi", "types": ["jupyter", "rstudio"]},
    3: {"cpu": "8", "memory": "16Gi", "storage": "50Gi", "types": ["jupyter", "rstudio", "vscode"]},
    4: {"cpu": "16", "memory": "32Gi", "storage": "100Gi", "types": ["jupyter", "rstudio", "vscode"]},
}

# Container images by workspace type
E_WORKSPACE_IMAGES = {
    "jupyter": os.getenv("WORKSPACE_JUPYTER_IMAGE", "jupyter/scipy-notebook:latest"),
    "rstudio": os.getenv("WORKSPACE_RSTUDIO_IMAGE", "rocker/rstudio:latest"),
    "vscode": os.getenv("WORKSPACE_VSCODE_IMAGE", "codercom/code-server:latest"),
}

E_NAMESPACE_PREFIX = "medinovai-ws-"
E_IDLE_TIMEOUT_MINUTES = int(os.getenv("WORKSPACE_IDLE_TIMEOUT_MINUTES", "60"))


def _get_conn(tenant_id: str):
    if not tenant_id or tenant_id.strip() == "":
        raise HTTPException(status_code=400, detail="X-Tenant-ID header is required")
    return tenant_id


def _load_k8s_config() -> client.CoreV1Api:
    """Load in-cluster or kubeconfig and return CoreV1Api."""
    try:
        config.load_incluster_config()
    except config.ConfigException:
        try:
            config.load_kube_config()
        except config.ConfigException as exc:
            raise HTTPException(status_code=503, detail="Kubernetes config not available") from exc
    return client.CoreV1Api()


def _load_apps_api() -> client.AppsV1Api:
    try:
        config.load_incluster_config()
    except config.ConfigException:
        try:
            config.load_kube_config()
        except config.ConfigException:
            pass
    return client.AppsV1Api()


class ProvisionWorkspaceRequest(BaseModel):
    """Request body for workspace provisioning."""

    study_id: str = Field(..., min_length=1, max_length=63)
    workspace_type: Literal["jupyter", "rstudio", "vscode"] = Field(..., description="Workspace type")
    tier: Literal[1, 2, 3, 4] = Field(1, description="Resource tier 1-4")
    researcher_id: str = Field(..., min_length=1, max_length=255)


@app.get("/health", summary="Health check")
async def health() -> Dict[str, str]:
    """Health endpoint for workspace operator."""
    return {"status": "healthy", "service": "medinovai-workspace-operator"}


@app.post("/api/v1/workspaces", summary="Provision workspace (S4-01)")
async def provision_workspace(
    body: ProvisionWorkspaceRequest,
    x_tenant_id: str = Header(..., alias="X-Tenant-ID"),
) -> Dict[str, Any]:
    """
    Provision a new workspace. Creates K8s Namespace, Deployment, Service, PVC.
    Returns workspace_id, status, url.
    """
    _get_conn(x_tenant_id)
    spec = E_TIER_SPECS.get(body.tier, E_TIER_SPECS[1])
    if body.workspace_type not in spec["types"]:
        raise HTTPException(
            status_code=400,
            detail=f"Workspace type {body.workspace_type} not available for tier {body.tier}. "
            f"Available: {spec['types']}",
        )

    workspace_id = str(uuid.uuid4())[:8]
    ns_name = f"{E_NAMESPACE_PREFIX}{workspace_id}"
    image = E_WORKSPACE_IMAGES.get(body.workspace_type, E_WORKSPACE_IMAGES["jupyter"])

    v1 = _load_k8s_config()
    apps_v1 = _load_apps_api()

    labels = {
        "app.kubernetes.io/name": "medinovai-workspace",
        "app.kubernetes.io/instance": workspace_id,
        "medinovai/tenant-id": x_tenant_id,
        "medinovai/study-id": body.study_id,
        "medinovai/researcher-id": body.researcher_id,
        "medinovai/tier": str(body.tier),
        "medinovai/workspace-type": body.workspace_type,
    }

    try:
        # Create namespace
        ns = client.V1Namespace(
            metadata=client.V1ObjectMeta(
                name=ns_name,
                labels=labels,
            ),
        )
        v1.create_namespace(ns)
        logger.info("workspace_namespace_created", workspace_id=workspace_id, ns=ns_name, tenant_id=x_tenant_id)

        # Create PVC
        pvc = client.V1PersistentVolumeClaim(
            metadata=client.V1ObjectMeta(name="workspace-storage", namespace=ns_name),
            spec=client.V1PersistentVolumeClaimSpec(
                access_modes=["ReadWriteOnce"],
                resources=client.V1ResourceRequirements(
                    requests={"storage": spec["storage"]},
                ),
            ),
        )
        v1.create_namespaced_persistent_volume_claim(namespace=ns_name, body=pvc)

        # Create Deployment
        deployment = client.V1Deployment(
            metadata=client.V1ObjectMeta(name="workspace", namespace=ns_name, labels=labels),
            spec=client.V1DeploymentSpec(
                replicas=1,
                selector=client.V1LabelSelector(match_labels={"app": "workspace"}),
                template=client.V1PodTemplateSpec(
                    metadata=client.V1ObjectMeta(labels={"app": "workspace", **labels}),
                    spec=client.V1PodSpec(
                        containers=[
                            client.V1Container(
                                name="workspace",
                                image=image,
                                ports=[client.V1ContainerPort(container_port=8888 if body.workspace_type == "jupyter" else 8787 if body.workspace_type == "rstudio" else 8080)],
                                resources=client.V1ResourceRequirements(
                                    requests={"cpu": spec["cpu"], "memory": spec["memory"]},
                                    limits={"cpu": spec["cpu"], "memory": spec["memory"]},
                                ),
                                volume_mounts=[
                                    client.V1VolumeMount(name="storage", mount_path="/home/jovyan/work" if body.workspace_type == "jupyter" else "/home/rstudio" if body.workspace_type == "rstudio" else "/home/coder"),
                                ],
                            ),
                        ],
                        volumes=[
                            client.V1Volume(
                                name="storage",
                                persistent_volume_claim=client.V1PersistentVolumeClaimVolumeSource(claim_name="workspace-storage"),
                            ),
                        ],
                    ),
                ),
            ),
        )
        apps_v1.create_namespaced_deployment(namespace=ns_name, body=deployment)

        # Create Service
        svc = client.V1Service(
            metadata=client.V1ObjectMeta(name="workspace", namespace=ns_name),
            spec=client.V1ServiceSpec(
                selector={"app": "workspace"},
                ports=[client.V1ServicePort(port=80, target_port=8888 if body.workspace_type == "jupyter" else 8787 if body.workspace_type == "rstudio" else 8080)],
            ),
        )
        v1.create_namespaced_service(namespace=ns_name, body=svc)

        # URL - in-cluster would use ingress; for now return placeholder
        base_url = os.getenv("WORKSPACE_BASE_URL", "https://workspace.medinovai.local")
        url = f"{base_url}/{workspace_id}"

        logger.info("workspace_provisioned",
                    workspace_id=workspace_id, ns=ns_name, url=url,
                    tenant_id=x_tenant_id, tier=body.tier)

        return {
            "workspace_id": workspace_id,
            "status": "provisioning",
            "url": url,
            "namespace": ns_name,
            "tier": body.tier,
            "workspace_type": body.workspace_type,
        }

    except ApiException as exc:
        logger.error("workspace_provision_failed",
                     workspace_id=workspace_id, error=str(exc), tenant_id=x_tenant_id)
        raise HTTPException(status_code=exc.status or 500, detail=exc.reason or str(exc)) from exc


@app.get("/api/v1/workspaces/{workspace_id}", summary="Get workspace status (S4-01)")
async def get_workspace_status(
    workspace_id: str,
    x_tenant_id: str = Header(..., alias="X-Tenant-ID"),
) -> Dict[str, Any]:
    """Get workspace status and URL."""
    _get_conn(x_tenant_id)
    ns_name = f"{E_NAMESPACE_PREFIX}{workspace_id}"
    v1 = _load_k8s_config()

    try:
        ns = v1.read_namespace(name=ns_name)
        base_url = os.getenv("WORKSPACE_BASE_URL", "https://workspace.medinovai.local")
        url = f"{base_url}/{workspace_id}"
        return {
            "workspace_id": workspace_id,
            "status": "running",
            "url": url,
            "namespace": ns_name,
        }
    except ApiException as exc:
        if exc.status == 404:
            raise HTTPException(status_code=404, detail=f"Workspace {workspace_id} not found") from exc
        raise HTTPException(status_code=exc.status or 500, detail=exc.reason or str(exc)) from exc


@app.delete("/api/v1/workspaces/{workspace_id}", summary="Terminate workspace (S4-01)")
async def terminate_workspace(
    workspace_id: str,
    x_tenant_id: str = Header(..., alias="X-Tenant-ID"),
) -> Dict[str, Any]:
    """Terminate workspace by deleting its namespace."""
    _get_conn(x_tenant_id)
    ns_name = f"{E_NAMESPACE_PREFIX}{workspace_id}"
    v1 = _load_k8s_config()

    try:
        v1.delete_namespace(name=ns_name)
        logger.info("workspace_terminated", workspace_id=workspace_id, ns=ns_name, tenant_id=x_tenant_id)
        return {"workspace_id": workspace_id, "status": "terminated"}
    except ApiException as exc:
        if exc.status == 404:
            return {"workspace_id": workspace_id, "status": "not_found"}
        raise HTTPException(status_code=exc.status or 500, detail=exc.reason or str(exc)) from exc


@app.get("/api/v1/workspaces", summary="List workspaces for tenant (S4-01)")
async def list_workspaces(
    x_tenant_id: str = Header(..., alias="X-Tenant-ID"),
) -> Dict[str, Any]:
    """List all workspaces for the tenant (namespaces with medinovai-ws- prefix)."""
    _get_conn(x_tenant_id)
    v1 = _load_k8s_config()

    try:
        ns_list = v1.list_namespace()
        workspaces = []
        for ns in ns_list.items:
            if not ns.metadata.name.startswith(E_NAMESPACE_PREFIX):
                continue
            tenant = (ns.metadata.labels or {}).get("medinovai/tenant-id", "")
            if tenant != x_tenant_id:
                continue
            ws_id = ns.metadata.name.replace(E_NAMESPACE_PREFIX, "")
            base_url = os.getenv("WORKSPACE_BASE_URL", "https://workspace.medinovai.local")
            workspaces.append({
                "workspace_id": ws_id,
                "namespace": ns.metadata.name,
                "status": "running",
                "url": f"{base_url}/{ws_id}",
            })
        return {"workspaces": workspaces, "tenant_id": x_tenant_id}
    except ApiException as exc:
        raise HTTPException(status_code=exc.status or 500, detail=exc.reason or str(exc)) from exc


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8080)
