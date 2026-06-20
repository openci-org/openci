import 'package:drift/drift.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/webhook_task/webhook_task_table.dart';

part 'webhook_task_dao.g.dart';

@DriftAccessor(tables: [WebhookTasks])
class WebhookTaskDao extends DatabaseAccessor<AppDatabase>
    with _$WebhookTaskDaoMixin {
  WebhookTaskDao(super.attachedDatabase);

  Future<DriftWebhookTask?> claimNextWebhookTask() async {
    return db.transaction(() async {
      final isPostgres = db.attachedDatabase.executor.dialect == SqlDialect.postgres;
      final sql = '''
        SELECT * FROM webhook_tasks
        WHERE status = 'pending'
        ORDER BY created_at ASC
        LIMIT 1
        ${isPostgres ? 'FOR UPDATE SKIP LOCKED' : ''}
      ''';
      final results = await db.customSelect(sql).get();
      if (results.isEmpty) return null;

      final row = results.first;
      final task = webhookTasks.map(row.data);

      final updated = task.copyWith(
        status: 'processing',
        updatedAt: DateTime.now().toUtc(),
      );
      await updateWebhookTask(updated);
      return updated;
    });
  }

  Future<void> insertWebhookTask(DriftWebhookTask task) =>
      into(webhookTasks).insert(task);

  Future<DriftWebhookTask?> getWebhookTask(String id) =>
      (select(webhookTasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> updateWebhookTask(DriftWebhookTask task) =>
      update(webhookTasks).replace(task);
}
