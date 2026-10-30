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

      test('creates a fresh schema without retired storage', () async {
        final db = await openDatabase();
        addTearDown(db.close);

        expect(await db.select(db.teams).get(), isEmpty);
        expect(await db.select(db.teamMembers).get(), isEmpty);
        expect(await db.select(db.buildJobs).get(), isEmpty);
        expect(await db.select(db.buildRuns).get(), isEmpty);
        expect(
          await db.customSelect('''
            SELECT table_name FROM information_schema.tables
            WHERE table_schema = 'public' AND table_name IN (
              'invitations', 'user_devices', 'udid_requests'
            )
          ''').get(),
          isEmpty,
        );
      });

      for (final retiredTables in [
        ['invitations', 'user_devices', 'udid_requests'],
        ['user_devices', 'udid_requests'],
        <String>[],
      ]) {
        test(
          'upgrades v31 with $retiredTables and preserves active data',
          () async {
            final fixture = await pg.Connection.openFromUrl(testDatabaseUrl);
            try {
              // Only columns relevant to the retirement are needed. The fresh
              // schema test above also exercises the complete generated schema.
              for (final statement in [
                'CREATE TABLE __schema (version INTEGER NOT NULL)',
                'INSERT INTO __schema VALUES (31)',
                'CREATE TABLE teams (id TEXT PRIMARY KEY, name TEXT NOT NULL)',
                '''CREATE TABLE team_members (
                id INTEGER PRIMARY KEY, team_id TEXT REFERENCES teams(id),
                user_id TEXT NOT NULL
              )''',
                '''CREATE TABLE build_jobs (
                id TEXT PRIMARY KEY, team_id TEXT REFERENCES teams(id)
              )''',
                '''CREATE TABLE build_runs (
                id TEXT PRIMARY KEY, build_job_id TEXT REFERENCES build_jobs(id),
                run_number INTEGER, provisioned_udids TEXT
              )''',
                'CREATE TABLE billing_accounts (team_id TEXT PRIMARY KEY)',
                '''CREATE TABLE billing_periods (
                id TEXT PRIMARY KEY, team_id TEXT REFERENCES billing_accounts(team_id)
              )''',
                "INSERT INTO teams VALUES ('team-1', 'OpenCI')",
                "INSERT INTO team_members VALUES (1, 'team-1', 'member-1')",
                "INSERT INTO build_jobs VALUES ('job-1', 'team-1')",
                '''INSERT INTO build_runs VALUES ('run-1', 'job-1', 42, '["artifact-udid"]')''',
                "INSERT INTO billing_accounts VALUES ('team-1')",
                "INSERT INTO billing_periods VALUES ('period-1', 'team-1')",
              ]) {
                await fixture.execute(statement);
              }
              for (final table in retiredTables) {
                await fixture.execute('''CREATE TABLE $table (
                id TEXT PRIMARY KEY, team_id TEXT REFERENCES teams(id)
              )''');
                await fixture.execute(
                  "INSERT INTO $table VALUES ('retired-1', 'team-1')",
                );
              }
            } finally {
              await fixture.close();
            }

            final db = await openDatabase();
            addTearDown(db.close);
            final tables = await db.customSelect('''
            SELECT table_name FROM information_schema.tables
            WHERE table_schema = 'public'
          ''').get();
            expect(
              tables.map((row) => row.read<String>('table_name')),
              unorderedEquals([
                '__schema',
                'teams',
                'team_members',
                'build_jobs',
                'build_runs',
                'billing_accounts',
                'billing_periods',
              ]),
            );
            expect(
              (await db
                      .customSelect('SELECT version FROM __schema')
                      .getSingle())
                  .read<int>('version'),
              32,
            );
            expect(
              (await db.customSelect('SELECT * FROM teams').getSingle()).data,
              {'id': 'team-1', 'name': 'OpenCI'},
            );
            expect(
              (await db.customSelect('SELECT * FROM team_members').getSingle())
                  .data,
              {'id': 1, 'team_id': 'team-1', 'user_id': 'member-1'},
            );
            expect(
              (await db.customSelect('SELECT * FROM build_jobs').getSingle())
                  .data,
              {'id': 'job-1', 'team_id': 'team-1'},
            );
            expect(
              (await db.customSelect('SELECT * FROM build_runs').getSingle())
                  .data,
              {
                'id': 'run-1',
                'build_job_id': 'job-1',
                'run_number': 42,
                'provisioned_udids': '["artifact-udid"]',
              },
            );
            expect(
              (await db
                      .customSelect('SELECT * FROM billing_accounts')
                      .getSingle())
                  .data,
              {'team_id': 'team-1'},
            );
            expect(
              (await db
                      .customSelect('SELECT * FROM billing_periods')
                      .getSingle())
                  .data,
              {'id': 'period-1', 'team_id': 'team-1'},
            );
          },
        );
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
