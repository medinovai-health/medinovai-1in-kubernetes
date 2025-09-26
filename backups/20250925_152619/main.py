
# Import authentication module
from auth import require_auth, create_access_token, validate_user_credentials

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

# Protect all existing endpoints with authentication
@app.get("/api/v1/patients")
@require_auth
@rate_limit(limit=100, window=60)
async def get_patients(request: Request, limit: int = 100, offset: int = 0):
    """Get list of patients - PROTECTED"""
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
        raise HTTPException(status_code=500, detail="Failed to fetch patients")

@app.post("/api/v1/patients")
@require_auth
@rate_limit(limit=100, window=60)
async def create_patient(request: Request, patient: PatientCreate):
    """Create a new patient - PROTECTED"""
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
        raise HTTPException(status_code=500, detail="Failed to create patient")

@app.get("/api/v1/patients/{patient_id}")
@require_auth
@rate_limit(limit=100, window=60)
async def get_patient(request: Request, patient_id: int):
    """Get a specific patient by ID - PROTECTED"""
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
        raise HTTPException(status_code=500, detail="Failed to fetch patient")

# Security headers middleware
@app.middleware("http")
async def add_security_headers(request: Request, call_next):
    response = await call_next(request)
    
    # Security headers
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    response.headers["Content-Security-Policy"] = "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"
    response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
    response.headers["Permissions-Policy"] = "geolocation=(), microphone=(), camera=()"
    
    return response

# Trusted host middleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
app.add_middleware(TrustedHostMiddleware, allowed_hosts=["medinovai.com", "*.medinovai.com"])

# Custom error handlers
@app.exception_handler(HTTPException)
async def http_exception_handler(request: Request, exc: HTTPException):
    """Custom HTTP exception handler"""
    logger.error(f"HTTP error: {exc.status_code} - {exc.detail}")
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "error": "Request failed",
            "message": "An error occurred processing your request",
            "status_code": exc.status_code
        }
    )

@app.exception_handler(Exception)
async def general_exception_handler(request: Request, exc: Exception):
    """General exception handler"""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={
            "error": "Internal server error",
            "message": "An unexpected error occurred",
            "status_code": 500
        }
    )
