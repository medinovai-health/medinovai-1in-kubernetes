#!/usr/bin/env python3
"""
MedinovAI Security Services
Comprehensive security framework for healthcare applications
"""

import os
import uuid
import hashlib
import secrets
import logging
from datetime import datetime, timedelta
from typing import Optional, List, Dict, Any
from contextlib import asynccontextmanager

import uvicorn
from fastapi import FastAPI, HTTPException, Depends, status, Request
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from pydantic import BaseModel, EmailStr, Field
from passlib.context import CryptContext
from jose import JWTError, jwt
import redis
import asyncpg
from cryptography.fernet import Fernet
import pyotp
import qrcode
from io import BytesIO
import base64

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Security configuration
SECRET_KEY = os.getenv("SECRET_KEY", secrets.token_urlsafe(32))
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30
REFRESH_TOKEN_EXPIRE_DAYS = 7
MFA_ISSUER = "MedinovAI"

# Password hashing
pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

# JWT token security
security = HTTPBearer()

# Database and Redis connections
db_pool = None
redis_client = None

# Encryption key for sensitive data
encryption_key = os.getenv("ENCRYPTION_KEY", Fernet.generate_key())
cipher_suite = Fernet(encryption_key)

# Pydantic models
class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, max_length=50)
    email: EmailStr
    password: str = Field(..., min_length=8)
    full_name: str = Field(..., min_length=1, max_length=100)

class UserLogin(BaseModel):
    username: str
    password: str
    mfa_code: Optional[str] = None

class UserResponse(BaseModel):
    id: str
    username: str
    email: str
    full_name: str
    mfa_enabled: bool
    roles: List[str]
    is_active: bool
    created_at: datetime
    last_login: Optional[datetime]

class RoleCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)
    description: str = Field(..., max_length=200)
    permissions: List[str]

class PermissionCreate(BaseModel):
    resource: str = Field(..., min_length=1, max_length=100)
    action: str = Field(..., min_length=1, max_length=50)
    conditions: Optional[Dict[str, Any]] = None

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int

class MFAEnableResponse(BaseModel):
    qr_code: str
    backup_codes: List[str]

class AuditLogResponse(BaseModel):
    id: str
    user_id: Optional[str]
    action: str
    resource: str
    resource_id: Optional[str]
    ip_address: str
    user_agent: str
    timestamp: datetime
    success: bool
    details: Optional[Dict[str, Any]]

# Database models
class User:
    def __init__(self, id: str, username: str, email: str, password_hash: str,
                 full_name: str, mfa_enabled: bool = False, mfa_secret: Optional[str] = None,
                 is_active: bool = True, is_locked: bool = False,
                 failed_login_attempts: int = 0, created_at: datetime = None,
                 updated_at: datetime = None, last_login: Optional[datetime] = None):
        self.id = id
        self.username = username
        self.email = email
        self.password_hash = password_hash
        self.full_name = full_name
        self.mfa_enabled = mfa_enabled
        self.mfa_secret = mfa_secret
        self.is_active = is_active
        self.is_locked = is_locked
        self.failed_login_attempts = failed_login_attempts
        self.created_at = created_at or datetime.utcnow()
        self.updated_at = updated_at or datetime.utcnow()
        self.last_login = last_login

class Role:
    def __init__(self, id: str, name: str, description: str, permissions: List[str],
                 is_active: bool = True, created_at: datetime = None,
                 updated_at: datetime = None):
        self.id = id
        self.name = name
        self.description = description
        self.permissions = permissions
        self.is_active = is_active
        self.created_at = created_at or datetime.utcnow()
        self.updated_at = updated_at or datetime.utcnow()

class AuditLog:
    def __init__(self, id: str, user_id: Optional[str], action: str, resource: str,
                 resource_id: Optional[str], ip_address: str, user_agent: str,
                 timestamp: datetime, success: bool, details: Optional[Dict[str, Any]] = None):
        self.id = id
        self.user_id = user_id
        self.action = action
        self.resource = resource
        self.resource_id = resource_id
        self.ip_address = ip_address
        self.user_agent = user_agent
        self.timestamp = timestamp
        self.success = success
        self.details = details or {}

