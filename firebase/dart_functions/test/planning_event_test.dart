import 'dart:convert';

import 'package:openci_dart_functions/src/planning_event.dart';
import 'package:openci_dart_functions/src/planner_runtime.dart';
import 'package:test/test.dart';

void main() {
  final repository = {
    'id': 10,
    'name': 'app',
    'owner': {'id': 20, 'login': 'org'},
  };
  final sha = 'a' * 40;
  final push = {
    'installation': {'id': 30},
    'repository': repository,
    'ref': 'refs/heads/develop',
    'after': sha,
    'head_commit': {'id': sha, 'message': 'Commit\nBody'},
  };

  test('validates push identity while reusing the migrated payload parser', () {
    final event = PlanningEvent.parse('push', jsonEncode(push))!;
    expect(event.repositoryId, 10);
    expect(event.ownerId, 20);
    expect(event.webhook.commitSha, sha);
    expect(event.webhook.branch, 'develop');
    expect(event.webhook.commitMessage, 'Commit');
  });
  test('PRs match the base branch and check out the head SHA and branch', () {
    final event = PlanningEvent.parse(
      'pull_request',
      jsonEncode({
        'installation': {'id': 30},
        'repository': repository,
        'action': 'synchronize',
        'number': 7,
        'pull_request': {
          'head': {'sha': sha, 'ref': 'feature'},
          'base': {'repo': repository, 'ref': 'develop'},
          'title': 'PR title',
        },
      }),
    )!;
    expect(event.webhook.triggerBranch, 'develop');
    expect(event.webhook.branch, 'feature');
    expect(event.webhook.commitSha, sha);
    expect(event.webhook.pullRequestNumber, 7);
  });
  test('deletions and ignored PR actions produce no plan', () {
    expect(PlanningEvent.parse('push', '{"deleted":true}'), isNull);
    expect(PlanningEvent.parse('pull_request', '{"action":"closed"}'), isNull);
  });
  test('malformed metadata never reaches GitHub', () {
    for (final value in <Object?>[
      null,
      [],
      {},
      {...push, 'after': 'main'},
      {...push, 'after': 'b' * 40},
      {
        ...push,
        'installation': {'id': 1.5},
      },
      {
        ...push,
        'repository': {...repository, 'name': '../other'},
      },
    ]) {
      expect(
        () => PlanningEvent.parse('push', jsonEncode(value)),
        throwsA(isA<InvalidPlanningInput>()),
      );
    }
  });
  test('SQL emulator access is limited to loopback demo projects', () {
    final local = {
      'FUNCTIONS_EMULATOR': 'true',
      'GCLOUD_PROJECT': 'demo-openci',
      'DATA_CONNECT_EMULATOR_HOST': '127.0.0.1:9399',
    };
    expect(dataConnectServiceUri(local).host, '127.0.0.1');
    for (final changes in [
      {'GCLOUD_PROJECT': 'openci-b1b91'},
      {'FUNCTIONS_EMULATOR': 'false'},
      {'DATA_CONNECT_EMULATOR_HOST': 'remote.test:9399'},
    ]) {
      expect(
        () => dataConnectServiceUri({...local, ...changes}),
        throwsStateError,
      );
    }
  });
}
