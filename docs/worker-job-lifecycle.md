# OpenCI Workerのジョブライフサイクル

このドキュメントは、Mac上で動作するOpenCI Worker (`openci_worker_supabase.dart`) が
どのようにジョブを検知・実行・報告するかをまとめたものです。

---

## 1. 起動と設定

### コマンド

```bash
openci_worker_supabase \
  --service-account /path/to/supabase-credentials.json \
  --worker-id mac-01
```

### 認証情報ファイル形式

```json
{
  "supabase_url": "https://xxx.supabase.co",
  "service_role_key": "eyJhbGci..."
}
```

| フィールド | 必須 | 説明 |
|---|---|---|
| `supabase_url` | ✅ | SupabaseプロジェクトのURL |
| `service_role_key` | ✅ | Supabase service_roleキー（PostgREST経由でDBアクセス） |

起動時に `worker_config` テーブルの `latest_version` を参照し、新バージョンがあれば通知を出す（`--update` フラグで自己アップデート可能）。

---

## 2. Jobのポーリング（Listen）

Workerは**ポーリング方式**でジョブを監視します。WebSocketやリアルタイムサブスクリプションは使用しません。

```
┌─────────────────────────────────────────────────────────┐
│  while (true)                                           │
│    1. POST /rest/v1/rpc/claim_next_build                │
│       { "p_worker_id": "mac-01" }                       │
│                                                         │
│       内部: SELECT ... FROM builds                      │
│             WHERE status = 'queued'                     │
│             FOR UPDATE SKIP LOCKED                      │
│             LIMIT 1                                     │
│             → status を 'in_progress' に更新            │
│                                                         │
│    2. ジョブなし → 10秒待機 → 繰り返し                  │
│       ジョブあり → _processBuild() へ                   │
└─────────────────────────────────────────────────────────┘
```

- **ポーリング間隔**: 10秒（`pollingIntervalSeconds = 10`）
- **排他制御**: `FOR UPDATE SKIP LOCKED` により複数のWorkerが同じジョブを取得しない
- **エラー時**: ループ内のエラーはキャッチしてログ出力し、10秒後に再試行（Workerは停止しない）

---

## 3. ビルド実行中のDB状態変化

### 3-1. ステータス遷移 (`builds.status`)

```
queued
  ↓  claim_next_build() RPC
in_progress
  ↓  ビルド完了
success / failure / cancelled
```

| 遷移 | トリガー | 備考 |
|---|---|---|
| `queued` → `in_progress` | `claim_next_build()` RPC | ジョブ取得時に自動遷移 |
| `in_progress` → `failure` | `updateBuildStatus('failure')` | `build_runs` 作成失敗時、ワークフロー未設定時、ステップ失敗時、予期しない例外時 |
| `in_progress` → `success` | `updateBuildStatus('success')` | 全ステップ完了時 |
| `in_progress` → `cancelled` | `updateBuildStatus('cancelled')` | ステップ開始前の Cancel 検知時 |

### 3-2. `builds` テーブルの更新フィールド

| フィールド | 更新タイミング | 値 |
|---|---|---|
| `status` | ジョブ取得時・完了時 | `in_progress` / `success` / `failure` / `cancelled` |
| `log_archive_path` | ビルド完了後のアーカイブアップロード成功時 | `{org_id}/{project_id}/{build_id}.txt` |

### 3-3. `build_runs` テーブル（試行記録）

ビルドごとに1レコード作成。1つのビルド（`builds`行）に対して複数の試行（`build_runs`行）が存在し得る。

| フィールド | 作成時 | 完了時 |
|---|---|---|
| `build_id` | 対象ビルドID | — |
| `status` | `in_progress` | `completed` |
| `conclusion` | — | `success` / `failure` / `cancelled` |

### 3-4. `environment_variables` テーブルの更新

`auto_increment = true` の環境変数は、ビルドごとに `increment_env_var()` RPCが呼ばれ、
値がアトミックにインクリメントされる。Workerはインクリメント**前**の値（現ビルドに割り当てる番号）を受け取る。

---

## 4. 環境変数の解決

ビルド実行前に、プロジェクトの環境変数を3種類の方法で解決してシェル環境に渡す。

```
┌───────────────────────────────────────────────────┐
│  getEnvVars(projectId)  →  環境変数リスト         │
│                                                   │
│  for each ev:                                     │
│    auto_increment == true                         │
│      → increment_env_var(id) RPC                  │
│        ※インクリメント前の値を使用               │
│                                                   │
│    is_secret == true                              │
│      → get_env_var_secret(id) RPC                 │
│        （Supabase Vault から復号して返す）        │
│                                                   │
│    is_secret == false && value != null            │
│      → ev.value をそのまま使用                   │
└───────────────────────────────────────────────────┘
```

### 組み込み環境変数（自動設定）

