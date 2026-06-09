import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:postgres/postgres.dart' as pg;

part 'database.g.dart';

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 32)();
  TextColumn get content => text().named('body')();
  DateTimeColumn get createdAt => dateTime().nullable()();
}

class MapConverter extends TypeConverter<Map<String, Object?>, String> {
  const MapConverter();
  @override
  Map<String, Object?> fromSql(String fromDb) {
    return jsonDecode(fromDb) as Map<String, Object?>;
  }

  @override
  String toSql(Map<String, Object?> value) {
    return jsonEncode(value);
  }
}

class StringListConverter extends TypeConverter<List<String>, String> {
  const StringListConverter();
  @override
  List<String> fromSql(String fromDb) {
    return (jsonDecode(fromDb) as List<dynamic>).cast<String>();
  }

  @override
  String toSql(List<String> value) {
    return jsonEncode(value);
  }
}

@DataClassName('DriftBuildJob')
class BuildJobs extends Table {
  TextColumn get id => text()();
  TextColumn get status => textEnum<BuildJobStatus>()();
  TextColumn get owner => text()();
  TextColumn get repo => text()();
  TextColumn get workflowName => text()();
  TextColumn get teamId => text().nullable()();
  TextColumn get workflowId => text().nullable()();
  TextColumn get workflowFileName => text().nullable()();
  TextColumn get commitSha => text().nullable()();
  IntColumn get pullRequestNumber => integer().nullable()();
  IntColumn get runCount => integer().nullable()();
  TextColumn get latestRunId => text().nullable()();
  TextColumn get tagName => text().nullable()();
  TextColumn get branch => text().nullable()();
  TextColumn get jobKey => text().nullable()();
  TextColumn get workflowJobKey => text().nullable()();

  TextColumn get matrix => text().map(const MapConverter()).nullable()();
  TextColumn get matrixLabel => text().nullable()();
  TextColumn get workflowRunId => text().nullable()();
  TextColumn get needs => text().map(const StringListConverter()).nullable()();

  TextColumn get failureSummary => text().nullable()();
  TextColumn get failureSummaryModel => text().nullable()();
  TextColumn get failureSummaryStatus => text().nullable()();
  IntColumn get failureSummaryDurationMs => integer().nullable()();

  TextColumn get provisionedUdids =>
      text().map(const StringListConverter()).nullable()();
  TextColumn get ipaUrl => text().nullable()();
  BoolColumn get hasIpa => boolean().nullable()();
  TextColumn get bundleId => text().nullable()();
  TextColumn get ipaVersion => text().nullable()();
  TextColumn get appName => text().nullable()();
  TextColumn get githubBaseUrl => text().nullable()();
  TextColumn get githubApiBaseUrl => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [TodoItems, BuildJobs])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

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
