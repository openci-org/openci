# GitHub Apps Setup for OpenCI

OpenCIがユーザーのリポジトリにアクセスし、CI/CDを実行するためには、GitHub Appを作成し、インストールする必要があります。

## 1. GitHub Appの作成

1. GitHubの [Developer Settings > GitHub Apps](https://github.com/settings/apps) にアクセスします。
2. "New GitHub App" をクリックします。
3. 以下の情報を入力します：
   - **GitHub App Name**: `openci-yourname` (ユニークな名前)
   - **Homepage URL**: `https://openci.io` (またはあなたのアプリのURL)
   - **Callback URL**: `https://openci.io/callback` (後で認証に使用する場合)
   - **Webhook URL**: 必須ですが、開発中は適当なURLでも可（例: `https://example.com/webhook`）。本番ではCIのイベントを受け取るバックエンドのURLになります。
   - **Webhook secret**: 任意の文字列（本番環境では必須）

## 2. 権限 (Permissions) の設定

CI/CDを実行するために必要な権限を設定します。

- **Repository permissions**:
  - `Actions`: Read & Write (ワークフローの実行)
  - `Checks`: Read & Write (チェック結果の報告)
  - `Contents`: Read & Write (コードのチェックアウト、設定ファイルの読み込み)
  - `Metadata`: Read-only (必須)
  - `Pull requests`: Read & Write (PRへのコメントなど)
- **User permissions**:
  - `Email addresses`: Read-only (ユーザー識別に役立つ場合があります)

## 3. インストール設定

- **Where can this GitHub App be installed?**: "Any account" (誰でも使えるようにする場合) または "Only on this account".

## 4. Appの情報を取得

作成後、以下の情報を控えておきます。

- **App ID**
- **Client ID**
- **Public Link** (例: `https://github.com/apps/openci-app`) -> これがインストールURLになります。

## 5. アプリへの組み込み

`workflow_editor_page.dart` のインストールボタンのURLを、取得した **Public Link** (`https://github.com/apps/<APP_NAME>/installations/new`) に置き換えます。

## 6. インストール済みかどうかの確認とデータ取得

ユーザーがアプリをインストールしているか確認したり、情報を取得するには2つの方法があります。

### A. フロントエンドでAPIを叩く (現在こちらを実装中)

ユーザーのGitHubアクセストークンを使ってAPIを叩きます。
API: `GET https://api.github.com/user/installations`

**取得できるデータ:**
レスポンスの `installations` 配列の中に、ユーザーがインストールした全アプリの情報が含まれます。
各インストールオブジェクトには以下のような情報が含まれています：

- `id`: インストールID (重要)
- `account`: インストールしたアカウント（ユーザーまたはOrganization）の情報
  - `login`: ユーザー名 (例: `masahiroaoki`)
  - `id`: ユーザーID
  - `avatar_url`: アイコンURL
  - `url`: プロフィールURL
- `app_id`: アプリのID
- `repository_selection`: `all` または `selected`

この方法のメリットは、バックエンドを介さずにすぐに確認できることです。

### B. Webhook (バックエンド)

GitHub App設定で指定した **Webhook URL** に、イベント通知がPOST送信されます。
`installation` イベント (action: `created`) が送信されます。

**Payloadに含まれるデータ:**

- `action`: `created`
- `installation`: インストール情報の詳細 (上記APIと同様)
- `repositories`: アプリがアクセス可能なリポジトリのリスト（`repository_selection`が`selected`の場合に特に重要）
- `sender`: インストール操作を行ったユーザーの情報

バックエンド構築後は、このWebhookを受け取り、DBのユーザー情報とInstall IDを紐付けるのが一般的です。
