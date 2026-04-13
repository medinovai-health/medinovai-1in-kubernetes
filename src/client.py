# client.py — medinovai-1in-kubernetes
# Build: 20260413.2900.001 | © 2026 DescartesBio / MedinovAI Health.
import httpx
from typing import Dict, Any, Optional
from src.discovery import get_service_url

class ServiceClient:
    """
    Typed async HTTP client for inter-service communication over Tailscale.
    """
    def __init__(self, target_service: str):
        self.target_service = target_service
        self.base_url = get_service_url(target_service)
        
    async def get(self, endpoint: str, params: Optional[Dict] = None) -> Dict[str, Any]:
        async with httpx.AsyncClient() as client:
            response = await client.get(f"{self.base_url}{endpoint}", params=params)
            response.raise_for_status()
            return response.json()
            
    async def post(self, endpoint: str, payload: Dict[str, Any]) -> Dict[str, Any]:
        async with httpx.AsyncClient() as client:
            response = await client.post(f"{self.base_url}{endpoint}", json=payload)
            response.raise_for_status()
            return response.json()
