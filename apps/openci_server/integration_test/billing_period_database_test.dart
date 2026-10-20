import 'dart:io';

import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift_postgres/drift_postgres.dart';
import 'package:openci_server/database.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  final databaseUrl = Platform.environment['OPENCI_TEST_DATABASE_URL'];

  for (final migrate in [false, true]) {
    test(
      'PostgreSQL billing periods on ${migrate ? 'v29 upgrade' : 'fresh database'}',
      () async {
        final connection = await pg.Connection.openFromUrl(databaseUrl!);
        addTearDown(connection.close);
        final schema = 'period_test_${const Uuid().v4().replaceAll('-', '')}';
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
        const account = BillingAccount(teamId: 'team-1');
        await db.into(db.billingAccounts).insert(account);
        final originalTeam = (await db.teamDao.getTeam(team.id))!.toJson();
        final originalMembers = await db.teamDao.getTeamMembers(team.id);

        if (migrate) {
          await db.customStatement('DROP TABLE billing_periods');
          await db.customStatement('UPDATE __schema SET version = 29');
          await db.close();
          db = AppDatabase(PgDatabase.opened(connection));
        }

        expect(await db.select(db.billingPeriods).get(), isEmpty);
        expect(
          (await db.customSelect('SELECT version FROM __schema').getSingle())
              .read<int>('version'),
          30,
        );
        expect((await db.teamDao.getTeam(team.id))!.toJson(), originalTeam);
        expect(await db.teamDao.getTeamMembers(team.id), originalMembers);
        expect(await db.select(db.billingAccounts).getSingle(), account);

        final trial = BillingPeriod(
          id: 'trial-1',
          teamId: team.id,
          planId: 'pro',
          periodType: 'trial',
          startsAt: DateTime.parse('2026-10-01T09:00:00+09:00'),
          endsAt: DateTime.utc(2026, 10, 8),
        );
        final paid = trial.copyWith(
          id: 'paid-1',
          planId: 'light',
          periodType: 'paid',
          startsAt: trial.endsAt,
          endsAt: DateTime.utc(2026, 11, 8),
          allowanceSeconds: const Value(36000),
        );
        final renewal = paid.copyWith(
          id: 'paid-2',
          planId: 'pro',
          startsAt: paid.endsAt,
          endsAt: DateTime.utc(2026, 12, 8),
          allowanceSeconds: const Value(360000),
        );
        for (final period in [trial, paid, renewal]) {
          await db.into(db.billingPeriods).insert(period);
        }
        final rawTrial = await db
            .customSelect(
              "SELECT starts_at, allowance_seconds FROM billing_periods WHERE id = 'trial-1'",
            )
            .getSingle();
        expect(
          rawTrial.read<int>('starts_at'),
          DateTime.utc(2026, 10).millisecondsSinceEpoch ~/ 1000,
        );
        expect(rawTrial.readNullable<int>('allowance_seconds'), isNull);

        await expectLater(
          db
              .into(db.billingPeriods)
              .insert(
                paid.copyWith(allowanceSeconds: const Value(999999)),
              ),
          throwsA(
            isA<pg.ServerException>().having((e) => e.code, 'code', '23505'),
          ),
        );
        for (final invalid in [
          paid.copyWith(planId: 'unknown'),
          paid.copyWith(periodType: 'unknown'),
          paid.copyWith(endsAt: paid.startsAt),
          paid.copyWith(endsAt: trial.startsAt),
          paid.copyWith(allowanceSeconds: const Value(-1)),
          paid.copyWith(allowanceSeconds: const Value(null)),
        ]) {
          await expectLater(
            db.into(db.billingPeriods).insert(invalid.copyWith(id: 'invalid')),
            throwsA(
              isA<pg.ServerException>().having((e) => e.code, 'code', '23514'),
            ),
          );
        }
        await expectLater(
          db
              .into(db.billingPeriods)
              .insert(
                paid.copyWith(id: 'orphan', teamId: 'missing-account'),
              ),
          throwsA(
            isA<pg.ServerException>().having((e) => e.code, 'code', '23503'),
          ),
        );

        await db.teamDao.deleteTeam(team.id);
        expect(await db.teamDao.getTeam(team.id), isNull);
        await expectLater(
          db.delete(db.billingAccounts).delete(account),
          throwsA(
            isA<pg.ServerException>().having((e) => e.code, 'code', '23503'),
          ),
        );
        await db.close();
        db = AppDatabase(PgDatabase.opened(connection));
        final periods = await (db.select(
          db.billingPeriods,
        )..orderBy([(p) => OrderingTerm.asc(p.startsAt)])).get();
        expect(periods.map((p) => p.id), ['trial-1', 'paid-1', 'paid-2']);
        expect(periods.map((p) => p.allowanceSeconds), [null, 36000, 360000]);
        expect(periods.first.startsAt.toUtc(), DateTime.utc(2026, 10));
        expect(periods.last.endsAt.toUtc(), DateTime.utc(2026, 12, 8));
        expect(await db.select(db.billingAccounts).getSingle(), account);
      },
      skip: databaseUrl == null ? 'Set OPENCI_TEST_DATABASE_URL' : false,
    );
  }
}
