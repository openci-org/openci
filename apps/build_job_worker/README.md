# build_job_worker

OpenCIのビルドjobを実行するDartバックエンドサービス。
最終的にはComposeから起動する常駐プロセスとして動作させます。

現在は設定の読み込み、jobを1件取得する関数、OrchardのVM作成・状態取得・削除用HTTPクライアントを実装しています。
起動すると設定を確認して終了し、job取得関数はまだ起動処理から呼び出しません。
そのため、起動時の外部API接続・VM操作は行いません。
既存dispatcher/executorやComposeの起動構成も変更していません。

## 設定

- `OPENCI_SERVER_URL`: 必須。openci_serverの接続先。
- `INTERNAL_API_KEY`: 必須。内部APIの認証キー。
- `ORCHARD_SERVICE_ACCOUNT_NAME`: 必須。Orchardのサービスアカウント名。
- `ORCHARD_SERVICE_ACCOUNT_TOKEN`: 必須。Orchardの認証トークン。
- `BASE_VM_NAME`: 任意。ベースVM名。デフォルトは`base-macos`。
- `ORCHARD_API_URL`: 任意。デフォルトは`https://orchard-controller:6120`。
- `LOKI_URL`: 任意。workerからのログ送信先。デフォルトは`http://loki:3100`。
- `LOKI_URL_FOR_VM`: 任意。VMからのログ送信先。デフォルトは`http://192.168.64.1:3100`。
- `SENTRY_DSN`: 任意。現段階では読み込みのみで、Sentryへの接続は行いません。

必須設定が未指定または空文字列の場合は、変数名を標準エラー出力へ出して
終了コード1で終了します。認証キーやトークンの値は出力しません。
`BUILD_JOB_ID`は不要です。Orchardの認証情報は環境変数から読み込みます。

`OrchardApiClient(config: config)`でクライアントを作成し、使用後に`close()`を呼び出します。
`waitForVmRunning()`は標準で3秒間隔・最大5分間、`running`または`active`になるまで待機します。
HTTP応答待ちも制限時間に含み、APIエラーは呼び出し元へ返します。
VMのCPU数・メモリは`createLease()`の引数、`ORCHARD_VM_CPU`・`ORCHARD_VM_MEMORY_GB`、
デフォルト値（2コア・4 GiB）の順に決まります。
既存executorと同様に、ローカルOrchardの`--no-pki`構成に対応します。
証明書の例外許可は設定した接続先のホスト・ポートに限定します。

## 実行

リポジトリルートで`flutter pub get`を実行してから、このディレクトリで実行します。

```sh
OPENCI_SERVER_URL=http://localhost:8080 \
INTERNAL_API_KEY=local-development-key \
ORCHARD_SERVICE_ACCOUNT_NAME=bootstrap-admin \
ORCHARD_SERVICE_ACCOUNT_TOKEN=local-development-token \
dart run bin/main.dart
```

## 検証

このディレクトリで実行します。テストにサーバーやVMの起動は不要です。

```sh
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
dart test integration_test
```
