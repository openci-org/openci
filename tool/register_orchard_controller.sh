#!/usr/bin/env bash
set -e

if [ -z "$TOKEN" ]; then
  read -rp "Enter Orchard bootstrap token: " TOKEN
fi

if [ -z "$TOKEN" ]; then
  echo "Error: Bootstrap token is required."
  exit 1
fi

echo "Starting Orchard Worker..."
orchard worker run https://127.0.0.1:6120 \
  --bootstrap-token "$TOKEN" \
  --no-pki \
  --default-cpu 2 \
  --default-memory 4096 \
  --resources org.cirruslabs.tart-vms=2
