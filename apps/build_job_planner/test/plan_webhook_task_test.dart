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

WebhookTask _pushTask({bool deleted = false}) {
  return _task(
    payload: jsonEncode({
      'ref': 'refs/heads/main',
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

WebhookTask _task({required String payload}) {
  return WebhookTask(
    id: 'task-1',
    deliveryId: 'delivery-1',
    eventType: 'push',
    payload: payload,
    status: 'processing',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

String _workflowSource({required String branch}) =>
    '''
Future<void> main() async {
  await GenuineCI.init(
    workflowName: 'CI',
    ciTrigger: CiTrigger.push(branch: '$branch'),
  );
}
''';
