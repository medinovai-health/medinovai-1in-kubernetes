"""
Rate limiting module for MedinovAI API Gateway
Implements rate limiting to prevent abuse and DoS attacks
"""

import time
from collections import defaultdict, deque
from fastapi import Request, HTTPException
import logging

logger = logging.getLogger(__name__)

class RateLimiter:
    def __init__(self):
        self.requests = defaultdict(deque)
    
    def is_allowed(self, key: str, limit: int, window: int) -> bool:
        """Check if request is allowed based on rate limit"""
        now = time.time()
        
        # Clean old requests
        while self.requests[key] and self.requests[key][0] <= now - window:
            self.requests[key].popleft()
        
        # Check if under limit
        if len(self.requests[key]) < limit:
            self.requests[key].append(now)
            return True
        
        return False

# Global rate limiter instance
rate_limiter = RateLimiter()

def rate_limit(limit: int = 100, window: int = 60):
    """Rate limiting decorator"""
    def decorator(func):
        async def wrapper(request: Request, *args, **kwargs):
            # Get client IP
            client_ip = request.client.host
            
            # Check rate limit
            if not rate_limiter.is_allowed(client_ip, limit, window):
                raise HTTPException(
                    status_code=429,
                    detail="Rate limit exceeded. Please try again later."
                )
            
            return await func(request, *args, **kwargs)
        return wrapper
    return decorator
