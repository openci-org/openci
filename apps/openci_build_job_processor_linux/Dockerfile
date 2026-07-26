FROM dart:3.11.5 AS build

WORKDIR /app

COPY packages/openci_shared/ ./packages/openci_shared/
COPY packages/openci_job_processor_shared/ ./packages/openci_job_processor_shared/
COPY apps/openci_build_job_processor_linux/ ./apps/openci_build_job_processor_linux/

RUN sed -i '/resolution: workspace/d' packages/openci_job_processor_shared/pubspec.yaml && \
    sed -i 's/openci_shared:/openci_shared:\n    path: ..\/openci_shared/g' packages/openci_job_processor_shared/pubspec.yaml

WORKDIR /app/apps/openci_build_job_processor_linux

# Remove workspace resolution so that dart pub get works successfully
RUN sed -i '/resolution: workspace/d' pubspec.yaml && \
    sed -i 's/openci_shared: \^1.0.1/openci_shared:\n    path: ..\/..\/packages\/openci_shared/g' pubspec.yaml

RUN dart pub get
RUN dart compile exe bin/main.dart -o processor

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -m -s /bin/bash appuser

WORKDIR /app

COPY --from=build --chown=appuser:appgroup /app/apps/openci_build_job_processor_linux/processor /app/processor

USER appuser

CMD ["/app/processor"]
