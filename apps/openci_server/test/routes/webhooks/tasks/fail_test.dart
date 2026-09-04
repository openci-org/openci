import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:test/test.dart';

import '../../../../routes/webhooks/tasks/[id]/fail.dart' as route;

void main() {
  group('POST /webhooks/tasks/[id]/fail', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('returns 405 for methods other than POST', () async {
      final context = TestRequestContext(
        path: '/webhooks/tasks/task-1/fail',
        method: HttpMethod.get,
      );

      final response = await route.onRequest(context.context, 'task-1');

      expect(response.statusCode, HttpStatus.methodNotAllowed);
    });

    test('returns 401 when unauthenticated', () async {
      final response = await _request(
        db: db,
        taskId: 'task-1',
        uid: null,
        errorMessage: 'workflow parse failed',
      );

      expect(response.statusCode, HttpStatus.unauthorized);
    });

    test(
      'returns 403 when authenticated without the internal API key',
      () async {
        final response = await _request(
          db: db,
          taskId: 'task-1',
          uid: 'firebase-user',
          errorMessage: 'workflow parse failed',
        );

        expect(response.statusCode, HttpStatus.forbidden);
      },
    );

    test('returns 400 when the body is invalid JSON', () async {
      final response = await _requestWithBody(
        db: db,
        taskId: 'task-1',
        body: 'not-json',
      );

      expect(response.statusCode, HttpStatus.badRequest);
    });

    test('returns 400 when errorMessage is missing', () async {
      final response = await _requestWithBody(
        db: db,
        taskId: 'task-1',
        body: jsonEncode(<String, Object?>{}),
      );

      expect(response.statusCode, HttpStatus.badRequest);
      final body = await response.json() as Map<String, dynamic>;
      expect(body['error'], 'errorMessage must be a non-empty string');
    });

    test('fails a processing task', () async {
      await _insertTask(db, id: 'task-1', status: 'processing');

      final response = await _request(
        db: db,
        taskId: 'task-1',
        errorMessage: '  workflow parse failed  ',
      );

      expect(response.statusCode, HttpStatus.ok);
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body['already_failed'], isFalse);

      final task = await db.webhookTaskDao.getWebhookTask('task-1');
      expect(task?.status, 'failed');
      expect(task?.errorMessage, 'workflow parse failed');
    });

    test('returns 404 when the task does not exist', () async {
      final response = await _request(
        db: db,
        taskId: 'missing-task',
        errorMessage: 'workflow parse failed',
      );

      expect(response.statusCode, HttpStatus.notFound);
    });

    test('returns 409 when the task is not processing', () async {
      await _insertTask(db, id: 'task-1', status: 'pending');

      final response = await _request(
        db: db,
        taskId: 'task-1',
        errorMessage: 'workflow parse failed',
      );

      expect(response.statusCode, HttpStatus.conflict);
      expect(
        (await db.webhookTaskDao.getWebhookTask('task-1'))?.status,
        'pending',
      );
    });

    test('repeated failure is idempotent', () async {
      await _insertTask(db, id: 'task-1', status: 'processing');

      final firstResponse = await _request(
        db: db,
        taskId: 'task-1',
        errorMessage: 'first failure',
      );
      final secondResponse = await _request(
        db: db,
        taskId: 'task-1',
        errorMessage: 'second failure',
      );

      expect(firstResponse.statusCode, HttpStatus.ok);
      expect(secondResponse.statusCode, HttpStatus.ok);
      final secondBody = await secondResponse.json() as Map<String, dynamic>;
      expect(secondBody['already_failed'], isTrue);
      expect(
        (await db.webhookTaskDao.getWebhookTask('task-1'))?.errorMessage,
        'first failure',
      );
    });
  });
}

Future<void> _insertTask(
  AppDatabase db, {
  required String id,
  required String status,
}) async {
  final now = DateTime.now().toUtc();
  await db.webhookTaskDao.insertWebhookTask(
    DriftWebhookTask(
      id: id,
      deliveryId: 'delivery-$id',
      eventType: 'push',
      payload: '{}',
      status: status,
      retryCount: 0,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<Response> _request({
  required AppDatabase db,
  required String taskId,
  required String errorMessage,
  String? uid = 'system-job-processor',
}) {
  return _requestWithBody(
    db: db,
    taskId: taskId,
    uid: uid,
    body: jsonEncode({'errorMessage': errorMessage}),
  );
}

Future<Response> _requestWithBody({
  required AppDatabase db,
  required String taskId,
  required String body,
  String? uid = 'system-job-processor',
}) async {
  final context = TestRequestContext(
    path: '/webhooks/tasks/$taskId/fail',
    method: HttpMethod.post,
    body: body,
  );
  context.provide<AppDatabase>(db);
  context.provide<String?>(uid);
  return await route.onRequest(context.context, taskId);
}
