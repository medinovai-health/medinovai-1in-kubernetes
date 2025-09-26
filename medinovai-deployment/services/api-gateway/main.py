from fastapi import FastAPI, HTTPException, Request, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import uvicorn
import logging

# Create FastAPI app
app = FastAPI(title="MedinovAI API Gateway", version="2.0.0")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import authentication module
from auth import create_access_token, validate_user_credentials, verify_token

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Security scheme
security = HTTPBearer()

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get current user from JWT token"""
    token = credentials.credentials
    try:
        payload = verify_token(token)
        return payload
    except Exception as e:
        raise HTTPException(status_code=401, detail="Invalid authentication token")

@app.get("/")
async def root():
    """Root endpoint"""
    return {"message": "MedinovAI API Gateway v2.0", "status": "healthy"}

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "api-gateway"}

# Add login endpoint
@app.post("/api/auth/login")
async def login(credentials: dict):
    """User login endpoint"""
    username = credentials.get("username")
    password = credentials.get("password")
    
    if not username or not password:
        raise HTTPException(status_code=400, detail="Username and password required")
    
    # Validate credentials
    if validate_user_credentials(username, password):
        access_token = create_access_token({"sub": username, "role": "user"})
        return {"access_token": access_token, "token_type": "bearer"}
    else:
        raise HTTPException(status_code=401, detail="Invalid credentials")

@app.get("/api/v1/patients")
async def get_patients(current_user: dict = Depends(get_current_user), limit: int = 100, offset: int = 0):
    """Get list of patients - PROTECTED"""
    logger.info(f"User {current_user.get('sub')} accessed patients endpoint")
    return {
        "patients": [
            {"id": 1, "name": "John Doe", "age": 45, "condition": "Hypertension"},
            {"id": 2, "name": "Jane Smith", "age": 32, "condition": "Diabetes"},
            {"id": 3, "name": "Bob Johnson", "age": 67, "condition": "Arthritis"}
        ], 
        "total": 3, 
        "limit": limit, 
        "offset": offset,
        "user": current_user.get('sub')
    }

@app.post("/api/v1/patients")
async def create_patient(patient: dict, current_user: dict = Depends(get_current_user)):
    """Create a new patient - PROTECTED"""
    logger.info(f"User {current_user.get('sub')} created patient: {patient.get('name', 'Unknown')}")
    return {
        "message": "Patient created successfully", 
        "patient": patient,
        "created_by": current_user.get('sub')
    }

@app.get("/api/v1/patients/{patient_id}")
async def get_patient(patient_id: int, current_user: dict = Depends(get_current_user)):
    """Get patient by ID - PROTECTED"""
    logger.info(f"User {current_user.get('sub')} accessed patient {patient_id}")
    return {
        "patient_id": patient_id, 
        "name": f"Patient {patient_id}",
        "details": "Patient medical details would be here",
        "accessed_by": current_user.get('sub')
    }

@app.get("/api/v1/dashboard")
async def get_dashboard_stats(current_user: dict = Depends(get_current_user)):
    """Get dashboard statistics - PROTECTED"""
    return {
        "total_patients": 156,
        "active_appointments": 23,
        "pending_results": 8,
        "system_alerts": 2,
        "user": current_user.get('sub'),
        "role": current_user.get('role', 'user')
    }

@app.get("/api/v1/ai/models")
async def get_ai_models(current_user: dict = Depends(get_current_user)):
    """Get available AI models - PROTECTED"""
    return {
        "models": [
            {"name": "qwen2.5:72b", "type": "large", "specialized": True},
            {"name": "deepseek-coder:latest", "type": "coding", "specialized": True},
            {"name": "codellama:34b", "type": "coding", "specialized": True},
            {"name": "llama3.1:70b", "type": "general", "specialized": False}
        ],
        "total": 55,
        "user": current_user.get('sub')
    }

@app.post("/api/v1/ai/chat")
async def ai_chat_proxy(request: dict, current_user: dict = Depends(get_current_user)):
    """Proxy AI chat requests - PROTECTED"""
    # This would proxy to the HealthLLM service
    import httpx
    
    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "http://medinovai-healthllm-enhanced:8000/api/chat",
                json=request,
                timeout=30.0
            )
            result = response.json()
            result["user"] = current_user.get('sub')
            return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI service error: {str(e)}")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)