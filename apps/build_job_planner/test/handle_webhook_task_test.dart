import 'dart:convert';

import 'package:build_job_planner/build_job_planner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:openci_shared/test_helpers.dart';
import 'package:test/test.dart';

class _MockOpenCiApiService extends Mock implements OpenCiApiService {}

void main() {
  group('handleWebhookTask', () {
    late OpenCiApiService api;

    setUp(() {
      api = _MockOpenCiApiService();
    });

    test('completes the task with serialized build job plans', () async {
      _stubPlanning(api);
      when(() => api.completeWebhookTask('task-1', any())).thenAnswer(
        (_) async => createMockResponse(<String, dynamic>{
          'success': true,
          'jobs_created': 1,
          'job_ids': ['job-1'],
          'already_completed': false,
        }),
      );

      final jobsCreated = await handleWebhookTask(task: _task(), api: api);

      expect(jobsCreated, 1);
      final body =
          verify(
                () => api.completeWebhookTask('task-1', captureAny()),
              ).captured.single
              as Map<String, dynamic>;
      expect(body, {
        'jobs': [
          {
            'owner': 'openci-org',
            'repo': 'openci',
            'workflowName': 'CI',
            'workflowFileName': 'ci.dart',
            'teamId': 'team-1',
            'commitSha': 'abc123',
            'commitMessage': 'feat: planner',
            'branch': 'main',
            'runsOn': 'macos-latest',
            'githubBaseUrl': 'https://github.com',
            'installationId': '998877',
          },
        ],
      });
      verifyNever(() => api.failWebhookTask(any(), any()));
    });

    test('marks the task as failed when planning fails', () async {
      when(() => api.failWebhookTask('task-1', any())).thenAnswer(
        (_) async => createMockResponse(<String, dynamic>{
          'success': true,
          'already_failed': false,
        }),
      );

      await expectLater(
        handleWebhookTask(
          task: _task(payload: 'invalid-json'),
          api: api,
        ),
        throwsA(isA<FormatException>()),
      );

      final body =
          verify(
                () => api.failWebhookTask('task-1', captureAny()),
              ).captured.single
              as Map<String, dynamic>;
      expect(body['errorMessage'], contains('Invalid WebhookTask JSON'));
      verifyNever(() => api.completeWebhookTask(any(), any()));
    });

    test('marks the task as failed when completion fails', () async {
      _stubPlanning(api);
      when(() => api.completeWebhookTask('task-1', any())).thenAnswer(
        (_) async => createMockResponse(<String, dynamic>{
          'success': false,
        }, statusCode: 500),
      );
      when(() => api.failWebhookTask('task-1', any())).thenAnswer(
        (_) async => createMockResponse(<String, dynamic>{
          'success': true,
          'already_failed': false,
        }),
      );

      await expectLater(
        handleWebhookTask(task: _task(), api: api),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Failed to complete webhook task task-1'),
          ),
        ),
      );

      final body =
          verify(
                () => api.failWebhookTask('task-1', captureAny()),
              ).captured.single
              as Map<String, dynamic>;
      expect(
        body['errorMessage'],
        contains('Failed to complete webhook task task-1'),
      );
    });

    test('rejects an invalid completion response', () async {
      _stubPlanning(api);
      when(() => api.completeWebhookTask('task-1', any())).thenAnswer(
        (_) async => createMockResponse(<String, dynamic>{
          'success': true,
          'jobs_created': 'one',
        }),
      );
      when(() => api.failWebhookTask('task-1', any())).thenAnswer(
        (_) async => createMockResponse(<String, dynamic>{
          'success': true,
          'already_failed': false,
        }),
      );

      await expectLater(
        handleWebhookTask(task: _task(), api: api),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('jobs_created must be an integer'),
          ),
        ),
      );
    });

    test('reports both errors when marking the task as failed fails', () async {
      when(() => api.failWebhookTask('task-1', any())).thenAnswer(
        (_) async => createMockResponse(<String, dynamic>{
          'success': false,
        }, statusCode: 500),
      );

      await expectLater(
        handleWebhookTask(
          task: _task(payload: 'invalid-json'),
          api: api,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            allOf(
              contains('Invalid WebhookTask JSON'),
              contains('also failed to mark it as failed'),
            ),
          ),
        ),
      );
    });
  });
}

void _stubPlanning(OpenCiApiService api) {
  when(() => api.getTeamByInstallationId(998877)).thenAnswer(
    (_) async => createMockResponse(
      Team(
        id: 'team-1',
        name: 'OpenCI',
        members: const [],
        installationIds: const [998877],
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
    ),
  );
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
        'content': _workflowSource,
      },
    ]),
  );
}

WebhookTask _task({String? payload}) {
  return WebhookTask(
    id: 'task-1',
    deliveryId: 'delivery-1',
    eventType: 'push',
    payload:
        payload ??
        jsonEncode({
          'ref': 'refs/heads/main',
          'head_commit': {
            'id': 'abc123',
            'message': 'feat: planner\n\ndetails',
          },
          'repository': {
            'name': 'openci',
            'owner': {'login': 'openci-org'},
          },
          'installation': {'id': 998877},
          'deleted': false,
        }),
    status: 'processing',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

const _workflowSource = '''
Future<void> main() async {
  await GenuineCI.init(
    workflowName: 'CI',
    ciTrigger: CiTrigger.push(branch: 'main'),
  );
}
''';
