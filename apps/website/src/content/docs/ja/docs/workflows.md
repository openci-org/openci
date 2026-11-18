---
title: Dartでワークフローを書く
description: 手順も、条件分岐も、関数も。アプリ開発で使っているDartを、そのままCIに。
---

## ワークフローの基本

テストのある Dart パッケージで、次の例を `openci/dart_ci.dart` に保存します。`openci_workflow` 0.4.2 以降を使って、フォーマットの確認、静的解析、テストを順番に実行します。

```dart
import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final ci = await OpenCI.init(
    workflowName: 'Dart checks',
    ciTriggers: [
      CITrigger.pullRequest(branch: 'main'),
      CITrigger.push(branch: 'main'),
    ],
  );

  await ci.run('dart pub get');
  await ci.dart.checkFormat();
  await ci.dart.analyze(fatalInfos: true);
  await ci.dart.test();
}
```

`checkFormat()` は Git の管理下にある Dart ファイルと、無視対象を除く新規の Dart ファイルの書式を確認します。ファイルへの書き込みは行いません。静的解析は既定で warning を失敗として扱います。`fatalInfos: true` を指定すると info でも失敗します。

## シェルコマンドを実行する

`ci.run` は `sh` を使ってコマンドを実行します。標準出力・標準エラーがビルドログに表示され、失敗したコマンドの終了コードでワークフローが終了します。

```dart
await ci.run('dart doc');
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

ワークフロー全体の既定のディレクトリは `OpenCI.init` の `currentWorkingDirectory` で設定します。Dart と Flutter のヘルパーでは、リポジトリルートからの相対パスを `dir` に渡すと、その呼び出しだけ実行先を変更できます。

```dart
await ci.dart.test(dir: 'packages/shared');
await ci.flutter.unitTests(dir: 'apps/mobile');
```

## 手元で実行する

リポジトリルートからDartファイルを実行します。

```sh
dart run openci/dart_ci.dart
```

必要なSDKとビルドツールは、実行環境側に用意してください。詳しくは[クイックスタート](/ja/docs/quickstart/)を参照してください。

## PR でテストしたコミットを確認する

実行のきっかけになったイベントは `ci.context` で取得できます。PR の `headSha` は、その実行で使った作業ブランチの先端コミットです。`checkoutSha` を見ると、マージ先ブランチと組み合わせて実際にテストしたマージコミットが分かります。

```dart
final context = ci.context;
if (context is PullRequestContext) {
  print('PR #${context.number}: ${context.headBranch} → ${context.baseBranch}');
  print('Tested merge: ${context.checkoutSha}');
}
```

push の場合は `PushContext`、ローカル実行の場合は `LocalContext` になるため、この例は PR のときだけ情報を出力します。

## 古いPRのCIを自動キャンセルする

`openci_workflow` 0.2.3 以降と自動キャンセルに対応したサーバーで、`OpenCI.init` に `cancelPreviousRuns: true` を指定します。

```dart
final ci = await OpenCI.init(
  workflowName: 'PR checks',
  ciTriggers: [CITrigger.pullRequest(branch: 'main')],
  cancelPreviousRuns: true,
);
```

新しいコミットの実行が登録されると、同じリポジトリ・PR・ワークフローファイルの、
自動キャンセルを有効にしていた古い待機中・実行中ジョブをキャンセルします。
別PR、pushによる実行、完了済みジョブ、同じコミットの再実行は対象外です。
`paths`条件で新しい実行がスキップされた場合も、古い実行は継続します。

初期値は`false`です。最後まで実行したいデプロイ用ワークフローでは無効のままにします。
値にはリテラルの`true`か`false`を指定してください。実行中ジョブは通常約15秒で
キャンセルを検知し、その後VMの削除とGitHub Checkの更新を行います。
