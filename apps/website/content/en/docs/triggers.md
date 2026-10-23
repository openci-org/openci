---
layout: genuine-docs
title: Triggers
description: Choose when CI runs. Connect your workflows to GitHub pushes and pull requests.
group: Workflows
eyebrow: RUN AT THE RIGHT TIME
reading: 2 min read
---
## Run on push

Trigger a workflow when a push reaches the specified branch.

```dart
ciTriggers: [
  CITrigger.push(branch: 'main'),
],
```

## Run on pull requests

Use `CITrigger.pullRequest` to run checks for pull requests.

```dart
ciTriggers: [
  CITrigger.pullRequest(branch: 'main'),
],
```

## Combine triggers

A list can contain multiple triggers. For example, run the same checks for pull requests targeting main and for pushes to main.

```dart
final ci = await OpenCI.init(
  workflowName: 'Flutter CI',
  ciTriggers: [
    CITrigger.push(branch: 'main'),
    CITrigger.pullRequest(branch: 'main'),
  ],
);
```

> Change branch names to match your repository. Use string literals for workflow names and branches.

## If a workflow does not run

- Check that the workflow is in the repository's `openci/` directory.
- Check the configured branch and the GitHub event.
- Check that the GitHub App has access to the repository.
- Check the dashboard for a created build and available build machines.

See [Write workflows in Dart](/en/docs/workflows/) for the workflow itself.
