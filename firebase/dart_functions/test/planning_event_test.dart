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

  Map<String, Object?> release({
    String action = 'published',
    Object? tag = 'v1.2.0',
    Object? draft = false,
  }) => {
    'installation': {'id': 30},
    'repository': repository,
    'action': action,
    'release': {
      'id': 40,
      'tag_name': tag,
      'draft': draft,
      'target_commitish': 'main',
    },
  };

  test('published releases await tag resolution instead of using a branch', () {
    final event = PlanningEvent.parse('release', jsonEncode(release()))!;
    expect(event.isRelease, isTrue);
    expect(event.webhook.commitSha, isEmpty);
    expect(event.webhook.branch, 'refs/tags/v1.2.0');
    expect(event.webhook.triggerBranch, 'v1.2.0');
    expect(event.webhook.triggerType, 'release');
    expect(event.webhook.pullRequestNumber, isNull);
    final pinned = event.withReleaseCommit(sha);
    expect(pinned.webhook.commitSha, sha);
    expect(pinned.webhook.branch, event.webhook.branch);
    expect(pinned.repositoryId, 10);
    expect(pinned.ownerId, 20);
    for (final badSha in ['main', '0' * 40, 'a' * 39]) {
      expect(
        () => event.withReleaseCommit(badSha),
        throwsA(isA<InvalidPlanningInput>()),
      );
    }
  });

  test('drafts and non-publication release actions do not plan jobs', () {
    for (final action in [
      'created',
      'edited',
      'deleted',
      'unpublished',
      'prereleased',
      'released',
    ]) {
      expect(
        PlanningEvent.parse('release', jsonEncode(release(action: action))),
        isNull,
      );
    }
    expect(
      PlanningEvent.parse('release', jsonEncode(release(draft: true))),
      isNull,
    );
  });

  test('release tags are valid complete Git tag names', () {
    for (final tag in <Object?>[
      null,
      1,
      '',
      '/v1',
      'v1/',
      'v1//rc',
      'v1..rc',
      'v1@{0}',
      'v1.lock',
      'v1/.rc',
      'v1.',
      'v1\n',
      'v1?',
      '../main',
      r'v1\rc',
    ]) {
      expect(
        () => PlanningEvent.parse('release', jsonEncode(release(tag: tag))),
        throwsA(isA<InvalidPlanningInput>()),
        reason: '$tag',
      );
    }
    for (final tag in ['v1.2.0', 'mobile/v1.2.0+41', 'v1.2.0-rc.1']) {
      expect(
        PlanningEvent.parse('release', jsonEncode(release(tag: tag))),
        isNotNull,
      );
    }
    expect(
      () => PlanningEvent.parse('release', jsonEncode(release(draft: null))),
      throwsA(isA<InvalidPlanningInput>()),
    );
  });

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
          'head': {'sha': sha, 'ref': 'feature', 'repo': repository},
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
  test('PR repository provenance fails closed for forks and unknown IDs', () {
    Map<String, Object?> pullRequest(Object? headRepo, Object? baseRepo) => {
      'installation': {'id': 30},
      'repository': repository,
      'action': 'opened',
      'number': 7,
      'pull_request': {
        'head': {'sha': sha, 'ref': 'feature', 'repo': headRepo},
        'base': {'ref': 'develop', 'repo': baseRepo},
        'title': 'PR title',
      },
    };

    for (final invalid in <Object?>[
      null,
      {},
      {'id': 99, 'fork': false},
      {'id': '10'},
      {'id': 0},
      {'id': -10},
      {'id': 10.5},
      {'id': 9007199254740992},
    ]) {
      for (final payload in [
        pullRequest(invalid, repository),
        pullRequest(repository, invalid),
      ]) {
        expect(
          () => PlanningEvent.parse('pull_request', jsonEncode(payload)),
          throwsA(isA<InvalidPlanningInput>()),
        );
      }
    }
    // A repository can itself be a fork while hosting a trusted local PR.
    final ownFork = {...repository, 'fork': true};
    for (final action in ['opened', 'synchronize', 'reopened']) {
      expect(
        PlanningEvent.parse(
          'pull_request',
          jsonEncode({...pullRequest(ownFork, ownFork), 'action': action}),
        ),
        isNotNull,
      );
    }
  });
  test('base retargets are replanned but unrelated PR edits are ignored', () {
    final payload = {
      'installation': {'id': 30},
      'repository': repository,
      'action': 'edited',
      'number': 7,
      'pull_request': {
        'head': {'sha': sha, 'ref': 'feature', 'repo': repository},
        'base': {'sha': 'b' * 40, 'repo': repository, 'ref': 'new-parent'},
        'title': 'PR',
      },
    };
    expect(PlanningEvent.parse('pull_request', jsonEncode(payload)), isNull);
    final event = PlanningEvent.parse(
      'pull_request',
      jsonEncode({
        ...payload,
        'changes': {
          'base': {
            'ref': {'from': 'old-parent'},
          },
        },
      }),
    )!;
    expect(event.baseSha, 'b' * 40);
    expect(event.webhook.triggerBranch, 'new-parent');
  });
  test('deletions and ignored PR actions produce no plan', () {
    expect(PlanningEvent.parse('push', '{"deleted":true}'), isNull);
    expect(PlanningEvent.parse('pull_request', '{"action":"labeled"}'), isNull);
  });
  test('merge and close events accept a deleted head but verify the base', () {
    for (final merged in [false, true]) {
      final payload = {
        'installation': {'id': 30},
        'repository': repository,
        'action': 'closed',
        'number': 7,
        'pull_request': {
          'merged': merged,
          'head': {'sha': sha, 'ref': 'feature', 'repo': null},
          'base': {'repo': repository, 'ref': 'develop'},
          'title': 'PR',
        },
      };
      expect(
        PlanningEvent.parse(
          'pull_request',
          jsonEncode(payload),
        )!.isPullRequestClosed,
        isTrue,
      );
      (payload['pull_request']! as Map)['base'] = {
        'repo': {'id': 99},
        'ref': 'develop',
      };
      expect(
        () => PlanningEvent.parse('pull_request', jsonEncode(payload)),
        throwsA(isA<InvalidPlanningInput>()),
      );
    }
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
  test('planner selects the deployment service within its own project', () {
    final environment = {
      'GCLOUD_PROJECT': 'openci-self-hosted-example',
      'OPENCI_DATA_CONNECT_SERVICE_ID': 'openci-self-hosted-example-service',
    };
    expect(
      dataConnectServiceUri(environment).path,
      '/v1/projects/openci-self-hosted-example/locations/asia-northeast1/services/openci-self-hosted-example-service',
    );
    expect(
      () => dataConnectServiceUri({
        ...environment,
        'OPENCI_DATA_CONNECT_SERVICE_ID': '../other',
      }),
      throwsStateError,
    );
  });
}
