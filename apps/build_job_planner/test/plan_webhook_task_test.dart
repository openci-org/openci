import 'dart:convert';

import 'package:build_job_planner/build_job_planner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:openci_shared/test_helpers.dart';
import 'package:test/test.dart';

class _MockOpenCiApiService extends Mock implements OpenCiApiService {}

void main() {
  group('planWebhookTask', () {
    late OpenCiApiService api;
    late Team team;

    setUp(() {
      api = _MockOpenCiApiService();
      team = Team(
        id: 'team-1',
        name: 'OpenCI',
        members: const [],
        installationIds: const [998877],
        githubBaseUrl: 'https://github.example.com',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
    });

    test('creates a BuildJobPlan for each matching workflow', () async {
      when(
        () => api.getTeamByInstallationId(998877),
      ).thenAnswer((_) async => createMockResponse(team));
      when(
        () => api.fetchGenuineCiFiles(
          'team-1',
          'openci',
          'abc123',
          owner: 'openci-org',
          installationId: 998877,
        ),
      ).thenAnswer(
        (_) async => createMockResponse([
          {
            'name': 'ci.dart',
            'path': 'genuine_ci/ci.dart',
            'content': _workflowSource(branch: 'main'),
          },
          {
            'name': 'develop.dart',
            'path': 'genuine_ci/develop.dart',
            'content': _workflowSource(branch: 'develop'),
          },
        ]),
      );

      final plans = await planWebhookTask(task: _pushTask(), api: api);

      expect(plans, hasLength(1));
      expect(plans.single.toJson(), {
        'owner': 'openci-org',
        'repo': 'openci',
        'workflowName': 'CI',
        'workflowFileName': 'ci.dart',
        'teamId': 'team-1',
        'commitSha': 'abc123',
        'commitMessage': 'feat: planner',
        'branch': 'main',
        'runsOn': 'macos-latest',
        'githubBaseUrl': 'https://github.example.com',
        'installationId': '998877',
      });
    });

    for (final eventType in ['push', 'pull_request']) {
      for (final branch in ['develop', 'main']) {
        test(
          'matches multiple triggers for $eventType targeting $branch',
          () async {
            _stubWorkflow(api, team, _multiTriggerWorkflowSource);
            final task = eventType == 'push'
                ? _pushTask(branch: branch)
                : _pullRequestTask(
                    baseBranch: branch,
                    headBranch: branch == 'develop' ? 'feature/ci' : 'develop',
                  );

            final plans = await planWebhookTask(task: task, api: api);

            expect(plans, hasLength(branch == 'develop' ? 1 : 0));
            if (plans.isNotEmpty) {
              expect(plans.single.workflowName, 'Dashboard CI');
              expect(plans.single.workflowFileName, 'dashboard_ci.dart');
              expect(plans.single.commitSha, 'abc123');
              expect(
                plans.single.branch,
                eventType == 'push' ? 'develop' : 'feature/ci',
              );
              expect(
                plans.single.pullRequestNumber,
                eventType == 'push' ? null : 42,
              );
            }
          },
        );
      }
    }

    test(
      'creates only one plan when multiple triggers match the event',
      () async {
        _stubWorkflow(api, team, '''
Future<void> main() async {
  await OpenCI.init(
    workflowName: 'CI',
    ciTriggers: [
      CiTrigger.push(branch: '*'),
      CiTrigger.push(branch: 'develop'),
      CiTrigger.push(branch: 'develop'),
    ],
  );
}
''');

        final plans = await planWebhookTask(
          task: _pushTask(branch: 'develop'),
          api: api,
        );

        expect(plans, hasLength(1));
      },
    );

    test(
      'returns no plans for a deleted branch without calling APIs',
      () async {
        final plans = await planWebhookTask(
          task: _pushTask(deleted: true),
          api: api,
        );

        expect(plans, isEmpty);
        verifyNever(() => api.getTeamByInstallationId(any()));
      },
    );

    test('returns no plans when no team owns the installation', () async {
      when(
        () => api.getTeamByInstallationId(998877),
      ).thenAnswer((_) async => createMockResponse(team, statusCode: 404));

      final plans = await planWebhookTask(task: _pushTask(), api: api);

      expect(plans, isEmpty);
      verifyNever(
        () => api.fetchGenuineCiFiles(
          any(),
          any(),
          any(),
          owner: any(named: 'owner'),
          installationId: any(named: 'installationId'),
        ),
      );
    });

    test('returns no plans when no GenuineCI files exist', () async {
      when(
        () => api.getTeamByInstallationId(998877),
      ).thenAnswer((_) async => createMockResponse(team));
      when(
        () => api.fetchGenuineCiFiles(
          'team-1',
          'openci',
          'abc123',
          owner: 'openci-org',
          installationId: 998877,
        ),
      ).thenAnswer((_) async => createMockResponse(<Map<String, dynamic>>[]));

      final plans = await planWebhookTask(task: _pushTask(), api: api);

      expect(plans, isEmpty);
    });

    test('throws FormatException for an invalid task payload', () async {
      await expectLater(
        planWebhookTask(
          task: _task(payload: 'not-json'),
          api: api,
        ),
        throwsA(isA<FormatException>()),
      );

      verifyNever(() => api.getTeamByInstallationId(any()));
    });

    test('throws StateError when team lookup fails', () async {
      when(
        () => api.getTeamByInstallationId(998877),
      ).thenAnswer((_) async => createMockResponse(team, statusCode: 500));

      await expectLater(
        planWebhookTask(task: _pushTask(), api: api),
        throwsA(isA<StateError>()),
      );
    });

    test('throws StateError when fetching GenuineCI files fails', () async {
      when(
        () => api.getTeamByInstallationId(998877),
      ).thenAnswer((_) async => createMockResponse(team));
      when(
        () => api.fetchGenuineCiFiles(
          'team-1',
          'openci',
          'abc123',
          owner: 'openci-org',
          installationId: 998877,
        ),
      ).thenAnswer(
        (_) async =>
            createMockResponse(<Map<String, dynamic>>[], statusCode: 500),
      );

      await expectLater(
        planWebhookTask(task: _pushTask(), api: api),
        throwsA(isA<StateError>()),
      );
    });
  });
}

void _stubWorkflow(OpenCiApiService api, Team team, String source) {
  when(
    () => api.getTeamByInstallationId(998877),
  ).thenAnswer((_) async => createMockResponse(team));
  when(
    () => api.fetchGenuineCiFiles(
      'team-1',
      'openci',
      'abc123',
      owner: 'openci-org',
      installationId: 998877,
    ),
  ).thenAnswer(
    (_) async => createMockResponse([
      {
        'name': 'dashboard_ci.dart',
        'path': 'genuine_ci/dashboard_ci.dart',
        'content': source,
      },
    ]),
  );
}

WebhookTask _pullRequestTask({
  required String baseBranch,
  required String headBranch,
}) {
  return _task(
    eventType: 'pull_request',
    payload: jsonEncode({
      'number': 42,
      'pull_request': {
        'head': {'sha': 'abc123', 'ref': headBranch},
        'base': {'ref': baseBranch},
        'title': 'feat: multiple triggers',
      },
      'repository': {
        'name': 'openci',
        'owner': {'login': 'openci-org'},
      },
      'installation': {'id': 998877},
    }),
  );
}

WebhookTask _pushTask({bool deleted = false, String branch = 'main'}) {
  return _task(
    payload: jsonEncode({
      'ref': 'refs/heads/$branch',
      'head_commit': {'id': 'abc123', 'message': 'feat: planner\n\ndetails'},
      'repository': {
        'name': 'openci',
        'owner': {'login': 'openci-org'},
      },
      'installation': {'id': 998877},
      'deleted': deleted,
    }),
  );
}

WebhookTask _task({required String payload, String eventType = 'push'}) {
  return WebhookTask(
    id: 'task-1',
    deliveryId: 'delivery-1',
    eventType: eventType,
    payload: payload,
    status: 'processing',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

String _workflowSource({required String branch}) =>
    '''
Future<void> main() async {
  await OpenCI.init(
    workflowName: 'CI',
    ciTriggers: [CiTrigger.push(branch: '$branch')],
  );
}
''';

const _multiTriggerWorkflowSource = '''
Future<void> main() async {
  await OpenCI.init(
    workflowName: 'Dashboard CI',
    ciTriggers: [
      CiTrigger.pullRequest(branch: 'develop'),
      CiTrigger.push(branch: 'develop'),
    ],
  );
}
''';
