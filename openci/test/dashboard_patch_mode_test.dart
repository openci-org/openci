import 'dart:convert';

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

  final releases = jsonEncode({
    'status': 'success',
    'data': {
      'releases': [
        {
          'version': '2.5.1+130',
          'platform_statuses': {'android': 'active', 'ios': 'active'},
        },
        {
          'version': '2.5.2+100',
          'platform_statuses': {'android': 'active', 'ios': 'draft'},
        },
        {
          'version': '2.5.2+99',
          'platform_statuses': {'android': 'active'},
        },
      ],
    },
  });

  test('uses the highest active build of the requested app version', () {
    expect(
      selectDashboardPatchRelease(
        releases,
        platform: 'android',
        versionName: '2.5.2',
      ),
      '2.5.2+100',
    );
  });

  test('waits for the requested version to be active on that platform', () {
    for (final versionName in ['2.5.2', '2.5.3']) {
      expect(
        selectDashboardPatchRelease(
          releases,
          platform: 'ios',
          versionName: versionName,
        ),
        isNull,
      );
    }
  });

  test('a failed release lookup cannot be treated as an unreleased app', () {
    expect(
      () => selectDashboardPatchRelease(
        '{"status":"error","error":{"code":"fetch_failed"}}',
        platform: 'android',
        versionName: '2.5.2',
      ),
      throwsFormatException,
    );
  });
}
