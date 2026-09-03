import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/webhook_task/webhook_task_dao.dart';
import 'package:test/test.dart';

import '../../../../routes/webhooks/tasks/[id]/fail.dart' as route;

void main() {
  group('POST /webhooks/tasks/[id]/fail', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() => db.close());

    test('requires the internal API identity', () async {
      await _insertTask(db, status: 'processing');

      final unauthenticated = await _failTask(db: db, uid: null);
      final regularUser = await _failTask(db: db, uid: 'user-123');

      expect(unauthenticated.statusCode, equals(HttpStatus.unauthorized));
      expect(regularUser.statusCode, equals(HttpStatus.forbidden));
    });

    test('returns 404 when the webhook task does not exist', () async {
      final response = await _failTask(
        db: db,
        uid: 'system-job-processor',
      );

      expect(response.statusCode, equals(HttpStatus.notFound));
    });

    test('returns 400 when errorMessage is missing', () async {
      await _insertTask(db, status: 'processing');

      final response = await _request(
        db: db,
        uid: 'system-job-processor',
        body: '{}',
      );

      expect(response.statusCode, equals(HttpStatus.badRequest));
      expect(
        (await db.webhookTaskDao.getWebhookTask('task-1'))?.status,
        equals('processing'),
      );
    });

    test('moves a processing task to retry_waiting', () async {
      await _insertTask(
        db,
        status: 'processing',
        leaseUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      );

      final response = await _failTask(
        db: db,
        uid: 'system-job-processor',
        errorMessage: 'GitHub temporarily unavailable',
      );

      expect(response.statusCode, equals(HttpStatus.ok));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body['status'], equals('retry_waiting'));
      expect(body['retry_count'], equals(1));
      expect(body['next_retry_at'], isNotNull);

      final task = await db.webhookTaskDao.getWebhookTask('task-1');
      expect(task?.status, equals('retry_waiting'));
      expect(task?.retryCount, equals(1));
      expect(task?.leaseUntil, isNull);
      expect(task?.nextRetryAt, isNotNull);
      expect(task?.errorMessage, equals('GitHub temporarily unavailable'));
    });

    test('moves a task to failed after retries are exhausted', () async {
      await _insertTask(
        db,
        status: 'processing',
        retryCount: webhookTaskRetryDelays.length,
      );

      final response = await _failTask(
        db: db,
        uid: 'system-job-processor',
        errorMessage: 'Permanent planner failure',
      );

      expect(response.statusCode, equals(HttpStatus.ok));
      final body = await response.json() as Map<String, dynamic>;
      expect(body['status'], equals('failed'));
      expect(body['retry_count'], equals(webhookTaskRetryDelays.length + 1));
      expect(body['next_retry_at'], isNull);
    });

    test('does not change an already failed task again', () async {
      await _insertTask(
        db,
        status: 'failed',
        retryCount: webhookTaskRetryDelays.length + 1,
        errorMessage: 'original failure',
      );

      final response = await _failTask(
        db: db,
        uid: 'system-job-processor',
        errorMessage: 'duplicate failure',
      );

      expect(response.statusCode, equals(HttpStatus.ok));
      final task = await db.webhookTaskDao.getWebhookTask('task-1');
      expect(task?.retryCount, equals(webhookTaskRetryDelays.length + 1));
      expect(task?.errorMessage, equals('original failure'));
    });
  });
}

Future<void> _insertTask(
  AppDatabase db, {
  required String status,
  DateTime? leaseUntil,
  int retryCount = 0,
  String? errorMessage,
}) {
  final now = DateTime.now().toUtc();
  return db.webhookTaskDao.insertWebhookTask(
    DriftWebhookTask(
      id: 'task-1',
      deliveryId: 'delivery-1',
      eventType: 'push',
      payload: '{}',
      status: status,
      leaseUntil: leaseUntil,
      retryCount: retryCount,
      errorMessage: errorMessage,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

Future<Response> _failTask({
  required AppDatabase db,
  required String? uid,
  String errorMessage = 'planner failed',
}) {
  return _request(
    db: db,
    uid: uid,
    body: jsonEncode({'errorMessage': errorMessage}),
  );
}

Future<Response> _request({
  required AppDatabase db,
  required String? uid,
  required String body,
}) async {
  final context = TestRequestContext(
    path: '/webhooks/tasks/task-1/fail',
    method: HttpMethod.post,
    body: body,
  );
  context.provide<AppDatabase>(db);
  context.provide<String?>(uid);
  return route.onRequest(context.context, 'task-1');
}
