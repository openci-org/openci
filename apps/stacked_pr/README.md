# Stacked PR GitHub App

GitHub / GitHub Enterprise Server の依存する PR を管理する Dart 製 GitHub App です。
親 PR の更新・マージに合わせて子 PR を rebase し、PR コメントと Checks に
スタックの状態を表示します。`/stack sync` または Check の Sync ボタンでも同期できます。

## 取り込み元

- Repository: <https://github.ibm.com/Masahiro-Aoki3/stacked_pr>
- Commit: `2268af2c100b78bb09731908f95d90c2e6e27d9c` (`main`)

このディレクトリには、元リポジトリの追跡対象ファイルを取り込んでいます。
実際の認証情報、SQLite データ、取得済みの Git リポジトリは含めていません。

現時点の実行方式は Dart Frog と SQLite を使う単独の常駐アプリです。
Firebase Functions への移行と OpenCI からの有効化設定は、後続の変更で追加します。
Docker で単独ビルドできるように、ルートの Dart workspace には登録せず、
このディレクトリの `pubspec.lock` で依存関係を管理します。

## ローカル開発

Dart 3.12 以降、Git、SQLite 3 の共有ライブラリが必要です。
以下はリポジトリのルートから実行します。

```sh
cd apps/stacked_pr
dart pub get --enforce-lockfile
cp .env.example .env
mkdir -p secrets
```

`.env` の GitHub ホスト、App ID、Webhook secret、対象リポジトリを設定し、
GitHub App の秘密鍵を `secrets/github-app.pem` に配置します。
GitHub.com を使う場合は `GITHUB_URL=https://github.com` を指定します。
App の権限とイベント購読は `app-manifest.example.json` を参照してください。

```sh
dart pub global activate dart_frog_cli 1.2.14
dart pub global run dart_frog_cli:dart_frog dev
```

Webhook の受信パスは `/webhooks`、ヘルスチェックは `/healthz` です。
ローカル開発では `.env.example` の設定により `127.0.0.1:3000` で待ち受けます。

## 検証

`apps/stacked_pr` で実行します。テストはモックと一時的なローカル Git リポジトリを
使うため、GitHub の認証情報は不要です。

```sh
dart format --output=none --set-exit-if-changed lib routes main.dart bin test integration_test
dart analyze --fatal-infos
dart test test integration_test --concurrency=1
```

モックを再生成する場合:

```sh
dart run build_runner build
```

## Docker

`.env` と秘密鍵を準備した後、`apps/stacked_pr` で実行します。

```sh
docker compose up --build -d
docker compose logs -f app
```

Compose はホストの `127.0.0.1:3000` に公開します。GitHub から届く HTTPS の
Webhook URL を別途用意してください。コンテナ内では `/data` に SQLite、
処理途中の記録、rebase に必要な Git の履歴を保存します。
同じデータ領域を扱うワーカーは 1 つとし、この領域を永続化してください。

## 現在の制約

- 同一リポジトリ内の直線的なスタックに対応します。親 PR から複数の子 PR に
  分岐するスタックは未対応で、親子関係の判定エラーが別スタックの表示にも影響します。
- 子 PR 固有の履歴に merge commit がある場合、自動 rebase を停止します。
- rebase の競合は自動解消しません。ローカルで修正してから `/stack sync` を実行します。
- SQLite とローカル Git の永続化を前提としているため、そのまま複数インスタンスへ
  スケールさせる構成には対応していません。
