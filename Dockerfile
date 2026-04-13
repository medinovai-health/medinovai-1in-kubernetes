# =============================================================================
# MedinovAI Production Dockerfile
# Sprint 5: Dockerfile Optimization & Production Hardening
# =============================================================================
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json pnpm-lock.yaml* yarn.lock* ./
RUN corepack enable && \
    if [ -f pnpm-lock.yaml ]; then pnpm install --frozen-lockfile; \
    elif [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
    elif [ -f package-lock.json ]; then npm ci; \
    else npm install; fi
COPY . .
RUN if [ -f "tsconfig.json" ]; then npm run build 2>/dev/null || echo "No build script"; fi

FROM node:20-alpine AS production
RUN addgroup -g 1001 -S medinovai && adduser -S medinovai -u 1001 -G medinovai
WORKDIR /app
COPY --from=builder --chown=medinovai:medinovai /app/package*.json ./
COPY --from=builder --chown=medinovai:medinovai /app/node_modules ./node_modules
COPY --from=builder --chown=medinovai:medinovai /app/dist ./dist
COPY --from=builder --chown=medinovai:medinovai /app/src ./src
RUN apk add --no-cache dumb-init curl && apk upgrade --no-cache && rm -rf /var/cache/apk/* /tmp/* /root/.npm
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 CMD curl -f http://localhost:${PORT:-3000}/health || exit 1
LABEL org.opencontainers.image.source="https://github.com/medinovai-health"
LABEL org.opencontainers.image.vendor="MedinovAI"
USER medinovai
EXPOSE ${PORT:-3000}
ENTRYPOINT ["dumb-init", "--"]
CMD ["node", "dist/index.js"]
