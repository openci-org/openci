FROM dart:stable AS builder

WORKDIR /app
COPY pubspec.* ./
RUN dart pub get
COPY . .
RUN dart compile exe bin/server.dart -o bin/server

FROM alpine:latest

RUN apk add --no-cache ca-certificates iptables gcompat

COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscaled /app/tailscaled
COPY --from=docker.io/tailscale/tailscale:stable /usr/local/bin/tailscale /app/tailscale
RUN mkdir -p /var/run/tailscale /var/cache/tailscale /var/lib/tailscale

COPY --from=builder /app/bin/server /app/server

COPY start.sh /app/start.sh
RUN chmod +x /app/start.sh

ENV PORT=8080

CMD ["/app/start.sh"]
