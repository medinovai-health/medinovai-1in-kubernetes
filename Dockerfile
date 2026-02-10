FROM node:20-alpine AS builder

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

FROM node:20-alpine

WORKDIR /usr/src/app

COPY --from=builder /usr/src/app/package*.json ./
COPY --from=builder /usr/src/app/dist ./dist

RUN npm install --only=production

USER node

LABEL maintainer="devops@medinovai.com"
LABEL version="1.0"

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 CMD ["node", "healthcheck.js"]

CMD ["node", "dist/main.js"]
