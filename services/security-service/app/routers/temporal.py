"""Temporal workflow integration endpoints."""

from fastapi import APIRouter
from pydantic import BaseModel
from typing import Optional, Dict, Any

router = APIRouter(prefix="/temporal", tags=["temporal"])


class WorkflowRequest(BaseModel):
    workflow_type: str
    input_data: Optional[Dict[str, Any]] = None
    tenant_id: Optional[str] = None


@router.post("/start")
async def start_workflow(request: WorkflowRequest):
    """Start a Temporal workflow."""
    # Phase 1: Stub - would integrate with Temporal server
    return {
        "workflow_id": f"wf-{request.workflow_type}-001",
        "status": "started",
        "workflow_type": request.workflow_type,
    }


@router.get("/status/{workflow_id}")
async def get_workflow_status(workflow_id: str):
    """Get status of a running workflow."""
    return {
        "workflow_id": workflow_id,
        "status": "running",
        "progress": 50,
    }
