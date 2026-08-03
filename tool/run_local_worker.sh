#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

echo "=================================================="
echo "🍏 Starting OpenCI Local Orchard Worker"
echo "=================================================="

# 1. Check if orchard CLI is installed
if ! command -v orchard &> /dev/null; then
  echo "❌ Error: 'orchard' command line tool is not installed on host."
  echo "Please install orchard first (e.g. via brew install cirruslabs/cli/orchard)."
  exit 1
fi

# 2. Check if Orchard Controller container is running
if ! docker ps --format '{{.Names}}' | grep -q "^openci-orchard-controller$"; then
  echo "❌ Error: 'openci-orchard-controller' Docker container is not running."
  echo "Please start the containers first with: docker compose up -d orchard-controller"
  exit 1
fi

# 3. Retrieve Bootstrap Token
echo "🔑 Fetching bootstrap token from openci-orchard-controller..."
TOKEN=$(docker exec openci-orchard-controller orchard get bootstrap-token bootstrap-admin 2>/dev/null || true)

if [ -z "$TOKEN" ]; then
  echo "❌ Error: Failed to fetch bootstrap token from Orchard Controller."
  exit 1
fi

# 4. Register Orchard CLI Context
echo "🔗 Setting up local Orchard CLI context (https://127.0.0.1:6120)..."
orchard context create https://127.0.0.1:6120 --bootstrap-token "$TOKEN" --no-pki --force > /dev/null 2>&1
orchard context default default > /dev/null 2>&1
echo "✅ Orchard CLI context configured."

# 5. Run Orchard Worker
echo ""
echo "🚀 Running Orchard Worker..."
echo "Press Ctrl+C to stop the worker."
echo "=================================================="

exec orchard worker run https://127.0.0.1:6120 --bootstrap-token "$TOKEN" --no-pki "$@"
