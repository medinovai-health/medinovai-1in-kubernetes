#!/usr/bin/env python3
"""
MedinovAI UI Agent Service
FastAPI service for configurable chatbots with adaptive learning
"""

import os
import logging
from datetime import datetime
from typing import Dict, List, Optional, Any
from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import uvicorn
import asyncio

from agent_registry import (
    UIAgentRegistry, AgentType, AgentResponse,
    get_patient_agent_response, get_doctor_agent_response,
    get_admin_agent_response, get_analytics_agent_response,
    get_clinical_agent_response
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="MedinovAI UI Agent Service",
    description="Configurable chatbot system with adaptive learning and 3-step guidance",
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

# Initialize agent registry
agent_registry = UIAgentRegistry()

# Pydantic models
class ChatRequest(BaseModel):
    query: str = Field(..., description="User query")
    context: Optional[Dict[str, Any]] = Field(None, description="Additional context")
    user_id: Optional[str] = Field(None, description="User identifier")
    session_id: Optional[str] = Field(None, description="Session identifier")

class ChatResponse(BaseModel):
    primary_response: str = Field(..., description="Primary response to user query")
    next_steps: List[str] = Field(..., description="Next 3 actionable steps")
    learning_note: str = Field(..., description="What the agent learned")
    confidence_score: float = Field(..., description="Confidence score (0-1)")
    model_used: str = Field(..., description="Model used for response")
    timestamp: datetime = Field(..., description="Response timestamp")

class AgentPerformanceResponse(BaseModel):
    agent_type: str = Field(..., description="Type of agent")
    total_interactions: int = Field(..., description="Total interactions")
    successful_interactions: int = Field(..., description="Successful interactions")
    average_confidence: float = Field(..., description="Average confidence score")
    user_satisfaction: float = Field(..., description="User satisfaction score")
    learning_progress: float = Field(..., description="Learning progress score")

class HealthResponse(BaseModel):
    status: str = Field(..., description="Service status")
    timestamp: datetime = Field(..., description="Health check timestamp")
    version: str = Field(..., description="Service version")
    agents_available: List[str] = Field(..., description="Available agents")
    models_available: List[str] = Field(..., description="Available models")

# Health check endpoint
@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Health check endpoint"""
    try:
        available_agents = [agent_type.value for agent_type in AgentType]
        available_models = agent_registry.get_available_models()
        
        return HealthResponse(
            status="healthy",
            timestamp=datetime.utcnow(),
            version="1.0.0",
            agents_available=available_agents,
            models_available=available_models
        )
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        raise HTTPException(status_code=500, detail=f"Health check failed: {str(e)}")

# Patient Portal Agent endpoints
@app.post("/api/v1/agents/patient/chat", response_model=ChatResponse)
async def patient_agent_chat(request: ChatRequest):
    """Chat with patient portal agent"""
    try:
        response = await get_patient_agent_response(request.query, request.context)
        
        return ChatResponse(
            primary_response=response.primary_response,
            next_steps=response.next_steps,
            learning_note=response.learning_note,
            confidence_score=response.confidence_score,
            model_used=response.model_used,
            timestamp=response.timestamp
        )
    except Exception as e:
        logger.error(f"Patient agent chat error: {e}")
        raise HTTPException(status_code=500, detail=f"Patient agent error: {str(e)}")

# Doctor Portal Agent endpoints
@app.post("/api/v1/agents/doctor/chat", response_model=ChatResponse)
async def doctor_agent_chat(request: ChatRequest):
    """Chat with doctor portal agent"""
    try:
        response = await get_doctor_agent_response(request.query, request.context)
        
        return ChatResponse(
            primary_response=response.primary_response,
            next_steps=response.next_steps,
            learning_note=response.learning_note,
            confidence_score=response.confidence_score,
            model_used=response.model_used,
            timestamp=response.timestamp
        )
    except Exception as e:
        logger.error(f"Doctor agent chat error: {e}")
        raise HTTPException(status_code=500, detail=f"Doctor agent error: {str(e)}")

# Admin Portal Agent endpoints
@app.post("/api/v1/agents/admin/chat", response_model=ChatResponse)
async def admin_agent_chat(request: ChatRequest):
    """Chat with admin portal agent"""
    try:
        response = await get_admin_agent_response(request.query, request.context)
        
        return ChatResponse(
            primary_response=response.primary_response,
            next_steps=response.next_steps,
            learning_note=response.learning_note,
            confidence_score=response.confidence_score,
            model_used=response.model_used,
            timestamp=response.timestamp
        )
    except Exception as e:
        logger.error(f"Admin agent chat error: {e}")
        raise HTTPException(status_code=500, detail=f"Admin agent error: {str(e)}")

# Analytics Agent endpoints
@app.post("/api/v1/agents/analytics/chat", response_model=ChatResponse)
async def analytics_agent_chat(request: ChatRequest):
    """Chat with analytics agent"""
    try:
        response = await get_analytics_agent_response(request.query, request.context)
        
        return ChatResponse(
            primary_response=response.primary_response,
            next_steps=response.next_steps,
            learning_note=response.learning_note,
            confidence_score=response.confidence_score,
            model_used=response.model_used,
            timestamp=response.timestamp
        )
    except Exception as e:
        logger.error(f"Analytics agent chat error: {e}")
        raise HTTPException(status_code=500, detail=f"Analytics agent error: {str(e)}")

# Clinical Agent endpoints
@app.post("/api/v1/agents/clinical/chat", response_model=ChatResponse)
async def clinical_agent_chat(request: ChatRequest):
    """Chat with clinical agent"""
    try:
        response = await get_clinical_agent_response(request.query, request.context)
        
        return ChatResponse(
            primary_response=response.primary_response,
            next_steps=response.next_steps,
            learning_note=response.learning_note,
            confidence_score=response.confidence_score,
            model_used=response.model_used,
            timestamp=response.timestamp
        )
    except Exception as e:
        logger.error(f"Clinical agent chat error: {e}")
        raise HTTPException(status_code=500, detail=f"Clinical agent error: {str(e)}")

# Generic agent endpoint
@app.post("/api/v1/agents/{agent_type}/chat", response_model=ChatResponse)
async def generic_agent_chat(agent_type: str, request: ChatRequest):
    """Chat with any agent by type"""
    try:
        # Convert string to AgentType enum
        try:
            agent_enum = AgentType(agent_type)
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Invalid agent type: {agent_type}")
        
        response = await agent_registry.get_agent_response(agent_enum, request.query, request.context)
        
        return ChatResponse(
            primary_response=response.primary_response,
            next_steps=response.next_steps,
            learning_note=response.learning_note,
            confidence_score=response.confidence_score,
            model_used=response.model_used,
            timestamp=response.timestamp
        )
    except Exception as e:
        logger.error(f"Generic agent chat error: {e}")
        raise HTTPException(status_code=500, detail=f"Agent error: {str(e)}")

# Performance monitoring endpoints
@app.get("/api/v1/agents/performance", response_model=Dict[str, AgentPerformanceResponse])
async def get_all_agent_performance():
    """Get performance metrics for all agents"""
    try:
        performance_data = agent_registry.get_all_agent_performance()
        
        response = {}
        for agent_type, metrics in performance_data.items():
            response[agent_type] = AgentPerformanceResponse(
                agent_type=agent_type,
                total_interactions=metrics.get('total_interactions', 0),
                successful_interactions=metrics.get('successful_interactions', 0),
                average_confidence=metrics.get('average_confidence', 0.0),
                user_satisfaction=metrics.get('user_satisfaction', 0.0),
                learning_progress=metrics.get('learning_progress', 0.0)
            )
        
        return response
    except Exception as e:
        logger.error(f"Performance metrics error: {e}")
        raise HTTPException(status_code=500, detail=f"Performance metrics error: {str(e)}")

@app.get("/api/v1/agents/{agent_type}/performance", response_model=AgentPerformanceResponse)
async def get_agent_performance(agent_type: str):
    """Get performance metrics for specific agent"""
    try:
        # Convert string to AgentType enum
        try:
            agent_enum = AgentType(agent_type)
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Invalid agent type: {agent_type}")
        
        metrics = agent_registry.get_agent_performance(agent_enum)
        
        return AgentPerformanceResponse(
            agent_type=agent_type,
            total_interactions=metrics.get('total_interactions', 0),
            successful_interactions=metrics.get('successful_interactions', 0),
            average_confidence=metrics.get('average_confidence', 0.0),
            user_satisfaction=metrics.get('user_satisfaction', 0.0),
            learning_progress=metrics.get('learning_progress', 0.0)
        )
    except Exception as e:
        logger.error(f"Agent performance error: {e}")
        raise HTTPException(status_code=500, detail=f"Agent performance error: {str(e)}")

# Configuration endpoints
@app.get("/api/v1/config/models")
async def get_available_models():
    """Get list of available models"""
    try:
        models = agent_registry.get_available_models()
        return {"models": models}
    except Exception as e:
        logger.error(f"Get models error: {e}")
        raise HTTPException(status_code=500, detail=f"Get models error: {str(e)}")

@app.get("/api/v1/config/agents")
async def get_available_agents():
    """Get list of available agents"""
    try:
        agents = [agent_type.value for agent_type in AgentType]
        return {"agents": agents}
    except Exception as e:
        logger.error(f"Get agents error: {e}")
        raise HTTPException(status_code=500, detail=f"Get agents error: {str(e)}")

# Learning and feedback endpoints
class FeedbackRequest(BaseModel):
    agent_type: str = Field(..., description="Type of agent")
    interaction_id: Optional[str] = Field(None, description="Interaction identifier")
    rating: int = Field(..., ge=1, le=5, description="User rating (1-5)")
    feedback: Optional[str] = Field(None, description="User feedback text")

@app.post("/api/v1/feedback")
async def submit_feedback(request: FeedbackRequest, background_tasks: BackgroundTasks):
    """Submit user feedback for learning"""
    try:
        # Convert string to AgentType enum
        try:
            agent_enum = AgentType(request.agent_type)
        except ValueError:
            raise HTTPException(status_code=400, detail=f"Invalid agent type: {request.agent_type}")
        
        # Process feedback in background
        background_tasks.add_task(process_feedback, agent_enum, request)
        
        return {"status": "feedback_received", "message": "Thank you for your feedback"}
    except Exception as e:
        logger.error(f"Feedback submission error: {e}")
        raise HTTPException(status_code=500, detail=f"Feedback submission error: {str(e)}")

async def process_feedback(agent_type: AgentType, feedback_request: FeedbackRequest):
    """Process user feedback for learning"""
    try:
        # Log feedback for learning
        feedback_data = {
            'agent_type': agent_type.value,
            'interaction_id': feedback_request.interaction_id,
            'rating': feedback_request.rating,
            'feedback': feedback_request.feedback,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        # Store feedback in learning system
        # This would typically update the agent's learning data
        logger.info(f"Processed feedback for {agent_type.value}: {feedback_data}")
        
    except Exception as e:
        logger.error(f"Feedback processing error: {e}")

# Startup and shutdown events
@app.on_event("startup")
async def startup_event():
    """Initialize service on startup"""
    logger.info("Starting MedinovAI UI Agent Service...")
    logger.info(f"Available agents: {[agent_type.value for agent_type in AgentType]}")
    logger.info(f"Available models: {agent_registry.get_available_models()}")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("Shutting down MedinovAI UI Agent Service...")

if __name__ == "__main__":
    # Run the service
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )







