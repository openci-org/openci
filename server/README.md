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

---

## ビルドログ仕様

### ログの流れ

```
ワーカー (Dart)
  │  ステップ開始: beginStep(index, name)
  │  ログ書き込み: writeLog(message, level, stepIndex, stepName)
  │  ステップ終了: endStep()
  └─ ビルド完了時:
       1. build_logs を全行フェッチ
       2. テキスト整形してSupabase Storageへアップロード
       3. builds.log_archive_path を更新

Supabase
  ├─ build_logs テーブル（7日間保持）
  └─ Storage: build-logs/{orgId}/{projectId}/{buildId}.txt

ダッシュボード (Next.js)
  ├─ ビルド中: Realtimeで build_logs の INSERT をストリーミング
  ├─ ビルド完了: Realtimeで builds の UPDATE を受信 → Downloadボタン表示
  └─ ログ閲覧: ステップごとのアコーディオン表示
```

### ログの保管とアーカイブ

| 項目 | 内容 |
|------|------|
| **DB保持期間** | 7日間（`build_logs.created_at` 基準） |
| **TTL削除** | pg_cron で毎日 03:00 UTC に `purge_old_build_logs()` を実行 |
| **アーカイブ** | ビルド完了時にワーカーが Supabase Storage へアップロード |
| **保存先** | `build-logs` バケット（プライベート）`{orgId}/{projectId}/{buildId}.txt` |
| **フォーマット** | UTF-8 プレーンテキスト |
| **ファイルサイズ上限** | なし（プランの容量上限のみ適用） |
| **ダウンロード** | ダッシュボードの Download ボタン → 300秒有効の署名付きURL |

7日経過後は DB のログは消えますが、Storage のアーカイブは残るためダウンロード可能です。

### ステップグループ化

ワーカーがログ書き込み時に `step_index`（0-based）と `step_name` を付与することで、ダッシュボード側でステップ単位のアコーディオン表示ができます。

**`build_logs` テーブルの関連カラム：**

| カラム | 型 | 説明 |
|--------|-----|------|
| `step_index` | `smallint \| null` | ステップ番号（0-based）。NULL はステップ外のログ（preamble） |
| `step_name` | `text \| null` | ステップ名（例: `"Build iOS"`） |

ワーカー側の使い方（Dart）：

```dart
// ステップ開始を宣言
logger.beginStep(0, "Build iOS");

// このあとの writeLog() には step_index/step_name が自動付与される
await logger.info("xcodebuild starting...");

// ステップ終了（以降は preamble 扱い）
logger.endStep();
```

ダッシュボードでの表示：
- `step_index` が付いているログ → ステップアコーディオンに分類
- `step_index` が NULL のログ → preamble（ステップ外ログ）として先頭に表示
- 最新ステップは自動展開、過去ステップは折りたたみ

### Realtime ストリーミング

ダッシュボードは2つのチャンネルをサブスクライブします：

| チャンネル | テーブル | イベント | 用途 |
|-----------|---------|---------|------|
| `build-logs-{buildRunId}` | `build_logs` | `INSERT` | 新しいログ行をリアルタイム追記 |
| `build-status-{buildId}` | `builds` | `UPDATE` | ステータス変化・`log_archive_path` 更新を検知 |

ビルド完了時に `builds.log_archive_path` が更新されると Realtime 経由でブラウザに通知され、Download ボタンが自動表示されます。

### ワーカー側の実装ポイント

**書き込みリトライ（指数バックオフ）：**
`writeLog()` は失敗時に最大3回（1秒 → 2秒）リトライします。3回失敗した場合はログをドロップして続行（ビルド自体は止めない）。

**アーカイブのタイミング：**
ビルドが `success` / `failure` / `cancelled` のいずれかで完了した時点でワーカーが即時アップロードします。アップロード失敗時は `builds.log_archive_path` が NULL のまま残ります（7日以内はDBから参照可能）。

**アーカイブファイルのフォーマット：**

