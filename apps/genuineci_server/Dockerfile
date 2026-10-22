FROM golang:1.27.2-bookworm AS build

WORKDIR /app

COPY apps/genuineci_server/go.mod apps/genuineci_server/go.sum ./
RUN go mod download

COPY apps/genuineci_server/cmd/ ./cmd/
COPY apps/genuineci_server/internal/ ./internal/
RUN CGO_ENABLED=0 go build -mod=readonly -trimpath -o /out/server ./cmd/server

FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -g 10001 appgroup && \
    useradd -u 10001 -g appgroup -m -s /usr/sbin/nologin appuser

WORKDIR /app

COPY --from=build /out/server /app/server

USER appuser

EXPOSE 8081

CMD ["/app/server"]
