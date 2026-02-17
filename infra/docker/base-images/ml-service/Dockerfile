# ─── MedinovAI ML Service Base Image ──────────────────────────────────────────
# GPU-enabled base image for AI model serving.

# ── Builder stage ─────────────────────────────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /build

COPY requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ── Runtime stage (GPU-enabled) ───────────────────────────────────────────────
# NOTE: For GPU support, replace with nvidia/cuda base image:
# FROM nvidia/cuda:12.4.1-runtime-ubuntu22.04 AS runtime
FROM python:3.12-slim AS runtime

# Security: non-root user
RUN groupadd -r medinovai && useradd -r -g medinovai -d /app -s /sbin/nologin medinovai

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed packages from builder
COPY --from=builder /install /usr/local

WORKDIR /app

# Model cache directory
RUN mkdir -p /app/models && chown medinovai:medinovai /app/models

# Copy application code
COPY --chown=medinovai:medinovai . .

# Switch to non-root user
USER medinovai

# Health check (longer startup for model loading)
HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Default port
EXPOSE 8080

# Environment
ENV PYTHONUNBUFFERED=1
ENV LOG_FORMAT=json
ENV LOG_LEVEL=INFO
ENV MODEL_CACHE_DIR=/app/models

CMD ["python", "-m", "app.serve"]
