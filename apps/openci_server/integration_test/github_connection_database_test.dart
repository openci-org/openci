import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift_postgres/drift_postgres.dart';
import 'package:openci_server/database.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import '../test/helpers/github_connection_table_tests.dart';
import '../test/helpers/insert_github_connection_tests.dart';

void main() {
  final databaseUrl = Platform.environment['OPENCI_TEST_DATABASE_URL'];

  group(
    'GitHub connections on PostgreSQL',
    () {
      late pg.Connection connection;

      setUp(() async {
        connection = await pg.Connection.openFromUrl(databaseUrl!);
        addTearDown(connection.close);
        final schema =
            'github_connection_test_${const Uuid().v4().replaceAll('-', '')}';
        await connection.execute('CREATE SCHEMA "$schema"');
        addTearDown(() => connection.execute('DROP SCHEMA "$schema" CASCADE'));
        await connection.execute('SET search_path TO "$schema"');
      });

      group('table constraints', () {
        testGitHubConnectionTable(
          () async => AppDatabase(PgDatabase.opened(connection)),
        );
      });

      group('inserting verified connections', () {
        testInsertGitHubConnection(
          () async => AppDatabase(PgDatabase.opened(connection)),
        );
      });

      test(
        'upgrades v27 without promoting legacy links or losing sessions',
        () async {
          var db = AppDatabase(PgDatabase.opened(connection));
          addTearDown(() => db.close());
          final team = DriftTeam(
            id: 'team-1',
            name: 'OpenCI',
            installationIds: const [123],
            aiEnabled: false,
            runNumber: 42,
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          );
          await db.teamDao.createTeamAndMember(team, 'user-1');
          await db.into(db.teams).insert(team.copyWith(id: 'team-2'));
          final request = DriftGitHubConnectionRequest(
            id: 'request-1',
            userId: 'user-1',
            teamId: 'team-1',
            stateHash: 'state-hash',
            codeVerifier: 'code-verifier',
            createdAt: DateTime.utc(2026),
            expiresAt: DateTime.utc(2026, 1, 1, 0, 10),
          );
          await db.into(db.gitHubConnectionRequests).insert(request);
          await db
              .into(db.gitHubConnectionSessions)
              .insert(
                GitHubConnectionSessionsCompanion.insert(
                  id: 'session-1',
                  userId: 'user-1',
                  teamId: 'team-1',
                  githubUserId: 123,
                  referenceHash: 'reference-hash',
                  encryptedAccessToken: const Value('encrypted-user-token'),
                  createdAt: DateTime.utc(2026),
                  expiresAt: DateTime.utc(2026, 1, 1, 0, 10),
                ),
              );
          final originalTeam = await db.teamDao.getTeam('team-1');
          final originalRequest = await db
              .select(db.gitHubConnectionRequests)
              .getSingle();

          // The existing tables are unchanged in v28. Removing only the new table
          // and restoring the version recreates the populated v27 schema.
          await db.customStatement('DROP TABLE github_connections');
          await db.customStatement('UPDATE __schema SET version = 27');
          await db.close();
          db = AppDatabase(PgDatabase.opened(connection));

          expect(await db.select(db.gitHubConnections).get(), isEmpty);
          expect(
            (await db.customSelect('SELECT version FROM __schema').getSingle())
                .read<int>('version'),
            28,
          );
          expect(
            (await db.teamDao.getTeam('team-1'))!.toJson(),
            originalTeam!.toJson(),
          );
          expect((await db.teamDao.getTeam('team-2'))!.installationIds, [123]);
          expect(
            (await db.teamDao.getTeamMembers('team-1')).single.userId,
            'user-1',
          );
          expect(
            (await db.select(db.gitHubConnectionRequests).getSingle()).toJson(),
            originalRequest.toJson(),
          );
          final session = await db
              .select(db.gitHubConnectionSessions)
              .getSingle();
          expect(session.id, 'session-1');
          expect(session.referenceHash, 'reference-hash');
          expect(session.encryptedAccessToken, 'encrypted-user-token');
          expect(session.consumedAt, isNull);

          await db.close();
          db = AppDatabase(PgDatabase.opened(connection));
          expect(await db.select(db.gitHubConnections).get(), isEmpty);
          expect(
            (await db.teamDao.getTeam('team-1'))!.toJson(),
            originalTeam.toJson(),
          );
        },
      );
    },
    skip: databaseUrl == null
        ? 'Set OPENCI_TEST_DATABASE_URL to a test database'
        : false,
  );
}
