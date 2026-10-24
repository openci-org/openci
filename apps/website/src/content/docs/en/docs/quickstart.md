---
title: Quickstart
description: Add your first workflow to a familiar project. Start by running analysis and tests locally.
---

## Before you begin

This guide adds a Dart workflow to a Flutter project and runs it locally.

- Install the Flutter / Dart SDK.
- Have a project where you can run `flutter analyze` and `flutter test`.
- Open a terminal in the project root.

> The same approach works for Dart packages. Use `dart pub add` to add the SDK, and `dart analyze` and `dart test` for checks.

## 01 Add the SDK

Add the workflow SDK to your Flutter project.

```sh
flutter pub add --dev openci_workflow
```

The service is called GenuineCI. The workflow package is named `openci_workflow`.

## 02 Write a workflow

Create an `openci/` directory at the repository root and add `flutter_ci.dart` inside it.

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

Set the name and triggers with `OpenCI.init`, then use `await` to run steps in order. If analysis or tests fail, the workflow exits with a failure too.

## 03 Try it locally

Run the file as a regular Dart script.

```sh
dart run openci/flutter_ci.dart
```

Analysis and test results appear in the terminal. Check that your workflow works in your own environment before sending it to CI.

> Local runs use your installed Flutter SDK and build tools. Prepare the SDKs and commands your workflow needs in advance.

## 04 Prepare to run in CI

Once your repository, GitHub App connection, team, and build machines are ready, commit the workflow and push it to the target branch. The triggers in Dart files under `openci/` are matched against GitHub events.

[Open the dashboard](https://dashboard.openci.org/) to check your builds. See [Triggers](/en/docs/triggers/) for event configuration.

## Next steps

- [Build and test Flutter](/en/docs/flutter/) — Build APKs and App Bundles
- [Write workflows in Dart](/en/docs/workflows/) — Reuse functions and configure monorepos
- [CLI reference](/en/docs/cli/) — Log in and switch teams
