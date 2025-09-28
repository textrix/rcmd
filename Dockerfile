# ===== BASE =====
FROM node:24-alpine AS base
ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "Building for ${TARGETPLATFORM} on ${BUILDPLATFORM}"
RUN apk add --no-cache bash git curl ca-certificates tzdata dumb-init
WORKDIR /app

# (여기서는 package.json을 복사하지 않습니다)

# ===== DEV (개발 진입용) =====
FROM base AS dev
WORKDIR /work
RUN npm i -g @anthropic-ai/claude-code
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["/usr/bin/dumb-init", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["sh"]

# ===== BUILD (프로덕션 빌드) =====
FROM base AS build
WORKDIR /app
ENV NODE_ENV=production
# 의존성 캐시 최적화는 여기(빌드 단계)에서만 수행
COPY package.json package-lock.json ./
RUN if [ -f package-lock.json ]; then npm ci --ignore-scripts; else npm install --ignore-scripts; fi
COPY . .
RUN npm run build
RUN npm prune --omit=dev
RUN npm audit --audit-level=high

# ===== PROD (런타임) =====
FROM node:24-alpine AS prod
WORKDIR /app
ENV NODE_ENV=production
RUN apk add --no-cache curl
COPY --from=build /app/build ./build
COPY --from=build /app/package.json /app/package-lock.json ./
COPY --from=build /app/node_modules ./node_modules
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/ || exit 1
CMD ["node", "build"]
