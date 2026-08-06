#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

echo "=================================================="
echo "🚀 Starting OpenCI Local Development Environment"
echo "=================================================="

# 1. Check & Setup Tart base-macos image
echo "📦 Step 1: Checking Tart VM base image..."
if ! tart list | grep -q "base-macos"; then
  echo "⚠️ base-macos image not found. Creating from ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5..."
  tart pull ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5
  tart clone ghcr.io/cirruslabs/macos-tahoe-vanilla:26.5 base-macos
  echo "✅ base-macos image created."
else
  echo "✅ base-macos image exists."
fi

# 2. Start Docker Compose core services
echo ""
echo "🐳 Step 2: Starting Docker containers (db, orchard, server, job-processor)..."
BASE_VM_NAME="${BASE_VM_NAME:-base-macos}" \
INTERNAL_API_KEY="${INTERNAL_API_KEY:-your-internal-api-key-here}" \
ORCHARD_API_URL="https://orchard-controller:6120" \
docker compose up -d --build db orchard-controller server job-processor

# 3. Wait for Orchard Controller to be ready
echo ""
echo "⏳ Step 3: Waiting for Orchard Controller to initialize..."
sleep 3

echo "🔑 Step 4: Registering Orchard CLI context..."
TOKEN=$(docker exec openci-orchard-controller orchard get bootstrap-token bootstrap-admin 2>/dev/null || true)
if [ -n "$TOKEN" ]; then
  orchard context create https://127.0.0.1:6120 --bootstrap-token "$TOKEN" --no-pki --force >/dev/null 2>&1
  orchard context default default >/dev/null 2>&1
  echo "✅ Orchard CLI context authenticated."
  
  CONTEXT_TOKEN=$(grep "serviceAccountToken:" ~/.orchard/orchard.yml | head -n 1 | awk '{print $2}')
  echo "🔄 Updating job-processor with Orchard credentials..."
  export ORCHARD_SERVICE_ACCOUNT_NAME="bootstrap-admin"
  export ORCHARD_SERVICE_ACCOUNT_TOKEN="$CONTEXT_TOKEN"

  if [ -f "$ROOT_DIR/.env" ]; then
    ENV_PATH="$ROOT_DIR/.env" CONTEXT_TOKEN="$CONTEXT_TOKEN" python3 -c "
import os
path = os.environ['ENV_PATH']
token = os.environ['CONTEXT_TOKEN'].strip().strip("'\"")
if os.path.exists(path):
    with open(path, 'r') as f:
        lines = f.readlines()
    updated = False
    new_lines = []
    for line in lines:
        if line.startswith('ORCHARD_SERVICE_ACCOUNT_TOKEN='):
            new_lines.append(f'ORCHARD_SERVICE_ACCOUNT_TOKEN={token}\n')
            updated = True
        else:
            new_lines.append(line)
    if not updated:
        new_lines.append(f'ORCHARD_SERVICE_ACCOUNT_TOKEN={token}\n')
    with open(path, 'w') as f:
        f.writelines(new_lines)
"
  fi

  docker compose up -d --force-recreate job-processor >/dev/null 2>&1
  echo "✅ job-processor authenticated with Orchard Controller."
else
  echo "⚠️ Could not auto-fetch Orchard bootstrap token. Context registration skipped."
fi

# 4. Seed Database Test Data
echo ""
echo "🌱 Step 5: Seeding test data to Database..."
dart run tool/seed_local_data.dart

echo ""
echo "=================================================="
echo "🎉 OpenCI Local Environment is Fully Ready!"
echo "=================================================="
echo ""
echo "All components (Server, DB, Orchard, JobProcessor) are running in Docker Compose!"
echo "JobProcessor worker is automatically polling for queued jobs."
echo ""
echo "💡 To run local Orchard worker with multi-VM concurrency, execute:"
echo 'TOKEN=$(docker exec openci-orchard-controller orchard get bootstrap-token bootstrap-admin) && orchard worker run https://127.0.0.1:6120 --bootstrap-token "$TOKEN" --no-pki --default-cpu 2 --default-memory 4096 --resources org.cirruslabs.tart-vms=2'
echo ""