| 変数名 | 値 |
|---|---|
| `OPENCI_BUILD_ID` | ビルドUUID |
| `OPENCI_PROJECT_ID` | プロジェクトUUID |
| `OPENCI_TAG` | タグ名（タグビルドの場合） |
| `OPENCI_BRANCH` | ブランチ名（ブランチビルドの場合） |
| `OPENCI_COMMIT_SHA` | コミットSHA（ある場合） |


---

## 5. ワークフローステップの実行

### YAML形式（GitHub Actions互換）

```yaml
jobs:
  build:
    steps:
      - name: Install dependencies
        run: flutter pub get
      - name: Build iOS
        run: flutter build ios --release
```

### ステップ実行フロー

```
for i, step in steps:
  1. beginStep(i, name)          // ログにステップコンテキスト付与開始
  2. isBuildCancelled(buildId)   // キャンセル確認
     → cancelled なら complete('cancelled') で終了
  3. shell.run(command)          // シェルコマンド実行
     stdout → logger.info()
     stderr → logger.warning()
  4. 成功 → endStep()、次のステップへ
     失敗 → logger.error(), complete('failure'), 終了
```

- **キャンセル確認**: 各ステップの**開始前**に `builds.status == 'cancelled'` をチェックする
- **ステップ失敗時**: 残りのステップをスキップし即座に `failure` で終了

---

## 6. ログシステム

### ログの流れ

```
コマンド出力 / 内部メッセージ
        │
        ├─→ print() で標準出力（Workerプロセスのコンソール）
        │
        └─→ POST /rest/v1/build_logs（Supabase DB）
               ├─ build_run_id
               ├─ build_id
               ├─ message
               ├─ level: 'info' | 'warning' | 'error'
               ├─ stack_trace (エラー時のみ)
               ├─ step_index (ステップ実行中のみ)
               └─ step_name  (ステップ実行中のみ)
```

### ログレベル

| レベル | 使用場面 |
|---|---|
| `info` | ステップ開始・完了、コマンドstdout、ビルド状態メッセージ |
| `warning` | コマンドstderr（非ゼロ終了でなければビルドは続行） |
| `error` | ステップ失敗、予期しない例外（stack_trace付き） |

### 書き込みリトライ

ログ書き込みは最大3回リトライ（指数バックオフ: 0→1s→2s待機）。
最終試行も失敗した場合は**ログを無視してビルドを継続**する（ログ書き込み失敗でビルドが止まらない設計）。

### アーカイブ

ビルド完了後（success / failure / cancelled を問わず）、全ログをSupabase Storageに保存する。

```
アーカイブパス: {org_id}/{project_id}/{build_id}.txt
バケット: build-logs
```

アーカイブファイルの形式:
```
Build: <build_id>
Repository: <github_owner>/<github_repo>
Commit: <7文字のSHA>
Branch: <branch>
Status: <conclusion>
Date: <ISO8601 UTC>
================================================================================

[Step 1] Install dependencies
--------------------------------------------------------------------------------
2024-01-01T00:00:01Z flutter pub get
2024-01-01T00:00:05Z ✓ Step completed: Install dependencies

[Step 2] Build iOS
--------------------------------------------------------------------------------
2024-01-01T00:00:06Z ▶ Running step: Build iOS
...
```

アーカイブ成功後、`builds.log_archive_path` にパスを記録する。

---

## 7. エラーハンドリングまとめ

| エラー種別 | 動作 |
|---|---|
| `build_runs` 作成失敗 | `builds.status = 'failure'` に更新してビルド終了 |
| ワークフロー未設定 / 見つからない | ログにエラー記録 → `failure` で終了 |
| ステップのコマンド実行失敗 | ログにエラー+スタックトレース記録 → `failure` で終了（後続ステップはスキップ） |
| キャンセル検知（ステップ開始前） | `cancelled` で終了、残ステップはスキップ |
| 予期しない例外（外側のcatch） | ログにエラー記録 → `failure` で終了 |
| ポーリングループエラー | コンソールにスタックトレース出力 → 10秒後に再開（Workerは落ちない） |
| ログ書き込み失敗 | 最大3回リトライ後は無視（ビルドは継続） |
| ログアーカイブ失敗 | コンソールにエラー出力のみ（ビルド結果には影響しない） |

---

## 8. セキュリティモデル

| アクター | アクセス方法 | 権限範囲 |
|---|---|---|
| Worker（`service_role`） | Supabase PostgREST + service_role key | 全テーブルへのCRUD（RLSバイパス） |
| ブラウザ（authenticated user） | Supabase PostgREST + JWT | RLSポリシーで自分の組織のみ |
| Vault シークレット | `get_env_var_secret(uuid)` SECURITY DEFINER RPC | Worker経由のみ（`vault.decrypted_secrets` 直アクセス不可） |

> **注意**: 現在のWorkerは `service_role_key` を使用しているため、RLSをバイパスして全データにアクセスできる。
> 本番環境では、認証情報ファイルの保護（ファイルパーミッション、秘密鍵管理）が重要。
