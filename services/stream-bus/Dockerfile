# Use a slim, secure base image
FROM node:25-alpine AS builder
# Set working directory
WORKDIR /usr/src/app
# Copy package files and install dependencies
COPY package*.json ./
RUN npm install --production
# Copy application source
COPY . .
# --- Second Stage: Final image ---
FROM node:25-alpine
# Set working directory
WORKDIR /usr/src/app
# Copy dependencies and built artifacts from builder stage
COPY --from=builder /usr/src/app/node_modules ./node_modules
COPY --from=builder /usr/src/app/dist ./dist
# Create a non-root user for security
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser
# Add metadata labels
LABEL maintainer="devops@medinovai.com"
LABEL version="1.0.0"
LABEL description="MedinovAI Real-Time Stream Bus"
# Health check to ensure service is running
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD [ "node", "dist/healthcheck.js" ]
# Expose the application port
EXPOSE 3000
# Start the application
CMD [ "node", "dist/main.js" ]
