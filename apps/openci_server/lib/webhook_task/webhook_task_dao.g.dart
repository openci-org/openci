// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webhook_task_dao.dart';

// ignore_for_file: type=lint
mixin _$WebhookTaskDaoMixin on DatabaseAccessor<AppDatabase> {
  $WebhookTasksTable get webhookTasks => attachedDatabase.webhookTasks;
  WebhookTaskDaoManager get managers => WebhookTaskDaoManager(this);
}

class WebhookTaskDaoManager {
  final _$WebhookTaskDaoMixin _db;
  WebhookTaskDaoManager(this._db);
  $$WebhookTasksTableTableManager get webhookTasks =>
      $$WebhookTasksTableTableManager(_db.attachedDatabase, _db.webhookTasks);
}
