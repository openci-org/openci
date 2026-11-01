FROM dart:3.12.2 AS build
RUN apt-get update && apt-get install -y --no-install-recommends git libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
ENV PUB_CACHE=/pub-cache
COPY pubspec.yaml pubspec.lock ./
RUN dart pub get --enforce-lockfile \
    && dart pub global activate dart_frog_cli 1.2.14
COPY . .
RUN dart format --output=none --set-exit-if-changed lib routes main.dart bin test integration_test \
    && dart analyze --fatal-infos \
    && dart test test integration_test --concurrency=1 \
    && dart build cli --target bin/stacked_pr.dart --output /opt/admin \
    && dart pub global run dart_frog_cli:dart_frog build \
    && cd build \
    && dart build cli --target bin/server.dart --output /opt/server

FROM debian:trixie-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends git ca-certificates util-linux libsqlite3-dev \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 app \
    && useradd --uid 1000 --gid app --create-home app \
    && mkdir /data && chown app:app /data
WORKDIR /app
ENV DATA_DIR=/data PORT=3000
COPY --from=build /opt/server/bundle /app/server
COPY --from=build /opt/admin/bundle /app/admin
COPY scripts/entrypoint.sh /app/entrypoint.sh
USER app
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
  CMD ["/app/admin/bin/stacked_pr", "healthcheck"]
ENTRYPOINT ["sh", "/app/entrypoint.sh"]
CMD ["/app/server/bin/server"]
