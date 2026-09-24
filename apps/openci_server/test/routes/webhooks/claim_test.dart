import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import '../../../routes/webhooks/_middleware.dart' as webhooks;
import '../../../routes/webhooks/claim.dart' as route;

void main() {
  group('POST /webhooks/claim', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('returns 405 for methods other than POST', () async {
      final response = await _request(
        db: db,
        method: HttpMethod.get,
      );

      expect(response.statusCode, HttpStatus.methodNotAllowed);
    });

    test('claims a pending task for the internal caller', () async {
      await _insertTask(db);

      final response = await _request(db: db);

      expect(response.statusCode, HttpStatus.ok);
      final body = await response.json() as Map<String, dynamic>;
      final task = WebhookTask.fromJson(body['task'] as Map<String, dynamic>);
      expect(task.id, 'task-1');
      expect(task.deliveryId, 'delivery-task-1');
      expect(task.eventType, 'push');
      expect(task.payload, '{"ref":"refs/heads/develop"}');
      expect(task.status, 'processing');
      expect(task.retryCount, 0);
      expect(task.errorMessage, isNull);
      expect(task.createdAt, DateTime.utc(2026, 9, 1));
      expect(task.updatedAt.isAfter(task.createdAt), isTrue);

      final storedTask = await db.webhookTaskDao.getWebhookTask('task-1');
      expect(storedTask?.status, 'processing');
      expect(storedTask!.updatedAt.isAfter(storedTask.createdAt), isTrue);
    });

    test('returns a null task when the queue is empty', () async {
      final response = await _request(db: db);

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.json(), {'task': null});
    });

    test('does not claim a processing task again', () async {
      await _insertTask(db);
      final firstResponse = await _request(db: db);
      final claimedTask = await db.webhookTaskDao.getWebhookTask('task-1');

      final secondResponse = await _request(db: db);

      expect(firstResponse.statusCode, HttpStatus.ok);
      expect(secondResponse.statusCode, HttpStatus.ok);
      expect(await secondResponse.json(), {'task': null});
      expect(
        await db.webhookTaskDao.getWebhookTask('task-1'),
        claimedTask,
      );
    });
  });
}

Future<void> _insertTask(AppDatabase db) async {
  final createdAt = DateTime.utc(2026, 9, 1);
  await db.webhookTaskDao.insertWebhookTask(
    DriftWebhookTask(
      id: 'task-1',
      deliveryId: 'delivery-task-1',
      eventType: 'push',
      payload: '{"ref":"refs/heads/develop"}',
      status: 'pending',
      retryCount: 0,
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
  );
}

Future<Response> _request({
  required AppDatabase db,
  HttpMethod method = HttpMethod.post,
}) async {
  const validator = InternalApiKeyValidator.forTesting(
    environment: {'INTERNAL_API_KEY': 'test-internal-key'},
  );
  final context = TestRequestContext(
    path: '/webhooks/claim',
    method: method,
    headers: {'Authorization': 'Bearer test-internal-key'},
  );
  context.provide<AppDatabase>(db);
  context.provide<InternalApiKeyValidator>(validator);
  return await webhooks.middleware(route.onRequest)(context.context);
}
