# Stacked PR GitHub App

GitHub / GitHub Enterprise Server の依存するPRを、Firebase Functionsで管理します。
親の更新・マージ後に子をrebaseし、PRコメントとChecksを更新します。
親1つに複数の子がある分岐にも対応し、エラーはそのスタック内に限定します。

SQLite、Firestore、永続Gitディレクトリは使いません。通知に関係するスタックの
ブランチだけを取得・更新し、PR一覧と履歴は毎回GitHubから読み直します。
履歴APIは複数PRをまとめて問い合わせ、続きのページも取得します。
PRのbaseが変わった通知では、移動前と移動後のスタックを両方更新します。

## 実行構成

```text
GitHub App webhook
  → stacked-pr-webhook（署名検証）
  → Cloud Tasks（未完了の用件・再試行）
  → stacked-pr-worker（非公開、GitHubを再取得してrestack）
```

Cloud Tasksに登録できた通知だけ202で受け付けます。通知IDをハッシュ化した
タスク名で重複登録を抑えます。PRの状態・操作ジャーナルは保存せず、タスクには
イベント種別、対象、コマンド実行者などの必要な情報だけを渡します。
PR本文やコミット一覧は保存しません。タスク登録前の障害は503を返します。
GitHubは失敗したWebhookを自動再送しないため、受信失敗はAppの配信画面から再送してください。

キューは同時実行1、最大8回、30〜300秒の間隔で再試行します。順序保証や
厳密な1回限りの配信には依存しません。署名を検証したHTTP受付だけを公開し、
workerはCloud Tasks用サービスアカウントのIDトークンで呼び出します。
`/stack sync`とCheckのSyncは、GitHub上でwrite権限を再確認します。
削除・停止されたinstallationの古いタスクは処理しません。

## GitHubの履歴からの復元

- 現在のPRのhead/baseブランチから親子関係を調べます。
- force push前後の先端はGraphQLの`HeadRefForcePushedEvent`から取得します。
- 親のmergeに伴うbase変更は`BaseRefChangedEvent`と閉じたPRの情報から復元します。
  連続する親のmergeや、親ブランチの削除にも対応します。
- 証拠のある親の履歴と子の履歴から変更境界を求めます。履歴が不足する場合、
  共通祖先だけを推測で採用せず、そのスタックの自動更新を止めます。
- 各呼び出しで一時Gitディレクトリを作り、最後に削除します。
- スタック内のrebaseがすべて成功した後、更新前のSHAを指定した
  `--force-with-lease`と`--atomic`でpushします。default branchは更新しません。
- push後に通信が切れても、再実行は現在のGitHubの履歴から計画を作り直します。
  新しい親を既に含む子は再適用せず、未完了のbase変更と表示更新を続けます。

コードの競合、親の未mergeでのclose、変更境界を確定できない場合は、PRに理由を表示します。
手元で修正・restackしてpushした後に`/stack sync`を実行してください。
子固有の履歴にmerge commitがある場合も自動rebaseを停止します。
Bot更新後は`git fetch origin`で取得し、未pushの変更がある場合は退避してから同期してください。

## ローカル検証

このディレクトリはルートのPub workspaceから独立しています。
Dart 3.12以降とGit 2.38以降が必要です。テスト用のダミー鍵と一時Gitリポジトリを使い、
GitHubのブランチ・PRを変更せずに検証できます。

```sh
dart pub get --enforce-lockfile
dart run build_runner build
dart format --output=none --set-exit-if-changed lib bin test integration_test
dart analyze --fatal-infos
dart test test integration_test --concurrency=1
dart compile exe bin/server.dart -o bin/server --target-os=linux --target-arch=x64
```

FirebaseのDart対応は実験段階です。HTTP Functionsのみを使います。
標準DartイメージにはGitがないため、workerの`functions.yaml`ではGit 2.43を含む
Google提供の`google-24-full/nodejs24`イメージを指定し、起動コマンドをコンパイル済み
Dartバイナリにします。Nodeコードへの書き換えや自前のDockerイメージ作成は行いません。
SDKのmanifest自動生成は`build.yaml`で無効化しています。
このファイルのruntime、IAM、secret、パラメーターは変更時に一緒に検証してください。

## Firebaseへの配置

