# Dockerfile for medinovai-infrastructure

# Stage 1: Build the application
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

# In a real-world scenario, you might have a build step
# RUN npm run build

# Stage 2: Production image
FROM node:20-alpine

WORKDIR /app

# Create a non-root user and group
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy dependencies and built files from the builder stage
COPY --from=builder /app/package*.json ./
RUN npm ci --only=production

COPY --from=builder /app/ .

# Set ownership for the app directory
RUN chown -R appuser:appgroup /app

# Switch to the non-root user
USER appuser

# Metadata
LABEL maintainer="BMAD <bmad@example.com>"
LABEL version="1.0"
LABEL description="MedinovAI Infrastructure"

EXPOSE 3000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD [ "node", "-e", "require('http').get('http://localhost:3000', (res) => process.exit(res.statusCode == 200 ? 0 : 1))" ]

CMD ["npm", "start"]
