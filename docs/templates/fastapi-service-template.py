"""
MedinovAI FastAPI Service Template
Healthcare-compliant microservice template with AI integration

Usage:
1. Replace [SERVICE_NAME] with your service name
2. Replace [PORT] with assigned port from range
3. Implement specific healthcare business logic
4. Add service-specific models and endpoints
"""

from fastapi import FastAPI, HTTPException, Depends, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from typing import Optional, List, Dict, Any
import uvicorn
import structlog
import httpx
import os
from datetime import datetime, timedelta
import json

# Configure structured logging
structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.JSONRenderer()
    ],
    wrapper_class=structlog.stdlib.BoundLogger,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

logger = structlog.get_logger()

# Configuration
class Settings:
    SERVICE_NAME: str = "[SERVICE_NAME]"
    SERVICE_VERSION: str = "2.0.0"
    SERVICE_PORT: int = [PORT]
    
    # Database Configuration
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql://user:pass@localhost/medinovai")
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379")
    
    # AI Configuration
    OLLAMA_BASE_URL: str = os.getenv("OLLAMA_BASE_URL", "http://ollama:11434")
    DEFAULT_AI_MODEL: str = "qwen2.5:32b"
    
    # Security Configuration
    JWT_SECRET_KEY: str = os.getenv("JWT_SECRET_KEY", "your-secret-key-here")
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    
    # CORS Configuration
    CORS_ORIGINS: List[str] = [
        "https://*.medinovai.local",
        "https://medinovai.local",
        "http://localhost:3000",  # Development
    ]

settings = Settings()

# FastAPI Application
app = FastAPI(
    title=f"MedinovAI {settings.SERVICE_NAME}",
    version=settings.SERVICE_VERSION,
    description="Healthcare-compliant microservice with AI integration",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "PATCH"],
    allow_headers=["*"],
)

# Security
security = HTTPBearer()

# Pydantic Models
class HealthCheck(BaseModel):
    status: str = Field(..., description="Service health status")
    service: str = Field(..., description="Service name")
    version: str = Field(..., description="Service version")
    timestamp: datetime = Field(default_factory=datetime.utcnow)
    dependencies: Dict[str, str] = Field(default_factory=dict)

class ErrorResponse(BaseModel):
    error: str = Field(..., description="Error message")
    detail: Optional[str] = Field(None, description="Error details")
    code: str = Field(..., description="Error code")
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class AIRequest(BaseModel):
    message: str = Field(..., description="Message for AI processing")
    model: Optional[str] = Field(None, description="AI model to use")
    context: Optional[str] = Field(None, description="Additional context")

class AIResponse(BaseModel):
    response: str = Field(..., description="AI response")
    model: str = Field(..., description="Model used")
    status: str = Field(..., description="Response status")
    timestamp: datetime = Field(default_factory=datetime.utcnow)

# Authentication and Authorization
def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> Dict[str, Any]:
    """Get current user from JWT token"""
    # TODO: Implement JWT token verification
    # This is a placeholder - implement actual JWT verification
    token = credentials.credentials
    
    # Mock user for template - replace with actual JWT verification
    return {
        "sub": "user123",
        "role": "healthcare_professional",
        "permissions": ["read_patients", "write_patients"]
    }

def require_healthcare_role(current_user: Dict = Depends(get_current_user)) -> Dict[str, Any]:
    """Require healthcare professional role"""
    allowed_roles = ["doctor", "nurse", "pharmacist", "healthcare_professional", "admin"]
    user_role = current_user.get("role", "")
    
    if user_role not in allowed_roles:
        logger.warning(
            "Unauthorized access attempt",
            user_id=current_user.get("sub"),
            role=user_role,
            required_roles=allowed_roles
        )
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Healthcare professional access required"
        )
    
    return current_user

