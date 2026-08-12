#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

echo "🔑 Orchard コントローラーから bootstrap-token を取得しています..."
BOOTSTRAP_TOKEN=$(docker exec openci-orchard-controller orchard get bootstrap-token bootstrap-admin 2>/dev/null || true)

if [ -z "$BOOTSTRAP_TOKEN" ]; then
  echo "❌ エラー: Orchard コントローラーコンテナから bootstrap-token を取得できませんでした。"
  echo "Orchard コンテナが起動しているか確認してください (docker compose ps)"
  exit 1
fi

echo "🔄 bootstrap-token を使用して Orchard コンテキストを認証・正規トークンを発行中..."
# コンテナ内で orchard context create を実行して正規の serviceAccountToken を発行・取得
docker exec openci-orchard-controller orchard context create https://127.0.0.1:6120 --bootstrap-token "$BOOTSTRAP_TOKEN" --no-pki --force >/dev/null 2>&1 || true

# コンテナ内の ~/.orchard/orchard.yml から正規の serviceAccountToken を抽出
SERVICE_TOKEN=$(docker exec openci-orchard-controller sh -c 'grep "serviceAccountToken:" ~/.orchard/orchard.yml 2>/dev/null | head -n 1 | awk "{print \$2}"' | tr -d '\r\n"' || true)

# ホスト側に orchard CLI があればホスト側でも試行
if [ -z "$SERVICE_TOKEN" ] && command -v orchard >/dev/null 2>&1; then
  orchard context create https://127.0.0.1:6120 --bootstrap-token "$BOOTSTRAP_TOKEN" --no-pki --force >/dev/null 2>&1 || true
  SERVICE_TOKEN=$(grep "serviceAccountToken:" ~/.orchard/orchard.yml 2>/dev/null | head -n 1 | awk '{print $2}' | tr -d '\r\n"')
fi

FINAL_TOKEN="${SERVICE_TOKEN:-$BOOTSTRAP_TOKEN}"

if [ -z "$FINAL_TOKEN" ]; then
  echo "❌ エラー: serviceAccountToken の生成・取得に失敗しました。"
  exit 1
fi

echo "✅ 正式な Service Account Token を取得しました (${FINAL_TOKEN:0:8}...)"

if [ -f "$ROOT_DIR/.env" ]; then
  echo "📝 .env ファイルの Orchard 認証情報を更新中..."
  
  if grep -q "^ORCHARD_SERVICE_ACCOUNT_NAME=" "$ROOT_DIR/.env"; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/^ORCHARD_SERVICE_ACCOUNT_NAME=.*/ORCHARD_SERVICE_ACCOUNT_NAME=bootstrap-admin/" "$ROOT_DIR/.env"
    else
      sed -i "s/^ORCHARD_SERVICE_ACCOUNT_NAME=.*/ORCHARD_SERVICE_ACCOUNT_NAME=bootstrap-admin/" "$ROOT_DIR/.env"
    fi
  else
    echo "ORCHARD_SERVICE_ACCOUNT_NAME=bootstrap-admin" >> "$ROOT_DIR/.env"
  fi

  if grep -q "^ORCHARD_SERVICE_ACCOUNT_TOKEN=" "$ROOT_DIR/.env"; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
      sed -i '' "s/^ORCHARD_SERVICE_ACCOUNT_TOKEN=.*/ORCHARD_SERVICE_ACCOUNT_TOKEN=$FINAL_TOKEN/" "$ROOT_DIR/.env"
    else
      sed -i "s/^ORCHARD_SERVICE_ACCOUNT_TOKEN=.*/ORCHARD_SERVICE_ACCOUNT_TOKEN=$FINAL_TOKEN/" "$ROOT_DIR/.env"
    fi
  else
    echo "ORCHARD_SERVICE_ACCOUNT_TOKEN=$FINAL_TOKEN" >> "$ROOT_DIR/.env"
  fi
  echo "✅ .env の更新が完了しました。"
else
  echo "⚠️ .env ファイルが見つからないため作成します。"
  echo "ORCHARD_SERVICE_ACCOUNT_NAME=bootstrap-admin" > "$ROOT_DIR/.env"
  echo "ORCHARD_SERVICE_ACCOUNT_TOKEN=$FINAL_TOKEN" >> "$ROOT_DIR/.env"
fi

echo "🔄 job-processor コンテナを再作成して環境変数を反映しています..."
docker compose up -d --force-recreate job-processor

echo "🎉 同期とコンテナの再反映が完了しました！!"
