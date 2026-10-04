---
layout: genuine-docs
title: トリガー
description: どのタイミングでCIを動かすか。GitHubのpushとpull requestに、ワークフローをつなぎます。
group: ワークフロー
eyebrow: RUN AT THE RIGHT TIME
reading: 2 min read
---
## pushで実行する

指定したブランチへのpushをトリガーにします。

```dart
ciTriggers: [
  CITrigger.push(branch: 'main'),
],
```

## pull requestで実行する

プルリクエストを対象にする場合は、`CITrigger.pullRequest` を使います。

```dart
ciTriggers: [
  CITrigger.pullRequest(branch: 'main'),
],
```

## 複数のトリガーを組み合わせる

リストに複数のトリガーを指定できます。たとえば、main向けのプルリクエストとmainへのpushで同じチェックを実行します。

```dart
final ci = await OpenCI.init(
  workflowName: 'Flutter CI',
  ciTriggers: [
    CITrigger.push(branch: 'main'),
    CITrigger.pullRequest(branch: 'main'),
  ],
);
```

> ブランチ名は、対象リポジトリに合わせて変更してください。ワークフロー名やブランチの指定には文字列リテラルを使います。

## 実行されないとき

- ワークフローがリポジトリの `openci/` ディレクトリにあるか確認する
- 指定したブランチとGitHubイベントを確認する
- GitHub Appが対象リポジトリにアクセスできるか確認する
- ダッシュボードでビルドが作成されているか、実行マシンが利用できるか確認する

ワークフロー本体の書き方は[Dartでワークフローを書く](/docs/workflows/)を参照してください。
