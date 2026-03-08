# Tailscale Proxy (Cloud Run)

Tailscale経由でビルドマシンのLume REST APIにアクセスするためのCloud Runプロキシサービス。
Dart (Relic) + socks5_proxy で実装。

## セットアップ

### 1. Tailscale Auth Keyの生成

[Tailscale Admin Console](https://login.tailscale.com/admin/settings/keys) で Ephemeral Auth Key を生成。

### 2. GCP Secret Managerに保存

```bash
echo -n "tskey-auth-xxxxx" | gcloud secrets create tailscale-authkey --data-file=-
```

### 3. デプロイ

```bash
gcloud run deploy tailscale-proxy \
  --source . \
  --region us-central1 \
  --project openci-dev-da298 \
  --set-secrets=TAILSCALE_AUTHKEY=tailscale-authkey:latest \
  --set-env-vars=PROXY_API_KEY=your-api-key \
  --allow-unauthenticated=false \
  --min-instances=0 \
  --max-instances=3 \
  --memory=512Mi \
  --cpu=1
```

## 使い方

```bash
# ヘルスチェック
curl https://<CLOUD_RUN_URL>/health

# Lume APIにプロキシ（例: VMリスト取得）
curl https://<CLOUD_RUN_URL>/proxy/vms \
  -H "x-api-key: your-api-key" \
  -H "x-target-url: http://<TAILSCALE_MACHINE_IP>:3000"
```

## 環境変数

| 変数                | 説明                                              |
| ------------------- | ------------------------------------------------- |
| `TAILSCALE_AUTHKEY` | Tailscaleの認証キー（Secret Managerから注入）     |
| `PROXY_API_KEY`     | プロキシへのアクセスを制限するAPIキー（任意）     |
| `SOCKS_HOST`        | SOCKS5プロキシのホスト（デフォルト: `localhost`） |
| `SOCKS_PORT`        | SOCKS5プロキシのポート（デフォルト: `1055`）      |
| `PORT`              | サーバーポート（デフォルト: `8080`）              |
