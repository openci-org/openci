import 'package:openci_server/build_job/build_job_plan_mapper.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('BuildJobPlanMapper', () {
    test('maps planner fields and initializes server-owned fields', () {
      const plan = BuildJobPlan(
        owner: 'openci-owner',
        repo: 'openci-repo',
        workflowName: 'Dashboard CI',
        workflowFileName: 'dashboard_ci.dart',
        teamId: 'team-1',
        workflowId: 'workflow-1',
        commitSha: 'commit-sha-1',
        commitMessage: 'Add mapper',
        pullRequestNumber: 42,
        branch: 'feature/mapper',
        tagName: 'v1.0.0',
        jobKey: 'test',
        workflowJobKey: 'dashboard-test',
        matrix: {'os': 'macos', 'arch': 'arm64'},
        matrixLabel: 'macos-arm64',
        workflowRunId: 'workflow-run-1',
        runsOn: 'macos-latest',
        githubBaseUrl: 'https://github.com',
        installationId: '98765',
      );
      final timestamp = DateTime.utc(2026, 9, 4, 6, 30);

      final job = plan.toDrift(id: 'job-1', timestamp: timestamp);

      expect(job.id, 'job-1');
      expect(job.status, BuildJobStatus.QUEUED);
      expect(job.owner, plan.owner);
      expect(job.repo, plan.repo);
      expect(job.workflowName, plan.workflowName);
      expect(job.workflowFileName, plan.workflowFileName);
      expect(job.teamId, plan.teamId);
      expect(job.workflowId, plan.workflowId);
      expect(job.commitSha, plan.commitSha);
      expect(job.commitMessage, plan.commitMessage);
      expect(job.pullRequestNumber, plan.pullRequestNumber);
      expect(job.tagName, plan.tagName);
      expect(job.branch, plan.branch);
      expect(job.jobKey, plan.jobKey);
      expect(job.workflowJobKey, plan.workflowJobKey);
      expect(job.matrix, plan.matrix);
      expect(job.matrixLabel, plan.matrixLabel);
      expect(job.workflowRunId, plan.workflowRunId);
      expect(job.runsOn, plan.runsOn);
      expect(job.githubBaseUrl, plan.githubBaseUrl);
      expect(job.installationId, plan.installationId);
      expect(job.runCount, 0);
      expect(job.createdAt, timestamp);
      expect(job.updatedAt, timestamp);
      expect(job.needs, isNull);
    });
  });
}
