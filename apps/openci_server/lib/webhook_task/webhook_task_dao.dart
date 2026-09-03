import 'package:drift/drift.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/webhook_task/webhook_task_table.dart';

part 'webhook_task_dao.g.dart';

const webhookTaskLeaseDuration = Duration(minutes: 5);
const webhookTaskRetryDelays = <Duration>[
  Duration(seconds: 5),
  Duration(seconds: 30),
  Duration(minutes: 2),
];

@DriftAccessor(tables: [WebhookTasks])
class WebhookTaskDao extends DatabaseAccessor<AppDatabase>
    with _$WebhookTaskDaoMixin {
  WebhookTaskDao(super.attachedDatabase);

  Future<DriftWebhookTask?> claimNextWebhookTask() async {
    return db.transaction(() async {
      final now = DateTime.now().toUtc();
      final isPostgres =
          db.attachedDatabase.executor.dialect == SqlDialect.postgres;
      final nowVariable = isPostgres ? r'$1' : '?1';
      final sql =
          '''
        SELECT * FROM webhook_tasks
        WHERE status = 'pending'
          OR (
            status = 'retry_waiting'
            AND (next_retry_at IS NULL OR next_retry_at <= $nowVariable)
          )
          OR (
            status = 'processing'
            AND (lease_until IS NULL OR lease_until <= $nowVariable)
          )
        ORDER BY created_at ASC
        LIMIT 1
        ${isPostgres ? 'FOR UPDATE SKIP LOCKED' : ''}
      ''';
      final results = await db
          .customSelect(
            sql,
            variables: [Variable<DateTime>(now)],
          )
          .get();
      if (results.isEmpty) return null;

      final row = results.first;
      final task = webhookTasks.map(row.data);

      final updated = task.copyWith(
        status: 'processing',
        leaseUntil: Value(now.add(webhookTaskLeaseDuration)),
        nextRetryAt: const Value(null),
        updatedAt: now,
      );
      await updateWebhookTask(updated);
      return updated;
    });
  }

  Future<DriftWebhookTask?> recordWebhookTaskFailure({
    required String taskId,
    required String errorMessage,
  }) async {
    return db.transaction(() async {
      final task = await getWebhookTask(taskId);
      if (task == null || task.status != 'processing') return task;

      final now = DateTime.now().toUtc();
      final retryCount = task.retryCount + 1;
      final shouldRetry = retryCount <= webhookTaskRetryDelays.length;
      final nextRetryAt = shouldRetry
          ? now.add(webhookTaskRetryDelays[retryCount - 1])
          : null;
      final updated = task.copyWith(
        status: shouldRetry ? 'retry_waiting' : 'failed',
        retryCount: retryCount,
        leaseUntil: const Value(null),
        nextRetryAt: Value(nextRetryAt),
        errorMessage: Value(errorMessage),
        updatedAt: now,
      );
      final updatedCount =
          await (update(webhookTasks)..where(
                (row) =>
                    row.id.equals(taskId) & row.status.equals('processing'),
              ))
              .write(
                WebhookTasksCompanion(
                  status: Value(updated.status),
                  retryCount: Value(updated.retryCount),
                  leaseUntil: const Value(null),
                  nextRetryAt: Value(updated.nextRetryAt),
                  errorMessage: Value(updated.errorMessage),
                  updatedAt: Value(updated.updatedAt),
                ),
              );
      if (updatedCount == 0) return getWebhookTask(taskId);
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
