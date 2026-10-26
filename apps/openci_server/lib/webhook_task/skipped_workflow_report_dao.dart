import 'package:drift/drift.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/webhook_task/skipped_workflow_report_table.dart';

part 'skipped_workflow_report_dao.g.dart';

@DriftAccessor(tables: [SkippedWorkflowReports])
class SkippedWorkflowReportDao extends DatabaseAccessor<AppDatabase>
    with _$SkippedWorkflowReportDaoMixin {
  SkippedWorkflowReportDao(super.attachedDatabase);

  Future<void> insertReport(SkippedWorkflowReportsCompanion report) =>
      into(skippedWorkflowReports).insert(report);

  Future<DriftSkippedWorkflowReport?> getReport(String id) => (select(
    skippedWorkflowReports,
  )..where((row) => row.id.equals(id))).getSingleOrNull();

  Future<List<DriftSkippedWorkflowReport>> getReportsForTask(String taskId) =>
      (select(skippedWorkflowReports)
            ..where((row) => row.webhookTaskId.equals(taskId))
            ..orderBy([
              (row) => OrderingTerm.asc(row.createdAt),
              (row) => OrderingTerm.asc(row.id),
            ]))
          .get();

  // Keep the workflow identity and external ID stable across reporting retries.
  Future<int> updateReportingState(DriftSkippedWorkflowReport report) =>
      (update(
        skippedWorkflowReports,
      )..where((row) => row.id.equals(report.id))).write(
        SkippedWorkflowReportsCompanion(
          checkRunId: Value(report.checkRunId),
          status: Value(report.status),
          attempts: Value(report.attempts),
          nextAttemptAt: Value(report.nextAttemptAt),
          lastError: Value(report.lastError),
          updatedAt: Value(report.updatedAt),
        ),
      );
}