配置先のFirebaseプロジェクトを用意してください。リージョンは`asia-northeast1`です。
codebase `stacked-pr`をこのディレクトリの`firebase.json`から配置します。
GitHub Appを登録し、App ID、秘密鍵、Webhook secretを設定してください。
実際の配置先、App設定値、秘密鍵をリポジトリにコミットしないでください。

1. `.env.example`を`.env.<project-id>`にコピーし、例示値を実際のApp ID、GitHubホスト、
   対象リポジトリ、サービスアカウントに置き換えます。`GITHUB_URL`にはGitHub.comなら
   `https://github.com`、GHESなら利用するホストのHTTPS URLを設定します。
   `ALLOWED_REPOSITORIES`には対象を`owner/repo`形式で指定します（複数はカンマ区切り）。
   GitHubホストと対象リポジトリに既定値はなく、明示的な設定が必要です。
2. Secret Managerに`STACKED_PR_GITHUB_PRIVATE_KEY`と`STACKED_PR_WEBHOOK_SECRET`を登録します。
3. [配置準備スクリプト](scripts/provision.sh)でAPI、サービスアカウント、キューを準備します。
   このスクリプトは明示的にクラウド設定を変更します。
4. まずworkerを配置してURLを取得し、`.env.<project-id>`の`STACKED_PR_WORKER_URL`に設定します。
5. 両方を配置します。manifestからCloud Tasks用アカウントだけに
   workerの`roles/run.invoker`を付与し、再配置でも維持します。

```sh
project=YOUR_PROJECT_ID
FIREBASE_CLI_EXPERIMENTS=dartfunctions npx --yes firebase-tools@15.34.2 deploy \
  --project "$project" --only functions:stacked-pr:stacked-pr-worker

# .env.<project-id> の STACKED_PR_WORKER_URL を更新した後
FIREBASE_CLI_EXPERIMENTS=dartfunctions npx --yes firebase-tools@15.34.2 deploy \
  --project "$project" --only functions:stacked-pr

```

一時領域はメモリを使うためworkerは2GiB、同時実行1、minInstances=0です。
処理開始から420秒を超えたら新しいGit/API操作を始めず、Git子プロセスにも期限を設定します。
Functionsの上限540秒より長い600秒をタスク期限とし、旧処理と再試行の重なりを抑えます。
単一スタックがこの時間・容量を超える場合は構成を見直す必要があります。
GitHub APIや権限の障害が続いて再試行を使い切った場合は、ログを確認して`/stack sync`を実行します。

## 既存Botからの切替

1. Firebase側の配置、Secret、workerの非公開IAM、GitHubへの接続を確認します。
2. Cloud Tasksキューを一時停止し、新しい鍵とWebhook secretを登録します。
   旧サーバーを停止できない場合、GitHub App設定で旧秘密鍵を削除します。
   既に発行されたinstallation tokenは最大1時間有効なため、旧鍵削除時刻の
   65分後を`STACKED_PR_RESUME_AT`にUTC形式で設定して両方のFunctionsを配置します。
3. GitHub AppのWebhook URLを`stacked-pr-webhook`のURLに変更し、新しいsecretを設定します。
   署名検証とキュー登録を確認してからキューを再開します。
   指定時刻までは通知を受け付けてCloud Tasksに予約し、PRは更新しません。
   指定時刻を過ぎると通常どおり処理します。通常の配置ではこの設定は空欄で構いません。
4. 対象のテスト用スタックで通常push、親のmerge、競合時の停止を確認します。
   その後`/stack sync`で既存スタックの状態を再取得できます。

SQLiteのデータ移送は不要です。旧Botで作成したマーカー付きコメントとChecksは、
同じApp IDで再利用します。問題があれば新しいキューを停止し、修正したrevisionを
再配置します。旧鍵失効後はアクセスできない旧環境にWebhookを戻しても復旧できません。
両方のworkerを並行稼働させないでください。

## 仕様の参照先

- [Firebase Dart Functions](https://firebase.google.com/docs/functions/start-dart)
- [Cloud Tasks HTTP認証](https://cloud.google.com/tasks/docs/creating-http-target-tasks)
- [GitHub PR履歴](https://docs.github.com/en/enterprise-server@3.19/graphql/reference/objects#headrefforcepushedevent)
- [Googleの実行環境に含まれるパッケージ](https://cloud.google.com/docs/buildpacks/stacks)