# Security utilities
def hash_password(password: str) -> str:
    """Hash password using Argon2"""
    return pwd_context.hash(password)

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify password against hash"""
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """Create JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode.update({"exp": expire, "type": "access"})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def create_refresh_token(data: dict) -> str:
    """Create JWT refresh token"""
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(days=REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode.update({"exp": expire, "type": "refresh"})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def verify_token(token: str, token_type: str = "access") -> dict:
    """Verify JWT token"""
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        if payload.get("type") != token_type:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token type"
            )
        return payload
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )

def encrypt_data(data: str) -> str:
    """Encrypt sensitive data"""
    return cipher_suite.encrypt(data.encode()).decode()

def decrypt_data(encrypted_data: str) -> str:
    """Decrypt sensitive data"""
    return cipher_suite.decrypt(encrypted_data.encode()).decode()

def generate_mfa_secret() -> str:
    """Generate MFA secret for TOTP"""
    return pyotp.random_base32()

def generate_mfa_qr_code(username: str, secret: str) -> str:
    """Generate QR code for MFA setup"""
    totp_uri = pyotp.totp.TOTP(secret).provisioning_uri(
        name=username,
        issuer_name=MFA_ISSUER
    )
    
    qr = qrcode.QRCode(version=1, box_size=10, border=5)
    qr.add_data(totp_uri)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    buffer = BytesIO()
    img.save(buffer, format='PNG')
    buffer.seek(0)
    
    return base64.b64encode(buffer.getvalue()).decode()

def verify_mfa_code(secret: str, code: str) -> bool:
    """Verify MFA TOTP code"""
    totp = pyotp.TOTP(secret)
    return totp.verify(code, valid_window=1)

def generate_backup_codes() -> List[str]:
    """Generate backup codes for MFA"""
    return [secrets.token_hex(4).upper() for _ in range(10)]

# Database operations
async def init_database():
    """Initialize database connection pool"""
    global db_pool
    try:
        db_pool = await asyncpg.create_pool(
            host=os.getenv("DB_HOST", "localhost"),
            port=int(os.getenv("DB_PORT", "5432")),
            user=os.getenv("DB_USER", "medinovai"),
            password=os.getenv("DB_PASSWORD", "medinovai"),
            database=os.getenv("DB_NAME", "medinovai_security"),
            min_size=5,
            max_size=20
        )
        
        # Create tables if they don't exist
        async with db_pool.acquire() as conn:
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS users (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    username VARCHAR(50) UNIQUE NOT NULL,
                    email VARCHAR(255) UNIQUE NOT NULL,
                    password_hash VARCHAR(255) NOT NULL,
                    full_name VARCHAR(100) NOT NULL,
                    mfa_enabled BOOLEAN DEFAULT FALSE,
                    mfa_secret VARCHAR(255),
                    backup_codes TEXT[],
                    is_active BOOLEAN DEFAULT TRUE,
                    is_locked BOOLEAN DEFAULT FALSE,
                    failed_login_attempts INTEGER DEFAULT 0,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    last_login TIMESTAMP
                )
            """)
            
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS roles (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    name VARCHAR(50) UNIQUE NOT NULL,
                    description VARCHAR(200),
                    permissions TEXT[],
                    is_active BOOLEAN DEFAULT TRUE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS user_roles (
                    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
                    role_id UUID REFERENCES roles(id) ON DELETE CASCADE,
                    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    PRIMARY KEY (user_id, role_id)
                )
            """)
            
            await conn.execute("""
                CREATE TABLE IF NOT EXISTS audit_logs (
                    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
                    action VARCHAR(100) NOT NULL,
                    resource VARCHAR(100) NOT NULL,
                    resource_id VARCHAR(100),
                    ip_address INET NOT NULL,
                    user_agent TEXT,
                    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    success BOOLEAN NOT NULL,
                    details JSONB
                )
            """)
            
            # Create indexes
            await conn.execute("CREATE INDEX IF NOT EXISTS idx_users_username ON users(username)")
            await conn.execute("CREATE INDEX IF NOT EXISTS idx_users_email ON users(email)")
            await conn.execute("CREATE INDEX IF NOT EXISTS idx_audit_logs_user_id ON audit_logs(user_id)")
            await conn.execute("CREATE INDEX IF NOT EXISTS idx_audit_logs_timestamp ON audit_logs(timestamp)")
            
        logger.info("Database initialized successfully")
        
    except Exception as e:
        logger.error(f"Failed to initialize database: {e}")
        raise

