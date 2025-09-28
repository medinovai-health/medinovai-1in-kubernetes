# -*- coding: utf-8 -*-
"""
Secure Authentication for Api Gateway Service
EN: Secure authentication with JWT and RBAC
ES: Autenticación segura con JWT y RBAC
FR: Authentification sécurisée avec JWT et RBAC
DE: Sichere Authentifizierung mit JWT und RBAC
"""

import jwt
import time
from typing import Optional, Dict, Any
from fastapi import HTTPException, Depends, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel

class TokenData(BaseModel):
    user_id: str
    roles: list[str]
    permissions: list[str]
    aud: str
    exp: int

class SecureAuth:
    def __init__(self, secret_key: str, algorithm: str = "HS256"):
        self.secret_key = secret_key
        self.algorithm = algorithm
        self.security = HTTPBearer()
    
    def create_token(self, user_id: str, roles: list[str], permissions: list[str]) -> str:
        """Create secure JWT token with audience claim"""
        payload = {
            "user_id": user_id,
            "roles": roles,
            "permissions": permissions,
            "aud": "api-gateway",  # Audience claim
            "iat": int(time.time()),
            "exp": int(time.time()) + 3600,  # 1 hour expiry
            "iss": "medinovai-auth"  # Issuer claim
        }
        return jwt.encode(payload, self.secret_key, algorithm=self.algorithm)
    
    def verify_token(self, token: str) -> TokenData:
        """Verify JWT token with audience validation"""
        try:
            payload = jwt.decode(
                token, 
                self.secret_key, 
                algorithms=[self.algorithm],
                audience="api-gateway"  # Validate audience
            )
            return TokenData(**payload)
        except jwt.ExpiredSignatureError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token has expired"
            )
        except jwt.InvalidAudienceError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token audience"
            )
        except jwt.InvalidTokenError:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token"
            )
    
    def require_role(self, required_role: str):
        """Decorator to require specific role"""
        def role_checker(token_data: TokenData = Depends(self.get_current_user)):
            if required_role not in token_data.roles:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Role {required_role} required"
                )
            return token_data
        return role_checker
    
    def require_permission(self, required_permission: str):
        """Decorator to require specific permission"""
        def permission_checker(token_data: TokenData = Depends(self.get_current_user)):
            if required_permission not in token_data.permissions:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail=f"Permission {required_permission} required"
                )
            return token_data
        return permission_checker
    
    async def get_current_user(self, credentials: HTTPAuthorizationCredentials = Depends(HTTPBearer())) -> TokenData:
        """Get current user from token"""
        return self.verify_token(credentials.credentials)
