---
title: CLIリファレンス
description: ターミナルからOpenCIへ。インストール、ログイン、チームの切り替えに必要なコマンド。
---

## インストール

Dart 3.11.5以降で、CLIをインストールします。

```sh
dart install openci_cli_plus
openci --help
```

コマンドが見つからない場合は、[DartのPATH設定](https://dart.dev/tools/dart-install)を確認してください。

## ログイン

ダッシュボードと同じメールアドレス・パスワードでログインします。パスワードは対話プロンプトで入力します。

```sh
openci login
```

別のサーバーを使う場合は、HTTPSのURLを指定します。

```sh
openci login --server https://ci.example.com
```

セルフホストのFirebaseプロジェクトを使う場合は、`--firebase-api-key` でそのプロジェクトのWeb APIキーも指定します。

## 現在の状態を確認する

現在のプロファイル、サーバー、チームを確認します。

```sh
openci status
```

## チームを切り替える

対話形式でチームを選びます。矢印キーで移動し、Enterで決定します。Escでキャンセルできます。

```sh
openci switch team
```

シークレット関連のコマンドは、切り替え後のチームに対して実行されます。

## コマンド一覧

| コマンド                     | 用途                                         |
| ---------------------------- | -------------------------------------------- |
| `openci login`               | リモート環境にログイン                       |
| `openci status`              | 現在のプロファイルとチームを確認             |
| `openci switch team`         | 操作対象のチームを切り替え                   |
| `openci list secrets`        | シークレット名を一覧表示                     |
| `openci register secret`     | シークレットを登録・更新                     |
| `openci register secretFile` | ファイルをBase64で登録                       |
| `openci sync`                | シークレット定義とワークスペースパスを生成   |
| `openci sync --secrets`      | シークレット定義のみを生成                   |
| `openci sync --paths`        | ワークスペースパスのみを生成（ログイン不要） |
| `openci update`              | CLIを更新                                    |

`sync` の生成ファイルは `openci/generated/` に保存されます。ワークフローでは `generated/secrets.g.dart` と `generated/paths.g.dart` を import してください。

## 表示言語と更新

CLIのメッセージを日本語または英語に切り替えられます。

```sh
openci use japanese
openci use english
```

最新の安定版に更新するには、次のコマンドを使います。

```sh
openci update
```
