# Stacked PR GitHub App

GitHub / GitHub Enterprise Server の依存するPRを、Firebase Functions（TypeScript / Node.js 22）で管理します。
親の更新・マージ後に子をrebaseし、PRコメントとChecksを更新します。
親1つに複数の子がある分岐にも対応し、エラーはそのスタック内に限定します。

PRの状態はDBに保存せず、PR一覧と履歴を毎回GitHubから読み直します。
Firestoreには同時更新を防ぐための、期限付きの実行ロックだけを保存します。
通知に関係するスタックのブランチだけを取得・更新し、履歴APIは複数PRをまとめて問い合わせ、
続きのページも取得します。PRのbase変更では移動前と移動後のスタックを両方更新します。

## 実行構成

```text
GitHub App webhook
  → stackedPrWebhook（onRequest・Octokit middleware）
  → Cloud Tasks（stackedPrWorkerキュー）
  → stackedPrWorker（onTaskDispatched・非公開・restack）
```

Webhookの署名検証・JSON解析・HTTP応答はOctokit middlewareに任せます。
`webhooks.on(...)` で対象のイベントを購読し、Firebase Admin SDKでタスクを登録してから200を返します。
middlewareの早期202応答はFunctionsの実行上限より後に設定し、未登録の通知を成功扱いにしません。
通知IDをハッシュ化したタスクIDで重複登録を抑えます。タスクにはイベント種別、対象、
コマンド実行者などの必要な情報だけを渡し、PR本文やコミット一覧は保存しません。
登録前の障害は503を返します。GitHubは失敗したWebhookを自動再送しないため、
受信失敗はGitHub Appの配信画面から再送してください。

キューの作成・更新、再試行、実行数の制限は `src/index.ts` のTask Queue Functions設定で管理します。
キュー全体の同時実行数は4、workerは `concurrency: 1` / `maxInstances: 4` です。
独立したスタックを最大4件並列に処理し、同じスタックの更新は直列にします。
再試行は `maxAttempts: 8` / `maxRetrySeconds: 3600`、間隔は30〜300秒です。
順序保証や厳密な1回限りの配信には依存しません。

### スタック単位の排他

更新対象の全PRとheadブランチのロックを、Firestoreのトランザクションで
一括取得します。1つでも他のworkerが使用中ならGitの処理や表示更新を開始せず、
Cloud Tasksの再試行に戻します。workerやrevisionをまたいでも同じロックを使います。
PRのbase変更では、移動前と移動後のスタックをまとめて取得します。

ロック取得後はGitHubを読み直し、取得前の古い計画を使いません。
新しい親子関係によって更新対象が増えていたら、ロックを解放して再試行します。
rebase、push、base変更、コメント・Checksの更新が終わるまで保持し、最後に解放します。
直列化は同時更新を防ぐもので、通知の到着順を保証するものではありません。

`StackedPrLocks/{sha256}` のドキュメントは `owner` と `expiresAt` の2項目だけです。
キーにはGitHubホスト、リポジトリID、PR番号またはブランチ名のハッシュを使います。
有効期限は15分で、workerの実行期限・HTTP期限・タスク期限より長くしています。
停止したworkerのロックは期限後に取得し直せます。古いworkerの解放処理は、
新しい所有者のロックを削除しません。Firestoreが使えないときは更新せず再試行します。
取得時に有効期限を確認するため、TTLによる削除を待つ必要はありません。
停止後に残ったロックはTTLで後から掃除します。

workerはCloud Tasks用サービスアカウントのIDトークンで呼び出します。
IAMのinvokerもそのアカウントに限定し、HTTPヘッダーだけでは認証しません。
`/stack sync` とCheckのSyncは、GitHub上でwrite権限を再確認します。
削除・停止されたinstallationの古いタスクは処理しません。

## GitHubの履歴からの復元

