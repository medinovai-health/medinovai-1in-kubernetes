"""
Input validation module for MedinovAI API Gateway
Implements comprehensive input validation and sanitization
"""

import re
from typing import Any, Dict, Optional
from pydantic import BaseModel, validator, Field
import html
import bleach

class PatientCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100, regex=r'^[a-zA-Z\s]+$')
    age: int = Field(..., ge=0, le=150)
    gender: str = Field(..., regex=r'^(Male|Female|Other)$')
    medical_record_number: str = Field(..., min_length=1, max_length=50, regex=r'^[A-Z0-9-]+$')
    contact_info: Optional[Dict[str, Any]] = None
    
    @validator('name')
    def validate_name(cls, v):
        if not v or not v.strip():
            raise ValueError('Name cannot be empty')
        # Sanitize HTML
        v = html.escape(v.strip())
        return v
    
    @validator('medical_record_number')
    def validate_mrn(cls, v):
        if not re.match(r'^[A-Z0-9-]+$', v):
            raise ValueError('Invalid medical record number format')
        return v.upper()
    
    @validator('contact_info')
    def validate_contact_info(cls, v):
        if v:
            # Sanitize contact info
            for key, value in v.items():
                if isinstance(value, str):
                    v[key] = html.escape(value)
        return v

def sanitize_input(data: str) -> str:
    """Sanitize input data"""
    if not isinstance(data, str):
        return data
    
    # Remove HTML tags
    data = bleach.clean(data, tags=[], strip=True)
    
    # Escape HTML entities
    data = html.escape(data)
    
    return data

def validate_sql_input(data: str) -> bool:
    """Validate input for SQL injection"""
    sql_patterns = [
        r'(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|SCRIPT)\b)',
        r'(\b(OR|AND)\s+\d+\s*=\s*\d+)',
        r'(\b(OR|AND)\s+\w+\s*=\s*\w+)',
        r'(\'\s*(OR|AND)\s+\')',
        r'(\"\s*(OR|AND)\s+\")',
        r'(\;\s*(DROP|DELETE|INSERT|UPDATE))',
        r'(\-\-|\#)',
        r'(\/\*|\*\/)'
    ]
    
    for pattern in sql_patterns:
        if re.search(pattern, data, re.IGNORECASE):
            return False
    
    return True
