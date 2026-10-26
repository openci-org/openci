import 'package:drift/drift.dart' show Value;
import 'package:openci_server/database.dart';
import 'package:openci_server/webhook_task/skipped_workflow_report_table.dart';
import 'package:test/test.dart';

void testSkippedWorkflowReportDao(Future<AppDatabase> Function() openDatabase) {
  late AppDatabase db;

  setUp(() async {
    db = await openDatabase();
    await db.seedDao.ensureTestTeam(teamId: 'team-1');
    final task = DriftWebhookTask(
      id: 'task-1',
      deliveryId: 'delivery-1',
      eventType: 'push',
      payload: '{}',
      status: 'completed',
      retryCount: 0,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await db.webhookTaskDao.insertWebhookTask(task);
    await db.webhookTaskDao.insertWebhookTask(
      task.copyWith(id: 'task-2', deliveryId: 'delivery-2'),
    );
  });

  test('inserts reports and keeps task lookups separate', () async {
    expect(await db.skippedWorkflowReportDao.getReport('missing'), isNull);
    expect(
      await db.skippedWorkflowReportDao.getReportsForTask('task-1'),
      isEmpty,
    );
    await db.skippedWorkflowReportDao.insertReport(_report);
    await db.skippedWorkflowReportDao.insertReport(
      _report.copyWith(
        id: const Value('skip-2'),
        webhookTaskId: const Value('task-2'),
        externalId: const Value('genuineci:skip:skip-2'),
      ),
    );

    final first = (await db.skippedWorkflowReportDao.getReport('skip-1'))!;
    final second = (await db.skippedWorkflowReportDao.getReport('skip-2'))!;
    expect(first.workflowFileName, 'website_ci.dart');
    expect(first.commitSha, 'commit-1');
    expect(first.externalId, 'genuineci:skip:skip-1');
    expect(first.reason, 'No changed files matched whenChanged.');
    expect(await db.skippedWorkflowReportDao.getReportsForTask('task-1'), [
      first,
    ]);
    expect(await db.skippedWorkflowReportDao.getReportsForTask('task-2'), [
      second,
    ]);
  });

  test(
    'updates reporting state while preserving the workflow identity',
    () async {
      await db.skippedWorkflowReportDao.insertReport(
        _report.copyWith(
          attempts: const Value(1),
          nextAttemptAt: Value(DateTime.utc(2026, 1, 1, 0, 5)),
          lastError: const Value('GitHub request timed out'),
        ),
      );
      final original = (await db.skippedWorkflowReportDao.getReport('skip-1'))!;
      await db.skippedWorkflowReportDao.insertReport(
        _report.copyWith(
          id: const Value('skip-2'),
          webhookTaskId: const Value('task-2'),
          externalId: const Value('genuineci:skip:skip-2'),
        ),
      );
      final untouched = await db.skippedWorkflowReportDao.getReport('skip-2');
      final reported = original.copyWith(
        checkRunId: const Value('4294967297'),
        status: SkippedWorkflowReportStatus.reported,
        attempts: 2,
        nextAttemptAt: const Value(null),
        lastError: const Value(null),
        updatedAt: DateTime.utc(2026, 1, 1, 0, 5),
      );

      final changed = await db.skippedWorkflowReportDao.updateReportingState(
        reported.copyWith(
          webhookTaskId: 'task-2',
          teamId: 'other-team',
          owner: 'other-owner',
          repo: 'other-repo',
          workflowName: 'Other CI',
          workflowFileName: 'other.dart',
          commitSha: 'other-commit',
          installationId: 'other-installation',
          reason: 'Changed reason',
          externalId: 'changed-external-id',
          createdAt: DateTime.utc(2027),
        ),
      );

      expect(changed, 1);
      final saved = (await db.skippedWorkflowReportDao.getReport('skip-1'))!;
      expect(saved.toJson(), reported.toJson());
      expect(saved.checkRunId, '4294967297');
      expect(saved.status, SkippedWorkflowReportStatus.reported);
      expect(saved.nextAttemptAt, isNull);
      expect(saved.lastError, isNull);
      expect(await db.skippedWorkflowReportDao.getReport('skip-2'), untouched);
    },
  );

  test('pending retry information survives database reopen', () async {
    await db.skippedWorkflowReportDao.insertReport(_report);
    final original = (await db.skippedWorkflowReportDao.getReport('skip-1'))!;
    await db.skippedWorkflowReportDao.updateReportingState(
      original.copyWith(
        attempts: 1,
        nextAttemptAt: Value(DateTime.utc(2026, 1, 1, 0, 5)),
        lastError: const Value('GitHub request timed out'),
        updatedAt: DateTime.utc(2026, 1, 1, 0, 1),
      ),
    );
    final before = (await db.skippedWorkflowReportDao.getReport('skip-1'))!;

    await db.close();
    db = await openDatabase();

    final saved = (await db.skippedWorkflowReportDao.getReport('skip-1'))!;
    expect(saved, before);
    expect(saved.status, SkippedWorkflowReportStatus.pending);
    expect(saved.externalId, 'genuineci:skip:skip-1');
    expect(saved.attempts, 1);
    expect(saved.nextAttemptAt!.toUtc(), DateTime.utc(2026, 1, 1, 0, 5));
    expect(saved.lastError, 'GitHub request timed out');
    expect(saved.updatedAt.toUtc(), DateTime.utc(2026, 1, 1, 0, 1));
  });

  test('storing a skip creates no execution or billing data', () async {
    final runNumber = (await db.teamDao.getTeam('team-1'))!.runNumber;
    await db.skippedWorkflowReportDao.insertReport(_report);

    expect(await db.select(db.buildJobs).get(), isEmpty);
    expect(await db.select(db.buildRuns).get(), isEmpty);
    expect(await db.select(db.billingAccounts).get(), isEmpty);
    expect(await db.select(db.billingPeriods).get(), isEmpty);
    expect((await db.teamDao.getTeam('team-1'))!.runNumber, runNumber);
    expect(
      (await db.webhookTaskDao.getWebhookTask('task-1'))!.status,
      'completed',
    );
  });
}

final _report = SkippedWorkflowReportsCompanion.insert(
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
