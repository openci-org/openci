import 'dart:io';

import 'package:drift_postgres/drift_postgres.dart';
import 'package:openci_server/database.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  final databaseUrl = Platform.environment['OPENCI_TEST_DATABASE_URL'];

  test(
    'PostgreSQL v28 migration preserves teams and adds durable billing identity',
    () async {
      final connection = await pg.Connection.openFromUrl(databaseUrl!);
      addTearDown(connection.close);
      final schema = 'billing_test_${const Uuid().v4().replaceAll('-', '')}';
      await connection.execute('CREATE SCHEMA "$schema"');
      addTearDown(() => connection.execute('DROP SCHEMA "$schema" CASCADE'));
      await connection.execute('SET search_path TO "$schema"');
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
      await db.teamDao.createTeamAndMember(team, 'member-1');
      final originalTeam = await db.teamDao.getTeam(team.id);
      final members = await db.teamDao.getTeamMembers(team.id);

      // Remove later schema additions to recreate a populated v28 database.
      await db.customStatement('ALTER TABLE build_runs DROP COLUMN run_number');
      await db.customStatement('DROP TABLE billing_periods');
      await db.customStatement('DROP TABLE billing_accounts');
      await db.customStatement('UPDATE __schema SET version = 28');
      await db.close();
      db = AppDatabase(PgDatabase.opened(connection));

      expect(await db.select(db.billingAccounts).get(), isEmpty);
      expect(
        (await db.customSelect('SELECT version FROM __schema').getSingle())
            .read<int>('version'),
        31,
      );
      expect(
        (await db.teamDao.getTeam(team.id))!.toJson(),
        originalTeam!.toJson(),
      );
      expect(await db.teamDao.getTeamMembers(team.id), members);

      const account = BillingAccount(teamId: 'team-1');
      await db.into(db.billingAccounts).insert(account);
      await expectLater(
        db.into(db.billingAccounts).insert(account),
        throwsA(isA<pg.ServerException>()),
      );
      expect(await db.select(db.billingAccounts).getSingle(), account);

      await db.teamDao.deleteTeam(team.id);
      expect(await db.teamDao.getTeam(team.id), isNull);
      expect(await db.teamDao.getTeamMembers(team.id), isEmpty);
      expect(await db.select(db.billingAccounts).getSingle(), account);
    },
    skip: databaseUrl == null ? 'Set OPENCI_TEST_DATABASE_URL' : false,
  );
}
