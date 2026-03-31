# ─── medinovaiOS — Multi-stage Dockerfile ─────────────────────────────────────
# Stage 1: Build the Vite SPA
# Stage 2: Bundle the Express server with esbuild
# Stage 3: Production runtime — static files + Express server on port 3030
# ─────────────────────────────────────────────────────────────────────────────

# ── Stage 1: Frontend build ───────────────────────────────────────────────────
FROM node:22-alpine AS frontend-builder
WORKDIR /app

# Install all deps (including devDeps for Vite build)
COPY package*.json ./
RUN npm ci --silent

# Copy source and build
COPY . .
RUN npm run build

# ── Stage 2: Server bundle ────────────────────────────────────────────────────
FROM node:22-alpine AS server-builder
WORKDIR /app

COPY package*.json ./
RUN npm ci --silent

COPY server/ ./server/
COPY tsconfig.json ./

RUN npx esbuild server/index.ts \
    --bundle \
    --platform=node \
    --target=node22 \
    --format=esm \
    --packages=external \
    --outfile=dist-server/server.js

# ── Stage 3: Production runtime ───────────────────────────────────────────────
FROM node:22-alpine AS runner
WORKDIR /app

# Install only production dependencies
COPY package*.json ./
RUN npm ci --omit=dev --silent

# Copy built artifacts
COPY --from=frontend-builder /app/dist ./dist
COPY --from=server-builder   /app/dist-server ./dist-server

ENV NODE_ENV=production
ENV PORT=3030

EXPOSE 3030

# Run as non-root
USER node

HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
  CMD wget -q -O /dev/null http://localhost:3030/health || exit 1

CMD ["node", "dist-server/server.js"]
