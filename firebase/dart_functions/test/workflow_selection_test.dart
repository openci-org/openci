import 'dart:io';

import 'package:openci_dart_functions/src/github_webhook_payload.dart';
import 'package:openci_dart_functions/src/open_ci_parser.dart';
import 'package:openci_dart_functions/src/plan_jobs.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

const event = GitHubWebhookPayload(
  installationId: 1,
  eventType: 'pull_request',
  owner: 'org',
  repo: 'app',
  commitSha: 'head',
  branch: 'feature',
  triggerBranch: 'develop',
  triggerType: 'pull_request',
);

ParsedWorkflow workflow(String name, List<ParsedCITrigger> triggers) =>
    ParsedWorkflow(
      workflowName: name,
      workflowFileName: '$name.dart',
      ciTriggers: triggers,
    );
ParsedCITrigger trigger(
  List<String>? patterns, {
  String type = 'pullRequest',
  String branch = '*',
}) => ParsedCITrigger(type: type, branch: branch, paths: patterns);

WorkflowPlan plan(List<ParsedWorkflow> workflows, ChangedFilesResult? files) =>
    planJobs(
      event: event,
      teamId: 'team',
      workflows: workflows,
      changedFiles: files,
    );
ChangedFilesResult diff(List<String> paths) => ChangedFilesResult(
  paths: paths,
  isComplete: true,
  headSha: 'head',
  baseSha: 'base',
);

void main() {
  test('event AND branch AND paths; only applicable triggers are ORed', () {
    final result = plan([
      workflow('run', [
        trigger(['apps/**']),
        trigger(['pubspec.lock']),
      ]),
      workflow('skip', [
        trigger(['website/**']),
        trigger(null, type: 'push'),
      ]),
      workflow('unmatched', [trigger(null, branch: 'release')]),
    ], diff(['pubspec.lock']));
    expect(result.jobs.map((job) => job.workflowName), ['run']);
    expect(result.skipped.map((w) => w.workflowName), ['skip']);
  });
  test(
    'an unfiltered applicable trigger runs once without changed-file lookup',
    () {
      final workflows = [
        workflow('run', [
          trigger(['apps/**']),
          trigger(null),
        ]),
      ];
      expect(needsChangedFiles(workflows, event), isFalse);
      expect(plan(workflows, diff([])).jobs, hasLength(1));
    },
  );
  test('a complete empty diff skips only filtered workflows', () {
    final result = plan([
      workflow('skip', [
        trigger(['**']),
      ]),
      workflow('run', [trigger(null)]),
    ], diff([]));
    expect(result.jobs, hasLength(1));
    expect(result.skipped, hasLength(1));
  });
  test('incomplete and wrong-revision data cannot skip CI', () {
    final workflows = [
      workflow('run', [
        trigger(['apps/**']),
      ]),
    ];
    for (final files in [
      null,
      const ChangedFilesResult(
        paths: [],
        isComplete: false,
        reason: 'github_timeout',
      ),
      const ChangedFilesResult(
        paths: [],
        isComplete: true,
        headSha: 'different',
      ),
    ]) {
      final result = plan(workflows, files);
      expect(result.jobs, hasLength(1));
      expect(result.skipped, isEmpty);
      expect(result.pathFilterReason, isNotNull);
    }
  });

  final definitions = Directory('../../openci')
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .map(
        (f) =>
            parseOpenCIWorkflow(f.readAsStringSync(), f.uri.pathSegments.last),
      )
      .whereType<ParsedWorkflow>()
      .toList();

  test(
    'Stacked PR source runs only Stacked PR CI among the six configured workflows',
    () {
      expect(definitions, hasLength(6));
      final result = plan(definitions, diff(['apps/stacked_pr/src/index.ts']));
      expect(result.jobs.map((job) => job.workflowName), ['Stacked PR CI']);
      expect(result.skipped, hasLength(5));
    },
  );
  test('docs-only changes allocate no build jobs', () {
    expect(plan(definitions, diff(['README.md'])).jobs, isEmpty);
    expect(plan(definitions, diff(['README.md'])).skipped, hasLength(6));
  });
  test('shared model changes also run their Dart Functions consumer', () {
    final result = plan(
      definitions,
      diff(['packages/openci_shared/lib/openci_shared.dart']),
    );
    expect(result.jobs.map((j) => j.workflowName).toSet(), {
      'OpenCI Shared CI',
      'Dart Functions CI',
    });
  });
  test('runtime SDK and workspace resolution changes run all workflows', () {
    for (final path in [
      'packages/openci_workflow/lib/openci_workflow.dart',
      'pubspec.lock',
      'apps/dashboard/pubspec.yaml',
    ]) {
      expect(plan(definitions, diff([path])).jobs, hasLength(6), reason: path);
    }
  });
  test('Node runtime changes run both Node workflows', () {
    final result = plan(definitions, diff(['.node-version']));
    expect(result.jobs.map((j) => j.workflowName).toSet(), {
      'Stacked PR CI',
      'Website CI',
    });
  });
}
