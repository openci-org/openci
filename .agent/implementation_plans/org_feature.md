# 組織（Organization）機能 実装計画

## データモデル

### 新規コレクション

#### `users_v0/{userId}`

```
{
  userId: string,
  email: string,
  displayName: string,
  personalOrgId: string,       // パーソナル組織のID
  selectedOrgId: string,       // 現在選択中の組織
  orgIds: string[],            // 所属する全組織のID一覧
  createdAt: Timestamp,
  updatedAt: Timestamp,
}
```

#### `orgs_v0/{orgId}`

```
{
  id: string,
  name: string,
  slug: string,
  type: "personal" | "team",
  ownerId: string,
  members: [
    { role: "owner" | "admin" | "member" | "viewer", userId: string }
  ],
  memberIds: string[],          // Security Rules用（membersと同期）
  createdAt: Timestamp,
  updatedAt: Timestamp,
}
```

#### `orgs_v0/{orgId}/invitations_v0/{invitationId}`（将来用）

```
{
  id: string,
  email: string,
  role: "admin" | "member" | "viewer",
  status: "pending" | "accepted" | "declined",
  invitedBy: string,
  createdAt: Timestamp,
  expiresAt: Timestamp,
}
```

### 既存コレクション変更（`orgId` フィールド追加）

- `workflows_v1/{workflowId}` → + `orgId: string`
- `secrets_v0/{secretId}` → + `orgId: string`
- `build_jobs_v0/{buildJobId}` → + `orgId: string`

---

## 実装タスク

### Phase 1: 基盤（データモデル & バックエンド）

#### Task 1.1: Security Rules の更新

- [ ] `users_v0` のルール追加
- [ ] `orgs_v0` のルール追加（memberIds を使ったアクセス制御）
- [ ] `workflows_v1` を `orgId` ベースのアクセス制御に変更
- [ ] `secrets_v0` を `orgId` ベースのアクセス制御に変更
- [ ] `build_jobs_v0` を `orgId` ベースのアクセス制御に変更（runs, logs 含む）
- **注意**: 移行中の後方互換を保つため、一時的に `userId` ベースのルールも残す

#### Task 1.2: Firebase Functions の更新

- [ ] ユーザー登録時にパーソナル組織を自動作成する Cloud Function（`onAuthUserCreated`）
  - `users_v0/{userId}` ドキュメント作成
  - `orgs_v0/{orgId}` ドキュメント作成（type: "personal"）
- [ ] `createBuildJobs` 関数: workflow の `orgId` を build_job に引き継ぐ
- [ ] `createSecretV1` 関数: `orgId` パラメータを受け取り保存する
- [ ] メンバー管理用 Cloud Function（将来用、Phase 3 で実装）
  - メンバー追加: `members` と `memberIds` を同時更新 + `users_v0.orgIds` 更新
  - メンバー削除: 同上の逆操作

#### Task 1.3: 既存ユーザーのマイグレーションスクリプト

- [ ] 全既存ユーザーに対して:
  1. `users_v0/{userId}` ドキュメントを作成
  2. `orgs_v0/{orgId}` パーソナル組織を作成
  3. `workflows_v1` の該当ドキュメントに `orgId` をバックフィル
  4. `secrets_v0` の該当ドキュメントに `orgId` をバックフィル
  5. `build_jobs_v0` の該当ドキュメントに `orgId` をバックフィル
- [ ] マイグレーションの冪等性を確保（再実行可能にする）
- **実行方法**: Node.js スクリプト（Firebase Admin SDK 使用）

---

### Phase 2: フロントエンド（Dashboard）

#### Task 2.1: 新規登録ユーザーの登録フロー更新

- [ ] サインアップ後に Cloud Function でパーソナル組織が自動作成されることを確認
- [ ] `users_v0` からユーザー情報を読み込む Provider 作成
- [ ] 初回ログイン時に `selectedOrgId` を設定する処理

#### Task 2.2: 組織コンテキストの導入

- [ ] `SelectedOrgProvider` の作成（現在選択中の組織を管理）
- [ ] `WorkflowListProvider` のクエリを `userId` → `orgId` ベースに変更
- [ ] `SecretManagerProvider` のクエリを `userId` → `orgId` ベースに変更
- [ ] `BuildJobsListProvider` のクエリを `userId` → `orgId` ベースに変更
- [ ] ワークフロー作成時に `orgId` を付与する処理の追加

#### Task 2.3: UI更新

- [ ] ナビゲーションバー or Settings に組織セレクター追加
- [ ] Settings ページに組織管理セクション追加（名前変更 etc.）
- [ ] (将来) メンバー招待UI
- [ ] (将来) 組織作成UI

---

### Phase 3: CLIワーカーの更新

#### Task 3.1: CLIの `orgId` 対応

- [ ] `processJob` にて、build job から `orgId` を読み取る
- [ ] workflow や secrets の取得は既存のドキュメントID指定のため変更不要
- [ ] ログ出力に `orgId` 情報を追加（デバッグ用）

---

### Phase 4: クリーンアップ

#### Task 4.1: 後方互換の削除

- [ ] Security Rules から `userId` ベースのルールを削除
- [ ] 旧ルールが残っていないことを確認
- [ ] Dashboard から `userId` ベースのクエリを完全削除

---

## 実施順序

```
Phase 1.2 (Functions: onAuthUserCreated)
    ↓
Phase 1.3 (マイグレーションスクリプト)
    ↓
Phase 1.1 (Security Rules - 後方互換あり版)
    ↓
Phase 2.1 (新規登録フロー)
    ↓
Phase 2.2 (Provider のクエリ変更)
    ↓
Phase 2.3 (UI更新)
    ↓
Phase 3.1 (CLI更新)
    ↓
Phase 4.1 (クリーンアップ)
```

## 備考

- CLIワーカーは `dart_firebase_admin` を使用（Data Connect 未対応）
- Firestore のドキュメントサイズ上限 1MB → 組織メンバー数は実質数百人程度まで（CI/CDでは十分）
- `memberIds` は `members` 配列と常に同期する必要あり（Cloud Functions で管理）
