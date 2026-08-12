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

echo "🔑 Orchard コントローラーでサービスアカウント '$SERVICE_ACCOUNT_NAME' を確実・最新化しています..."
# 既存の同名サービスアカウントを削除してトークンの不一致（409 Conflict）を防ぐ
docker exec openci-orchard-controller orchard delete service-account "$SERVICE_ACCOUNT_NAME" >/dev/null 2>&1 || true

# 権限(roles)付きでサービスアカウントとトークンを作成
docker exec openci-orchard-controller orchard create service-account "$SERVICE_ACCOUNT_NAME" \
  --roles compute:read \
  --roles compute:write \
  --roles compute:connect \
  --roles admin:read \
  --roles admin:write \
  --token "$TOKEN" >/dev/null

echo "✅ サービスアカウント '$SERVICE_ACCOUNT_NAME' (トークン一致済み) を作成・権限付与しました。"

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

echo "🎉 Orchard Service Account の同期が完全に成功しました！"