async def init_redis():
    """Initialize Redis connection"""
    global redis_client
    try:
        redis_client = redis.Redis(
            host=os.getenv("REDIS_HOST", "localhost"),
            port=int(os.getenv("REDIS_PORT", "6379")),
            password=os.getenv("REDIS_PASSWORD"),
            db=int(os.getenv("REDIS_DB", "0")),
            decode_responses=True
        )
        # Test connection
        redis_client.ping()
        logger.info("Redis initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize Redis: {e}")
        raise

# Authentication dependencies
async def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)) -> User:
    """Get current authenticated user"""
    token = credentials.credentials
    payload = verify_token(token, "access")
    user_id = payload.get("sub")
    
    if user_id is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials"
        )
    
    # Get user from database
    async with db_pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT * FROM users WHERE id = $1 AND is_active = TRUE",
            user_id
        )
        
        if row is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or inactive"
            )
        
        # Get user roles
        role_rows = await conn.fetch(
            "SELECT r.name FROM roles r JOIN user_roles ur ON r.id = ur.role_id WHERE ur.user_id = $1 AND r.is_active = TRUE",
            user_id
        )
        roles = [row["name"] for row in role_rows]
        
        return User(
            id=str(row["id"]),
            username=row["username"],
            email=row["email"],
            password_hash=row["password_hash"],
            full_name=row["full_name"],
            mfa_enabled=row["mfa_enabled"],
            mfa_secret=row["mfa_secret"],
            is_active=row["is_active"],
            is_locked=row["is_locked"],
            failed_login_attempts=row["failed_login_attempts"],
            created_at=row["created_at"],
            updated_at=row["updated_at"],
            last_login=row["last_login"]
        )

async def require_permission(permission: str):
    """Decorator to require specific permission"""
    async def permission_checker(current_user: User = Depends(get_current_user)):
        # Get user permissions
        async with db_pool.acquire() as conn:
            role_rows = await conn.fetch(
                "SELECT r.permissions FROM roles r JOIN user_roles ur ON r.id = ur.role_id WHERE ur.user_id = $1 AND r.is_active = TRUE",
                current_user.id
            )
            
            user_permissions = []
            for row in role_rows:
                user_permissions.extend(row["permissions"] or [])
            
            if permission not in user_permissions:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="Insufficient permissions"
                )
        
        return current_user
    
    return permission_checker

# Audit logging
async def log_audit_event(user_id: Optional[str], action: str, resource: str,
                         resource_id: Optional[str], ip_address: str, user_agent: str,
                         success: bool, details: Optional[Dict[str, Any]] = None):
    """Log audit event"""
    try:
        async with db_pool.acquire() as conn:
            await conn.execute(
                "INSERT INTO audit_logs (user_id, action, resource, resource_id, ip_address, user_agent, success, details) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)",
                user_id, action, resource, resource_id, ip_address, user_agent, success, details
            )
    except Exception as e:
        logger.error(f"Failed to log audit event: {e}")

# FastAPI app
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    # Startup
    await init_database()
    await init_redis()
    yield
    # Shutdown
    if db_pool:
        await db_pool.close()
    if redis_client:
        redis_client.close()

app = FastAPI(
    title="MedinovAI Security Services",
    description="Comprehensive security framework for healthcare applications",
    version="1.0.0",
    lifespan=lifespan
)

# Security middleware
app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["localhost", "127.0.0.1", "*.medinovai.com"]
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["https://*.medinovai.com"],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# API endpoints
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "medinovai-security-services"}

