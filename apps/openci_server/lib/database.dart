import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_postgres/drift_postgres.dart';
import 'package:postgres/postgres.dart' as pg;

part 'database.g.dart';

class TodoItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 6, max: 32)();
  TextColumn get content => text().named('body')();
  DateTimeColumn get createdAt => dateTime().nullable()();
}

@DriftDatabase(tables: [TodoItems])
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
