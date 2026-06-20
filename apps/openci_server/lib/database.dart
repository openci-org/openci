import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:openci_server/build_job/build_job.dart';
import 'package:openci_server/build_job/build_job_dao.dart';
import 'package:openci_server/build_run/build_run.dart';
import 'package:openci_server/build_run/build_run_dao.dart';
import 'package:openci_server/processed_webhook/processed_webhook_table.dart';
import 'package:openci_server/secret/secret_table.dart';
import 'package:openci_server/team/team_dao.dart';
import 'package:openci_server/team/team_table.dart';
import 'package:openci_server/webhook_task/webhook_task_dao.dart';
import 'package:openci_server/webhook_task/webhook_task_table.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:postgres/postgres.dart' as pg;

part 'database.g.dart';

@DriftDatabase(
  tables: [
    BuildJobs,
    BuildJobLogs,
    BuildRuns,
    Teams,
    TeamMembers,
    Secrets,
    ProcessedWebhooks,
    WebhookTasks,
  ],
  daos: [BuildJobDao, BuildRunDao, TeamDao, WebhookTaskDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(buildJobs);
        }
        if (from < 3) {
          await m.createTable(buildJobLogs);
        }
        if (from < 4) {
          await m.createTable(teams);
          await m.createTable(teamMembers);
        }
        if (from < 5) {
          await m.createTable(buildRuns);
        }
        if (from < 6) {
          await m.createTable(secrets);
        }
        if (from >= 2 && from < 7) {
          await m.addColumn(buildJobs, buildJobs.installationId);
          await m.addColumn(buildJobs, buildJobs.checkRunId);
        }
        if (from < 8) {
          await m.createTable(processedWebhooks);
        }
        if (from < 9) {
          await m.addColumn(buildJobs, buildJobs.runsOn);
        }
        if (from < 10) {
          await m.createTable(webhookTasks);
        }
      },
    );
  }

  static QueryExecutor _openConnection() {
    final databaseUrl = loadDatabaseUrl();
    return PgDatabase.opened(
      pg.Pool.withUrl(databaseUrl),
    );
  }
}

String loadDatabaseUrl({Map<String, String>? environment}) {
  final env = environment ?? Platform.environment;
  final databaseUrlEnv = env['DATABASE_URL'];

  if (databaseUrlEnv == null || databaseUrlEnv.trim().isEmpty) {
    throw StateError(
      'DATABASE_URL environment variable must be specified.',
    );
  }

  return databaseUrlEnv;
}