```
Build: <buildId>
Repository: owner/repo
Commit: abc1234
Branch: main
Status: success
Date: 2026-02-23T03:00:00Z
================================================================================

[Step 1] Build iOS
--------------------------------------------------------------------------------
10:00:01.123 [INFO] ▶ Running step: Build iOS
10:00:30.789 [INFO] ✓ Step completed: Build iOS

[Step 2] Upload to TestFlight
--------------------------------------------------------------------------------
10:00:31.012 [INFO] ▶ Running step: Upload to TestFlight
...
```

## メール配信（Resend）

すべてのトランザクションメール（組織招待、Supabase Auth のパスワードリセット・メール確認等）を [Resend](https://resend.com) 経由で送信します。

### 環境変数

| 変数名 | 説明 | 例 |
|---|---|---|
| `RESEND_API_KEY` | Resend API キー | `re_xxxxxxxxxxxx` |
| `RESEND_FROM_EMAIL` | 送信元アドレス | `OpenCI <noreply@openci.io>` |

ローカル開発用のシークレットは `server/.env.resend` に記載できます（`.gitignore` 済み）。

### 本番セットアップ

#### 1. Resend

1. [resend.com](https://resend.com) でアカウント作成
2. **Domains** で送信元ドメインを認証（DNS レコード追加）
3. **API Keys** で API キーを発行

#### 2. Vercel 環境変数

Vercel ダッシュボード → Settings → Environment Variables に追加：

- `RESEND_API_KEY`
- `RESEND_FROM_EMAIL`

#### 3. Supabase Dashboard SMTP 設定

Supabase Auth のメール（パスワードリセット、サインアップ確認等）も Resend 経由で送信するため、Supabase Dashboard で SMTP を設定します。

1. [app.supabase.com](https://app.supabase.com) → プロジェクト → **Authentication** → **SMTP Settings**
2. **Enable Custom SMTP** をオン
3. 以下を入力：

| 項目 | 値 |
|---|---|
| Sender email | `noreply@openci.io`（Resend で認証済みのアドレス） |
| Sender name | `OpenCI` |
| Host | `smtp.resend.com` |
| Port | `465` |
| Username | `resend` |
| Password | Resend API キー |

4. **Save** をクリック

#### 4. Supabase Dashboard メールテンプレート

1. **Authentication** → **Email Templates**
2. 各テンプレートタイプ（Confirm signup, Reset password, Change email address）の Subject と Body を `server/supabase/templates/` 内の対応する HTML ファイルの内容に置き換え

| テンプレートタイプ | ソースファイル |
|---|---|
| Confirm signup | `supabase/templates/confirmation.html` |
| Reset password | `supabase/templates/recovery.html` |
| Change email address | `supabase/templates/email_change.html` |

### 開発環境バナー

`NODE_ENV === "development"` の場合、Resend SDK で送信するメール（組織招待等）の上部に黄色の開発環境バナーが表示されます。ローカル開発では Supabase の Inbucket（`http://localhost:54324`）でメールを確認できます。

---

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
│       ├── email/
│       │   ├── resend.ts         # Resend クライアントラッパー
│       │   └── templates/
│       │       ├── base-layout.ts  # 共通HTMLレイアウト（開発バナー含む）
│       │       └── invitation.ts   # 招待メールテンプレート
│       └── supabase/
│           ├── client.ts     # ブラウザ用クライアント
│           ├── server.ts     # サーバー用クライアント
│           ├── queries.ts    # DB クエリヘルパー
│           └── types.ts      # 型定義
└── supabase/
    ├── migrations/           # DB マイグレーション（順番に適用）
    ├── templates/            # Supabase Auth メールテンプレート（HTML）
    ├── functions/            # Supabase Edge Functions
    ├── setup/                # 初回セットアップ用 SQL（マイグレーション外）
    │   └── cron.sql          # cron ジョブ登録（make sb-setup-cron で実行）
    └── config.toml           # Supabase ローカル設定
```
