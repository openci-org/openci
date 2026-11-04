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

## Cancel older PR runs

With `openci_workflow` 0.2.3 and a server supporting PR auto cancellation, add
`cancelPreviousRuns: true` to `OpenCI.init`:

```dart
final ci = await OpenCI.init(
  workflowName: 'PR checks',
  ciTriggers: [CITrigger.pullRequest(branch: 'main')],
  cancelPreviousRuns: true,
);
```

A scheduled run for a new commit cancels older opted-in queued or running jobs
for the same repository, PR and workflow file. Other PRs, push runs, completed
jobs and same-commit reruns are unaffected. A run skipped by `paths` does not
cancel an older run. The default is `false`; leave it disabled for deployment
workflows that must finish. Use a literal `true` or `false`. Running jobs normally
observe cancellation within about 15 seconds, then clean up their VM and update
the GitHub Check.
