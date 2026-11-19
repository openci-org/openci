import 'package:openci_workflow/openci_workflow.dart';
import 'package:openci_workflows/dashboard_patch_mode.dart';
import 'package:test/test.dart';

void main() {
  final repository = WorkflowRepository(
    owner: 'openci-org',
    name: 'openci',
    githubBaseUrl: Uri.https('github.com'),
  );

  PushContext push(String branch) => PushContext(
    repository: repository,
    jobId: 'job',
    runId: 'run',
    runNumber: 1,
    branch: branch,
    commitSha: 'head',
    checkoutSha: 'head',
  );

  test('pull requests pass --dry-run even when targeting develop', () {
    final pr = PullRequestContext(
      repository: repository,
      jobId: 'job',
      runId: 'run',
      runNumber: 1,
      number: 1,
      headBranch: 'feature',
      baseBranch: 'develop',
      headSha: 'head',
      baseSha: 'base',
      checkoutSha: 'merge',
    );
    expect(DashboardPatchMode.forContext(pr)?.shorebirdArgument, '--dry-run');
  });

  test('only develop pushes publish to stable', () {
    expect(
      DashboardPatchMode.forContext(push('develop'))?.shorebirdArgument,
      '--track=stable',
    );
    for (final branch in ['feature', 'refs/tags/v2.5.1']) {
      expect(DashboardPatchMode.forContext(push(branch)), isNull);
    }
    expect(DashboardPatchMode.forContext(const LocalContext()), isNull);
  });
}
