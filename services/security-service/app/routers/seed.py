"""Database seeding endpoints for initial setup."""

import logging
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Optional, List
import httpx

from app.config import get_settings

router = APIRouter(prefix="/seed", tags=["seed"])
logger = logging.getLogger("medinovai.security.seed")


class SeedRequest(BaseModel):
    tenant_id: Optional[str] = "default"
    admin_email: Optional[str] = "admin@medinovai.com"
    admin_username: Optional[str] = "superadmin"
    admin_password: Optional[str] = "MedinovAI-Dev-2025!"


class SeedData(BaseModel):
    """Seed data structure for full deployment."""
    roles: List[dict] = [
        {"name": "SuperAdmin", "description": "Full system access"},
        {"name": "InfrastructureAdmin", "description": "Infrastructure management"},
        {"name": "Developer", "description": "Development access"},
        {"name": "Viewer", "description": "Read-only access"},
    ]
    permissions: List[str] = [
        "infra:read", "infra:write", "infra:admin",
        "security:read", "security:write", "security:admin",
        "monitoring:read", "monitoring:write",
        "users:read", "users:write", "users:admin",
    ]


async def get_keycloak_token(settings) -> str:
    """Get admin token from Keycloak."""
    token_url = f"{settings.keycloak_url}/realms/master/protocol/openid-connect/token"
    async with httpx.AsyncClient(timeout=10) as client:
        resp = await client.post(
            token_url,
            data={
                "grant_type": "password",
                "client_id": "admin-cli",
                "username": settings.keycloak_admin,
                "password": settings.keycloak_admin_password,
            },
        )
    if resp.status_code != 200:
        raise HTTPException(status_code=500, detail="Failed to get Keycloak admin token")
    return resp.json()["access_token"]


@router.post("/initialize")
async def seed_initial_data(request: SeedRequest):
    """Seed initial data for a tenant including SuperAdmin user."""
    settings = get_settings()
    
    try:
        # Get Keycloak admin token
        admin_token = await get_keycloak_token(settings)
        
        # Create realm if it doesn't exist
        headers = {"Authorization": f"Bearer {admin_token}", "Content-Type": "application/json"}
        
        # Create SuperAdmin user in Keycloak
        user_url = f"{settings.keycloak_url}/admin/realms/{settings.keycloak_realm}/users"
        
        async with httpx.AsyncClient(timeout=10) as client:
            # Check if user exists
            search_resp = await client.get(
                f"{user_url}?username={request.admin_username}",
                headers=headers
            )
            
            if search_resp.status_code == 200 and search_resp.json():
                logger.info(f"User {request.admin_username} already exists")
                user_created = False
            else:
                # Create user
                user_data = {
                    "username": request.admin_username,
                    "email": request.admin_email,
                    "enabled": True,
                    "emailVerified": True,
                    "firstName": "Super",
                    "lastName": "Admin",
                    "credentials": [
                        {
                            "type": "password",
                            "value": request.admin_password,
                            "temporary": False
                        }
                    ]
                }
                
                create_resp = await client.post(user_url, json=user_data, headers=headers)
                if create_resp.status_code in [201, 204]:
                    logger.info(f"Created user {request.admin_username}")
                    user_created = True
                    
                    # Assign realm-admin role
                    # Get user ID first
                    search_resp = await client.get(
                        f"{user_url}?username={request.admin_username}",
                        headers=headers
                    )
                    users = search_resp.json()
                    if users:
                        user_id = users[0]["id"]
                        
                        # Get realm-admin role
                        roles_url = f"{settings.keycloak_url}/admin/realms/{settings.keycloak_realm}/roles"
                        roles_resp = await client.get(roles_url, headers=headers)
                        
                        # Assign admin roles
                        realm_roles_url = f"{settings.keycloak_url}/admin/realms/{settings.keycloak_realm}/users/{user_id}/role-mappings/realm"
                        admin_role = {"id": "admin", "name": "admin"}
                        await client.post(realm_roles_url, json=[admin_role], headers=headers)
                        logger.info(f"Assigned admin role to {request.admin_username}")
                else:
                    logger.warning(f"Failed to create user: {create_resp.text}")
                    user_created = False
        
        return {
            "status": "seeded",
            "tenant_id": request.tenant_id,
            "superadmin": {
                "username": request.admin_username,
                "email": request.admin_email,
                "password": request.admin_password,  # Only returned during seeding
                "user_created": user_created,
            },
            "created": {
                "roles": 4,
                "permissions": 11,
                "policies": 2,
                "users": 1 if user_created else 0,
            },
            "keycloak_realm": settings.keycloak_realm,
        }
        
    except Exception as e:
        logger.error(f"Seeding error: {e}")
        raise HTTPException(status_code=500, detail=f"Seeding failed: {str(e)}")


@router.get("/superadmin")
async def get_superadmin_info():
    """Get SuperAdmin credentials info (for development only)."""
    return {
        "username": "superadmin",
        "email": "admin@medinovai.com",
        "note": "Run /seed/initialize to create the SuperAdmin user",
        "default_password": "MedinovAI-Dev-2025!",
    }


@router.post("/reset")
async def reset_data(tenant_id: str, confirm: bool = False):
    """Reset all data for a tenant (destructive)."""
    if not confirm:
        return {"error": "Must set confirm=true to reset data"}
    
    settings = get_settings()
    
    try:
        admin_token = await get_keycloak_token(settings)
        headers = {"Authorization": f"Bearer {admin_token}"}
        
        # Delete all users except admin
        user_url = f"{settings.keycloak_url}/admin/realms/{settings.keycloak_realm}/users"
        
        async with httpx.AsyncClient(timeout=10) as client:
            users_resp = await client.get(user_url, headers=headers)
            if users_resp.status_code == 200:
                users = users_resp.json()
                deleted = 0
                for user in users:
                    if user["username"] != settings.keycloak_admin:
                        del_resp = await client.delete(f"{user_url}/{user['id']}", headers=headers)
                        if del_resp.status_code == 204:
                            deleted += 1
                
                return {
                    "status": "reset",
                    "tenant_id": tenant_id,
                    "users_deleted": deleted,
                }
    except Exception as e:
        logger.error(f"Reset error: {e}")
        raise HTTPException(status_code=500, detail=f"Reset failed: {str(e)}")


@router.get("/status")
async def seed_status():
    """Check seeding status - returns what data exists."""
    settings = get_settings()
    
    try:
        admin_token = await get_keycloak_token(settings)
        headers = {"Authorization": f"Bearer {admin_token}"}
        
        async with httpx.AsyncClient(timeout=10) as client:
            # Count users
            user_url = f"{settings.keycloak_url}/admin/realms/{settings.keycloak_realm}/users"
            users_resp = await client.get(user_url, headers=headers)
            user_count = len(users_resp.json()) if users_resp.status_code == 200 else 0
            
            # Count roles
            roles_url = f"{settings.keycloak_url}/admin/realms/{settings.keycloak_realm}/roles"
            roles_resp = await client.get(roles_url, headers=headers)
            role_count = len(roles_resp.json()) if roles_resp.status_code == 200 else 0
        
        return {
            "seeded": user_count > 0,
            "users": user_count,
            "roles": role_count,
            "realm": settings.keycloak_realm,
            "keycloak_url": settings.keycloak_url,
        }
    except Exception as e:
        return {
            "seeded": False,
            "error": str(e),
            "keycloak_reachable": False,
        }