@app.post("/auth/register", response_model=UserResponse)
async def register_user(user_data: UserCreate, request: Request):
    """Register new user"""
    try:
        # Check if user already exists
        async with db_pool.acquire() as conn:
            existing_user = await conn.fetchrow(
                "SELECT id FROM users WHERE username = $1 OR email = $2",
                user_data.username, user_data.email
            )
            
            if existing_user:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Username or email already exists"
                )
            
            # Create user
            user_id = str(uuid.uuid4())
            password_hash = hash_password(user_data.password)
            
            await conn.execute(
                "INSERT INTO users (id, username, email, password_hash, full_name) VALUES ($1, $2, $3, $4, $5)",
                user_id, user_data.username, user_data.email, password_hash, user_data.full_name
            )
            
            # Assign default role
            default_role = await conn.fetchrow("SELECT id FROM roles WHERE name = 'patient'")
            if default_role:
                await conn.execute(
                    "INSERT INTO user_roles (user_id, role_id) VALUES ($1, $2)",
                    user_id, default_role["id"]
                )
            
            # Log audit event
            await log_audit_event(
                user_id, "user_registration", "user", user_id,
                request.client.host, request.headers.get("user-agent", ""),
                True, {"username": user_data.username, "email": user_data.email}
            )
            
            # Get created user
            user_row = await conn.fetchrow("SELECT * FROM users WHERE id = $1", user_id)
            role_rows = await conn.fetch(
                "SELECT r.name FROM roles r JOIN user_roles ur ON r.id = ur.role_id WHERE ur.user_id = $1",
                user_id
            )
            roles = [row["name"] for row in role_rows]
            
            return UserResponse(
                id=str(user_row["id"]),
                username=user_row["username"],
                email=user_row["email"],
                full_name=user_row["full_name"],
                mfa_enabled=user_row["mfa_enabled"],
                roles=roles,
                is_active=user_row["is_active"],
                created_at=user_row["created_at"],
                last_login=user_row["last_login"]
            )
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Registration failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Registration failed"
        )

@app.post("/auth/login", response_model=TokenResponse)
async def login_user(login_data: UserLogin, request: Request):
    """Authenticate user and return tokens"""
    try:
        async with db_pool.acquire() as conn:
            # Get user
            user_row = await conn.fetchrow(
                "SELECT * FROM users WHERE username = $1 AND is_active = TRUE",
                login_data.username
            )
            
            if not user_row:
                await log_audit_event(
                    None, "login_failed", "user", login_data.username,
                    request.client.host, request.headers.get("user-agent", ""),
                    False, {"reason": "user_not_found"}
                )
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid credentials"
                )
            
            # Check if account is locked
            if user_row["is_locked"]:
                await log_audit_event(
                    str(user_row["id"]), "login_failed", "user", login_data.username,
                    request.client.host, request.headers.get("user-agent", ""),
                    False, {"reason": "account_locked"}
                )
                raise HTTPException(
                    status_code=status.HTTP_423_LOCKED,
                    detail="Account is locked"
                )
            
            # Verify password
            if not verify_password(login_data.password, user_row["password_hash"]):
                # Increment failed login attempts
                failed_attempts = user_row["failed_login_attempts"] + 1
                is_locked = failed_attempts >= 5
                
                await conn.execute(
                    "UPDATE users SET failed_login_attempts = $1, is_locked = $2 WHERE id = $3",
                    failed_attempts, is_locked, user_row["id"]
                )
                
                await log_audit_event(
                    str(user_row["id"]), "login_failed", "user", login_data.username,
                    request.client.host, request.headers.get("user-agent", ""),
                    False, {"reason": "invalid_password", "failed_attempts": failed_attempts}
                )
                
                raise HTTPException(
                    status_code=status.HTTP_401_UNAUTHORIZED,
                    detail="Invalid credentials"
                )
            
            # Check MFA if enabled
            if user_row["mfa_enabled"]:
                if not login_data.mfa_code:
                    raise HTTPException(
                        status_code=status.HTTP_400_BAD_REQUEST,
                        detail="MFA code required"
                    )
                
                if not verify_mfa_code(user_row["mfa_secret"], login_data.mfa_code):
                    await log_audit_event(
                        str(user_row["id"]), "login_failed", "user", login_data.username,
                        request.client.host, request.headers.get("user-agent", ""),
                        False, {"reason": "invalid_mfa_code"}
                    )
                    raise HTTPException(
                        status_code=status.HTTP_401_UNAUTHORIZED,
                        detail="Invalid MFA code"
                    )
            
            # Reset failed login attempts and update last login
            await conn.execute(
                "UPDATE users SET failed_login_attempts = 0, last_login = CURRENT_TIMESTAMP WHERE id = $1",
                user_row["id"]
            )
            
            # Create tokens
            access_token = create_access_token(data={"sub": str(user_row["id"])})
            refresh_token = create_refresh_token(data={"sub": str(user_row["id"])})
            
            # Store refresh token in Redis
            await redis_client.setex(
                f"refresh_token:{user_row['id']}",
                REFRESH_TOKEN_EXPIRE_DAYS * 24 * 60 * 60,
                refresh_token
            )
            
            # Log successful login
            await log_audit_event(
                str(user_row["id"]), "login_success", "user", login_data.username,
                request.client.host, request.headers.get("user-agent", ""),
                True, {"mfa_used": user_row["mfa_enabled"]}
            )
            
            return TokenResponse(
                access_token=access_token,
                refresh_token=refresh_token,
                expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60
            )
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Login failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Login failed"
        )

