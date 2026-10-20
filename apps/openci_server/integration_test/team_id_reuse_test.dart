import 'dart:io';

import 'package:drift_postgres/drift_postgres.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/team/team_dao.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  final databaseUrl = Platform.environment['OPENCI_TEST_DATABASE_URL'];

  test(
    'rejects team ID reuse after waiting for concurrent deletion',
    () async {
      final connection = await pg.Connection.openFromUrl(databaseUrl!);
      addTearDown(connection.close);
      final schema = 'team_reuse_${const Uuid().v4().replaceAll('-', '')}';
      await connection.execute('CREATE SCHEMA "$schema"');
      addTearDown(() => connection.execute('DROP SCHEMA "$schema" CASCADE'));
      await connection.execute('SET search_path TO "$schema"');
      final db = AppDatabase(PgDatabase.opened(connection));
      addTearDown(db.close);
      final team = DriftTeam(
        id: 'team-1',
        name: 'Original Team',
        installationIds: const [],
        aiEnabled: false,
        runNumber: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      await db.teamDao.createTeamAndMember(team, 'original-user');
      final pid =
          (await connection.execute('SELECT pg_backend_pid()')).single.single
              as int;

      final deleter = await pg.Connection.openFromUrl(databaseUrl);
      addTearDown(deleter.close);
      final observer = await pg.Connection.openFromUrl(databaseUrl);
      addTearDown(observer.close);
      await deleter.execute('SET search_path TO "$schema"');
      await deleter.execute('BEGIN');
      addTearDown(() => deleter.execute('ROLLBACK'));
      // Neither the new identity nor the deletion is visible to the creator yet.
      await deleter.execute("INSERT INTO billing_accounts VALUES ('team-1')");
      await deleter.execute("DELETE FROM teams WHERE id = 'team-1'");
      final rejected = expectLater(
        db.teamDao.createTeamAndMember(team, 'new-user'),
        throwsA(isA<TeamIdAlreadyUsedException>()),
      );

      final waiting = Stopwatch()..start();
      while (true) {
        final rows = await observer.execute('''
          SELECT pid FROM pg_stat_activity
          WHERE pid = $pid AND wait_event_type = 'Lock'
        ''');
        if (rows.isNotEmpty) break;
        if (waiting.elapsed > const Duration(seconds: 5)) {
          fail('Team creation did not wait for the concurrent deletion');
        }
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
      await deleter.execute('COMMIT');
      await rejected;

      expect(await db.teamDao.getTeam(team.id), isNull);
      expect(await db.teamDao.getTeamMembers(team.id), isEmpty);
      expect(
        await db.select(db.billingAccounts).getSingle(),
        BillingAccount(teamId: team.id),
      );
      final freshTeam = team.copyWith(id: 'fresh-team');
      await db.teamDao.createTeamAndMember(freshTeam, 'new-user');
      expect((await db.teamDao.getTeam(freshTeam.id))?.id, freshTeam.id);
      expect(
        (await db.teamDao.getTeamMembers(freshTeam.id)).single.userId,
        'new-user',
      );
      expect(await db.select(db.billingAccounts).get(), hasLength(1));
    },
    skip: databaseUrl == null ? 'Set OPENCI_TEST_DATABASE_URL' : false,
  );
}
