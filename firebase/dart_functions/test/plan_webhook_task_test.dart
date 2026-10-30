import 'dart:convert';

import 'package:openci_dart_functions/build_job_planner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:openci_shared/test_helpers.dart';
import 'package:test/test.dart';

class _MockOpenCIApiService extends Mock implements OpenCIApiService {}

void main() {
  group('planWebhookTask', () {
    late OpenCIApiService api;
    late Team team;

    setUp(() {
      api = _MockOpenCIApiService();
      team = Team(
        id: 'team-1',
        name: 'OpenCI',
        members: const [],
        installationIds: const [998877],
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
    });

    test('includes a BuildJobPlan for each matching workflow', () async {
      when(
        () => api.getTeamByInstallationId(998877),
      ).thenAnswer((_) async => createMockResponse(team));
      when(
        () => api.fetchOpenCIFiles(
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
            'path': 'openci/ci.dart',
            'content': _workflowSource(branch: 'main'),
          },
          {
            'name': 'develop.dart',
            'path': 'openci/develop.dart',
            'content': _workflowSource(branch: 'develop'),
          },
        ]),
      );

      final plan = await planWebhookTask(task: _pushTask(), api: api);

      expect(plan.jobs, hasLength(1));
      expect(plan.jobs.single.toJson(), {
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
      expect(plan.skippedWorkflows, isEmpty);
      expect(plan.changedFilesFallbackReason, isNull);
    });

    test('matches the push trigger targeting develop', () async {
      _stubWorkflow(api, team, _multiTriggerWorkflowSource);

      final plan = await planWebhookTask(
        task: _pushTask(branch: 'develop'),
        api: api,
      );

      expect(plan.jobs, hasLength(1));
      expect(plan.jobs.single.workflowName, 'Dashboard CI');
      expect(plan.jobs.single.workflowFileName, 'dashboard_ci.dart');
      expect(plan.jobs.single.commitSha, 'abc123');
      expect(plan.jobs.single.branch, 'develop');
      expect(plan.jobs.single.pullRequestNumber, isNull);
      expect(plan.skippedWorkflows, isEmpty);
      expect(plan.changedFilesFallbackReason, isNull);
    });

    test('returns an empty plan for a push to an unmatched branch', () async {
      _stubWorkflow(api, team, _multiTriggerWorkflowSource);

      final plan = await planWebhookTask(task: _pushTask(), api: api);

      expect(plan, const WebhookTaskPlan(jobs: []));
    });

    test(
      'matches pull requests by base branch and preserves the head',
      () async {
        _stubWorkflow(api, team, _multiTriggerWorkflowSource);

        final plan = await planWebhookTask(
          task: _pullRequestTask(
            baseBranch: 'develop',
            headBranch: 'feature/ci',
          ),
          api: api,
        );

        expect(plan.jobs, hasLength(1));
        expect(plan.jobs.single.workflowName, 'Dashboard CI');
        expect(plan.jobs.single.workflowFileName, 'dashboard_ci.dart');
        expect(plan.jobs.single.commitSha, 'abc123');
        expect(plan.jobs.single.branch, 'feature/ci');
        expect(plan.jobs.single.pullRequestNumber, 42);
        expect(plan.skippedWorkflows, isEmpty);
        expect(plan.changedFilesFallbackReason, isNull);
      },
    );

    test(
      'returns an empty plan for a pull request to an unmatched base',
      () async {
        _stubWorkflow(api, team, _multiTriggerWorkflowSource);

        final plan = await planWebhookTask(
          task: _pullRequestTask(baseBranch: 'main', headBranch: 'develop'),
          api: api,
        );

        expect(plan, const WebhookTaskPlan(jobs: []));
      },
    );

    test(
      'includes only one job when multiple triggers match the event',
      () async {
        _stubWorkflow(api, team, '''
Future<void> main() async {
  await OpenCI.init(
    workflowName: 'CI',
    ciTriggers: [
      CITrigger.push(branch: '*'),
      CITrigger.push(branch: 'develop'),
      CITrigger.push(branch: 'develop'),
    ],
  );
}
''');

        final plan = await planWebhookTask(
          task: _pushTask(branch: 'develop'),
          api: api,
        );

        expect(plan.jobs, hasLength(1));
        expect(plan.skippedWorkflows, isEmpty);
        expect(plan.changedFilesFallbackReason, isNull);
      },
    );

    test(
      'keeps whenChanged workflows without looking up changed files',
      () async {
        _stubWorkflow(api, team, '''
Future<void> main() async {
  await OpenCI.init(
    workflowName: 'Dashboard CI',
    ciTriggers: [
      CITrigger.push(branch: 'main', whenChanged: ['apps/dashboard/**']),
    ],
  );
}
''');

        final plan = await planWebhookTask(task: _pushTask(), api: api);

        expect(plan.jobs, hasLength(1));
        expect(plan.jobs.single.workflowName, 'Dashboard CI');
        expect(plan.skippedWorkflows, isEmpty);
        expect(plan.changedFilesFallbackReason, isNull);
        verifyNever(() => api.getWebhookTaskChangedFiles(any()));
      },
    );

    test(
      'returns an empty plan for a deleted branch without calling APIs',
      () async {
        final plan = await planWebhookTask(
          task: _pushTask(deleted: true),
          api: api,
        );

        expect(plan, const WebhookTaskPlan(jobs: []));
        verifyNever(() => api.getTeamByInstallationId(any()));
      },
    );

    test('returns an empty plan when no team owns the installation', () async {
      when(
        () => api.getTeamByInstallationId(998877),
      ).thenAnswer((_) async => createMockResponse(team, statusCode: 404));

      final plan = await planWebhookTask(task: _pushTask(), api: api);

      expect(plan, const WebhookTaskPlan(jobs: []));
      verifyNever(
        () => api.fetchOpenCIFiles(
          any(),
          any(),
          any(),
          owner: any(named: 'owner'),
          installationId: any(named: 'installationId'),
        ),
      );
    });

    test('returns an empty plan when no OpenCI files exist', () async {
      when(
        () => api.getTeamByInstallationId(998877),
      ).thenAnswer((_) async => createMockResponse(team));
      when(
        () => api.fetchOpenCIFiles(
          'team-1',
          'openci',
          'abc123',
          owner: 'openci-org',
          installationId: 998877,
        ),
      ).thenAnswer((_) async => createMockResponse(<Map<String, dynamic>>[]));

      final plan = await planWebhookTask(task: _pushTask(), api: api);

      expect(plan, const WebhookTaskPlan(jobs: []));
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

    test('throws StateError when fetching OpenCI files fails', () async {
      when(
        () => api.getTeamByInstallationId(998877),
      ).thenAnswer((_) async => createMockResponse(team));
      when(
        () => api.fetchOpenCIFiles(
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

void _stubWorkflow(OpenCIApiService api, Team team, String source) {
  when(
    () => api.getTeamByInstallationId(998877),
  ).thenAnswer((_) async => createMockResponse(team));
  when(
    () => api.fetchOpenCIFiles(
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
        'path': 'openci/dashboard_ci.dart',
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
    ciTriggers: [CITrigger.push(branch: '$branch')],
  );
}
''';

const _multiTriggerWorkflowSource = '''
Future<void> main() async {
  await OpenCI.init(
    workflowName: 'Dashboard CI',
    ciTriggers: [
      CITrigger.pullRequest(branch: 'develop'),
      CITrigger.push(branch: 'develop'),
    ],
  );
}
''';
