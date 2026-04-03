"""FastAPI application factory for MedinovAI Security Service."""

import logging
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.staticfiles import StaticFiles

from app.config import get_settings
from app.routers import (
    agents,
    audit,
    auth,
    break_glass,
    field_security,
    health,
    policy,
    rbac,
    seed,
    sensitive,
    temporal,
    tenant_rules,
    token_validator,
    zero_touch,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(name)s %(levelname)s %(message)s",
)


def create_app() -> FastAPI:
    settings = get_settings()

    app = FastAPI(
        title="MedinovAI Security Service",
        version=settings.version,
        description=(
            "Authorization, identity, and security"
            " platform for MedinovAI."
        ),
        docs_url="/docs",
        redoc_url="/redoc",
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(health.router)
    app.include_router(auth.router)
    app.include_router(token_validator.router)
    app.include_router(policy.router)
    app.include_router(break_glass.router)
    app.include_router(audit.router)
    app.include_router(rbac.router)
    app.include_router(seed.router)
    app.include_router(temporal.router)
    app.include_router(field_security.router)
    app.include_router(zero_touch.router)
    app.include_router(sensitive.router)
    app.include_router(tenant_rules.router)
    app.include_router(agents.router)

    # Mount static files for login page
    static_dir = Path(__file__).parent / "static"
    if static_dir.exists():
        app.mount("/static", StaticFiles(directory=static_dir), name="static")

    # Login page route - serves the common login UI
    @app.get("/login", response_class=HTMLResponse)
    async def login_page(request: Request):
        """Serve the common login page for all MedinovAI services."""
        login_html = static_dir / "login.html"
        if login_html.exists():
            return HTMLResponse(content=login_html.read_text())
        return HTMLResponse(content="<h1>Login Page Not Found</h1>", status_code=404)

    # Root redirect to login
    @app.get("/")
    async def root():
        """Redirect to login page."""
        return RedirectResponse(url="/login")

    return app