- 現在のPRのhead/baseブランチから親子関係を調べます。
- force push前後の先端はGraphQLの `HeadRefForcePushedEvent` から取得します。
- 親のmergeに伴うbase変更は `BaseRefChangedEvent`、
  `AutomaticBaseChangeSucceededEvent` と閉じたPRの情報から復元します。
  連続する親のmergeや、親ブランチの削除にも対応します。
- 証拠のある親と子の履歴から変更境界を求めます。履歴が不足する場合、
  共通祖先だけを推測で採用せず、そのスタックの自動更新を止めます。
- 各呼び出しで一時Gitディレクトリを作り、最後に削除します。
- スタック内のrebaseがすべて成功した後、更新前のSHAを指定した
  `--force-with-lease` と `--atomic` でpushします。default branchは更新しません。
- push後に通信が切れても、再実行は現在のGitHubの履歴から計画を作り直します。
  新しい親を既に含む子は再適用せず、未完了のbase変更と表示更新を続けます。

コードの競合、親の未mergeでのclose、変更境界を確定できない場合はPRに理由を表示します。
手元で修正・restackしてpushした後に `/stack sync` を実行してください。
子固有の履歴にmerge commitがある場合も自動rebaseを停止します。
Bot更新後は `git fetch origin` で取得し、未pushの変更がある場合は退避してから同期してください。

## ローカル検証とCI

このディレクトリは独立したnpmパッケージです。Node.js 22とGit 2.34以降を使います。
テスト用のダミー鍵と一時Gitリポジトリを使い、実際のGitHubのブランチ・PRは変更しません。

```sh
npm ci --workspaces=false
npm run fmt:check
npm run check
npm test
npm run test:runtime
npm run test:locks
```

`npm test` は単体テストと実Gitを使う統合テストです。
`test:runtime` はFunctions Frameworkで実際のHTTP受付、Task QueueのJSON形式、
Git rebase/pushを検証します。IAMと実サービスへの接続は配置後の検証対象です。
`test:locks` はJava 21以上が必要で、ローカルFirestoreエミュレータ上で
別クライアント間の同時取得、競合時の一括取り消し、期限切れ後の復旧を検証します。
`firebase.emulator.json` とdeny-allルールはテスト専用です。
OpenCIの `openci/stacked_pr_ci.dart` は `scripts/ci.sh` を実行し、
ルートの `.node-version` に固定されたNodeを用意して、`test:locks` 以外のチェックを行います。
Firestoreを変更するPRでは、Java 21を用意して `test:locks` も実行してください。

ソースは `src/`、ビルド結果は `lib/` です。生成結果はGitにコミットしません。
FirebaseのpredeployでTypeScriptをビルドし、Node.jsの標準ランタイムへ配置します。
標準の `google-22-full/nodejs22` に含まれるGitを使用します。
Gitの `rebase.updateRefs=false` を明示し、他のブランチの自動更新を防ぎます。

## Firebaseへの配置

リージョンは `asia-northeast1`、codebaseは `stacked-pr` です。
このディレクトリの `firebase.json` から配置します。

1. `.env.example` を `.env.<project-id>` にコピーしてApp ID、GitHubホスト、
   対象リポジトリ、サービスアカウントを設定します。
   `GITHUB_URL` はGitHub.comなら `https://github.com`、GHESならそのHTTPS originです。
   `ALLOWED_REPOSITORIES` は `owner/repo` 形式で指定します（複数はカンマ区切り）。
2. Secret Managerに `STACKED_PR_GITHUB_PRIVATE_KEY` と `STACKED_PR_WEBHOOK_SECRET` を登録します。
   Webhook secretは32文字以上にします。設定値・秘密鍵はコミットしません。
3. 既存のFirestore Nativeデータベースを使います。既定は `(default)` で、
   別のDBを使う場合は `STACKED_PR_LOCK_DATABASE` にそのIDを設定します。
   `StackedPrLocks` へのWeb/Mobileクライアントからの読み書きはルールで禁止してください。
   他の広い `allow` によってこのコレクションが許可されないことも確認が必要です。
   このパッケージから既存DBのルール全体を置き換えることはしません。
