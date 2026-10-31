---
title: セルフホスト
description: Firebase、GCP、Apple SiliconのMacを使ったGenuineCIの構成を知る。
---

## 自分の環境で動かす

GenuineCIはオープンソースのCIです。FirebaseとGCPでジョブを管理し、Orchard経由でApple SiliconのMac上にビルド用VMを起動します。

ソースコードと構成ファイルは、[GitHubリポジトリ](https://github.com/openci-org/openci)で公開しています。

## 主な構成

| コンポーネント                  | 役割                                      |
| ------------------------------- | ----------------------------------------- |
| ダッシュボード・Firebase Auth   | サインイン、チームとビルドの管理          |
| Firebase SQL Connect            | チーム、ジョブ、ログ、課金状態の保存      |
| Firebase Functions              | Webhookの受信、ジョブ作成、実行の割り当て |
| Cloud Run executor              | Orchard経由のワークフロー実行と結果の記録 |
| Orchard Controller・Macワーカー | macOS VMの割り当てと起動                  |
| GitHub App                      | 対象リポジトリとの連携とイベントの受信    |

ローカルでDartワークフローを実行するだけなら、これらのデプロイは不要です。[クイックスタート](/ja/docs/quickstart/)から試せます。

## 開発とデプロイ

旧APIサーバー、PostgreSQLのCompose構成、`genuineci dev start`コマンドは廃止しました。単独で起動できるFirebase Auth Emulatorは引き続き利用できます。Functions、Data Connect、ビルド実行環境はそれぞれ設定します。

- [Firebaseの開発・エミュレーター設定](https://github.com/openci-org/openci/blob/develop/firebase/README.md)
- [FunctionsとCloud Runのデプロイ](https://github.com/openci-org/openci/blob/develop/firebase/functions/DEPLOYMENT.md)
- [Orchard Controllerの配置](https://github.com/openci-org/openci/blob/develop/infra/orchard/README.md)

自分の環境では、サービスアカウント、GitHub・Stripe連携、ネットワーク、シークレット、Macワーカーを設定してください。デプロイ記録内のプロジェクトIDなどはOpenCI本番環境の値なので、自分のリソースに置き換えます。
