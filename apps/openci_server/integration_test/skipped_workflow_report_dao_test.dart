import 'dart:io';

import 'package:drift_postgres/drift_postgres.dart';
import 'package:openci_server/database.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../test/helpers/skipped_workflow_report_dao_tests.dart';

void main() {
  final databaseUrl = Platform.environment['OPENCI_TEST_DATABASE_URL'];

  group(
    'SkippedWorkflowReportDao on PostgreSQL',
    () {
      late String schema;

      setUp(() async {
        final connection = await pg.Connection.openFromUrl(databaseUrl!);
        addTearDown(connection.close);
        schema = 'skipped_dao_test_${const Uuid().v4().replaceAll('-', '')}';
        await connection.execute('CREATE SCHEMA "$schema"');
        addTearDown(() => connection.execute('DROP SCHEMA "$schema" CASCADE'));
      });

      testSkippedWorkflowReportDao(() async {
        final connection = await pg.Connection.openFromUrl(databaseUrl!);
        addTearDown(connection.close);
        await connection.execute('SET search_path TO "$schema"');
        final db = AppDatabase(PgDatabase.opened(connection));
        addTearDown(db.close);
        return db;
      });
    },
    skip: databaseUrl == null ? 'Set OPENCI_TEST_DATABASE_URL' : false,
  );
}
