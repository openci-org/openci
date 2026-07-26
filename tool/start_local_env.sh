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
echo "🐳 Step 2: Starting Docker containers (openci-db, seaweedfs, orchard, server)..."
docker compose up -d --build db seaweedfs orchard-controller server

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
echo "To start the JobProcessor worker in Orchard mode, run:"
echo ""
echo "USE_ORCHARD=true \\"
echo "OPENCI_SERVER_URL=http://localhost:8080 \\"
echo "INTERNAL_API_KEY=your-internal-api-key-here \\"
echo "OPENCI_RUNS_ON_PATTERN=macos-latest \\"
echo "LUME_BASE_VM_NAME=base-macos \\"
echo "dart run apps/openci_build_job_processor/bin/main.dart"
echo ""
