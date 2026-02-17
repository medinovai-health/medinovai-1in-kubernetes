# ─── MedinovAI Node Service Base Image ────────────────────────────────────────
# Multi-stage build with non-root user, health check, and OpenTelemetry.

# ── Builder stage ─────────────────────────────────────────────────────────────
FROM node:22-slim AS builder

WORKDIR /build

COPY package.json package-lock.json* ./
RUN npm ci --production --ignore-scripts

# ── Runtime stage ─────────────────────────────────────────────────────────────
FROM node:22-slim AS runtime

# Security: non-root user
RUN groupadd -r medinovai && useradd -r -g medinovai -d /app -s /sbin/nologin medinovai

# Install runtime dependencies only
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy node_modules from builder
COPY --from=builder /build/node_modules ./node_modules

# Copy application code
COPY --chown=medinovai:medinovai . .

# Switch to non-root user
USER medinovai

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Default port
EXPOSE 3000

# Structured logging
ENV NODE_ENV=production
ENV LOG_FORMAT=json
ENV LOG_LEVEL=info

CMD ["node", "dist/server.js"]
