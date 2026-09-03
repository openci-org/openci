import 'package:build_job_planner/src/get_webhook_task.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:openci_shared/test_helpers.dart';
import 'package:test/test.dart';

class _MockOpenCiApiService extends Mock implements OpenCiApiService {}

void main() {
  group('getWebhookTask', () {
    late OpenCiApiService api;
    final log = Logger('GetWebhookTaskTest');

    setUp(() {
      api = _MockOpenCiApiService();
    });

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
