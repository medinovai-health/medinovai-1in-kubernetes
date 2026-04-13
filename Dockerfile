# Dockerfile — medinovai-1in-kubernetes
# Build: 20260413.2500.001 | © 2026 DescartesBio / MedinovAI Health.
# Multi-stage build for minimal production image

FROM python:3.11-slim AS builder
WORKDIR /app
COPY requirements.txt* ./
RUN pip install --no-cache-dir -r requirements.txt 2>/dev/null || true
COPY . .

FROM python:3.11-slim AS runtime
WORKDIR /app
COPY --from=builder /app .
ENV NODE_ENV=production \
    ATLAS_OS_GATEWAY_URL=http://atlas-gateway:8000 \
    ZTA_AUDIT_ENABLED=true \
    MODULE_NAME=medinovai-1in-kubernetes \
    BUILD=20260413.2500.001
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
CMD ["python3", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
