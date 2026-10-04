---
layout: genuine-docs
title: Flutterのビルドとテスト
description: 静的解析からAPKのビルドまで。Flutterのためのヘルパーで、ワークフローを読みやすく。
group: ワークフロー
eyebrow: MADE FOR FLUTTER
reading: 3 min read
---
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
