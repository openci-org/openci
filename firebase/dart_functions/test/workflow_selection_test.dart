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
  final pullRequestDefinitions = definitions
      .where(
        (definition) =>
            definition.matches(eventType: 'pull_request', branch: 'develop'),
      )
      .toList();

  test('website source runs only Website CI', () {
    final result = plan(
      definitions,
      diff(['apps/website/src/components/Pricing.astro']),
    );
    expect(result.jobs.map((job) => job.workflowName), ['Website CI']);
    expect(result.skipped, hasLength(pullRequestDefinitions.length - 1));
  });
  test('docs-only changes allocate no build jobs', () {
    expect(plan(definitions, diff(['README.md'])).jobs, isEmpty);
    expect(
      plan(definitions, diff(['README.md'])).skipped,
      hasLength(pullRequestDefinitions.length),
    );
  });
  test('shared model changes also run their Dart Functions consumer', () {
    final result = plan(
      definitions,
      diff(['packages/openci_shared/lib/openci_shared.dart']),
    );
    expect(result.jobs.map((j) => j.workflowName).toSet(), {
      'OpenCI Shared CI',
      'Dart Functions CI',
      'Dart Format Check',
      'macOS release checks',
    });
  });
  test('runtime SDK and workspace resolution changes run all PR workflows', () {
    for (final path in [
      'packages/openci_workflow/lib/openci_workflow.dart',
      'pubspec.lock',
      'apps/dashboard/pubspec.yaml',
    ]) {
      expect(
        plan(definitions, diff([path])).jobs,
        hasLength(pullRequestDefinitions.length),
        reason: path,
      );
    }
  });
  test('macOS publication runs only on develop pushes', () {
    final cd = definitions.singleWhere(
      (definition) => definition.workflowName == 'Dashboard macOS CD',
    );
    expect(cd.cancelPreviousRuns, isFalse);
    expect(cd.matches(eventType: 'pull_request', branch: 'develop'), isFalse);
    expect(cd.matches(eventType: 'push', branch: 'feature'), isFalse);
    expect(cd.matches(eventType: 'push', branch: 'develop'), isTrue);
    expect(cd.ciTriggers.single.matchesChangedFiles(['README.md']), isFalse);
    expect(
      cd.ciTriggers.single.matchesChangedFiles([
        'apps/dashboard/lib/main.dart',
      ]),
      isTrue,
    );
  });
  test('macOS release checks never run on deployment pushes', () {
    final ci = definitions.singleWhere(
      (definition) => definition.workflowName == 'macOS release checks',
    );
    expect(ci.cancelPreviousRuns, isTrue);
    expect(ci.matches(eventType: 'pull_request', branch: 'develop'), isTrue);
    expect(ci.matches(eventType: 'push', branch: 'develop'), isFalse);
  });
  for (final (name, platform) in [
    ('Dashboard TestFlight IPA', 'ios'),
    ('Dashboard Google Play AAB', 'android'),
  ]) {
    test('$name runs only on matching develop pushes', () {
      final workflow = definitions.singleWhere((w) => w.workflowName == name);
      final trigger = workflow.ciTriggers.single;
      expect(trigger.matches(eventType: 'push', branch: 'develop'), isTrue);
      expect(trigger.matches(eventType: 'push', branch: 'feature'), isFalse);
      expect(
        trigger.matches(eventType: 'pull_request', branch: 'develop'),
        isFalse,
      );
      for (final path in [
        'apps/dashboard/lib/main.dart',
        'apps/dashboard/pubspec.yaml',
        'packages/openci_shared/pubspec.yaml',
        'openci/${workflow.workflowFileName}',
        'pubspec.yaml',
        'pubspec.lock',
      ]) {
        expect(trigger.matchesChangedFiles([path]), isTrue, reason: path);
      }
      for (final directory in ['ios', 'android', 'macos', 'web']) {
        final path = 'apps/dashboard/$directory/file';
        expect(
          trigger.matchesChangedFiles([path]),
          directory == platform,
          reason: path,
        );
      }
      expect(
        trigger.matchesChangedFiles([
          'README.md',
          'apps/openci_cli/pubspec.yaml',
        ]),
        isFalse,
      );
    });
  }
  test('Node runtime changes run all Node workflows', () {
    final result = plan(definitions, diff(['.node-version']));
    expect(result.jobs.map((j) => j.workflowName).toSet(), {
      'Website CI',
      'Firebase Functions CI',
    });
  });
  test('Functions source and inputs select Firebase Functions CI', () {
    for (final path in [
      'firebase/functions/executor/github.ts',
      'firebase/functions/test/vitest/pull_request_checkout.test.ts',
      'firebase/generated/dispatch-admin/index.d.ts',
      'firebase/scripts/ci.sh',
      'firebase/healthcheck.ts',
      'firebase/package.json',
      'firebase/tsconfig.functions.json',
    ]) {
      expect(
        plan(definitions, diff([path])).jobs.map((job) => job.workflowName),
        ['Firebase Functions CI'],
        reason: path,
      );
    }
  });
  test('root npm inputs run Website and Firebase Functions CI', () {
    for (final path in [
      'package.json',
      'package-lock.json',
      'vite.config.mts',
    ]) {
      expect(
        plan(
          definitions,
          diff([path]),
        ).jobs.map((job) => job.workflowName).toSet(),
        {'Website CI', 'Firebase Functions CI'},
        reason: path,
      );
    }
  });
  test('Firebase Functions CI also checks pushes to develop', () {
    final functions = definitions.singleWhere(
      (workflow) => workflow.workflowName == 'Firebase Functions CI',
    );
    final push = functions.ciTriggers.singleWhere(
      (trigger) => trigger.type == 'push',
    );
    expect(functions.cancelPreviousRuns, isTrue);
    expect(push.matches(eventType: 'push', branch: 'develop'), isTrue);
    expect(push.matches(eventType: 'push', branch: 'feature'), isFalse);
    expect(
      push.matchesChangedFiles(['firebase/functions/executor/github.ts']),
      isTrue,
    );
  });
}
