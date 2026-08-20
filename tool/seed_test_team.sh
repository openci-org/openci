#!/usr/bin/env bash
set -e

SERVER_URL="http://localhost:8080"

echo "🌱 Seeding test team to $SERVER_URL/internal/seed/teams..."

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$SERVER_URL/internal/seed/teams")

HTTP_BODY=$(echo "$RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" -ge 200 ]; then
  echo "✅ Seed completed successfully! (HTTP $HTTP_CODE)"
  echo "$HTTP_BODY"
else
  echo "❌ Seed failed! (HTTP $HTTP_CODE)"
  echo "$HTTP_BODY"
  exit 1
fi
