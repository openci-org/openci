---
layout: genuine-docs
title: クイックスタート
description: いつものプロジェクトに、最初のワークフローを。まずはローカルで解析とテストを実行してみましょう。
group: はじめに
eyebrow: YOUR FIRST WORKFLOW
reading: 5 min read
---
## はじめる前に

このガイドでは、FlutterプロジェクトにDartのワークフローを追加し、ローカルで実行します。

- Flutter / Dart SDKがインストールされていること
- `flutter analyze` と `flutter test` を実行できるプロジェクトがあること
- プロジェクトのルートディレクトリでターミナルを開いていること

> Dartパッケージでも同じように使えます。SDKの追加には `dart pub add`、解析・テストには `dart analyze` と `dart test` を使ってください。

## 01 SDKを追加する

Flutterプロジェクトに、ワークフロー用のSDKを追加します。

```sh
flutter pub add --dev openci_workflow
```

サービス名はGenuineCI、ワークフローのパッケージ名は `openci_workflow` です。

## 02 ワークフローを書く

リポジトリのルートに `openci/` ディレクトリを作り、その中に `flutter_ci.dart` を追加します。

```dart
import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'Flutter CI',
    ciTriggers: [
      CITrigger.push(branch: 'main'),
      CITrigger.pullRequest(branch: 'main'),
    ],
  );

  await ci.run('flutter pub get');
  await ci.flutter.staticAnalysis();
  await ci.flutter.unitTests();
}
```

`OpenCI.init` で名前とトリガーを設定し、`await` で処理を順番に実行します。解析やテストが失敗すると、ワークフローも失敗として終了します。

## 03 ローカルで確かめる

作成したファイルを、いつものDartスクリプトとして実行します。

```sh
dart run openci/flutter_ci.dart
```

ターミナルに解析とテストの結果が出力されます。CIへ送る前に、ワークフローが自分の環境で動くことを確認できます。

> ローカル実行では、手元のFlutterやビルドツールを使用します。ワークフローが必要とするSDKやコマンドをあらかじめ用意してください。

## 04 CIで動かす準備

リポジトリとGitHub Appの連携、チーム、実行マシンの準備ができたら、ワークフローをコミットして対象ブランチへpushします。`openci/` 内のDartファイルのトリガーが、GitHubイベントと照合されます。

[ダッシュボードを開く](https://dashboard.openci.org/)と、ビルドの状況を確認できます。実行イベントの指定は[トリガー](/docs/triggers/)を参照してください。

## 次にできること

- [Flutterのビルドとテスト](/docs/flutter/) — APKやApp Bundleをビルドする
- [Dartでワークフローを書く](/docs/workflows/) — 関数の再利用やモノレポの設定
- [CLIリファレンス](/docs/cli/) — ログインとチームの切り替え
