#!/usr/bin/env python3
"""
MedinovAI Service Template
Template for all dependent services that must use data-services
"""

import os
import logging
from fastapi import FastAPI, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
import httpx
import uvicorn

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(
    title="MedinovAI Service Template",
    description="Template for dependent services that use data-services",
    version="1.0.0"
)

security = HTTPBearer()

# Configuration - MUST use data-services
DATA_SERVICES_URL = os.getenv("DATA_SERVICES_URL", "http://data-services:8080")
SECURITY_SERVICE_URL = os.getenv("SECURITY_SERVICE_URL", "http://medinovai-security:8080")
SUBSCRIPTION_SERVICE_URL = os.getenv("SUBSCRIPTION_SERVICE_URL", "http://subscription:8080")
LOG_LEVEL = os.getenv("LOG_LEVEL", "info")

# Service configuration
SERVICE_NAME = os.getenv("SERVICE_NAME", "api-gateway")
DEPENDENT_SERVICE = True
USES_DATA_SERVICES = True

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": SERVICE_NAME,
        "dependent_service": DEPENDENT_SERVICE,
        "uses_data_services": USES_DATA_SERVICES,
        "data_services_url": DATA_SERVICES_URL
    }

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": f"MedinovAI {SERVICE_NAME}",
        "version": "1.0.0",
        "dependent_service": DEPENDENT_SERVICE,
        "uses_data_services": USES_DATA_SERVICES,
        "architecture": "data-services-dependent"
    }

@app.get("/data/test")
async def test_data_services_connection():
    """Test connection to data-services"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{DATA_SERVICES_URL}/health")
            if response.status_code == 200:
                return {
                    "status": "success",
                    "message": "Successfully connected to data-services",
                    "data_services_status": response.json()
                }
            else:
                raise HTTPException(status_code=503, detail="Data services unavailable")
    except Exception as e:
        logger.error(f"Data services connection error: {str(e)}")
        raise HTTPException(status_code=503, detail="Failed to connect to data-services")

@app.get("/security/test")
async def test_security_services_connection():
    """Test connection to security services"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{SECURITY_SERVICE_URL}/health")
            if response.status_code == 200:
                return {
                    "status": "success",
                    "message": "Successfully connected to security services",
                    "security_services_status": response.json()
                }
            else:
                raise HTTPException(status_code=503, detail="Security services unavailable")
    except Exception as e:
        logger.error(f"Security services connection error: {str(e)}")
        raise HTTPException(status_code=503, detail="Failed to connect to security services")

@app.get("/subscription/test")
async def test_subscription_services_connection():
    """Test connection to subscription services"""
    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{SUBSCRIPTION_SERVICE_URL}/health")
            if response.status_code == 200:
                return {
                    "status": "success",
                    "message": "Successfully connected to subscription services",
                    "subscription_services_status": response.json()
                }
            else:
                raise HTTPException(status_code=503, detail="Subscription services unavailable")
    except Exception as e:
        logger.error(f"Subscription services connection error: {str(e)}")
        raise HTTPException(status_code=503, detail="Failed to connect to subscription services")

# Example of how to use data-services for data operations
@app.get("/data/patients")
async def get_patients(credentials: HTTPAuthorizationCredentials = Depends(security)):
    """Get patients from data-services"""
    try:
        # First validate token with security service
        async with httpx.AsyncClient() as client:
            # Validate token
            auth_response = await client.get(
                f"{SECURITY_SERVICE_URL}/auth/validate",
                headers={"Authorization": f"Bearer {credentials.credentials}"}
            )
            
            if auth_response.status_code != 200:
                raise HTTPException(status_code=401, detail="Invalid token")
            
            # Get data from data-services
            data_response = await client.get(
                f"{DATA_SERVICES_URL}/api/patients",
                headers={"Authorization": f"Bearer {credentials.credentials}"}
            )
            
            if data_response.status_code == 200:
                return {
                    "status": "success",
                    "data": data_response.json(),
                    "message": "Data retrieved from data-services"
                }
            else:
                raise HTTPException(status_code=503, detail="Failed to get data from data-services")
                
    except Exception as e:
        logger.error(f"Error getting patients: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to get patients")

if __name__ == "__main__":
    uvicorn.run(
        "app:app",
        host="0.0.0.0",
        port=8080,
        log_level=LOG_LEVEL.lower(),
        reload=False
    )
