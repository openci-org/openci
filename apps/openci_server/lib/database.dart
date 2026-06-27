import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:openci_server/build_job/build_job.dart';
import 'package:openci_server/build_job/build_job_dao.dart';
import 'package:openci_server/build_run/build_run.dart';
import 'package:openci_server/build_run/build_run_dao.dart';
import 'package:openci_server/device/device_dao.dart';
import 'package:openci_server/device/device_table.dart';
import 'package:openci_server/processed_webhook/processed_webhook_table.dart';
import 'package:openci_server/secret/secret_dao.dart';
import 'package:openci_server/secret/secret_table.dart';
import 'package:openci_server/team/team_dao.dart';
import 'package:openci_server/team/team_table.dart';
import 'package:openci_server/webhook_task/webhook_task_dao.dart';
import 'package:openci_server/webhook_task/webhook_task_table.dart';
import 'package:openci_server/worker_heartbeat/worker_heartbeat_dao.dart';
import 'package:openci_server/worker_heartbeat/worker_heartbeat_table.dart';
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
    WorkerHeartbeats,
    UserDevices,
  ],
  daos: [
    BuildJobDao,
    BuildRunDao,
    TeamDao,
    WebhookTaskDao,
    SecretDao,
    WorkerHeartbeatDao,
    DeviceDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 11) {
          throw StateError(
            'Migrations from schema version $from are no longer supported. '
            'Please recreate the database or manually upgrade to version 11 first.',
          );
        }
        if (from < 12) {
          await m.createTable(workerHeartbeats);
        }
        if (from < 13) {
          await m.createTable(userDevices);
        }
        if (from < 14) {
          await customStatement(
            "UPDATE user_devices SET device_product = 'Unknown' WHERE device_product IS NULL;",
          );
          await customStatement(
            "UPDATE user_devices SET device_os_version = 'Unknown' WHERE device_os_version IS NULL;",
          );
          await customStatement(
            "ALTER TABLE user_devices ALTER COLUMN device_product SET NOT NULL;",
          );
          await customStatement(
            "ALTER TABLE user_devices ALTER COLUMN device_os_version SET NOT NULL;",
          );
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
