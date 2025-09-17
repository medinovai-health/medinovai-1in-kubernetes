#!/usr/bin/env python3
"""
MedinovAI API Gateway Service
A FastAPI-based API gateway for the MedinovAI healthcare platform
"""

import os
import logging
from datetime import datetime
from typing import Dict, Any, Optional
import asyncio

from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import uvicorn
import redis
import psycopg2
from psycopg2.extras import RealDictCursor
from pydantic import BaseModel
import httpx

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="MedinovAI API Gateway",
    description="API Gateway for MedinovAI Healthcare Platform",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://medinovai:medinovai123@postgres:5432/medinovai")
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379")
HEALTHLLM_URL = os.getenv("HEALTHLLM_URL", "http://healthllm:8000")

# Global variables for connections
redis_client = None
db_connection = None

# Pydantic models
class HealthResponse(BaseModel):
    status: str
    timestamp: datetime
    version: str
    services: Dict[str, str]

class PatientCreate(BaseModel):
    name: str
    age: int
    gender: str
    medical_record_number: str
    contact_info: Optional[Dict[str, Any]] = None

class PatientResponse(BaseModel):
    id: int
    name: str
    age: int
    gender: str
    medical_record_number: str
    contact_info: Optional[Dict[str, Any]] = None
    created_at: datetime
    updated_at: datetime

class AIQueryRequest(BaseModel):
    query: str
    context: Optional[str] = None
    model: Optional[str] = None

class AIQueryResponse(BaseModel):
    response: str
    model_used: str
    confidence: float
    timestamp: datetime

# Database connection
async def get_db_connection():
    global db_connection
    if db_connection is None or db_connection.closed:
        try:
            db_connection = psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor)
            logger.info("Database connection established")
        except Exception as e:
            logger.error(f"Database connection failed: {e}")
            raise HTTPException(status_code=500, detail="Database connection failed")
    return db_connection

# Redis connection
async def get_redis_client():
    global redis_client
    if redis_client is None:
        try:
            redis_client = redis.from_url(REDIS_URL)
            redis_client.ping()
            logger.info("Redis connection established")
        except Exception as e:
            logger.error(f"Redis connection failed: {e}")
            raise HTTPException(status_code=500, detail="Redis connection failed")
    return redis_client

# Startup event
@app.on_event("startup")
async def startup_event():
    """Initialize connections on startup"""
    logger.info("Starting MedinovAI API Gateway...")
    
    # Test database connection
    try:
        conn = await get_db_connection()
        with conn.cursor() as cur:
            cur.execute("SELECT 1")
        logger.info("Database connection verified")
    except Exception as e:
        logger.error(f"Database connection failed: {e}")
    
    # Test Redis connection
    try:
        redis_cli = await get_redis_client()
        redis_cli.ping()
        logger.info("Redis connection verified")
    except Exception as e:
        logger.error(f"Redis connection failed: {e}")

# Health check endpoint
@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    services_status = {}
    
    # Check database
    try:
        conn = await get_db_connection()
        with conn.cursor() as cur:
            cur.execute("SELECT 1")
        services_status["database"] = "healthy"
    except Exception as e:
        services_status["database"] = f"unhealthy: {str(e)}"
    
    # Check Redis
    try:
        redis_cli = await get_redis_client()
        redis_cli.ping()
        services_status["redis"] = "healthy"
    except Exception as e:
        services_status["redis"] = f"unhealthy: {str(e)}"
    
    # Check HealthLLM
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{HEALTHLLM_URL}/health", timeout=5.0)
            if response.status_code == 200:
                services_status["healthllm"] = "healthy"
            else:
                services_status["healthllm"] = f"unhealthy: HTTP {response.status_code}"
    except Exception as e:
        services_status["healthllm"] = f"unhealthy: {str(e)}"
    
    return HealthResponse(
        status="healthy" if all("healthy" in status for status in services_status.values()) else "degraded",
        timestamp=datetime.utcnow(),
        version="1.0.0",
        services=services_status
    )

# Root endpoint
@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "MedinovAI API Gateway",
        "version": "1.0.0",
        "status": "running",
        "timestamp": datetime.utcnow(),
        "docs": "/docs"
    }

