---
title: Write workflows in Dart
description: Steps, conditionals, and functions. Bring the Dart you use for app development to CI.
---

## Workflow basics

A workflow is a Dart file in your repository's `openci/` directory. Initialize it with `OpenCI.init`, then call the commands you want to run in order.

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

> Define workflow names and trigger branches as string literals so the planner can read them before execution.

## Run shell commands

`ci.run` executes commands using `sh`. Standard output and standard error appear in the build log. A failed command ends the workflow with that command's exit code.

```dart
await ci.run('dart format --output=none --set-exit-if-changed .');
await ci.run('dart analyze --fatal-infos');
```

Use `await` to wait for each command to finish before starting the next one.

## Reuse steps with functions

Put steps shared by multiple workflows into Dart functions.

```dart
Future<void> checkFlutter(OpenCI ci) async {
  await ci.run('flutter pub get');
  await ci.flutter.staticAnalysis();
  await ci.flutter.unitTests();
}
```

You can move these functions into regular Dart files and import them into your workflows.

## Work with monorepos

Set `workingDirectory` to a path relative to the repository root.

```dart
await ci.run(
  'flutter analyze',
  workingDirectory: 'apps/mobile',
);
```

Use `currentWorkingDirectory` in `OpenCI.init` to set the workflow's default directory. Flutter helpers also accept a `dir` for individual calls.

```dart
await ci.flutter.unitTests(dir: 'apps/mobile');
```

## Run locally

Run the Dart file from the repository root.

```sh
dart run openci/flutter_ci.dart
```

Install the required SDKs and build tools in the execution environment. See the [Quickstart](/en/docs/quickstart/) for details.
