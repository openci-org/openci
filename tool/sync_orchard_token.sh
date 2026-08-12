#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$ROOT_DIR"

SERVICE_ACCOUNT_NAME="openci-api"
ENV_FILE="$ROOT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env が見つかりません。先に prepare_env.sh を実行してください。" >&2
  exit 1
fi

echo "🎲 新しい Service Account Token を生成しています..."
TOKEN=$(openssl rand -hex 32)

echo "🔑 Orchard コントローラーでサービスアカウント '$SERVICE_ACCOUNT_NAME' を作成中..."
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

echo "📝 .env ファイルの Orchard トークンを更新中..."
ENV_PATH="$ENV_FILE" ACCOUNT_TOKEN="$TOKEN" python3 -c '
import os, re
path = os.environ["ENV_PATH"]
token = os.environ["ACCOUNT_TOKEN"]
with open(path, "r") as f:
    content = f.read()

if "ORCHARD_SERVICE_ACCOUNT_TOKEN=" in content:
    content = re.sub(r"^ORCHARD_SERVICE_ACCOUNT_TOKEN=.*$", f"ORCHARD_SERVICE_ACCOUNT_TOKEN={token}", content, flags=re.M)
else:
    content += f"\nORCHARD_SERVICE_ACCOUNT_TOKEN={token}"

with open(path, "w") as f:
    f.write(content.strip() + "\n")
'

echo "🔄 job-processor コンテナを再作成して反映中..."
docker compose up -d --force-recreate job-processor

echo "🎉 Orchard Service Account の同期が完了しました"
