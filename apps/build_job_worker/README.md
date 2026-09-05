# Build Job Worker

Temporal TypeScript SDK を使う最小の Worker です。`EchoWorkflow` が `EchoActivity` を呼び、入力された文字列をそのまま返します。

Workflow と Activity は両方ともこの Worker で実行され、Temporal サーバーがタスクと実行履歴を管理します。現段階では `openci_server`、Orchard、GitHub には接続せず、実際のビルドも行いません。

## 起動

リポジトリルートで実行します。Docker Compose だけで起動でき、ホストへの Node.js や Temporal CLI のインストールは不要です。

```sh
docker compose -p openci-temporal-dev -f docker-compose.temporal.yml up --build -d --wait
```

この Compose は検証専用です。既存の `docker-compose.yml` とは併用せず、別プロジェクトとして起動します。既存の dispatcher／executor やその他のサービスは起動しません。

- Temporal UI: <http://localhost:8233>
- Temporal gRPC: `localhost:7233`
- Namespace: `default`
- Task Queue: `openci-build-job-worker`

ポートはホストのループバックアドレスにだけ公開しています。`server start-dev` は開発用であり、本番環境には使用しないでください。

## Workflow を1件実行

```sh
docker compose -p openci-temporal-dev -f docker-compose.temporal.yml exec -T temporal \
  temporal workflow execute \
  --type EchoWorkflow \
  --task-queue openci-build-job-worker \
  --input '"Hello OpenCI"' \
  --execution-timeout 1m
```

`Completed` と結果 `"Hello OpenCI"` が表示されれば成功です。Temporal UI の `default` Namespace から、Workflow と Activity の実行履歴も確認できます。

Worker のログは次のコマンドで確認できます。

```sh
docker compose -p openci-temporal-dev -f docker-compose.temporal.yml logs build-job-worker
```

## ローカル開発・テスト

Node.js 22.12 以降と Vite+ を使います。既存の TypeScript パッケージと同じ npm workspace に登録しており、依存関係はルートの `package-lock.json` で管理します。

リポジトリルートで依存関係をインストールします。

```sh
npm ci --workspace apps/build_job_worker --include-workspace-root=false
```

`apps/build_job_worker` で実行します。

```sh
vp fmt --check
vp check
vp run typecheck
vp test
vp run build
```

Activity の単体テストに加えて、Workflow は SDK が起動する一時的な Temporal サーバーで検証します。初回はテスト用バイナリのダウンロードにネットワーク接続が必要です。Docker Compose の環境には接続せず、テスト終了時に一時サーバーを停止します。

文字列の受け渡し、Activity の結果の返却、一時的な失敗からの再試行、失敗が続いたときに初回を含む最大3回で打ち切ることを検証します。

ホストで Worker を動かす場合は、Docker 側の Worker を停止して Temporal サーバーだけを起動し、ビルド後に `vp run start` を実行します。接続先は `TEMPORAL_ADDRESS` で変更でき、省略時は `localhost:7233` です。

## CI

`.github/workflows/build-job-worker-ci.yml` で、Worker・ルートの npm 依存関係や Vite+ 設定・CI 定義を変更した push を検証します。ブランチは限定していないため、作業ブランチへの push と `develop` へのマージの両方が対象です。

Ubuntu / Node.js 22 でフォーマット、静的解析、型チェック、Activity・Workflow のテスト、TypeScript のビルド、Docker イメージのビルドを実行します。テストは一時的な Temporal サーバーを起動するため、外部の Temporal 環境や追加のシークレットは不要です。デプロイは行いません。

Compose 設定は `.github/workflows/docker-compose-ci.yml` で別に検証します。`docker-compose.yml` と `docker-compose.temporal.yml` をそれぞれ独立して検証し、`.env.example` のダミー値を使って全 profile に対する `docker compose config --quiet` を実行します。Compose ファイル・`.env.example`・CI 定義の変更が対象で、コンテナの起動や外部サービスへの接続は行いません。

## ファイル構成

- `src/worker.ts`: Temporal への接続、Workflow と Activity の登録、Worker の起動・終了。
- `src/workflows.ts`: Activity の実行順序とタイムアウト・再試行の設定。
- `src/activities.ts`: 実際の処理。現段階では入力された文字列を返すだけ。

Workflow から Activity は型情報だけを import し、`proxyActivities` 経由で呼び出します。これにより、Activity の処理を直接実行せず Temporal に実行を依頼します。

## 停止

リポジトリルートで実行します。

```sh
docker compose -p openci-temporal-dev -f docker-compose.temporal.yml down
```

実行履歴は専用の Docker ボリュームに保存され、停止・再起動しても残ります。`down` に `--volumes` を付けると、この検証環境の実行履歴が削除されるので注意してください。
