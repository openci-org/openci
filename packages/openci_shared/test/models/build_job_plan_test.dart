import 'package:json_annotation/json_annotation.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('BuildJobPlan', () {
    test('round-trips through JSON without persistence fields', () {
      const plan = BuildJobPlan(
        owner: 'openci-owner',
        repo: 'openci-repo',
        workflowName: 'Dashboard CI',
        workflowFileName: 'dashboard_ci.dart',
        teamId: 'team-1',
        workflowId: 'workflow-1',
        commitSha: 'commit-sha-1',
        commitMessage: 'Add shared BuildJobPlan',
        pullRequestNumber: 42,
        branch: 'feature/shared-plan',
        jobKey: 'test',
        workflowJobKey: 'dashboard-test',
        matrix: {'os': 'macos'},
        matrixLabel: 'macos',
        workflowRunId: 'workflow-run-1',
        runsOn: 'macos-latest',
        githubBaseUrl: 'https://github.com',
        installationId: '98765',
      );

      final json = plan.toJson();

      expect(BuildJobPlan.fromJson(json), equals(plan));
      expect(json, isNot(contains('id')));
      expect(json, isNot(contains('status')));
      expect(json, isNot(contains('runCount')));
      expect(json, isNot(contains('createdAt')));
      expect(json, isNot(contains('updatedAt')));
    });

    test('rejects persistence fields', () {
      final json = _buildJobPlan().toJson()..['id'] = 'planner-owned-id';

      expect(
        () => BuildJobPlan.fromJson(json),
        throwsA(isA<UnrecognizedKeysException>()),
      );
    });

    test('rejects needs because it is not part of the planner contract', () {
      final json = _buildJobPlan().toJson()..['needs'] = ['setup'];

      expect(
        () => BuildJobPlan.fromJson(json),
        throwsA(isA<UnrecognizedKeysException>()),
      );
    });

    test('rejects empty required fields', () {
      final json = _buildJobPlan().toJson()..['owner'] = '';

      expect(() => BuildJobPlan.fromJson(json), throwsFormatException);
    });
  });
}

BuildJobPlan _buildJobPlan() {
  return const BuildJobPlan(
    owner: 'openci-owner',
    repo: 'openci-repo',
    workflowName: 'Dashboard CI',
    workflowFileName: 'dashboard_ci.dart',
    teamId: 'team-1',
    commitSha: 'commit-sha-1',
    branch: 'main',
    runsOn: 'macos-latest',
    githubBaseUrl: 'https://github.com',
    installationId: '98765',
  );
}
