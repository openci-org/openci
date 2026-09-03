import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/webhook_task/webhook_task_dao.dart';
import 'package:test/test.dart';

void main() {
  group('WebhookTaskDao.claimNextWebhookTask', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() => db.close());

    test('claims a pending task and assigns a lease', () async {
      await _insertTask(db, status: 'pending');
      final beforeClaim = DateTime.now().toUtc();

      final claimed = await db.webhookTaskDao.claimNextWebhookTask();

      final afterClaim = DateTime.now().toUtc();
      expect(claimed, isNotNull);
      expect(claimed?.status, equals('processing'));
      expect(claimed?.retryCount, isZero);
      expect(claimed?.nextRetryAt, isNull);
      expect(
        claimed?.leaseUntil?.isBefore(
          beforeClaim.add(webhookTaskLeaseDuration),
        ),
        isFalse,
      );
      expect(
        claimed?.leaseUntil?.isAfter(
          afterClaim.add(webhookTaskLeaseDuration),
        ),
        isFalse,
      );
    });

    test('does not claim a processing task with an active lease', () async {
      await _insertTask(
        db,
        status: 'processing',
        leaseUntil: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      final claimed = await db.webhookTaskDao.claimNextWebhookTask();

      expect(claimed, isNull);
    });

    test('reclaims a processing task with an expired lease', () async {
      await _insertTask(
        db,
        status: 'processing',
        leaseUntil: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      );
      final beforeClaim = DateTime.now().toUtc();

      final claimed = await db.webhookTaskDao.claimNextWebhookTask();

      expect(claimed?.id, equals('task-1'));
      expect(claimed?.status, equals('processing'));
      expect(claimed?.retryCount, isZero);
      expect(claimed?.leaseUntil?.isAfter(beforeClaim), isTrue);
    });

    test('reclaims a legacy processing task without a lease', () async {
      await _insertTask(db, status: 'processing');

      final claimed = await db.webhookTaskDao.claimNextWebhookTask();

      expect(claimed?.id, equals('task-1'));
      expect(claimed?.leaseUntil, isNotNull);
    });

    test('does not claim a retry before nextRetryAt', () async {
      await _insertTask(
        db,
        status: 'retry_waiting',
        nextRetryAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );

      final claimed = await db.webhookTaskDao.claimNextWebhookTask();

      expect(claimed, isNull);
    });

    test('claims a retry after nextRetryAt', () async {
      await _insertTask(
        db,
        status: 'retry_waiting',
        nextRetryAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      );

      final claimed = await db.webhookTaskDao.claimNextWebhookTask();

      expect(claimed?.id, equals('task-1'));
      expect(claimed?.status, equals('processing'));
      expect(claimed?.nextRetryAt, isNull);
      expect(claimed?.leaseUntil, isNotNull);
    });
  });

  group('WebhookTaskDao.recordWebhookTaskFailure', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() => db.close());

    for (
      var retryIndex = 0;
      retryIndex < webhookTaskRetryDelays.length;
      retryIndex++
    ) {
      final retryCount = retryIndex + 1;
      final retryDelay = webhookTaskRetryDelays[retryIndex];

      test('schedules retry $retryCount after $retryDelay', () async {
        await _insertTask(
          db,
          status: 'processing',
          retryCount: retryIndex,
          leaseUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
        );
        final beforeFailure = DateTime.now().toUtc();

        final updated = await db.webhookTaskDao.recordWebhookTaskFailure(
          taskId: 'task-1',
          errorMessage: 'temporary failure',
        );

        final afterFailure = DateTime.now().toUtc();
        expect(updated?.status, equals('retry_waiting'));
        expect(updated?.retryCount, equals(retryCount));
        expect(updated?.leaseUntil, isNull);
        expect(updated?.errorMessage, equals('temporary failure'));
        expect(
          updated?.nextRetryAt?.isBefore(beforeFailure.add(retryDelay)),
          isFalse,
        );
        expect(
          updated?.nextRetryAt?.isAfter(afterFailure.add(retryDelay)),
          isFalse,
        );
      });
    }

    test('marks the task as failed after all retries are exhausted', () async {
      await _insertTask(
        db,
        status: 'processing',
        retryCount: webhookTaskRetryDelays.length,
        leaseUntil: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      );

      final updated = await db.webhookTaskDao.recordWebhookTaskFailure(
        taskId: 'task-1',
        errorMessage: 'permanent failure',
      );

      expect(updated?.status, equals('failed'));
      expect(updated?.retryCount, equals(webhookTaskRetryDelays.length + 1));
      expect(updated?.leaseUntil, isNull);
      expect(updated?.nextRetryAt, isNull);
      expect(updated?.errorMessage, equals('permanent failure'));
    });

    test('does not change a task that is not processing', () async {
      await _insertTask(db, status: 'completed');

      final updated = await db.webhookTaskDao.recordWebhookTaskFailure(
        taskId: 'task-1',
        errorMessage: 'late failure',
      );

      expect(updated?.status, equals('completed'));
      expect(updated?.retryCount, isZero);
      expect(updated?.errorMessage, isNull);
    });
  });
}

Future<void> _insertTask(
  AppDatabase db, {
  required String status,
  DateTime? leaseUntil,
  DateTime? nextRetryAt,
  int retryCount = 0,
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
      nextRetryAt: nextRetryAt,
      retryCount: retryCount,
      createdAt: now,
      updatedAt: now,
    ),
  );
}