# AI Service Integration
class AIService:
    """Healthcare AI service integration"""
    
    def __init__(self):
        self.base_url = settings.OLLAMA_BASE_URL
        self.default_model = settings.DEFAULT_AI_MODEL
    
    async def chat_completion(
        self, 
        message: str, 
        model: Optional[str] = None,
        healthcare_context: bool = True
    ) -> Dict[str, Any]:
        """Send chat completion request with healthcare context"""
        
        model = model or self.default_model
        
        # Healthcare-specific system prompt
        system_prompt = """You are MedinovAI, a healthcare AI assistant. 
        Provide accurate, evidence-based medical information.
        Always recommend consulting healthcare professionals for medical decisions.
        Maintain HIPAA compliance and patient confidentiality.
        Include appropriate medical disclaimers in your responses."""
        
        if healthcare_context:
            prompt = f"System: {system_prompt}\n\nHuman: {message}\n\nAssistant:"
        else:
            prompt = message
        
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    f"{self.base_url}/api/generate",
                    json={
                        "model": model,
                        "prompt": prompt,
                        "stream": False,
                        "options": {
                            "temperature": 0.7,
                            "top_p": 0.9,
                            "num_ctx": 2048,
                            "num_predict": 512
                        }
                    }
                )
                
                if response.status_code == 200:
                    result = response.json()
                    return {
                        "response": result.get("response", "").strip(),
                        "model": model,
                        "status": "success"
                    }
                else:
                    logger.error(
                        "AI service error",
                        status_code=response.status_code,
                        response=response.text
                    )
                    raise HTTPException(
                        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                        detail="AI service temporarily unavailable"
                    )
                    
        except httpx.TimeoutException:
            logger.warning("AI service timeout", model=model)
            # Return fallback response
            return {
                "response": self._get_fallback_response(message),
                "model": f"{model} (fallback)",
                "status": "timeout_fallback"
            }
        except Exception as e:
            logger.error("AI service error", error=str(e))
            return {
                "response": "I apologize, but I'm currently experiencing technical difficulties. Please consult with a healthcare professional for medical concerns.",
                "model": model,
                "status": "error"
            }
    
    def _get_fallback_response(self, message: str) -> str:
        """Generate fallback response when AI is unavailable"""
        message_lower = message.lower()
        
        if any(word in message_lower for word in ['emergency', 'urgent', 'chest pain', 'difficulty breathing']):
            return "This appears to be an urgent medical concern. Please seek immediate medical attention or call emergency services (911)."
        
        elif any(word in message_lower for word in ['medication', 'drug', 'prescription']):
            return "For medication-related questions, please consult with a healthcare professional or pharmacist. Never stop or change medications without medical supervision."
        
        else:
            return "I'm currently experiencing high load and cannot provide my full analysis. For medical concerns, please consult with a qualified healthcare professional."

ai_service = AIService()

# Exception Handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """Handle HTTP exceptions with structured logging"""
    logger.warning(
        "HTTP exception",
        status_code=exc.status_code,
        detail=exc.detail,
        path=request.url.path,
        method=request.method
    )
    
    return JSONResponse(
        status_code=exc.status_code,
        content=ErrorResponse(
            error="HTTP Error",
            detail=exc.detail,
            code=f"HTTP_{exc.status_code}"
        ).dict()
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """Handle general exceptions with structured logging"""
    logger.error(
        "Unhandled exception",
        error=str(exc),
        path=request.url.path,
        method=request.method,
        exc_info=True
    )
    
    return JSONResponse(
        status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
        content=ErrorResponse(
            error="Internal Server Error",
            detail="An unexpected error occurred",
            code="INTERNAL_ERROR"
        ).dict()
    )

# Health Check Endpoints
@app.get("/", response_model=Dict[str, Any])
async def root():
    """Root endpoint with service information"""
    return {
        "message": f"MedinovAI {settings.SERVICE_NAME} v{settings.SERVICE_VERSION}",
        "status": "healthy",
        "service": settings.SERVICE_NAME,
        "version": settings.SERVICE_VERSION,
        "documentation": "/docs",
        "health_check": "/health"
    }

@app.get("/health", response_model=HealthCheck)
async def health_check():
    """Kubernetes health check endpoint"""
    dependencies = {}
    
    # Check AI service availability
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(f"{settings.OLLAMA_BASE_URL}/api/tags")
            dependencies["ollama"] = "connected" if response.status_code == 200 else "disconnected"
    except:
        dependencies["ollama"] = "disconnected"
    
    # TODO: Add database health check
    dependencies["database"] = "unknown"  # Replace with actual DB check
    dependencies["redis"] = "unknown"     # Replace with actual Redis check
    
    return HealthCheck(
        status="healthy",
        service=settings.SERVICE_NAME,
        version=settings.SERVICE_VERSION,
        dependencies=dependencies
    )

@app.get("/ready")
async def readiness_check():
    """Kubernetes readiness check endpoint"""
    # TODO: Add readiness checks for dependencies
    return {"status": "ready", "service": settings.SERVICE_NAME}

# AI Integration Endpoints
@app.post("/api/v1/ai/chat", response_model=AIResponse)
async def ai_chat(
    request: AIRequest,
    current_user: Dict = Depends(require_healthcare_role)
):
    """AI chat endpoint for healthcare professionals"""
    
    logger.info(
        "AI chat request",
        user_id=current_user.get("sub"),
        model=request.model or settings.DEFAULT_AI_MODEL,
        message_length=len(request.message)
    )
    
    if not request.message.strip():
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Message is required"
        )
    
    result = await ai_service.chat_completion(
        message=request.message,
        model=request.model
    )
    
    # Log AI interaction for audit
    logger.info(
        "AI interaction completed",
        user_id=current_user.get("sub"),
        model=result["model"],
        status=result["status"],
        audit_event=True
    )
    
    return AIResponse(
        response=result["response"],
        model=result["model"],
        status=result["status"]
    )

