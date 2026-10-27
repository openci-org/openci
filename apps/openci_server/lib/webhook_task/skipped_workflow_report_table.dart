import 'package:drift/drift.dart';
import 'package:openci_server/team/team_table.dart';
import 'package:openci_server/webhook_task/webhook_task_table.dart';

enum SkippedWorkflowReportStatus { pending, reported }

@DataClassName('DriftSkippedWorkflowReport')
class SkippedWorkflowReports extends Table {
  TextColumn get id => text()();
  TextColumn get webhookTaskId =>
      text().references(WebhookTasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get teamId =>
      text().references(Teams, #id, onDelete: KeyAction.cascade)();
  TextColumn get owner => text()();
  TextColumn get repo => text()();
  TextColumn get workflowName => text()();
  TextColumn get workflowFileName => text()();
  TextColumn get commitSha => text()();
  TextColumn get installationId => text()();
  TextColumn get reason => text()();
  TextColumn get externalId => text().unique()();
  TextColumn get checkRunId => text().nullable()();
  TextColumn get status => textEnum<SkippedWorkflowReportStatus>().withDefault(
    const Constant('pending'),
  )();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime().nullable()();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {webhookTaskId, workflowFileName, commitSha},
  ];
}
