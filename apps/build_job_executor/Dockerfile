FROM dart:3.11.5 AS build

WORKDIR /app

COPY packages/openci_shared/ ./packages/openci_shared/
COPY apps/build_job_executor/ ./apps/build_job_executor/

WORKDIR /app/apps/build_job_executor

# Remove workspace resolution so that dart pub get works successfully
RUN sed -i '/resolution: workspace/d' pubspec.yaml && \
    sed -i 's/openci_shared: \^1.0.1/openci_shared:\n    path: ..\/..\/packages\/openci_shared/g' pubspec.yaml

RUN dart pub get
RUN dart compile exe bin/main.dart -o processor

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends openssh-client sshpass && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -m -s /bin/bash appuser && \
    mkdir -p /home/appuser/.ssh && \
    printf "Host 100.*\n    StrictHostKeyChecking no\n    UserKnownHostsFile /dev/null\n" > /home/appuser/.ssh/config && \
    chmod 700 /home/appuser/.ssh && \
    chmod 600 /home/appuser/.ssh/config && \
    chown -R appuser:appgroup /home/appuser/.ssh && \
    printf "\nHost 100.*\n    StrictHostKeyChecking no\n    UserKnownHostsFile /dev/null\n" >> /etc/ssh/ssh_config

WORKDIR /app

COPY --from=build --chown=appuser:appgroup /app/apps/build_job_executor/processor /app/processor

USER appuser

CMD ["/app/processor"]
