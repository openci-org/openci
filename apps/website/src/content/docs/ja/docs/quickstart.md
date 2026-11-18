---
title: クイックスタート
description: いつものプロジェクトに、最初のワークフローを。まずはローカルで解析とテストを実行してみましょう。
---

## はじめる前に

このガイドでは、FlutterプロジェクトにDartのワークフローを追加し、ローカルで実行します。

- Dart 3.11.5 以降を含む Flutter SDK がインストールされていること
- `flutter analyze` と `flutter test` を実行できるプロジェクトがあること
- プロジェクトのルートディレクトリでターミナルを開いていること

> Dart パッケージの場合は `dart pub add --dev openci_workflow` で SDK を追加し、[Dart のワークフロー例](/ja/docs/workflows/)を使ってください。

## 01 SDKを追加する

FlutterプロジェクトにOpenCIのワークフローSDKを追加します。

```sh
flutter pub add --dev openci_workflow
```

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

1. [Web ダッシュボード](https://dashboard.openci.org/)にサインインし、チームを選択または作成します。初めて登録する場合は Google アカウントを使います。
2. チームの切り替え画面で「GitHubと連携」を開き、リポジトリを選んで連携を確定します。OpenCI の GitHub App がそのリポジトリにアクセスでき、操作する GitHub ユーザーが **Write** 以上の権限を持っていることを確認してください。
3. OpenCI Cloud の場合は「設定 → 課金を管理」でチームの支払い設定を確認し、カード登録の案内があれば登録します。
4. `openci/flutter_ci.dart` と依存関係の変更をコミットします。連携したリポジトリに作業ブランチを push し、`main` 向けの PR を開きます。PR のチェックに **Flutter CI** が表示されたら、ダッシュボードでジョブを開くと解析とテストのログを読めます。

この例は `main` への push でも実行されます。別のブランチを使う場合は、コミット前に両方のトリガーを変更してください。PR を積み重ねる場合や、特定のファイルが変わったときだけ実行する場合は[トリガー](/ja/docs/triggers/)を参照してください。

## 次にできること

- [Flutterのビルドとテスト](/ja/docs/flutter/) — APKやApp Bundleをビルドする
- [Dartでワークフローを書く](/ja/docs/workflows/) — 関数の再利用やモノレポの設定
- [CLIリファレンス](/ja/docs/cli/) — ログインとチームの切り替え
