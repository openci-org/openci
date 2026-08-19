FROM dart:3.11.5 AS build

WORKDIR /app

COPY packages/openci_shared/ ./packages/openci_shared/
COPY apps/build_job_dispatcher/ ./apps/build_job_dispatcher/

WORKDIR /app/apps/build_job_dispatcher

# Remove workspace resolution so that dart pub get works successfully
RUN sed -i '/resolution: workspace/d' pubspec.yaml && \
    sed -i 's/openci_shared: \^1.0.1/openci_shared:\n    path: ..\/..\/packages\/openci_shared/g' pubspec.yaml

RUN dart pub get
RUN dart compile exe bin/main.dart -o dispatcher

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg && \
    install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian bookworm stable" > /etc/apt/sources.list.d/docker.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        docker-ce-cli \
        docker-compose-plugin && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY --from=build /app/apps/build_job_dispatcher/dispatcher /app/dispatcher

CMD ["/app/dispatcher"]
