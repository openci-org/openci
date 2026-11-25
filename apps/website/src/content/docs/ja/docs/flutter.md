---
title: Flutterのビルドとテスト
description: Flutter SDK のバージョンを指定し、単体テストと Patrol テストを実行して Android・iOS アプリをビルドします。
---

## Flutter のバージョンを指定する

`OpenCI.init` の `flutterVersion` に、アプリで使うバージョンを文字列リテラルで指定します。CI は依存関係を解決する前にそのバージョンを選択します。省略時はビルドイメージの既定の SDK が使われます。ローカル実行では、手元でパスの通っている Flutter SDK を使います。

```dart
final ci = await OpenCI.init(
  workflowName: 'Flutter CI',
  ciTriggers: [CITrigger.pullRequest(branch: 'main')],
  flutterVersion: '3.47.8',
);
```

## 依存関係を取得する

解析やテストの前に、プロジェクトの依存関係を取得します。

```dart
await ci.run('flutter pub get');
```

## 静的解析とテスト

Flutterのコマンドは、専用のヘルパーから呼び出せます。

```dart
await ci.flutter.staticAnalysis();
await ci.flutter.unitTests();
```

独自のフラグを指定したいときは `ci.run` でコマンドを直接実行できます。

```dart
await ci.run('flutter analyze --fatal-infos');
```

## iOS シミュレータで Patrol テストを実行する

`openci_workflow` 0.4.4 以降では、シミュレータを起動してその端末 ID を Patrol に渡せます。ワークフローを実行する Mac に Xcode と対応する iOS シミュレータランタイムをインストールしてください。既定の端末は iPhone 17 Pro で、iOS 26 以降が必要です。

アプリに Patrol 用の iOS テストターゲットを設定します。ヘルパーはプロジェクトの `patrol_cli` を実行するので、依存関係に含まれていなければ、アプリのディレクトリで `flutter pub add --dev patrol_cli` を実行してください。例のテストファイルはアプリ内のパスに置き換えます。[Patrol のセットアップ手順](https://patrol.leancode.co/documentation)

```dart
final simulator = await ci.launchIosSimulator();
try {
  await ci.patrol.test(
    device: simulator.id,
    targets: ['patrol_test/app_startup_test.dart'],
  );
} finally {
  await simulator.dispose();
}
```

`launchIosSimulator()` は新しく作成した端末の起動完了まで待ちます。テストに失敗した場合も `finally` でシミュレータを終了・削除し、ワークフローはテストの失敗を報告します。[OpenCI ダッシュボードで使っているワークフローの全文](https://github.com/openci-org/openci/blob/develop/openci/dashboard/ios/patrol.dart)

## Androidをビルドする

APKとAndroid App Bundleのビルドに対応しています。

```dart
await ci.flutter.buildApk();
await ci.flutter.buildAab();
```

`flavor` を指定すると、Flutterの `--flavor` オプションに渡されます。省略時はFlutterの既定の選択を使います。

```dart
await ci.flutter.buildApk(flavor: 'staging');
await ci.flutter.buildAab(flavor: 'production');
```

> Flavorはアプリ側に設定が必要です。署名やストアへの配布も、ビルドとは別に設定します。

## iOSをビルドする

任意のFlutterコマンドを `ci.run` で実行できます。署名をせずにビルドを確認する例です。

```dart
await ci.run('flutter build ios --no-codesign');
```

macOS上のXcodeと、プロジェクトが必要とする依存関係を用意してください。TestFlightやApp Storeへの配布では、別途署名・配布の設定が必要です。

## パッケージごとに実行する

モノレポでは、呼び出しごとの `dir` で対象ディレクトリを選びます。

```dart
await ci.flutter.staticAnalysis(dir: 'apps/mobile');
await ci.flutter.unitTests(dir: 'apps/mobile');
await ci.flutter.buildApk(dir: 'apps/mobile');
```
