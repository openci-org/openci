---
title: Triggers
description: Choose which branches, pull requests, tags, and changed files trigger a workflow.
---

## Run on push

For a push, `branch` matches the branch that received the commits.

```dart
ciTriggers: [
  CITrigger.push(branch: 'main'),
],
```

GitHub also sends tag pushes. For example, `CITrigger.push(branch: 'refs/tags/v*')` matches a tag named `v1.2.0`.

## Run on pull requests

OpenCI runs PR checks when the source and destination branches belong to the same connected repository. The `branch` value matches the **base branch** (the merge destination). This trigger runs for a PR from `feature/login` into `main`.

```dart
ciTriggers: [
  CITrigger.pullRequest(branch: 'main'),
],
```

## Combine triggers

In a stack of PRs, the second PR targets the first PR's branch. Use `branch: '*'` to check PRs targeting any branch. A separate push trigger can still restrict push builds to `main`. The workflow runs when any trigger matches.

```dart
final ci = await OpenCI.init(
  workflowName: 'Flutter CI',
  ciTriggers: [
    CITrigger.push(branch: 'main'),
    CITrigger.pullRequest(branch: '*'),
  ],
);
```

## Run only when selected files change

Add `paths` to the push or pull request trigger you want to filter. This PR check runs when a change touches the mobile app, its shared package, a package manifest, the lockfile, or the workflow itself.

```dart
ciTriggers: [
  CITrigger.pullRequest(
    branch: '*',
    paths: [
      'apps/mobile/**',
      'packages/shared/**',
      '**/pubspec.yaml',
      'pubspec.lock',
      'openci/flutter_ci.dart',
    ],
  ),
],
```

Use a nonempty list of string literals relative to the repository root. Matches are case-sensitive. In a path, `*` matches within one segment and `**` can span directories. Omitting `paths` lets that trigger run for any change.

OpenCI considers the full PR diff, or the changes between the previous and new commits for a push. When the complete diff contains no match, the GitHub check shows **Skipped** and no build machine starts. If the changed-file list is incomplete, OpenCI runs the check. Running the Dart file locally always executes the workflow directly.

## If a workflow does not run

- Check that the workflow is a Dart file directly inside the repository's `openci/` directory.
- Check the event and target branch. Use literal strings for the workflow name and branches so OpenCI can read them before execution.
- Check that the GitHub App has access to the repository.
- Check the dashboard for a created build and available build machines.

See [Write workflows in Dart](/en/docs/workflows/) for the workflow itself.
