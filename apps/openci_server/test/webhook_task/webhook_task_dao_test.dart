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
  });
}

Future<void> _insertTask(
  AppDatabase db, {
  required String status,
  DateTime? leaseUntil,
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
      retryCount: 0,
      createdAt: now,
      updatedAt: now,
    ),
  );
}
