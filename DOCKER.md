# Docker Deployment Guide

## Overview
Production-optimized Docker configuration (BMAD Sprint 5).

## Features
- Multi-stage build (~150MB)
- Non-root user (UID 1001)
- Health checks
- dumb-init signal handling
- Resource limits
- Read-only filesystem
- Trivy security scanning

## Quick Start
```bash
docker compose up -d
curl http://localhost:3000/health
docker compose logs -f app
```
