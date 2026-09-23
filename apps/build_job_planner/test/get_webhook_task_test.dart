import 'package:build_job_planner/src/get_webhook_task.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:openci_shared/test_helpers.dart';
import 'package:test/test.dart';

class _MockOpenCIApiService extends Mock implements OpenCIApiService {}

void main() {
  group('getWebhookTask', () {
    late OpenCIApiService api;
    final log = Logger('GetWebhookTaskTest');

    setUp(() {
      api = _MockOpenCIApiService();
    });

    for (final status in [401, 409, 503]) {
      test(
        'reports HTTP $status instead of treating it as an empty queue',
        () async {
          when(() => api.claimNextWebhookTask()).thenAnswer(
            (_) async =>
                createMockResponse(<String, dynamic>{}, statusCode: status),
          );

          await expectLater(
            getWebhookTask(api, log),
            throwsA(
              isA<StateError>().having(
                (error) => error.message,
                'message',
                contains('HTTP $status'),
              ),
            ),
          );
          verify(() => api.claimNextWebhookTask()).called(1);
        },
      );
    }

    test('propagates a transport failure', () async {
      final error = StateError('connection lost');
      when(
        () => api.claimNextWebhookTask(),
      ).thenAnswer((_) async => throw error);

      await expectLater(getWebhookTask(api, log), throwsA(same(error)));
      verify(() => api.claimNextWebhookTask()).called(1);
    });

    test('rejects a missing response body even with HTTP 200', () async {
      final response = createMockResponse(
        null,
      ).copyWith<Map<String, dynamic>>();
      when(() => api.claimNextWebhookTask()).thenAnswer((_) async => response);

      await expectLater(getWebhookTask(api, log), throwsA(isA<StateError>()));
      verify(() => api.claimNextWebhookTask()).called(1);
    });

    for (final task in [
      [],
      {'id': 'incomplete-task'},
    ]) {
      test('rejects malformed task data: $task', () async {
        when(
          () => api.claimNextWebhookTask(),
        ).thenAnswer((_) async => createMockResponse({'task': task}));

        await expectLater(getWebhookTask(api, log), throwsA(isA<TypeError>()));
      });
    }

    test('returns null when task data is null', () async {
      when(
        () => api.claimNextWebhookTask(),
      ).thenAnswer((_) async => createMockResponse({'task': null}));

      final task = await getWebhookTask(api, log);

      expect(task, isNull);
    });

    test('returns WebhookTask when task data is present', () async {
      final now = DateTime.now().toUtc().toIso8601String();
      final taskMap = {
        'id': 'task-123',
        'eventType': 'push',
        'deliveryId': 'del-456',
        'payload': '{"ref": "refs/heads/main"}',
        'status': 'pending',
        'createdAt': now,
        'updatedAt': now,
      };

      when(
        () => api.claimNextWebhookTask(),
      ).thenAnswer((_) async => createMockResponse({'task': taskMap}));

      final task = await getWebhookTask(api, log);

      expect(task, isNotNull);
      expect(task!.id, equals('task-123'));
      expect(task.eventType, equals('push'));
    });
  });
}
