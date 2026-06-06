FROM dart:3.11.5 AS build

WORKDIR /app

COPY packages/openci_shared/ ./packages/openci_shared/
COPY apps/openci_server/ ./apps/openci_server/

WORKDIR /app/apps/openci_server

# Remove workspace resolution so that dart pub get works successfully
RUN sed -i '/resolution: workspace/d' pubspec.yaml && \
    sed -i 's/openci_shared: \^1.0.1/openci_shared:\n    path: ..\/..\/packages\/openci_shared/g' pubspec.yaml

RUN dart pub get
RUN dart compile exe bin/server.dart -o bin/server

FROM debian:bookworm-slim

RUN apt-get update && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/apps/openci_server/bin/server /app/server

ENV HOST=any
ENV PORT=8080

EXPOSE 8080

CMD ["/app/server"]
