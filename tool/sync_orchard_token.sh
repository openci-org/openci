#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

echo "🔑 Orchard コントローラーから認証トークンを取得しています..."
TOKEN=$(docker exec openci-orchard-controller orchard get bootstrap-token bootstrap-admin 2>/dev/null || true)

if [ -z "$TOKEN" ]; then
  echo "❌ エラー: Orchard コントローラーコンテナからトークンを取得できませんでした。"
  echo "Orchard コンテナが起動しているか確認してください (docker compose ps)"
  exit 1
fi

echo "✅ トークンを取得しました (${TOKEN:0:8}...)"

if [ -f "$ROOT_DIR/.env" ]; then
  echo "📝 .env ファイルの ORCHARD_SERVICE_ACCOUNT_TOKEN を更新中..."
  if grep -q "^ORCHARD_SERVICE_ACCOUNT_TOKEN=" "$ROOT_DIR/.env"; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/^ORCHARD_SERVICE_ACCOUNT_TOKEN=.*/ORCHARD_SERVICE_ACCOUNT_TOKEN=$TOKEN/" "$ROOT_DIR/.env"
    else
      sed -i "s/^ORCHARD_SERVICE_ACCOUNT_TOKEN=.*/ORCHARD_SERVICE_ACCOUNT_TOKEN=$TOKEN/" "$ROOT_DIR/.env"
    fi
  else
    echo "ORCHARD_SERVICE_ACCOUNT_TOKEN=$TOKEN" >> "$ROOT_DIR/.env"
  fi
  echo "✅ .env の更新が完了しました。"
else
  echo "⚠️ .env ファイルが見つからないため作成します。"
  echo "ORCHARD_SERVICE_ACCOUNT_TOKEN=$TOKEN" > "$ROOT_DIR/.env"
fi

echo "🔄 job-processor を再起動しています..."
docker compose restart job-processor

echo "🎉 完了しました!!"
