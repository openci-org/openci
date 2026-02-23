# open-ci server

Next.js + Supabase で構成された Web アプリ（管理画面）です。

## 前提条件

- [pnpm](https://pnpm.io/)
- [Docker](https://www.docker.com/)（ローカル Supabase を起動する場合）

## Make コマンド一覧

```bash
make help
```

で全コマンドと説明を確認できます。

### ローカル開発

| コマンド | 説明 |
|---|---|
| `make init` | 依存インストール + git フック設定 |
| `make start` | 開発サーバーを起動 |
| `make lint` | リンターを実行 |
| `make lint-fix` | リンターを自動修正付きで実行 |
| `make typecheck` | TypeScript 型チェックを実行 |

### Vercel

| コマンド | 説明 |
|---|---|
| `make vercel-login` | Vercel CLI にログイン |
| `make vercel-link` | このディレクトリを Vercel プロジェクトにリンク |
| `make vercel-pull` | 環境変数と設定を Vercel から `.env.local` へ取得 |
| `make vercel-deploy` | プレビューデプロイ |
| `make vercel-deploy-prod` | 本番デプロイ |
| `make vercel-open` | Vercel ダッシュボードをブラウザで開く |

### Supabase

| コマンド | 説明 |
|---|---|
| `make sb-login` | Supabase CLI にログイン |
| `make sb-link` | リモート Supabase プロジェクトにリンク |
| `make sb-start` | ローカル Supabase スタックを起動（Docker 必須） |
| `make sb-stop` | ローカル Supabase スタックを停止 |
| `make sb-status` | ローカル Supabase の状態と接続情報を表示 |
| `make sb-migrate` | ローカル DB にマイグレーションを適用 |
| `make sb-reset` | ローカル DB を初期化（全データ削除 + マイグレーション再実行） |
| `make sb-setup` | 本番向け初回セットアップ一括実行（migrate + cron 登録） |
| `make sb-setup-cron` | 本番 DB に cron ジョブのみを登録（要 pg_cron 有効化） |

### 環境変数・クリーンアップ

| コマンド | 説明 |
|---|---|
| `make env-check` | 必要な環境変数の設定状況を一覧表示 |
| `make clear` | `node_modules` と `.next` を削除 |
| `make clear-db` | ローカル Supabase の DB ボリュームを削除（全データ消去） |

## Vercel プロジェクトの作成（初回のみ）

### 1. Vercel ダッシュボードでプロジェクトを作成

1. [vercel.com/new](https://vercel.com/new) を開く
2. Git リポジトリをインポート、または **"Continue with CLI"** を選択
3. **Root Directory** に `openci/server` を指定
4. Framework Preset が **Next.js** になっていることを確認して Deploy

> Git 連携せず CLI のみで作る場合は手順 2 の `make vercel-link` で新規作成できます。

### 2. Supabase Integration を追加

Vercel と Supabase を Marketplace 連携すると、Supabase の接続情報が Vercel の環境変数へ自動注入されます。

1. Vercel ダッシュボード → **Integrations** → Supabase を検索してインストール
2. 連携する Supabase プロジェクトを選択
3. 完了後、以下の環境変数が Vercel に自動追加される：
   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `POSTGRES_URL` など

### 3. Sentry Integration を追加

1. Vercel ダッシュボード → **Integrations** → Sentry を検索してインストール
2. Sentry の Organization `openci-inc`、Project `web-server` を選択
3. 完了後、`SENTRY_AUTH_TOKEN` が Vercel に自動追加される

### 4. CLI でローカルにリンク

```bash
make vercel-login   # Vercel アカウントにログイン
make vercel-link    # 作成済みのプロジェクトを選択してリンク
make vercel-pull    # 環境変数を .env.local に取得
```

---

## ローカル開発セットアップ

### 1. 依存インストール

```bash
make init
```

### 2. Supabase のセットアップ

#### ローカル DB（Docker 必須）

```bash
make sb-start    # ローカル Supabase スタックを起動
make sb-migrate  # マイグレーションを適用
```

起動後に `make sb-status` で接続情報を確認し、`.env.local` の値と一致しているか確認します。

#### リモートプロジェクト（Supabase クラウド）

```bash
make sb-login
make sb-link     # プロジェクト ref を入力（app.supabase.com で確認）
```

**前提**: Supabase Dashboard → Database → Extensions → **pg_cron** を有効化してください。

```bash
make sb-setup    # マイグレーション適用 + cron ジョブ登録を一括実行
```

`sb-setup` は `sb-migrate` と `sb-setup-cron` を順に実行します。再実行しても安全です。
cron ジョブ登録後は Dashboard → Integrations → Cron で `purge-old-build-logs`（毎日 03:00 UTC）を確認できます。

### 3. 環境変数の確認

```bash
make env-check
```

すべての項目が `[OK]` になっていることを確認します。

### 4. 開発サーバーの起動

```bash
make start
```

ブラウザで [http://localhost:3000](http://localhost:3000) を開きます。

---

## デプロイ

```bash
make vercel-deploy       # プレビュー環境へデプロイ
make vercel-deploy-prod  # 本番環境へデプロイ
make vercel-open         # Vercel ダッシュボードを開く
```

## ディレクトリ構成

```
server/
├── src/
│   ├── app/                  # Next.js App Router のページ・レイアウト
│   │   ├── (public)/         # 認証不要ページ（ログイン等）
│   │   ├── orgs/[orgSlug]/   # 組織ダッシュボード
│   │   └── api/              # API Routes
│   ├── components/           # UI コンポーネント
│   └── lib/
│       └── supabase/
│           ├── client.ts     # ブラウザ用クライアント
│           ├── server.ts     # サーバー用クライアント
│           ├── queries.ts    # DB クエリヘルパー
│           └── types.ts      # 型定義
└── supabase/
    ├── migrations/           # DB マイグレーション（順番に適用）
    ├── functions/            # Supabase Edge Functions
    ├── setup/                # 初回セットアップ用 SQL（マイグレーション外）
    │   └── cron.sql          # cron ジョブ登録（make sb-setup-cron で実行）
    └── config.toml           # Supabase ローカル設定
```
