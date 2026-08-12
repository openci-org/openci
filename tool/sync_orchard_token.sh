#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

SERVICE_ACCOUNT_NAME="openci-api"
ENV_FILE="$ROOT_DIR/.env"

# .env から既存のトークンを取得、無ければ新規生成
TOKEN=""
if [ -f "$ENV_FILE" ]; then
  TOKEN=$(grep "^ORCHARD_SERVICE_ACCOUNT_TOKEN=" "$ENV_FILE" | cut -d'=' -f2- | tr -d '\r\n"' || true)
fi

if [ -z "$TOKEN" ] || [[ "$TOKEN" == *"failed"* ]] || [[ "$TOKEN" == *"exec"* ]] || [[ "$TOKEN" == *"orchard-bootstrap-token"* ]]; then
  echo "🎲 新しい Service Account Token を生成しています..."
  TOKEN=$(openssl rand -hex 32)
fi

echo "🔑 Orchard コントローラーにサービスアカウント '$SERVICE_ACCOUNT_NAME' を作成・権限付与しています..."
docker exec openci-orchard-controller orchard create service-account "$SERVICE_ACCOUNT_NAME" \
  --roles compute:read \
  --roles compute:write \
  --roles compute:connect \
  --roles admin:read \
  --roles admin:write \
  --token "$TOKEN" >/dev/null 2>&1 || true

echo "✅ サービスアカウント '$SERVICE_ACCOUNT_NAME' の権限が準備できました。"

if [ -f "$ENV_FILE" ]; then
  echo "📝 .env ファイルの Orchard 認証情報を更新中..."
  
  if grep -q "^ORCHARD_SERVICE_ACCOUNT_NAME=" "$ENV_FILE"; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s|^ORCHARD_SERVICE_ACCOUNT_NAME=.*|ORCHARD_SERVICE_ACCOUNT_NAME=$SERVICE_ACCOUNT_NAME|" "$ENV_FILE"
    else
      sed -i "s|^ORCHARD_SERVICE_ACCOUNT_NAME=.*|ORCHARD_SERVICE_ACCOUNT_NAME=$SERVICE_ACCOUNT_NAME|" "$ENV_FILE"
    fi
  else
    echo "ORCHARD_SERVICE_ACCOUNT_NAME=$SERVICE_ACCOUNT_NAME" >> "$ENV_FILE"
  fi

  if grep -q "^ORCHARD_SERVICE_ACCOUNT_TOKEN=" "$ENV_FILE"; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s|^ORCHARD_SERVICE_ACCOUNT_TOKEN=.*|ORCHARD_SERVICE_ACCOUNT_TOKEN=$TOKEN|" "$ENV_FILE"
    else
      sed -i "s|^ORCHARD_SERVICE_ACCOUNT_TOKEN=.*|ORCHARD_SERVICE_ACCOUNT_TOKEN=$TOKEN|" "$ENV_FILE"
    fi
  else
    echo "ORCHARD_SERVICE_ACCOUNT_TOKEN=$TOKEN" >> "$ENV_FILE"
  fi
  echo "✅ .env の更新が完了しました。"
else
  echo "⚠️ .env ファイルが見つからないため作成します。"
  echo "ORCHARD_SERVICE_ACCOUNT_NAME=$SERVICE_ACCOUNT_NAME" > "$ENV_FILE"
  echo "ORCHARD_SERVICE_ACCOUNT_TOKEN=$TOKEN" >> "$ENV_FILE"
fi

echo "🔄 job-processor イメージをビルド＆再作成して反映しています..."
docker compose up -d --build --force-recreate job-processor

echo "🎉 Orchard Service Account の作成と同期が完了しました！"
