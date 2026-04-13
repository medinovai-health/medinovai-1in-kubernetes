# router.py — medinovai-1in-kubernetes
# Build: 20260413.2700.001 | © 2026 DescartesBio / MedinovAI Health.
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from . import models, schemas
from .database import get_db

router = APIRouter(prefix="/api/v1/1inkubernetes", tags=["1inKubernetes"])

@router.post("/", response_model=schemas.1inKubernetesResponse)
def create_record(record: schemas.1inKubernetesCreate, db: Session = Depends(get_db)):
    db_record = models.1inKubernetes(**record.model_dump())
    db.add(db_record)
    db.commit()
    db.refresh(db_record)
    return db_record

@router.get("/", response_model=List[schemas.1inKubernetesResponse])
def list_records(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    return db.query(models.1inKubernetes).offset(skip).limit(limit).all()

@router.get("/{entity_id}", response_model=schemas.1inKubernetesResponse)
def get_record(entity_id: str, db: Session = Depends(get_db)):
    record = db.query(models.1inKubernetes).filter(models.1inKubernetes.entity_id == entity_id).first()
    if not record:
        raise HTTPException(status_code=404, detail="Record not found")
    return record
