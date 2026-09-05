FROM node:22-bookworm-slim AS build
WORKDIR /app

COPY package.json package-lock.json ./
COPY apps/build_job_worker/package.json ./apps/build_job_worker/
RUN npm ci --workspace apps/build_job_worker --include-workspace-root=false --no-audit --no-fund

COPY apps/build_job_worker/ ./apps/build_job_worker/
RUN npm run build --workspace apps/build_job_worker

FROM node:22-bookworm-slim
ENV NODE_ENV=production
WORKDIR /app

COPY package.json package-lock.json ./
COPY apps/build_job_worker/package.json ./apps/build_job_worker/
RUN npm ci --omit=dev --workspace apps/build_job_worker --include-workspace-root=false --no-audit --no-fund

COPY --from=build /app/apps/build_job_worker/dist ./apps/build_job_worker/dist
USER node
WORKDIR /app/apps/build_job_worker
CMD ["node", "dist/worker.js"]
