# API Reference — medinovai-1in-kubernetes

> (c) 2025 MedinovAI — Empowering human will for cure.
> Sprint 11: Documentation & API Docs

## Overview

This document provides the complete API reference for `medinovai-1in-kubernetes`, part of the MedinovAI **AI/ML Engine** layer.

## Authentication

All API endpoints require authentication via Bearer token or API key.

```
Authorization: Bearer <token>
X-API-Key: <api-key>
```

## Base URL

| Environment | URL |
|-------------|-----|
| Development | `http://localhost:8080/api/v1` |
| Staging | `https://staging.medinovai.com/medinovai-1in-kubernetes/api/v1` |
| Production | `https://api.medinovai.com/medinovai-1in-kubernetes/api/v1` |

## Endpoints

### Health Check

```
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "uptime": "24h 15m",
  "dependencies": {
    "database": "connected",
    "cache": "connected"
  }
}
```

### Service Info

```
GET /info
```

**Response:**
```json
{
  "name": "medinovai-1in-kubernetes",
  "layer": "AI/ML Engine",
  "language": "Python",
  "version": "1.0.0",
  "build": "sprint-11"
}
```

## Error Handling

All errors follow the standard MedinovAI error format:

```json
{
  "error": {
    "code": "ERR_001",
    "message": "Human-readable error description",
    "details": {},
    "timestamp": "2026-04-14T12:00:00Z",
    "requestId": "req_abc123"
  }
}
```

## Rate Limiting

| Tier | Requests/min | Burst |
|------|-------------|-------|
| Standard | 100 | 150 |
| Premium | 1000 | 1500 |
| Internal | Unlimited | N/A |

## Compliance

- HIPAA: PHI data encrypted at rest and in transit
- GDPR: Data subject rights endpoints available
- FDA 21 CFR Part 11: Audit trail on all mutations
