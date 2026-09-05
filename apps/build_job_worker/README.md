# build_job_worker

OpenCIのビルドjobを実行するDartバックエンドサービス。
最終的にはComposeから起動する常駐プロセスとして動作させます。

現在は設定の読み込みと、jobを1件取得する関数まで実装しています。
起動すると設定を確認して終了し、job取得関数はまだ起動処理から呼び出しません。
そのため、起動時の外部API接続・VM操作は行いません。
既存dispatcher/executorやComposeの起動構成も変更していません。

## 設定

- `OPENCI_SERVER_URL`: 必須。openci_serverの接続先。
- `INTERNAL_API_KEY`: 必須。内部APIの認証キー。
- `SENTRY_DSN`: 任意。現段階では読み込みのみで、Sentryへの接続は行いません。

必須設定が未指定または空文字列の場合は、変数名を標準エラー出力へ出して
終了コード1で終了します。認証キーの値は出力しません。
`BUILD_JOB_ID`は不要です。Orchard・VM固有の設定は、VM準備処理の移植時に追加します。

## 実行

リポジトリルートで`flutter pub get`を実行してから、このディレクトリで実行します。

```sh
OPENCI_SERVER_URL=http://localhost:8080 INTERNAL_API_KEY=local-development-key dart run bin/main.dart
```

## 検証

このディレクトリで実行します。テストにサーバーやVMの起動は不要です。

```sh
dart format --output=none --set-exit-if-changed .
dart analyze --fatal-infos
dart test
dart test integration_test
```
