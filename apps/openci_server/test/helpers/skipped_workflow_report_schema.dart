import 'package:drift/drift.dart' show Value;
import 'package:openci_server/database.dart';
import 'package:openci_server/webhook_task/skipped_workflow_report_table.dart';
import 'package:test/test.dart';

Future<void> expectSkippedWorkflowReportSchema(AppDatabase db) async {
  final report = SkippedWorkflowReportsCompanion.insert(
    id: 'skip-1',
    webhookTaskId: 'task-1',
    teamId: 'team-1',
    owner: 'openci-org',
    repo: 'openci',
    workflowName: 'Website CI',
    workflowFileName: 'website_ci.dart',
    commitSha: 'commit-1',
    installationId: '12345678',
    reason: 'No changed files matched whenChanged.',
    externalId: 'genuineci:skip:skip-1',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  await db.into(db.skippedWorkflowReports).insert(report);
  final saved = await db.select(db.skippedWorkflowReports).getSingle();
  expect(saved.status, SkippedWorkflowReportStatus.pending);
  expect(saved.attempts, 0);
  expect(saved.checkRunId, isNull);
  expect(saved.nextAttemptAt, isNull);
  expect(saved.lastError, isNull);

  await expectLater(
    db
        .into(db.skippedWorkflowReports)
        .insert(
          report.copyWith(
            id: const Value('duplicate-workflow'),
            externalId: const Value('genuineci:skip:duplicate'),
          ),
        ),
    throwsException,
  );
  await expectLater(
    db
        .into(db.skippedWorkflowReports)
        .insert(
          report.copyWith(
            id: const Value('duplicate-external-id'),
            workflowFileName: const Value('other_ci.dart'),
          ),
        ),
    throwsException,
  );
  expect(await db.select(db.skippedWorkflowReports).get(), [saved]);
}
