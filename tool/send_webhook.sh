#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Load .env if present
if [ ! -f "$ROOT_DIR/.env" ]; then
  echo "Error: .env file not found at $ROOT_DIR/.env"
  exit 1
fi

export $(grep -v '^#' "$ROOT_DIR/.env" | xargs)

SERVER_URL="http://localhost:8080"
WEBHOOK_SECRET="${GITHUB_WEBHOOK_SECRET}"
EVENT_TYPE="pull_request"

OWNER="openci-org"
REPO="openci"
INSTALLATION_ID="153083749"

PR_NUMBER=1
BASE_BRANCH="develop"
HEAD_BRANCH="feature/awesome-feature"
COMMIT_SHA="develop"
PR_TITLE="feat: simulate GitHub PR opened event from local"

DELIVERY_ID="delivery-$(date +%s)"

PAYLOAD=$(cat <<EOF
{
  "action": "opened",
  "number": $PR_NUMBER,
  "pull_request": {
    "title": "$PR_TITLE",
    "head": {
      "ref": "$HEAD_BRANCH",
      "sha": "$COMMIT_SHA"
    },
    "base": {
      "ref": "$BASE_BRANCH"
    }
  },
  "repository": {
    "name": "$REPO",
    "owner": {
      "login": "$OWNER"
    }
  },
  "installation": {
    "id": $INSTALLATION_ID
  }
}
EOF
)

# Calculate HMAC SHA-256 signature
SIGNATURE=$(printf "%s" "$PAYLOAD" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" | sed 's/^.* //')

echo "🚀 Dispatching GitHub Pull Request ($EVENT_TYPE) Webhook to $SERVER_URL/webhook..."
echo "   - Target: $OWNER/$REPO"
echo "   - PR #$PR_NUMBER: $HEAD_BRANCH -> $BASE_BRANCH"
echo "   - Installation ID: $INSTALLATION_ID"
echo "   - Delivery ID: $DELIVERY_ID"

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$SERVER_URL/webhook" \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: $EVENT_TYPE" \
  -H "X-GitHub-Delivery: $DELIVERY_ID" \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -d "$PAYLOAD")

HTTP_BODY=$(echo "$RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
  echo "✅ PR Webhook dispatched successfully! (HTTP $HTTP_CODE)"
  echo "$HTTP_BODY"
else
  echo "❌ Failed to dispatch PR webhook! (HTTP $HTTP_CODE)"
  echo "$HTTP_BODY"
  exit 1
fi
