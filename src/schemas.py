# schemas.py — medinovai-1in-kubernetes
# Build: 20260413.2700.001 | © 2026 DescartesBio / MedinovAI Health.
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any
from datetime import datetime

class 1inKubernetesBase(BaseModel):
    entity_id: str = Field(..., description="Unique identifier")
    status: str = Field(default="active")
    payload: Optional[Dict[str, Any]] = None
    is_phi: bool = Field(default=False)

class 1inKubernetesCreate(1inKubernetesBase):
    pass

class 1inKubernetesResponse(1inKubernetesBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True
