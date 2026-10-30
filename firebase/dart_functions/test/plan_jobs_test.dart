import 'package:openci_dart_functions/src/github_webhook_payload.dart';
import 'package:openci_dart_functions/src/plan_jobs.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('planJobs', () {
    test('creates complete job metadata only for matching workflows', () {
      final jobs = planJobs(
        event: _pushEvent(),
        teamId: 'team-1',
        files: [
          _workflow('CITrigger.push(branch: \'main\')', name: 'ci.dart'),
          _workflow('CITrigger.push(branch: \'develop\')'),
        ],
      );

      expect(jobs, hasLength(1));
      expect(jobs.single.toJson(), {
        'owner': 'openci-org',
        'repo': 'openci',
        'workflowName': 'CI',
        'workflowFileName': 'ci.dart',
        'teamId': 'team-1',
        'commitSha': 'abc123',
        'commitMessage': 'feat: planner',
        'branch': 'main',
        'runsOn': 'macos-latest',
        'installationId': '998877',
      });
    });

    test('matches the push trigger targeting develop', () {
      final jobs = planJobs(
        event: _pushEvent(branch: 'develop'),
        teamId: 'team-1',
        files: [_workflow(_multipleTriggers)],
      );

      expect(jobs, hasLength(1));
      expect(jobs.single.branch, 'develop');
      expect(jobs.single.pullRequestNumber, isNull);
    });

    test('ignores a push to an unmatched branch', () {
      expect(
        planJobs(
          event: _pushEvent(),
          teamId: 'team-1',
          files: [_workflow(_multipleTriggers)],
        ),
        isEmpty,
      );
    });

    test('matches PRs by base branch and checks out the head', () {
      final jobs = planJobs(
        event: _pullRequestEvent(
          baseBranch: 'develop',
          headBranch: 'feature/ci',
        ),
        teamId: 'team-1',
        files: [_workflow(_multipleTriggers)],
      );

      expect(jobs, hasLength(1));
      expect(jobs.single.commitSha, 'head-sha');
      expect(jobs.single.branch, 'feature/ci');
      expect(jobs.single.pullRequestNumber, 42);
      expect(jobs.single.commitMessage, 'feat: multiple triggers');
    });

    test('ignores a PR whose head matches but base does not', () {
      expect(
        planJobs(
          event: _pullRequestEvent(baseBranch: 'main', headBranch: 'develop'),
          teamId: 'team-1',
          files: [_workflow(_multipleTriggers)],
        ),
        isEmpty,
      );
    });

    test('creates one job when multiple triggers match', () {
      final jobs = planJobs(
        event: _pushEvent(branch: 'develop'),
        teamId: 'team-1',
        files: [
          _workflow('''
            CITrigger.push(branch: '*'),
            CITrigger.push(branch: 'develop'),
            CITrigger.push(branch: 'develop'),
          '''),
        ],
      );

      expect(jobs, hasLength(1));
    });

    test('preserves whenChanged workflows for later path evaluation', () {
      final jobs = planJobs(
        event: _pushEvent(),
        teamId: 'team-1',
        files: [
          _workflow(
            "CITrigger.push(branch: 'main', whenChanged: ['apps/dashboard/**'])",
          ),
        ],
      );

      expect(jobs, hasLength(1));
    });

    test('returns no jobs when there are no workflow files', () {
      expect(
        planJobs(event: _pushEvent(), teamId: 'team-1', files: []),
        isEmpty,
      );
    });
  });
}

GitHubWebhookPayload _pushEvent({String branch = 'main'}) =>
    GitHubWebhookPayload.fromRawJson(
      eventType: 'push',
      rawJson: {
        'ref': 'refs/heads/$branch',
        'head_commit': {'id': 'abc123', 'message': 'feat: planner\n\ndetails'},
        'repository': {
          'name': 'openci',
          'owner': {'login': 'openci-org'},
        },
        'installation': {'id': 998877},
        'deleted': false,
      },
    );

GitHubWebhookPayload _pullRequestEvent({
  required String baseBranch,
  required String headBranch,
}) => GitHubWebhookPayload.fromRawJson(
  eventType: 'pull_request',
  rawJson: {
    'number': 42,
    'pull_request': {
      'head': {'sha': 'head-sha', 'ref': headBranch},
      'base': {'ref': baseBranch},
      'title': 'feat: multiple triggers',
    },
    'repository': {
      'name': 'openci',
      'owner': {'login': 'openci-org'},
    },
    'installation': {'id': 998877},
  },
);

OpenCIFile _workflow(String triggers, {String name = 'dashboard_ci.dart'}) =>
    OpenCIFile(
      name: name,
      path: 'openci/$name',
      content:
          '''
Future<void> main() async {
  await OpenCI.init(workflowName: 'CI', ciTriggers: [$triggers]);
}
''',
    );

const _multipleTriggers = '''
  CITrigger.pullRequest(branch: 'develop'),
  CITrigger.push(branch: 'develop'),
''';
