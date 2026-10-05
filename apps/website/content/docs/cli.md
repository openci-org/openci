---
layout: genuine-docs
title: CLIリファレンス
description: ターミナルからGenuineCIへ。インストール、ログイン、チームの切り替えに必要なコマンド。
group: 環境とツール
eyebrow: AT YOUR COMMAND
reading: 3 min read
---
## インストール

Dart 3.11.5以降で、CLIをインストールします。

```sh
dart install genuineci_cli
genuineci --help
```

コマンドが見つからない場合は、[DartのPATH設定](https://dart.dev/tools/dart-install)を確認してください。

## ログイン

ダッシュボードと同じメールアドレス・パスワードでログインします。パスワードは対話プロンプトで入力します。

```sh
genuineci login
```

別のサーバーを使う場合は、HTTPSのURLを指定します。

```sh
genuineci login --server https://ci.example.com
```

セルフホストのFirebaseプロジェクトを使う場合は、`--firebase-api-key` でそのプロジェクトのWeb APIキーも指定します。

## 現在の状態を確認する

現在のプロファイル、サーバー、チームを確認します。

```sh
genuineci status
```

## チームを切り替える

対話形式でチームを選びます。矢印キーで移動し、Enterで決定します。Escでキャンセルできます。

```sh
genuineci switch team
```

シークレット関連のコマンドは、切り替え後のチームに対して実行されます。

## コマンド一覧

| コマンド | 用途 |
| --- | --- |
| `genuineci login` | リモート環境にログイン |
| `genuineci status` | 現在のプロファイルとチームを確認 |
| `genuineci switch team` | 操作対象のチームを切り替え |
| `genuineci list secrets` | シークレット名を一覧表示 |
| `genuineci register secret` | シークレットを登録・更新 |
| `genuineci register secretFile` | ファイルをBase64で登録 |
| `genuineci sync` | シークレット定義とワークスペースパスを生成 |
| `genuineci sync --secrets` | シークレット定義のみを生成 |
| `genuineci sync --paths` | ワークスペースパスのみを生成（ログイン不要） |
| `genuineci update` | CLIを更新 |

`sync` の生成ファイルは `openci/generated/` に保存されます。ワークフローでは `generated/secrets.g.dart` と `generated/paths.g.dart` を import してください。

## 表示言語と更新

CLIのメッセージを日本語または英語に切り替えられます。

```sh
genuineci use japanese
genuineci use english
```

最新の安定版に更新するには、次のコマンドを使います。

```sh
genuineci update
```
