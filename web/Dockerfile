FROM node:20-alpine AS deps

WORKDIR /app/web

COPY web/package.json web/package-lock.json ./
RUN npm ci

FROM node:20-alpine AS builder

ENV NEXT_TELEMETRY_DISABLED=1

WORKDIR /app

COPY --from=deps /app/web/node_modules ./web/node_modules
COPY web ./web
COPY api ./api

WORKDIR /app/web

RUN npm run build

FROM node:20-alpine AS prod-deps

WORKDIR /app/web

COPY web/package.json web/package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

FROM node:20-alpine AS runner

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV HOSTNAME=0.0.0.0
ENV PORT=3000

WORKDIR /app

COPY --from=builder /app/api ./api
COPY --from=builder /app/web/.next ./web/.next
COPY --from=builder /app/web/public ./web/public
COPY --from=builder /app/web/package.json ./web/package.json
COPY --from=builder /app/web/next.config.js ./web/next.config.js
COPY --from=prod-deps /app/web/node_modules ./web/node_modules

WORKDIR /app/web

EXPOSE 3000

CMD ["sh", "-c", "npm run start -- --hostname ${HOSTNAME} --port ${PORT}"]
