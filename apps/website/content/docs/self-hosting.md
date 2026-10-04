---
layout: genuine-docs
title: セルフホスト
description: 実行環境も、自分の手に。Apple SiliconのMacを使ったGenuineCIの構成を知る。
group: 環境とツール
eyebrow: YOUR MACHINES, TOO
reading: 3 min read
---
## 自分の環境で動かす

GenuineCIはオープンソースのCIです。Apple SiliconのMacを実行マシンとして、ワークフローを動かす構成を用意できます。

ソースコードと構成ファイルは、[GitHubリポジトリ](https://github.com/openci-org/openci)で公開しています。

## 主な構成

| コンポーネント | 役割 |
| --- | --- |
| ダッシュボード | チーム、リポジトリ、ビルド結果を扱う |
| API / プランナー | GitHubイベントからワークフローを計画する |
| ワーカー | Mac上でビルドジョブを実行する |
| GitHub App | 対象リポジトリとの連携とイベントの受信 |

ローカルでDartワークフローを実行するだけなら、これらを起動する必要はありません。[クイックスタート](/docs/quickstart/)から試せます。

## ローカル開発環境

リポジトリの開発環境には、APIやFirebase Auth Emulator、Orchard Controller、Macワーカーをまとめて起動するコマンドがあります。

```sh
genuineci dev start
```

このコマンドはGenuineCIのソースコードのチェックアウト内で実行します。あらかじめ、Docker Compose 2.24.4以降、Compose用の設定・認証情報、`base-macos` VMなどの準備が必要です。

> `dev start` はローカル開発向けのコマンドです。本番環境の公開や認証設定まで自動で完了するものではありません。

## 詳細なセットアップ

環境の前提条件や開発用の起動手順は、現在の[CLI README](https://github.com/openci-org/openci/tree/develop/apps/openci_cli)を参照してください。

本番環境では、GitHub App、認証、ネットワーク、シークレット、実行マシンの管理を構成に合わせて設定します。質問や提案は[GitHub Issues](https://github.com/openci-org/openci/issues)へどうぞ。
