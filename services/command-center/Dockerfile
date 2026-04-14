# Dockerfile — MedinovAI Command Center v3.0
# (c) 2026 Copyright MedinovAI. All Rights Reserved.
# Multi-stage hardened build: minimal attack surface, non-root, read-only FS

# ── Stage 1: Dependencies ──────────────────────────────────────────────────
FROM node:20-alpine AS deps
LABEL org.opencontainers.image.source="https://github.com/medinovai-health/medinovai-infrastructure"
LABEL org.opencontainers.image.vendor="MedinovAI"
LABEL org.opencontainers.image.title="MedinovAI Command Center"
LABEL org.opencontainers.image.version="3.0.0"

RUN apk add --no-cache libc6-compat
WORKDIR /app
COPY ui/package.json ui/package-lock.json* ./
RUN npm ci --only=production --ignore-scripts && npm cache clean --force

# ── Stage 2: Builder ───────────────────────────────────────────────────────
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY ui/ .

# Build args for environment injection
ARG NEXT_PUBLIC_COMMAND_CENTER_VERSION=3.0.0
ARG NEXT_PUBLIC_BUILD_ID
ARG NEXT_PUBLIC_ENVIRONMENT=production

ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production
ENV NEXT_PUBLIC_COMMAND_CENTER_VERSION=${NEXT_PUBLIC_COMMAND_CENTER_VERSION}
ENV NEXT_PUBLIC_BUILD_ID=${NEXT_PUBLIC_BUILD_ID}
ENV NEXT_PUBLIC_ENVIRONMENT=${NEXT_PUBLIC_ENVIRONMENT}

RUN npm run build

# ── Stage 3: Runner (hardened) ─────────────────────────────────────────────
FROM node:20-alpine AS runner
WORKDIR /app

# Security hardening
RUN apk add --no-cache curl tini && \
    addgroup --system --gid 1001 medinovai && \
    adduser --system --uid 1001 --ingroup medinovai --no-create-home command-center

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=9443
ENV HOSTNAME=0.0.0.0

# Copy only what's needed
COPY --from=builder --chown=command-center:medinovai /app/public ./public
COPY --from=builder --chown=command-center:medinovai /app/.next/standalone ./
COPY --from=builder --chown=command-center:medinovai /app/.next/static ./.next/static

# Copy the Nexus AI Agent
COPY --chown=command-center:medinovai agent/ ./agent/

# Non-root execution
USER command-center

EXPOSE 9443

# Use tini as PID 1 for proper signal handling
ENTRYPOINT ["/sbin/tini", "--"]

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:9443/api/health || exit 1

CMD ["node", "server.js"]
