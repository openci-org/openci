---
title: Build and test Flutter
description: Pin a Flutter SDK, run unit and Patrol tests, and build Android and iOS apps.
---

## Choose the Flutter version

Set `flutterVersion` in `OpenCI.init` to the release your app uses. OpenCI selects it before resolving dependencies. Give the exact version as a string literal. If you omit it, CI uses the build image's default. A local run uses the Flutter SDK on your path.

```dart
final ci = await OpenCI.init(
  workflowName: 'Flutter CI',
  ciTriggers: [CITrigger.pullRequest(branch: 'main')],
  flutterVersion: '3.47.8',
);
```

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

## Run a Patrol test on an iOS simulator

With `openci_workflow` 0.4.4 or later, you can start a simulator and pass its device ID to Patrol. On the Mac running the workflow, install Xcode and a compatible iOS simulator runtime. The default device is an iPhone 17 Pro and requires iOS 26 or later.

Configure Patrol's iOS test target in your app. The helper runs the project's copy of `patrol_cli`. If the package is missing, add it from the app directory with `flutter pub add --dev patrol_cli`. Replace the test path below with one from your app. [Patrol setup guide](https://patrol.leancode.co/documentation)

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

`launchIosSimulator()` waits until the new simulator has booted. If the test fails, the `finally` block still shuts down and deletes the simulator, and the workflow reports the test failure. [Full example from the OpenCI dashboard](https://github.com/openci-org/openci/blob/develop/openci/dashboard_ios_patrol_ci.dart)

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
