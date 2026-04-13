# models.py — medinovai-1in-kubernetes
# Build: 20260413.2700.001 | © 2026 DescartesBio / MedinovAI Health.
from sqlalchemy import Column, Integer, String, DateTime, Boolean, JSON
from sqlalchemy.sql import func
from .database import Base

class 1inKubernetes(Base):
    __tablename__ = "1inkubernetes_records"

    id = Column(Integer, primary_key=True, index=True)
    entity_id = Column(String(255), unique=True, index=True, nullable=False)
    status = Column(String(50), default="active")
    payload = Column(JSON, nullable=True)
    is_phi = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