# Patient management endpoints
@app.post("/api/v1/patients", response_model=PatientResponse)
async def create_patient(patient: PatientCreate):
    """Create a new patient"""
    try:
        conn = await get_db_connection()
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO patients (name, age, gender, medical_record_number, contact_info, created_at, updated_at)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
                RETURNING id, name, age, gender, medical_record_number, contact_info, created_at, updated_at
            """, (
                patient.name,
                patient.age,
                patient.gender,
                patient.medical_record_number,
                patient.contact_info,
                datetime.utcnow(),
                datetime.utcnow()
            ))
            result = cur.fetchone()
            conn.commit()
            
            return PatientResponse(**dict(result))
    except Exception as e:
        logger.error(f"Error creating patient: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to create patient: {str(e)}")

@app.get("/api/v1/patients", response_model=list[PatientResponse])
async def get_patients(limit: int = 100, offset: int = 0):
    """Get list of patients"""
    try:
        conn = await get_db_connection()
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, name, age, gender, medical_record_number, contact_info, created_at, updated_at
                FROM patients
                ORDER BY created_at DESC
                LIMIT %s OFFSET %s
            """, (limit, offset))
            results = cur.fetchall()
            
            return [PatientResponse(**dict(row)) for row in results]
    except Exception as e:
        logger.error(f"Error fetching patients: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch patients: {str(e)}")

@app.get("/api/v1/patients/{patient_id}", response_model=PatientResponse)
async def get_patient(patient_id: int):
    """Get a specific patient by ID"""
    try:
        conn = await get_db_connection()
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, name, age, gender, medical_record_number, contact_info, created_at, updated_at
                FROM patients
                WHERE id = %s
            """, (patient_id,))
            result = cur.fetchone()
            
            if not result:
                raise HTTPException(status_code=404, detail="Patient not found")
            
            return PatientResponse(**dict(result))
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching patient {patient_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch patient: {str(e)}")

# AI/ML endpoints
@app.post("/api/v1/ai/query", response_model=AIQueryResponse)
async def ai_query(request: AIQueryRequest):
    """Query the AI/ML service"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                f"{HEALTHLLM_URL}/api/v1/chat/completions",
                json={
                    "messages": [
                        {"role": "system", "content": "You are a medical AI assistant. Provide helpful, accurate medical information while maintaining patient privacy and HIPAA compliance."},
                        {"role": "user", "content": request.query}
                    ],
                    "model": request.model or "meditron:7b",
                    "max_tokens": 1000,
                    "temperature": 0.7
                },
                timeout=30.0
            )
            
            if response.status_code == 200:
                ai_response = response.json()
                return AIQueryResponse(
                    response=ai_response.get("choices", [{}])[0].get("message", {}).get("content", "No response"),
                    model_used=ai_response.get("model", "unknown"),
                    confidence=0.85,  # Placeholder confidence score
                    timestamp=datetime.utcnow()
                )
            else:
                raise HTTPException(status_code=response.status_code, detail="AI service error")
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="AI service timeout")
    except Exception as e:
        logger.error(f"Error querying AI service: {e}")
        raise HTTPException(status_code=500, detail=f"AI service error: {str(e)}")

# FHIR endpoint
@app.get("/fhir/metadata")
async def fhir_metadata():
    """FHIR metadata endpoint"""
    return {
        "resourceType": "CapabilityStatement",
        "status": "active",
        "date": datetime.utcnow().isoformat(),
        "publisher": "MedinovAI",
        "kind": "instance",
        "software": {
            "name": "MedinovAI FHIR Server",
            "version": "1.0.0"
        },
        "fhirVersion": "4.0.1",
        "format": ["json"],
        "rest": [
            {
                "mode": "server",
                "resource": [
                    {
                        "type": "Patient",
                        "interaction": [
                            {"code": "read"},
                            {"code": "search-type"}
                        ]
                    }
                ]
            }
        ]
    }

# Metrics endpoint
@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    # Basic metrics for now
    return {
        "medinovai_api_requests_total": 0,
        "medinovai_api_requests_duration_seconds": 0.0,
        "medinovai_database_connections_active": 1,
        "medinovai_redis_connections_active": 1
    }

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=False,
        log_level="info"
    )

