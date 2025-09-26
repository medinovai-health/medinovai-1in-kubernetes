"""
Authentication module for MedinovAI API Gateway
Implements JWT-based authentication with proper security
"""

from jose import jwt
import os
from datetime import datetime, timedelta
from functools import wraps
from fastapi import HTTPException, Request, Depends
import logging

logger = logging.getLogger(__name__)

# JWT Configuration
JWT_SECRET = os.getenv("JWT_SECRET", "medinovai-jwt-secret-change-in-production")
JWT_ALGORITHM = "HS256"
JWT_EXPIRATION = 3600  # 1 hour

def create_access_token(data: dict):
    """Create JWT access token"""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(seconds=JWT_EXPIRATION)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, JWT_SECRET, algorithm=JWT_ALGORITHM)
    return encoded_jwt

def verify_token(token: str):
    """Verify JWT token"""
    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.JWTError:
        raise HTTPException(status_code=401, detail="Invalid token")

def require_auth(f):
    """Authentication decorator"""
    @wraps(f)
    async def decorated_function(*args, **kwargs):
        # Get token from request
        request = None
        for arg in args:
            if isinstance(arg, Request):
                request = arg
                break
        
        if not request:
            raise HTTPException(status_code=401, detail="Request object not found")
        
        token = request.headers.get('Authorization')
        if not token:
            raise HTTPException(status_code=401, detail="Authorization token required")
        
        if token.startswith('Bearer '):
            token = token[7:]
        
        try:
            payload = verify_token(token)
            request.state.current_user = payload
        except HTTPException:
            raise
        
        return await f(*args, **kwargs)
    return decorated_function

def validate_user_credentials(username: str, password: str) -> bool:
    """Validate user credentials"""
    # TODO: Implement proper user validation against database
    # For now, using basic validation
    valid_users = {
        "admin": "admin123",
        "doctor": "doctor123",
        "nurse": "nurse123"
    }
    
    return valid_users.get(username) == password
