"""
Logging configuration for MedinovAI API Gateway
Implements structured logging with audit trails
"""

import logging
import json
import time
from datetime import datetime
from typing import Dict, Any

class StructuredFormatter(logging.Formatter):
    """Custom formatter for structured logging"""
    
    def format(self, record):
        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno
        }
        
        if hasattr(record, 'user_id'):
            log_entry['user_id'] = record.user_id
        
        if hasattr(record, 'request_id'):
            log_entry['request_id'] = record.request_id
        
        if record.exc_info:
            log_entry['exception'] = self.formatException(record.exc_info)
        
        return json.dumps(log_entry)

def setup_logging():
    """Setup structured logging"""
    # Create logger
    logger = logging.getLogger("medinovai_api")
    logger.setLevel(logging.INFO)
    
    # Create console handler
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    
    # Create file handler
    file_handler = logging.FileHandler("api_gateway.log")
    file_handler.setLevel(logging.INFO)
    
    # Set formatter
    formatter = StructuredFormatter()
    console_handler.setFormatter(formatter)
    file_handler.setFormatter(formatter)
    
    # Add handlers
    logger.addHandler(console_handler)
    logger.addHandler(file_handler)
    
    return logger

# Audit logging
def log_audit_event(event_type: str, user_id: str, details: Dict[str, Any]):
    """Log audit events"""
    audit_logger = logging.getLogger("audit")
    audit_logger.info(
        f"Audit event: {event_type}",
        extra={
            "event_type": event_type,
            "user_id": user_id,
            "details": details,
            "timestamp": datetime.utcnow().isoformat()
        }
    )