@app.post("/auth/refresh", response_model=TokenResponse)
async def refresh_token(refresh_token: str, request: Request):
    """Refresh access token"""
    try:
        # Verify refresh token
        payload = verify_token(refresh_token, "refresh")
        user_id = payload.get("sub")
        
        # Check if refresh token exists in Redis
        stored_token = await redis_client.get(f"refresh_token:{user_id}")
        if not stored_token or stored_token != refresh_token:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token"
            )
        
        # Create new access token
        access_token = create_access_token(data={"sub": user_id})
        
        # Log token refresh
        await log_audit_event(
            user_id, "token_refresh", "auth", user_id,
            request.client.host, request.headers.get("user-agent", ""),
            True
        )
        
        return TokenResponse(
            access_token=access_token,
            refresh_token=refresh_token,
            expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Token refresh failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Token refresh failed"
        )

@app.post("/auth/logout")
async def logout_user(current_user: User = Depends(get_current_user), request: Request = None):
    """Logout user and invalidate tokens"""
    try:
        # Remove refresh token from Redis
        await redis_client.delete(f"refresh_token:{current_user.id}")
        
        # Log logout
        await log_audit_event(
            current_user.id, "logout", "auth", current_user.id,
            request.client.host if request else "unknown",
            request.headers.get("user-agent", "") if request else "",
            True
        )
        
        return {"message": "Successfully logged out"}
        
    except Exception as e:
        logger.error(f"Logout failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Logout failed"
        )

@app.get("/auth/user/profile", response_model=UserResponse)
async def get_user_profile(current_user: User = Depends(get_current_user)):
    """Get current user profile"""
    # Get user roles
    async with db_pool.acquire() as conn:
        role_rows = await conn.fetch(
            "SELECT r.name FROM roles r JOIN user_roles ur ON r.id = ur.role_id WHERE ur.user_id = $1",
            current_user.id
        )
        roles = [row["name"] for row in role_rows]
    
    return UserResponse(
        id=current_user.id,
        username=current_user.username,
        email=current_user.email,
        full_name=current_user.full_name,
        mfa_enabled=current_user.mfa_enabled,
        roles=roles,
        is_active=current_user.is_active,
        created_at=current_user.created_at,
        last_login=current_user.last_login
    )

