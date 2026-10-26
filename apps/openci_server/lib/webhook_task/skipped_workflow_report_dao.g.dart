// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skipped_workflow_report_dao.dart';

// ignore_for_file: type=lint
mixin _$SkippedWorkflowReportDaoMixin on DatabaseAccessor<AppDatabase> {
  $WebhookTasksTable get webhookTasks => attachedDatabase.webhookTasks;
  $TeamsTable get teams => attachedDatabase.teams;
  $SkippedWorkflowReportsTable get skippedWorkflowReports =>
      attachedDatabase.skippedWorkflowReports;
  SkippedWorkflowReportDaoManager get managers =>
      SkippedWorkflowReportDaoManager(this);
}

class SkippedWorkflowReportDaoManager {
  final _$SkippedWorkflowReportDaoMixin _db;
  SkippedWorkflowReportDaoManager(this._db);
  $$WebhookTasksTableTableManager get webhookTasks =>
      $$WebhookTasksTableTableManager(_db.attachedDatabase, _db.webhookTasks);
  $$TeamsTableTableManager get teams =>
      $$TeamsTableTableManager(_db.attachedDatabase, _db.teams);
  $$SkippedWorkflowReportsTableTableManager get skippedWorkflowReports =>
      $$SkippedWorkflowReportsTableTableManager(
        _db.attachedDatabase,
        _db.skippedWorkflowReports,
      );
}
