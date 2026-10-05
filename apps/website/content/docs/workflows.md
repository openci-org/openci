---
layout: genuine-docs
title: Dartでワークフローを書く
description: 手順も、条件分岐も、関数も。アプリ開発で使っているDartを、そのままCIに。
group: ワークフロー
eyebrow: WORKFLOWS IN DART
reading: 4 min read
---
## ワークフローの基本

ワークフローは、リポジトリの `openci/` ディレクトリに置くDartファイルです。`OpenCI.init` でワークフローを初期化し、実行したいコマンドを順番に呼び出します。

```dart
import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'Dart checks',
    ciTriggers: [CITrigger.push(branch: 'main')],
  );

  await ci.run('dart pub get');
  await ci.run('dart analyze --fatal-infos');
  await ci.run('dart test');
}
```

> プランナーが実行前に読み取れるように、ワークフロー名とトリガーのブランチは文字列リテラルで定義してください。

## シェルコマンドを実行する

`ci.run` は `sh` を使ってコマンドを実行します。標準出力・標準エラーがビルドログに表示され、失敗したコマンドの終了コードでワークフローが終了します。

```dart
await ci.run('dart format --output=none --set-exit-if-changed .');
await ci.run('dart analyze --fatal-infos');
```

コマンドに `await` を付けると、ひとつの処理が完了してから次の処理に進みます。

## 処理を関数にまとめる

複数のワークフローで共通する処理は、Dartの関数にできます。

```dart
Future<void> checkFlutter(OpenCI ci) async {
  await ci.run('flutter pub get');
  await ci.flutter.staticAnalysis();
  await ci.flutter.unitTests();
}
```

通常のDartファイルとして切り出し、必要なワークフローからインポートできます。

## モノレポで実行する

`workingDirectory` は、リポジトリルートからの相対パスで指定します。

```dart
await ci.run(
  'flutter analyze',
  workingDirectory: 'apps/mobile',
);
```

ワークフロー全体の既定のディレクトリには、`OpenCI.init` の `currentWorkingDirectory` を使います。Flutterヘルパーは呼び出しごとの `dir` も指定できます。

```dart
await ci.flutter.unitTests(dir: 'apps/mobile');
```

## 手元で実行する

リポジトリルートからDartファイルを実行します。

```sh
dart run openci/flutter_ci.dart
```

必要なSDKとビルドツールは、実行環境側に用意してください。詳しくは[クイックスタート](/docs/quickstart/)を参照してください。
