#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SERVER_URL="http://localhost:8080"

echo "🗑️  Deleting build jobs from $SERVER_URL/internal/build_jobs..."

RESPONSE=$(curl -s -w "\n%{http_code}" -X DELETE "$SERVER_URL/internal/build_jobs" \
  -H "Content-Type: application/json")

HTTP_BODY=$(echo "$RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
  echo "✅ Build jobs deleted successfully! (HTTP $HTTP_CODE)"
  echo "$HTTP_BODY"
else
  echo "❌ Failed to delete build jobs! (HTTP $HTTP_CODE)"
  echo "$HTTP_BODY"
  exit 1
fi
