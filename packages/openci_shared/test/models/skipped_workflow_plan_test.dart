import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('SkippedWorkflowPlan', () {
    test('round-trips the metadata needed for a skipped Check', () {
      final json = _plan.toJson();

      expect(json, {
        'owner': 'openci-owner',
        'repo': 'openci-repo',
        'workflowName': 'GenuineCI CLI CI',
        'workflowFileName': 'genuineci_cli_ci.dart',
        'teamId': 'team-1',
        'commitSha': 'commit-sha-1',
        'installationId': '98765',
        'reason': 'No changed files matched whenChanged.',
      });
      expect(
        SkippedWorkflowPlan.fromJson(
          jsonDecode(jsonEncode(_plan)) as Map<String, Object?>,
        ),
        _plan,
      );
    });

    test('requires the commit SHA', () {
      final json = _plan.toJson()..remove('commitSha');

      expect(
        () => SkippedWorkflowPlan.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });

    test('requires the installation ID to be a string', () {
      final json = _plan.toJson()..['installationId'] = 98765;

      expect(
        () => SkippedWorkflowPlan.fromJson(json),
        throwsA(isA<TypeError>()),
      );
    });

    test('rejects an empty workflow name', () {
      final json = _plan.toJson()..['workflowName'] = '';

      expect(
        () => SkippedWorkflowPlan.fromJson(json),
        throwsFormatException,
      );
    });

    test('rejects a whitespace-only exclusion reason', () {
      final json = _plan.toJson()..['reason'] = ' \t\n ';

      expect(
        () => SkippedWorkflowPlan.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('reason'),
          ),
        ),
      );
    });

    test('rejects a planner-supplied GitHub base URL', () {
      final json = _plan.toJson()
        ..['githubBaseUrl'] = 'https://untrusted.example';

      expect(
        () => SkippedWorkflowPlan.fromJson(json),
        throwsA(isA<UnrecognizedKeysException>()),
      );
    });

    test('rejects server-owned Check IDs', () {
      final json = _plan.toJson()..['checkRunId'] = 123;

      expect(
        () => SkippedWorkflowPlan.fromJson(json),
        throwsA(isA<UnrecognizedKeysException>()),
      );
    });
  });
}

const _plan = SkippedWorkflowPlan(
  owner: 'openci-owner',
  repo: 'openci-repo',
  workflowName: 'GenuineCI CLI CI',
  workflowFileName: 'genuineci_cli_ci.dart',
  teamId: 'team-1',
  commitSha: 'commit-sha-1',
  installationId: '98765',
  reason: 'No changed files matched whenChanged.',
);
