"""Application configuration via environment variables."""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    service_name: str = "medinovai-security-service"
    version: str = "1.0.0"
    debug: bool = False

    database_url: str = "postgresql+asyncpg://postgres:postgres123@localhost:5432/security"
    redis_url: str = "redis://:redis123@localhost:6379/0"

    # Keycloak Integration - Uses in-cluster Keycloak service
    keycloak_url: str = "http://medinovai-keycloak.medinovai-security:8080"
    keycloak_realm: str = "medinovai"
    keycloak_admin: str = "admin"
    keycloak_admin_password: str = ""

    # Ollama (Tailscale network only - no external AI APIs)
    registry_url: str = "http://medinovai-registry.medinovai:8000"
    aifactory_url: str = "http://100.106.54.9:8082/v1"
    use_local_ollama_only: bool = True

    jwt_algorithm: str = "RS256"
    access_token_ttl_seconds: int = 300
    token_cache_ttl_seconds: int = 300
    permission_cache_ttl_seconds: int = 300
    field_policy_cache_ttl_seconds: int = 600

    port: int = 8000
    host: str = "0.0.0.0"


@lru_cache
def get_settings() -> Settings:
    return Settings()
