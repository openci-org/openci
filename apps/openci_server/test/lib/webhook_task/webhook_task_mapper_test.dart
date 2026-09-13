import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/webhook_task/webhook_task_mapper.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  for (final errorMessage in [null, 'upstream unavailable']) {
    test(
      'webhook task database round trip preserves retry state: $errorMessage',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        final task = WebhookTask(
          id: 'task-1',
          deliveryId: 'delivery-1',
          eventType: 'pull_request',
          payload: '{"action":"opened","title":"ビルド"}',
          status: errorMessage == null ? 'pending' : 'failed',
          retryCount: errorMessage == null ? 0 : 3,
          errorMessage: errorMessage,
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 2, 1),
        );

        await db.webhookTaskDao.insertWebhookTask(task.toDrift());
        final stored = await db.select(db.webhookTasks).getSingle();

        expect(stored.toShared().toJson(), task.toJson());
      },
    );
  }
}
