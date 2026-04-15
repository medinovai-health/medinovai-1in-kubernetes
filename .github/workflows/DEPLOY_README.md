# MedinovAI AIFactory Deploy — Reusable Workflow

## Overview

The `deploy-to-aifactory.yml` reusable workflow enables any repo in the `medinovai-health` org
to deploy to the AIFactory MacStudio with just 3 lines of YAML.

## Usage

Add this to your repo's `.github/workflows/cd.yml`:

```yaml
name: CD — Deploy to AIFactory

on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    uses: medinovai-health/medinovai-infrastructure/.github/workflows/deploy-to-aifactory.yml@main
    with:
      service_name: "My Service Name"
      port: 8080
    secrets: inherit
```

## Parameters

| Parameter | Required | Default | Description |
|-----------|----------|---------|-------------|
| `service_name` | ✓ | — | Human-readable service name |
| `port` | ✓ | — | Port the service runs on |
| `deploy_dir` | ✗ | repo name | Directory under `~/aifactory/deployments/` |
| `health_path` | ✗ | `/api/health` | Health check endpoint path |
| `compose_file` | ✗ | `docker-compose.yml` | Docker Compose file name |
| `timeout_minutes` | ✗ | `30` | Deployment timeout |

## Required Org Secrets

These must be set in the `medinovai-health` GitHub org settings:

- `TS_OAUTH_CLIENT_ID` — Tailscale OAuth client ID
- `TS_OAUTH_CLIENT_SECRET` — Tailscale OAuth client secret
- `MACSTUDIO_TS_IP` — MacStudio Tailscale IP address
- `MACSTUDIO_USER` — MacStudio SSH username
- `MACSTUDIO_SSH_KEY` — MacStudio SSH private key

## What It Does

1. Checks out the repo
2. Extracts version from `package.json`, `pyproject.toml`, or `Cargo.toml`
3. Connects to Tailscale VPN
4. SSH into MacStudio AIFactory
5. Clones/pulls the repo to `~/aifactory/deployments/<deploy_dir>/`
6. Runs `docker compose up -d --build`
7. Waits up to 3 minutes for health check to pass
8. Writes deployment summary to GitHub Actions

## Prerequisites

Each repo must have:
- A `docker-compose.yml` (or custom compose file) at the repo root
- A health check endpoint (default: `/api/health`)
- The service listening on the specified port

## Port Registry

See the [Port Registry](../../services/command-center/PORT_REGISTRY.md) for allocated ports.
