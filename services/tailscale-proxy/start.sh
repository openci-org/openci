#!/bin/sh

/app/tailscaled --tun=userspace-networking --socks5-server=localhost:1055 --port=41641 --statedir=/var/lib/tailscale &

until /app/tailscale up --auth-key="${TAILSCALE_AUTHKEY}" --hostname=openci-proxy 2>&1; do
  echo "Waiting for tailscale to come up..."
  sleep 1
done

echo "Tailscale started"

/app/server
