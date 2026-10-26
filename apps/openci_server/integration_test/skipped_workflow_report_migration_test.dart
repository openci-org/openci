import 'dart:io';

import 'package:drift_postgres/drift_postgres.dart';
import 'package:openci_server/database.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../test/helpers/skipped_workflow_report_schema.dart';

void main() {
  final databaseUrl = Platform.environment['OPENCI_TEST_DATABASE_URL'];

  test(
    'creates skipped reports on fresh PostgreSQL and upgrades v31 without data loss',
    () async {
      final connection = await pg.Connection.openFromUrl(databaseUrl!);
      addTearDown(connection.close);
      final schema =
          'skipped_report_test_${const Uuid().v4().replaceAll('-', '')}';
      await connection.execute('CREATE SCHEMA "$schema"');
      addTearDown(() => connection.execute('DROP SCHEMA "$schema" CASCADE'));
      await connection.execute('SET search_path TO "$schema"');
      var db = AppDatabase(PgDatabase.opened(connection));
      addTearDown(() => db.close());

      await db.seedDao.ensureTestTeam(teamId: 'team-1');
      final job = await db.seedDao.createTestBuildJob(teamId: 'team-1');
      await db.buildRunDao.insertBuildRun(
        DriftBuildRun(
          id: 'run-1',
          buildJobId: job.id,
          runNumber: 41,
          status: 'completed',
          conclusion: 'success',
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
      await db.webhookTaskDao.insertWebhookTask(
        DriftWebhookTask(
          id: 'task-1',
          deliveryId: 'delivery-1',
          eventType: 'push',
          payload: '{}',
          status: 'completed',
          retryCount: 0,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
      final team = await db.select(db.teams).getSingle();
      final task = await db.select(db.webhookTasks).getSingle();
      final storedJob = await db.select(db.buildJobs).getSingle();
      final run = await db.select(db.buildRuns).getSingle();
      await expectSkippedWorkflowReportSchema(db);

      await db.customStatement('DROP TABLE skipped_workflow_reports');
      await db.customStatement('UPDATE __schema SET version = 31');
      await db.close();
      db = AppDatabase(PgDatabase.opened(connection));

      expect(await db.select(db.skippedWorkflowReports).get(), isEmpty);
      expect(
        (await db.customSelect('SELECT version FROM __schema').getSingle())
            .read<int>('version'),
        32,
      );
      expect((await db.select(db.teams).getSingle()).toJson(), team.toJson());
      expect(
        (await db.select(db.webhookTasks).getSingle()).toJson(),
        task.toJson(),
      );
      expect(
        (await db.select(db.buildJobs).getSingle()).toJson(),
        storedJob.toJson(),
      );
      expect(
        (await db.select(db.buildRuns).getSingle()).toJson(),
        run.toJson(),
      );
      await expectSkippedWorkflowReportSchema(db);
    },
    skip: databaseUrl == null ? 'Set OPENCI_TEST_DATABASE_URL' : false,
  );
}
