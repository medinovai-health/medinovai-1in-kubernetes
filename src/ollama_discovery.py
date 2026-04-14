# ollama_discovery.py — medinovai-1in-kubernetes
# Build: 20260413.3100.001 | © 2026 DescartesBio / MedinovAI Health.
import os
import httpx
import logging
from typing import Optional, List, Dict
from src.vault import get_secret

logger = logging.getLogger(__name__)

class OllamaTailnetDiscoverer:
    """
    Auto-discovers Ollama instances running on the Tailscale network.
    Checks heartbeat and available models before routing inference requests.
    """
    def __init__(self):
        # Known static nodes on Tailnet (MacStudio, DGX Spark)
        self.known_nodes = [
            "macstudio-ai-1.tailnet.medinovai:11434",
            "macstudio-ai-2.tailnet.medinovai:11434",
            "dgx-spark-cluster.tailnet.medinovai:11434"
        ]
        self.active_nodes = []
        
    async def ping_nodes(self):
        self.active_nodes = []
        async with httpx.AsyncClient(timeout=2.0) as client:
            for node in self.known_nodes:
                try:
                    url = f"http://{node}/api/tags"
                    response = await client.get(url)
                    if response.status_code == 200:
                        models = [m["name"] for m in response.json().get("models", [])]
                        self.active_nodes.append({"node": node, "models": models})
                        logger.debug(f"Ollama node {node} is online with {len(models)} models.")
                except Exception as e:
                    logger.debug(f"Ollama node {node} is offline or unreachable: {e}")
                    
        return self.active_nodes
        
    async def get_best_node_for_model(self, model_name: str) -> Optional[str]:
        if not self.active_nodes:
            await self.ping_nodes()
            
        for node_info in self.active_nodes:
            if model_name in node_info["models"]:
                return f"http://{node_info['node']}"
                
        # Fallback to commercial API (OpenAI/Anthropic) if local model not found
        logger.warning(f"Model {model_name} not found on Tailnet. Falling back to commercial API.")
        return None

ollama_discoverer = OllamaTailnetDiscoverer()
