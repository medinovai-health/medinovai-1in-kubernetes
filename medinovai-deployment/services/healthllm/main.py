#!/usr/bin/env python3
"""
MedinovAI HealthLLM Service
A FastAPI-based AI/ML service for healthcare applications
"""

import os
import logging
import json
from datetime import datetime
from typing import Dict, Any, Optional, List
import asyncio

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import uvicorn
import httpx
import redis
import psycopg2
from psycopg2.extras import RealDictCursor

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="MedinovAI HealthLLM",
    description="AI/ML Service for MedinovAI Healthcare Platform",
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
OLLAMA_BASE_URL = os.getenv("OLLAMA_BASE_URL", "http://host.docker.internal:11434")
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://medinovai:medinovai123@postgres:5432/medinovai")
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379")
DEFAULT_MODELS = os.getenv("DEFAULT_MODELS", "meditron:7b,qwen2.5:72b,deepseek-coder:33b").split(",")

# Global variables
redis_client = None
db_connection = None

# Pydantic models
class HealthResponse(BaseModel):
    status: str
    timestamp: datetime
    version: str
    ollama_status: str
    available_models: List[str]

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatCompletionRequest(BaseModel):
    messages: List[ChatMessage]
    model: Optional[str] = None
    max_tokens: Optional[int] = 1000
    temperature: Optional[float] = 0.7
    stream: Optional[bool] = False

class ChatCompletionResponse(BaseModel):
    id: str
    object: str
    created: int
    model: str
    choices: List[Dict[str, Any]]
    usage: Dict[str, int]

class ModelInfo(BaseModel):
    name: str
    size: int
    digest: str
    modified_at: str

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
    logger.info("Starting MedinovAI HealthLLM Service...")
    
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
    ollama_status = "unknown"
    available_models = []
    
    # Check Ollama connection
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=5.0)
            if response.status_code == 200:
                ollama_status = "healthy"
                models_data = response.json()
                available_models = [model["name"] for model in models_data.get("models", [])]
            else:
                ollama_status = f"unhealthy: HTTP {response.status_code}"
    except Exception as e:
        ollama_status = f"unhealthy: {str(e)}"
    
    return HealthResponse(
        status="healthy" if ollama_status == "healthy" else "degraded",
        timestamp=datetime.utcnow(),
        version="1.0.0",
        ollama_status=ollama_status,
        available_models=available_models
    )

# Root endpoint
@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "MedinovAI HealthLLM Service",
        "version": "1.0.0",
        "status": "running",
        "timestamp": datetime.utcnow(),
        "docs": "/docs"
    }

# Models endpoint
@app.get("/api/v1/models")
async def list_models():
    """List available models"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{OLLAMA_BASE_URL}/api/tags", timeout=10.0)
            if response.status_code == 200:
                models_data = response.json()
                models = []
                for model in models_data.get("models", []):
                    models.append(ModelInfo(
                        name=model["name"],
                        size=model.get("size", 0),
                        digest=model.get("digest", ""),
                        modified_at=model.get("modified_at", "")
                    ))
                return {"data": models}
            else:
                raise HTTPException(status_code=response.status_code, detail="Failed to fetch models")
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Ollama service timeout")
    except Exception as e:
        logger.error(f"Error fetching models: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch models: {str(e)}")

# Chat completions endpoint
@app.post("/api/v1/chat/completions", response_model=ChatCompletionResponse)
async def chat_completions(request: ChatCompletionRequest):
    """Chat completions endpoint"""
    try:
        # Use default model if not specified
        model = request.model or DEFAULT_MODELS[0]
        
        # Prepare messages for Ollama
        messages = [{"role": msg.role, "content": msg.content} for msg in request.messages]
        
        # Call Ollama API
        async with httpx.AsyncClient() as client:
            ollama_request = {
                "model": model,
                "messages": messages,
                "stream": request.stream,
                "options": {
                    "temperature": request.temperature,
                    "num_predict": request.max_tokens
                }
            }
            
            response = await client.post(
                f"{OLLAMA_BASE_URL}/api/chat",
                json=ollama_request,
                timeout=60.0
            )
            
            if response.status_code == 200:
                ollama_response = response.json()
                
                # Log the interaction to database
                await log_ai_interaction(
                    query=messages[-1]["content"] if messages else "",
                    response=ollama_response.get("message", {}).get("content", ""),
                    model_used=model
                )
                
                # Format response to match OpenAI API
                return ChatCompletionResponse(
                    id=f"chatcmpl-{datetime.utcnow().timestamp()}",
                    object="chat.completion",
                    created=int(datetime.utcnow().timestamp()),
                    model=model,
                    choices=[{
                        "index": 0,
                        "message": {
                            "role": "assistant",
                            "content": ollama_response.get("message", {}).get("content", "")
                        },
                        "finish_reason": "stop"
                    }],
                    usage={
                        "prompt_tokens": 0,
                        "completion_tokens": 0,
                        "total_tokens": 0
                    }
                )
            else:
                raise HTTPException(status_code=response.status_code, detail="Ollama service error")
    except httpx.TimeoutException:
        raise HTTPException(status_code=504, detail="Ollama service timeout")
    except Exception as e:
        logger.error(f"Error in chat completions: {e}")
        raise HTTPException(status_code=500, detail=f"Chat completion error: {str(e)}")

# Log AI interaction to database
async def log_ai_interaction(query: str, response: str, model_used: str):
    """Log AI interaction to database for audit purposes"""
    try:
        conn = await get_db_connection()
        with conn.cursor() as cur:
            cur.execute("""
                INSERT INTO ai_interactions (query, response, model_used, confidence_score, created_at)
                VALUES (%s, %s, %s, %s, %s)
            """, (query, response, model_used, 0.85, datetime.utcnow()))
            conn.commit()
    except Exception as e:
        logger.error(f"Failed to log AI interaction: {e}")

# Get AI interactions history
@app.get("/api/v1/interactions")
async def get_interactions(limit: int = 100, offset: int = 0):
    """Get AI interactions history"""
    try:
        conn = await get_db_connection()
        with conn.cursor() as cur:
            cur.execute("""
                SELECT id, query, response, model_used, confidence_score, created_at
                FROM ai_interactions
                ORDER BY created_at DESC
                LIMIT %s OFFSET %s
            """, (limit, offset))
            results = cur.fetchall()
            
            return {"interactions": [dict(row) for row in results]}
    except Exception as e:
        logger.error(f"Error fetching interactions: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch interactions: {str(e)}")

# Metrics endpoint
@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    try:
        conn = await get_db_connection()
        with conn.cursor() as cur:
            cur.execute("SELECT COUNT(*) as total_interactions FROM ai_interactions")
            result = cur.fetchone()
            total_interactions = result["total_interactions"] if result else 0
        
        return {
            "medinovai_healthllm_requests_total": total_interactions,
            "medinovai_healthllm_requests_duration_seconds": 0.0,
            "medinovai_healthllm_ollama_connected": 1 if await check_ollama_health() else 0
        }
    except Exception as e:
        logger.error(f"Error generating metrics: {e}")
        return {
            "medinovai_healthllm_requests_total": 0,
            "medinovai_healthllm_requests_duration_seconds": 0.0,
            "medinovai_healthllm_ollama_connected": 0
        }

# Check Ollama health
async def check_ollama_health():
    """Check if Ollama is healthy"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{OLLAMA_BASE_URL}/api/version", timeout=5.0)
            return response.status_code == 200
    except:
        return False

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=False,
        log_level="info"
    )

