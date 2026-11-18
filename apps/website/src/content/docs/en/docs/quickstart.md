---
title: Quickstart
description: Add your first workflow to a familiar project. Start by running analysis and tests locally.
---

## Before you begin

This guide adds a Dart workflow to a Flutter project and runs it locally.

- Install Flutter with Dart 3.11.5 or later.
- Have a project where you can run `flutter analyze` and `flutter test`.
- Open a terminal in the project root.

> For a Dart package, install the SDK with `dart pub add --dev openci_workflow` and follow the [Dart workflow example](/en/docs/workflows/).

## 01 Add the SDK

Add the OpenCI workflow SDK to your Flutter project.

```sh
flutter pub add --dev openci_workflow
```

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

1. Sign in to the [web dashboard](https://dashboard.openci.org/) and select or create a team. Use Google to create a new account.
2. Open the team switcher and choose **Connect GitHub**. Select your repository and confirm the connection. The OpenCI GitHub App needs access to the repository, and your GitHub account needs **Write** access or higher.
3. For OpenCI Cloud, check the team's billing status under **Settings → Manage billing**. Register a payment card if prompted.
4. Commit `openci/flutter_ci.dart` and the dependency changes. Push your branch to the connected repository and open a pull request targeting `main`. Look for **Flutter CI** in the PR checks and open the job in the dashboard to see the analysis and test output.

The example also runs on pushes to `main`. If your repository uses another branch, update both triggers before committing. See [Triggers](/en/docs/triggers/) to run checks on stacked PRs or selected files.

## Next steps

- [Build and test Flutter](/en/docs/flutter/) — Build APKs and App Bundles
- [Write workflows in Dart](/en/docs/workflows/) — Reuse functions and configure monorepos
- [CLI reference](/en/docs/cli/) — Log in and switch teams
