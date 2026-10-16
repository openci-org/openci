import 'dart:io';

import 'package:openci_server/database.dart';
import 'package:openci_server/open_postgres_database.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  // Use a disposable PostgreSQL database. The test user needs CREATEDB.
  final databaseUrl = Platform.environment['OPENCI_TEST_DATABASE_URL'];

  group(
    'PostgreSQL database connections',
    () {
      late pg.Connection admin;
      late String databaseName;
      late String testDatabaseUrl;

      setUp(() async {
        admin = await pg.Connection.openFromUrl(databaseUrl!);
        addTearDown(admin.close);
        databaseName =
            'postgres_connection_test_${const Uuid().v4().replaceAll('-', '')}';
        await admin.execute('CREATE DATABASE "$databaseName"');
        addTearDown(() => admin.execute('DROP DATABASE "$databaseName"'));
        testDatabaseUrl = Uri.parse(
          databaseUrl,
        ).replace(path: '/$databaseName').toString();
      });

      Future<AppDatabase> openDatabase() async {
        return AppDatabase(openPostgresDatabase(testDatabaseUrl));
      }

      test(
        'rolls back every statement in a batch on the same connection',
        () async {
          final db = await openDatabase();
          addTearDown(db.close);
          await db.customStatement(
            'CREATE TABLE rollback_probe (id INTEGER PRIMARY KEY)',
          );

          await expectLater(
            db.transaction(() async {
              await db.batch((batch) {
                batch.customStatement('INSERT INTO rollback_probe VALUES (1)');
                batch.customStatement('INSERT INTO rollback_probe VALUES (2)');
              });
              throw StateError('force rollback');
            }),
            throwsStateError,
          );

          expect(
            await db.customSelect('SELECT id FROM rollback_probe').get(),
            isEmpty,
          );
          // The same connection is usable after a rolled-back transaction.
          await db.customStatement('INSERT INTO rollback_probe VALUES (3)');
          expect(
            await db.customSelect('SELECT id FROM rollback_probe').get(),
            hasLength(1),
          );
        },
      );
    },
    skip: databaseUrl == null
        ? 'Set OPENCI_TEST_DATABASE_URL to a test database'
        : false,
  );
}
