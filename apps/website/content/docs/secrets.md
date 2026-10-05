---
layout: genuine-docs
title: シークレット
description: APIトークンや設定ファイルをチームで管理し、ワークフローから使うための準備をします。
group: ワークフロー
eyebrow: CONFIGURE YOUR BUILD
reading: 3 min read
---
## チームを確認する

シークレット操作は、CLIで選択しているチームに対して行われます。

```sh
genuineci status
genuineci switch team
```

## シークレットを登録する

対話形式で名前と値を入力します。値の入力は非表示になります。

```sh
genuineci register secret
```

同じ名前のシークレットを登録すると、既存の値が更新されます。

## 名前の一覧を見る

値を表示せずに、登録されている名前だけを確認します。

```sh
genuineci list secrets
```

## ファイルを登録する

ファイルをBase64のシークレットとして登録できます。

```sh
genuineci register secretFile
```

対話形式でファイルを選択すると、ファイル名からシークレット名が生成されます。たとえば `google-services.json` は `GOOGLE_SERVICES_JSON_BASE64` になります。

> 既存の名前と一致すると、そのシークレットが更新されます。登録先のチームとファイルを確認してから実行してください。

## 定義を同期する

ワークフローのプロジェクト内で、シークレットの定義を更新します。

```sh
genuineci sync secrets
```

チームを切り替えた場合も、必要に応じて再度同期します。CLIのインストールとログインは[CLIリファレンス](/docs/cli/)を参照してください。
