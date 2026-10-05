# OpenCI Workflow

Write OpenCI workflows in Dart. Define branch triggers, run shell commands, and stream command output to OpenCI's build logs.

## Install

Add the SDK to your repository's root package:

```sh
dart pub add --dev openci_workflow
```

For a Flutter repository, use `flutter pub add --dev openci_workflow`.

## Define a workflow

Create `openci/static_analysis.dart` in the repository root:

```dart
import 'package:openci_workflow/openci_workflow.dart';

Future<void> main() async {
  final openCI = await OpenCI.init(
    workflowName: 'Static Analysis',
    ciTriggers: [
      CITrigger.push(branch: 'main'),
      CITrigger.pullRequest(branch: 'main'),
    ],
  );

  await openCI.run('dart analyze --fatal-infos');
}
```

OpenCI discovers Dart files in `openci/` and matches their declared triggers to GitHub events. Keep workflow names and trigger branches as string literals so the planner can read them without executing the workflow.

For Flutter analysis, use `await openCI.flutter.staticAnalysis()` or pass your preferred `flutter analyze` flags to `openCI.run()`.

Run Flutter tests with an optional time zone and tag exclusion:

```dart
await openCI.flutter.unitTests(tz: TimeZone.asiaTokyo, excludeTags: 'golden');
```

The `tz` argument accepts `TimeZone.asiaTokyo` or `TimeZone.utc` and sets the command's `TZ` environment variable. Omitting it preserves the inherited time zone. The `excludeTags` argument is passed as Flutter's `--exclude-tags` selector, including expressions such as `'golden || slow'`. Omit it to run without a tag exclusion. Use `dir` to override the workflow's working directory for that call.

Build Android APKs and app bundles with an optional product flavor:

```dart
await openCI.flutter.buildApk(flavor: 'staging');
await openCI.flutter.buildAab(flavor: 'production');
```

The `flavor` argument is passed to Flutter's `--flavor` option. Omit it to keep Flutter's default flavor selection. Both methods also accept `dir` to override the workflow's working directory for that call.

## Run locally

```sh
dart pub get
dart run openci/static_analysis.dart
```

Commands run sequentially when awaited. A failed command exits the workflow with the same exit code. Commands use `sh`, so the runtime needs a Unix shell and the tools called by the workflow.

Use `workingDirectory` to run a command relative to the repository root:

```dart
await openCI.run('flutter analyze', workingDirectory: 'apps/mobile');
```

## Build logs

Command output is always printed to stdout and stderr. OpenCI workers provide `LOKI_URL`, `OPENCI_RUN_ID`, and `OPENCI_BUILD_JOB_ID` to also send structured build logs to Loki. Without `LOKI_URL`, local execution only prints to the terminal.

Log forwarding failures produce a warning and do not change the command's exit status.
