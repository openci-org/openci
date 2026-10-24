---
title: Build and test Flutter
description: From static analysis to APK builds. Keep workflows readable with Flutter helpers.
---

## Install dependencies

Fetch project dependencies before running analysis or tests.

```dart
await ci.run('flutter pub get');
```

## Analyze and test

Call Flutter commands through dedicated helpers.

```dart
await ci.flutter.staticAnalysis();
await ci.flutter.unitTests();
```

Use `ci.run` to run a command directly when you need custom flags.

```dart
await ci.run('flutter analyze --fatal-infos');
```

## Build for Android

Both APK and Android App Bundle builds are supported.

```dart
await ci.flutter.buildApk();
await ci.flutter.buildAab();
```

The `flavor` argument is passed to Flutter's `--flavor` option. When omitted, Flutter uses its default selection.

```dart
await ci.flutter.buildApk(flavor: 'staging');
await ci.flutter.buildAab(flavor: 'production');
```

> Configure flavors in your app first. Signing and store distribution also require configuration beyond the build itself.

## Build for iOS

Run any Flutter command with `ci.run`. This example checks the build without signing it.

```dart
await ci.run('flutter build ios --no-codesign');
```

Prepare Xcode on macOS and the dependencies your project needs. TestFlight and App Store distribution require additional signing and distribution configuration.

## Run in individual packages

In a monorepo, choose the target directory with `dir` on each call.

```dart
await ci.flutter.staticAnalysis(dir: 'apps/mobile');
await ci.flutter.unitTests(dir: 'apps/mobile');
await ci.flutter.buildApk(dir: 'apps/mobile');
```
