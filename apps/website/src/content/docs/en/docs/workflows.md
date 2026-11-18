---
title: Write workflows in Dart
description: Steps, conditionals, and functions. Bring the Dart you use for app development to CI.
---

## Workflow basics

Save this example as `openci/dart_ci.dart` in a Dart package with tests. It uses `openci_workflow` 0.4.2 or later to check formatting, analyze the package, and run its tests.

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

`checkFormat()` checks tracked and non-ignored new Dart files in the Git checkout without rewriting them. Analysis fails on warnings by default. Set `fatalInfos: true` to fail on info-level diagnostics too.

## Run shell commands

`ci.run` executes commands using `sh`. Standard output and standard error appear in the build log. A failed command ends the workflow with that command's exit code.

```dart
await ci.run('dart doc');
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

Use `currentWorkingDirectory` in `OpenCI.init` to set the workflow's default directory. The Dart and Flutter helpers accept a repository-relative `dir` that overrides the default for one call.

```dart
await ci.dart.test(dir: 'packages/shared');
await ci.flutter.unitTests(dir: 'apps/mobile');
```

## Run locally

Run the Dart file from the repository root.

```sh
dart run openci/dart_ci.dart
```

Install the required SDKs and build tools in the execution environment. See the [Quickstart](/en/docs/quickstart/) for details.

## Identify the revision tested on a PR

Read `ci.context` when a step needs the event that started the run. For a PR, `headSha` identifies the last commit on the source branch used for this run. `checkoutSha` identifies the merge commit OpenCI actually tested against the base branch.

```dart
final context = ci.context;
if (context is PullRequestContext) {
  print('PR #${context.number}: ${context.headBranch} → ${context.baseBranch}');
  print('Tested merge: ${context.checkoutSha}');
}
```

A push produces a `PushContext` and a local invocation produces a `LocalContext`, so the example prints these details only on a PR.

## Cancel older PR runs

With `openci_workflow` 0.2.3 or later and a server that supports PR auto-cancellation, enable `cancelPreviousRuns` in `OpenCI.init`.

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