# Service-Specific Endpoints (TODO: Implement based on service requirements)
@app.get("/api/v1/[resource]")
async def list_resources(
    limit: int = 100,
    offset: int = 0,
    current_user: Dict = Depends(require_healthcare_role)
):
    """List resources with pagination"""
    # TODO: Implement resource listing logic
    logger.info(
        "Resource list request",
        user_id=current_user.get("sub"),
        limit=limit,
        offset=offset
    )
    
    return {
        "resources": [],  # TODO: Replace with actual data
        "total": 0,
        "limit": limit,
        "offset": offset,
        "user": current_user.get("sub")
    }

@app.post("/api/v1/[resource]")
async def create_resource(
    resource_data: Dict[str, Any],
    current_user: Dict = Depends(require_healthcare_role)
):
    """Create new resource"""
    # TODO: Implement resource creation logic
    logger.info(
        "Resource creation request",
        user_id=current_user.get("sub"),
        resource_type="[resource]",
        audit_event=True
    )
    
    return {
        "message": "Resource created successfully",
        "resource": resource_data,
        "created_by": current_user.get("sub"),
        "created_at": datetime.utcnow().isoformat()
    }

@app.get("/api/v1/[resource]/{resource_id}")
async def get_resource(
    resource_id: str,
    current_user: Dict = Depends(require_healthcare_role)
):
    """Get specific resource by ID"""
    # TODO: Implement resource retrieval logic
    logger.info(
        "Resource access",
        user_id=current_user.get("sub"),
        resource_id=resource_id,
        resource_type="[resource]",
        audit_event=True
    )
    
    return {
        "resource_id": resource_id,
        "resource_type": "[resource]",
        "data": {},  # TODO: Replace with actual data
        "accessed_by": current_user.get("sub"),
        "accessed_at": datetime.utcnow().isoformat()
    }

# Metrics endpoint for Prometheus
@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    # TODO: Implement Prometheus metrics collection
    # For now, return basic metrics
    metrics_data = f"""
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total{{method="GET",endpoint="/health",status="200"}} 1

# HELP service_info Service information
# TYPE service_info gauge
service_info{{service="{settings.SERVICE_NAME}",version="{settings.SERVICE_VERSION}"}} 1
"""
    return metrics_data

if __name__ == "__main__":
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=settings.SERVICE_PORT,
        log_config={
            "version": 1,
            "disable_existing_loggers": False,
            "formatters": {
                "default": {
                    "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s",
                },
            },
            "handlers": {
                "default": {
                    "formatter": "default",
                    "class": "logging.StreamHandler",
                    "stream": "ext://sys.stdout",
                },
            },
            "root": {
                "level": "INFO",
                "handlers": ["default"],
            },
        }
    )
