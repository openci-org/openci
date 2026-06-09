import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:openci_server/build_job/build_job.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:postgres/postgres.dart' as pg;

part 'database.g.dart';

@DriftDatabase(tables: [BuildJobs, BuildJobLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 3;

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
      },
    );
  }
  Future<void> insertBuildJob(DriftBuildJob job) => into(buildJobs).insert(job);

  Future<DriftBuildJob?> getBuildJob(String id) =>
      (select(buildJobs)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> updateBuildJob(DriftBuildJob job) =>
      update(buildJobs).replace(job);

  Future<void> insertBuildJobLog(String runId, String content) =>
      into(buildJobLogs).insert(
        BuildJobLogsCompanion.insert(
          runId: runId,
          logContent: content,
          createdAt: DateTime.now().toUtc(),
        ),
      );

  Future<List<DriftBuildJobLog>> getBuildJobLogs(String runId) =>
      (select(buildJobLogs)
            ..where((t) => t.runId.equals(runId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

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