@app.post("/auth/mfa/enable", response_model=MFAEnableResponse)
async def enable_mfa(current_user: User = Depends(get_current_user), request: Request = None):
    """Enable MFA for current user"""
    try:
        # Generate MFA secret
        mfa_secret = generate_mfa_secret()
        backup_codes = generate_backup_codes()
        
        # Update user in database
        async with db_pool.acquire() as conn:
            await conn.execute(
                "UPDATE users SET mfa_secret = $1, backup_codes = $2 WHERE id = $3",
                mfa_secret, backup_codes, current_user.id
            )
        
        # Generate QR code
        qr_code = generate_mfa_qr_code(current_user.username, mfa_secret)
        
        # Log MFA enablement
        await log_audit_event(
            current_user.id, "mfa_enabled", "user", current_user.id,
            request.client.host if request else "unknown",
            request.headers.get("user-agent", "") if request else "",
            True
        )
        
        return MFAEnableResponse(
            qr_code=qr_code,
            backup_codes=backup_codes
        )
        
    except Exception as e:
        logger.error(f"MFA enablement failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="MFA enablement failed"
        )

@app.post("/auth/mfa/verify")
async def verify_mfa_setup(mfa_code: str, current_user: User = Depends(get_current_user), request: Request = None):
    """Verify MFA setup with TOTP code"""
    try:
        async with db_pool.acquire() as conn:
            user_row = await conn.fetchrow("SELECT mfa_secret FROM users WHERE id = $1", current_user.id)
            
            if not user_row or not user_row["mfa_secret"]:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="MFA not set up"
                )
            
            # Verify MFA code
            if not verify_mfa_code(user_row["mfa_secret"], mfa_code):
                await log_audit_event(
                    current_user.id, "mfa_verification_failed", "user", current_user.id,
                    request.client.host if request else "unknown",
                    request.headers.get("user-agent", "") if request else "",
                    False
                )
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid MFA code"
                )
            
            # Enable MFA
            await conn.execute(
                "UPDATE users SET mfa_enabled = TRUE WHERE id = $1",
                current_user.id
            )
            
            # Log successful MFA verification
            await log_audit_event(
                current_user.id, "mfa_verified", "user", current_user.id,
                request.client.host if request else "unknown",
                request.headers.get("user-agent", "") if request else "",
                True
            )
            
            return {"message": "MFA successfully enabled"}
            
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"MFA verification failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="MFA verification failed"
        )

@app.get("/auth/audit/logs", response_model=List[AuditLogResponse])
async def get_audit_logs(
    limit: int = 100,
    offset: int = 0,
    user_id: Optional[str] = None,
    action: Optional[str] = None,
    resource: Optional[str] = None,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    current_user: User = Depends(require_permission("audit:read"))
):
    """Get audit logs with filtering"""
    try:
        async with db_pool.acquire() as conn:
            # Build query
            query = "SELECT * FROM audit_logs WHERE 1=1"
            params = []
            param_count = 0
            
            if user_id:
                param_count += 1
                query += f" AND user_id = ${param_count}"
                params.append(user_id)
            
            if action:
                param_count += 1
                query += f" AND action = ${param_count}"
                params.append(action)
            
            if resource:
                param_count += 1
                query += f" AND resource = ${param_count}"
                params.append(resource)
            
            if start_date:
                param_count += 1
                query += f" AND timestamp >= ${param_count}"
                params.append(start_date)
            
            if end_date:
                param_count += 1
                query += f" AND timestamp <= ${param_count}"
                params.append(end_date)
            
            query += " ORDER BY timestamp DESC LIMIT $1 OFFSET $2"
            params.extend([limit, offset])
            
            rows = await conn.fetch(query, *params)
            
            return [
                AuditLogResponse(
                    id=str(row["id"]),
                    user_id=str(row["user_id"]) if row["user_id"] else None,
                    action=row["action"],
                    resource=row["resource"],
                    resource_id=row["resource_id"],
                    ip_address=str(row["ip_address"]),
                    user_agent=row["user_agent"],
                    timestamp=row["timestamp"],
                    success=row["success"],
                    details=row["details"]
                )
                for row in rows
            ]
            
    except Exception as e:
        logger.error(f"Failed to get audit logs: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Failed to get audit logs"
        )

if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info"
    )
