import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('WebhookTaskPlan', () {
    test('decodes legacy jobs-only payloads with no skipped workflows', () {
      final plan = WebhookTaskPlan.fromJson({
        'jobs': [_job.toJson()],
      });

      expect(plan.jobs, [_job]);
      expect(plan.skippedWorkflows, isEmpty);
      expect(plan.changedFilesFallbackReason, isNull);
    });

    test('round-trips jobs-only plans and omits a null fallback reason', () {
      const plan = WebhookTaskPlan(jobs: [_job]);
      final json = plan.toJson();

      expect(json, {
        'jobs': [_job.toJson()],
        'skippedWorkflows': [],
      });
      expect(WebhookTaskPlan.fromJson(json), plan);
    });

    test('round-trips skips-only plans through wire JSON', () {
      const plan = WebhookTaskPlan(
        jobs: [],
        skippedWorkflows: [_skip],
      );

      expect(plan.toJson(), {
        'jobs': [],
        'skippedWorkflows': [_skip.toJson()],
      });
      expect(
        WebhookTaskPlan.fromJson(
          jsonDecode(jsonEncode(plan)) as Map<String, Object?>,
        ),
        plan,
      );
    });

    test('round-trips mixed results as nested JSON objects', () {
      const plan = WebhookTaskPlan(
        jobs: [_job],
        skippedWorkflows: [_skip],
      );

      expect(plan.toJson(), {
        'jobs': [_job.toJson()],
        'skippedWorkflows': [_skip.toJson()],
      });
      expect(
        WebhookTaskPlan.fromJson(
          jsonDecode(jsonEncode(plan)) as Map<String, Object?>,
        ),
        plan,
      );
    });

    test('round-trips a changed-file fallback reason', () {
      const plan = WebhookTaskPlan(
        jobs: [_job],
        changedFilesFallbackReason: 'Changed-file list is incomplete.',
      );
      final json = plan.toJson();

      expect(
        json['changedFilesFallbackReason'],
        'Changed-file list is incomplete.',
      );
      expect(WebhookTaskPlan.fromJson(json), plan);
    });

    test('omits an explicitly null fallback reason when re-encoding', () {
      final plan = WebhookTaskPlan.fromJson({
        'jobs': [],
        'changedFilesFallbackReason': null,
      });

      expect(plan.changedFilesFallbackReason, isNull);
      expect(plan.toJson(), isNot(contains('changedFilesFallbackReason')));
    });

    test('requires a jobs array', () {
      expect(
        () => WebhookTaskPlan.fromJson({}),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => WebhookTaskPlan.fromJson({'jobs': null}),
        throwsA(isA<TypeError>()),
      );
      expect(
        () => WebhookTaskPlan.fromJson({'jobs': 'invalid'}),
        throwsA(isA<TypeError>()),
      );
    });

    test('rejects job entries that are not objects', () {
      expect(
        () => WebhookTaskPlan.fromJson({
          'jobs': ['invalid'],
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('rejects a non-array skippedWorkflows value', () {
      expect(
        () => WebhookTaskPlan.fromJson({
          'jobs': [],
          'skippedWorkflows': {},
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('rejects explicitly null skippedWorkflows', () {
      expect(
        () => WebhookTaskPlan.fromJson({
          'jobs': [],
          'skippedWorkflows': null,
        }),
        throwsA(isA<DisallowedNullValueException>()),
      );
    });

    test('rejects skipped workflow entries that are not objects', () {
      expect(
        () => WebhookTaskPlan.fromJson({
          'jobs': [],
          'skippedWorkflows': [null],
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('rejects a non-string fallback reason', () {
      expect(
        () => WebhookTaskPlan.fromJson({
          'jobs': [],
          'changedFilesFallbackReason': false,
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('preserves required-field validation for nested jobs', () {
      final job = _job.toJson()..['owner'] = '';

      expect(
        () => WebhookTaskPlan.fromJson({
          'jobs': [job],
        }),
        throwsFormatException,
      );
    });

    test('preserves rejection of persistence fields in nested jobs', () {
      final job = _job.toJson()..['id'] = 'planner-owned-id';

      expect(
        () => WebhookTaskPlan.fromJson({
          'jobs': [job],
        }),
        throwsA(isA<UnrecognizedKeysException>()),
      );
    });

    test('preserves legacy GitHub URL handling for nested jobs', () {
      final job = _job.toJson()
        ..['githubBaseUrl'] = 'https://untrusted.example';
      final plan = WebhookTaskPlan.fromJson({
        'jobs': [job],
      });

      expect(plan.jobs.single, _job);
      expect(plan.jobs.single.toJson(), isNot(contains('githubBaseUrl')));
      expect(job['githubBaseUrl'], 'https://untrusted.example');
    });

    test('validates the reason in a nested skipped workflow', () {
      final skip = _skip.toJson()..['reason'] = '';

      expect(
        () => WebhookTaskPlan.fromJson({
          'jobs': [],
          'skippedWorkflows': [skip],
        }),
        throwsFormatException,
      );
    });

    test('rejects unknown completion fields', () {
      expect(
        () => WebhookTaskPlan.fromJson({
          'jobs': [],
          'status': 'completed',
        }),
        throwsA(isA<UnrecognizedKeysException>()),
      );
    });
  });
}

const _job = BuildJobPlan(
  owner: 'openci-owner',
  repo: 'openci-repo',
  workflowName: 'Planner CI',
  workflowFileName: 'build_job_planner_ci.dart',
  teamId: 'team-1',
  commitSha: 'commit-sha-1',
  branch: 'main',
  runsOn: 'macos-latest',
  installationId: '98765',
);

const _skip = SkippedWorkflowPlan(
  owner: 'openci-owner',
  repo: 'openci-repo',
  workflowName: 'GenuineCI CLI CI',
  workflowFileName: 'genuineci_cli_ci.dart',
  teamId: 'team-1',
  commitSha: 'commit-sha-1',
  installationId: '98765',
  reason: 'No changed files matched whenChanged.',
);
