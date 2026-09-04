import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/webhook_task/fail_webhook_task.dart';
import 'package:openci_server/webhook_task/webhook_task_transition_exception.dart';
import 'package:test/test.dart';

void main() {
  group('parseWebhookTaskErrorMessage', () {
    test('returns a trimmed error message', () {
      expect(
        parseWebhookTaskErrorMessage({'errorMessage': '  parse failed  '}),
        'parse failed',
      );
    });

    test('rejects a missing errorMessage', () {
      expect(
        () => parseWebhookTaskErrorMessage(const {}),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a non-string errorMessage', () {
      expect(
        () => parseWebhookTaskErrorMessage({'errorMessage': 123}),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects a blank errorMessage', () {
      expect(
        () => parseWebhookTaskErrorMessage({'errorMessage': '   '}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('failWebhookTask', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('fails a processing task and stores the error message', () async {
      await _insertTask(db, id: 'task-1', status: 'processing', retryCount: 2);

      final result = await failWebhookTask(
        db: db,
        taskId: 'task-1',
        errorMessage: 'workflow parse failed',
      );

      expect(result.alreadyFailed, isFalse);
      final task = await db.webhookTaskDao.getWebhookTask('task-1');
      expect(task?.status, 'failed');
      expect(task?.errorMessage, 'workflow parse failed');
      expect(task?.retryCount, 2);
    });

    test('throws when the task does not exist', () async {
      await expectLater(
        failWebhookTask(
          db: db,
          taskId: 'missing-task',
          errorMessage: 'workflow parse failed',
        ),
        throwsA(isA<WebhookTaskNotFoundException>()),
      );
    });

    test('throws without changing a pending task', () async {
      await _insertTask(db, id: 'task-1', status: 'pending');

      await expectLater(
        failWebhookTask(
          db: db,
          taskId: 'task-1',
          errorMessage: 'workflow parse failed',
        ),
        throwsA(
          isA<InvalidWebhookTaskStatusException>().having(
            (error) => error.status,
            'status',
            'pending',
          ),
        ),
      );

      final task = await db.webhookTaskDao.getWebhookTask('task-1');
      expect(task?.status, 'pending');
      expect(task?.errorMessage, isNull);
    });

    test('throws without changing a completed task', () async {
      await _insertTask(db, id: 'task-1', status: 'completed');

      await expectLater(
        failWebhookTask(
          db: db,
          taskId: 'task-1',
          errorMessage: 'workflow parse failed',
        ),
        throwsA(
          isA<InvalidWebhookTaskStatusException>().having(
            (error) => error.status,
            'status',
            'completed',
          ),
        ),
      );

      expect(
        (await db.webhookTaskDao.getWebhookTask('task-1'))?.status,
        'completed',
      );
    });

    test('returns already failed without replacing the first error', () async {
      await _insertTask(
        db,
        id: 'task-1',
        status: 'failed',
        errorMessage: 'first failure',
      );

      final result = await failWebhookTask(
        db: db,
        taskId: 'task-1',
        errorMessage: 'second failure',
      );

      expect(result.alreadyFailed, isTrue);
      final task = await db.webhookTaskDao.getWebhookTask('task-1');
      expect(task?.status, 'failed');
      expect(task?.errorMessage, 'first failure');
    });
  });
}

Future<void> _insertTask(
  AppDatabase db, {
  required String id,
  required String status,
  int retryCount = 0,
  String? errorMessage,
}) async {
  final now = DateTime.now().toUtc();
  await db.webhookTaskDao.insertWebhookTask(
    DriftWebhookTask(
      id: id,
      deliveryId: 'delivery-$id',
      eventType: 'push',
      payload: '{}',
      status: status,
      retryCount: retryCount,
      errorMessage: errorMessage,
      createdAt: now,
      updatedAt: now,
    ),
  );
}