4. `scripts/provision.sh PROJECT_ID [LOCK_DATABASE]` でAPI、サービスアカウント、必要なIAMを準備します。
   これは明示的にクラウド設定を変更するスクリプトです。
   runtimeには指定したDBに限定した `roles/datastore.user` を付与します。
   `StackedPrLocks.expiresAt` のTTLも設定します（期限の判定はアプリ側で行います）。
   DBは既存のものを確認し、暗黙には作成しません。
   キューの作成・更新はFirebase CLIがTask Queue Functions設定から行います。
5. 依存関係をインストールし、workerとWebhookを配置します。

```sh
npm ci --workspaces=false
npx --yes firebase-tools@15.34.2 deploy --project YOUR_PROJECT_ID \
  --only functions:stacked-pr:stackedPrWorker,functions:stacked-pr:stackedPrWebhook
```

GitHub AppのWebhook URLを配置された `stackedPrWebhook` のURLに設定します。
タスクの宛先URLはAdmin SDKが解決するため、worker URLの手動設定は不要です。
配置後はworkerの非公開IAM、署名検証とタスク登録、通常push、親のmerge、
競合時の停止と `/stack sync`、同じスタックの排他と別スタックの並列処理を
テスト用スタックで確認してください。

直列版から初めて切り替えるときは、キューを一時停止し、実行中の旧workerが
終了してから配置・再開してください。ロックを持たない旧版との同時実行は防げません。
ロック導入後も、同じAppのworkerは同じプロジェクト・DBを参照する必要があります。

一時領域はメモリを使うためworkerは1インスタンスあたり2GiB、minInstances=0です。
処理開始から420秒を超えたら新しいGit/API操作を始めず、Git子プロセスにも期限を設定します。
Functionsの上限540秒より長い600秒をタスク期限とし、旧処理と再試行の重なりを抑えます。
単一スタックがこの時間・容量を超える場合は構成を見直す必要があります。
再試行を使い切った場合はログを確認して `/stack sync` を実行します。

## 既存配置の切替

新しい関数名は `stackedPrWebhook` / `stackedPrWorker`、キュー名は `stackedPrWorker` です。
旧 `stacked-pr` キューのタスクはJSON形式も異なるため、新workerへそのまま転送しません。
切替時は旧Webhook受付を止め、旧キューの処理完了と旧workerの停止を確認してから
新Webhookへ切り替えます。未処理の用件はGitHubの配信画面から再送するか、
`/stack sync` で現在の状態を再取得します。2つのworkerを並行稼働させないでください。
旧関数・旧キューの削除は切替確認後に行います。

旧workerを停止できずGitHub Appの鍵を失効させて切り替える場合は、
旧鍵の削除から65分後を `STACKED_PR_RESUME_AT` にUTC形式で指定してください。
その時刻までは新タスクを予約し、PRは更新しません。通常運用では空欄にします。
同じApp IDであれば既存のマーカー付きコメントとChecksを再利用します。

## 仕様の参照先

- [Firebase Task Queue Functions](https://firebase.google.com/docs/functions/task-functions)
- [Cloud Tasks HTTP認証](https://cloud.google.com/tasks/docs/creating-http-target-tasks)
- [Firestoreのトランザクション](https://firebase.google.com/docs/firestore/manage-data/transactions)
- [FirestoreのDB単位のIAM権限](https://firebase.google.com/docs/firestore/manage-databases)
- [FirestoreのTTL](https://firebase.google.com/docs/firestore/ttl)
- [GitHub PR履歴](https://docs.github.com/en/enterprise-server@3.19/graphql/reference/objects#headrefforcepushedevent)
- [Googleの実行環境に含まれるパッケージ](https://cloud.google.com/docs/buildpacks/stacks)

<!-- OpenCI paths production verification: Stacked PR-only change, 2026-11-02. -->
