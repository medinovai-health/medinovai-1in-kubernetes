# vault.py — medinovai-1in-kubernetes
# Build: 20260413.2800.001 | © 2026 DescartesBio / MedinovAI Health.
import os
import httpx
from functools import lru_cache

VAULT_ADDR = os.getenv("VAULT_ADDR", "http://vault.tailnet.medinovai:8200")
VAULT_TOKEN = os.getenv("VAULT_TOKEN", "")

@lru_cache(maxsize=128)
def get_secret(secret_path: str, key: str = None) -> str:
    """
    Retrieves a secret from HashiCorp Vault (running on Tailscale).
    Uses v1 KV engine format by default.
    """
    if not VAULT_TOKEN:
        # Fallback to local env var for local dev
        return os.getenv(key) if key else None

    url = f"{VAULT_ADDR}/v1/secret/data/{secret_path}"
    headers = {"X-Vault-Token": VAULT_TOKEN}
    
    try:
        response = httpx.get(url, headers=headers, timeout=3.0)
        response.raise_for_status()
        data = response.json().get("data", {}).get("data", {})
        return data.get(key) if key else data
    except Exception as e:
        print(f"Vault retrieval failed for {secret_path}: {e}")
        return os.getenv(key) if key else None
