# Dockerfile — MedinovAI Command Center v3.0
# (c) 2026 Copyright MedinovAI. All Rights Reserved.
# Multi-stage build: builder → production
# Build context: services/command-center/ui/ (set in docker-compose.yml)
# ── Stage 1: Builder (install all deps + build) ───────────────────────────
FROM node:20-alpine AS builder
RUN apk add --no-cache libc6-compat
WORKDIR /app
# Context is ./ui, so package.json is at root of context
COPY package.json ./
# Use --legacy-peer-deps to handle React 19 peer dependency conflicts
RUN npm install --legacy-peer-deps
COPY . .
# Ensure public directory exists for Next.js standalone
RUN mkdir -p public
# Build args for environment injection
ARG NEXT_PUBLIC_COMMAND_CENTER_VERSION=3.0.0
ARG NEXT_PUBLIC_BUILD_ID=20260415.1
ARG NEXT_PUBLIC_ENVIRONMENT=production
ARG NEXT_PUBLIC_BASE_URL=http://localhost:9443
ARG NEXT_PUBLIC_COMMIT_SHA=local
ENV NEXT_TELEMETRY_DISABLED=1
ENV NODE_ENV=production
ENV NEXT_PUBLIC_COMMAND_CENTER_VERSION=${NEXT_PUBLIC_COMMAND_CENTER_VERSION}
ENV NEXT_PUBLIC_BUILD_ID=${NEXT_PUBLIC_BUILD_ID}
ENV NEXT_PUBLIC_ENVIRONMENT=${NEXT_PUBLIC_ENVIRONMENT}
ENV NEXT_PUBLIC_BASE_URL=${NEXT_PUBLIC_BASE_URL}
ENV NEXT_PUBLIC_COMMIT_SHA=${NEXT_PUBLIC_COMMIT_SHA}
RUN npm run build
# ── Stage 2: Production Runner (hardened) ─────────────────────────────────
FROM node:20-alpine AS production
WORKDIR /app
RUN apk add --no-cache wget tini && \
    addgroup --system --gid 1001 medinovai && \
    adduser --system --uid 1001 --ingroup medinovai --no-create-home command-center
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=9443
ENV HOSTNAME=0.0.0.0
# Copy only what's needed from builder
RUN mkdir -p ./public
COPY --from=builder --chown=command-center:medinovai /app/public ./public
COPY --from=builder --chown=command-center:medinovai /app/.next/standalone ./
COPY --from=builder --chown=command-center:medinovai /app/.next/static ./.next/static
USER command-center
EXPOSE 9443
ENTRYPOINT ["/sbin/tini", "--"]
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget -qO- http://localhost:9443/api/health || exit 1
CMD ["node", "server.js"]
