import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift_postgres/drift_postgres.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  final databaseUrl = Platform.environment['OPENCI_TEST_DATABASE_URL'];

  for (final migrate in [false, true]) {
    test(
      'PostgreSQL run numbers on ${migrate ? 'v30 upgrade' : 'fresh database'}',
      () async {
        final connection = await pg.Connection.openFromUrl(databaseUrl!);
        addTearDown(connection.close);
        final schema =
            'run_number_test_${const Uuid().v4().replaceAll('-', '')}';
        await connection.execute('CREATE SCHEMA "$schema"');
        addTearDown(() => connection.execute('DROP SCHEMA "$schema" CASCADE'));
        await connection.execute('SET search_path TO "$schema"');
        var db = AppDatabase(PgDatabase.opened(connection));
        addTearDown(() => db.close());
        final now = DateTime.utc(2026);
        final team = DriftTeam(
          id: 'team-1',
          name: 'OpenCI',
          installationIds: const [123],
          aiEnabled: false,
          runNumber: 42,
          createdAt: now,
          updatedAt: now,
        );
        await db.teamDao.createTeamAndMember(team, 'member-1');
        await db
            .into(db.buildJobs)
            .insert(
              DriftBuildJob(
                id: 'job-1',
                teamId: team.id,
                status: BuildJobStatus.SUCCESS,
                owner: 'openci-org',
                repo: 'openci',
                workflowName: 'CI',
                workflowFileName: 'ci.dart',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db.buildRunDao.insertBuildRun(
          DriftBuildRun(
            id: 'run-1',
            buildJobId: 'job-1',
            status: 'completed',
            conclusion: 'success',
            createdAt: now,
            updatedAt: now,
          ),
        );
        final originalTeam = (await db.teamDao.getTeam(team.id))!;
        final originalMembers = await db.teamDao.getTeamMembers(team.id);
        final originalJob = await db.select(db.buildJobs).getSingle();
        final originalRun = await db.select(db.buildRuns).getSingle();

        if (migrate) {
          await db.customStatement('DROP TABLE skipped_workflow_reports');
          await db.customStatement(
            'ALTER TABLE build_runs DROP COLUMN run_number',
          );
          await db.customStatement('UPDATE __schema SET version = 30');
          await db.close();
          db = AppDatabase(PgDatabase.opened(connection));
        }

        expect(
          (await db.customSelect('SELECT version FROM __schema').getSingle())
              .read<int>('version'),
          32,
        );
        expect(
          (await db.teamDao.getTeam(team.id))!.toJson(),
          originalTeam.toJson(),
        );
        expect(await db.teamDao.getTeamMembers(team.id), originalMembers);
        expect(
          (await db.select(db.buildJobs).getSingle()).toJson(),
          originalJob.toJson(),
        );
        final preservedRun = await db.select(db.buildRuns).getSingle();
        expect(preservedRun.toJson(), originalRun.toJson());
        expect(preservedRun.runNumber, isNull);

        await db.buildRunDao.insertBuildRun(
          DriftBuildRun(
            id: 'run-2',
            buildJobId: 'job-1',
            runNumber: 42,
            status: 'in_progress',
            createdAt: now,
            updatedAt: now,
          ),
        );
        await db.close();
        db = AppDatabase(PgDatabase.opened(connection));
        expect(
          (await db.buildRunDao.getBuildRun('job-1', 'run-1'))!.runNumber,
          isNull,
        );
        expect(
          (await db.buildRunDao.getBuildRun('job-1', 'run-2'))!.runNumber,
          42,
        );
        expect((await db.teamDao.getTeam(team.id))!.runNumber, 42);
      },
      skip: databaseUrl == null ? 'Set OPENCI_TEST_DATABASE_URL' : false,
    );
  }

  group(
    'Atomic run-number allocation on PostgreSQL',
    () {
      late AppDatabase db;
      late AppDatabase peer;

      setUp(() async {
        final connection = await pg.Connection.openFromUrl(databaseUrl!);
        addTearDown(connection.close);
        final schema =
            'run_number_test_${const Uuid().v4().replaceAll('-', '')}';
        await connection.execute('CREATE SCHEMA "$schema"');
        addTearDown(() => connection.execute('DROP SCHEMA "$schema" CASCADE'));
        await connection.execute('SET search_path TO "$schema"');
        db = AppDatabase(PgDatabase.opened(connection));
        addTearDown(db.close);
        await db.seedDao.ensureTestTeam(teamId: 'team-a');
        await db.seedDao.ensureTestTeam(teamId: 'team-b');

        final other = await pg.Connection.openFromUrl(databaseUrl);
        addTearDown(other.close);
        await other.execute('SET search_path TO "$schema"');
        peer = AppDatabase(PgDatabase.opened(other));
        addTearDown(peer.close);
      });

      test(
        'allocates distinct numbers across concurrent connections',
        () async {
          final numbers = await Future.wait(
            List.generate(30, (index) {
              final database = index.isEven ? db : peer;
              return database.transaction(
                () => database.teamDao.allocateRunNumber('team-a'),
              );
            }),
          );

          expect(
            numbers,
            unorderedEquals(List.generate(30, (index) => index + 1)),
          );
          expect((await db.teamDao.getTeam('team-a'))!.runNumber, 31);
          expect((await db.teamDao.getTeam('team-b'))!.runNumber, 1);
          expect(
            await peer.transaction(
              () => peer.teamDao.allocateRunNumber('team-b'),
            ),
            1,
          );
          expect((await db.teamDao.getTeam('team-a'))!.runNumber, 31);
        },
      );

      test('rolls back the counter with a failed transaction', () async {
        await expectLater(
          db.transaction(() async {
            expect(await db.teamDao.allocateRunNumber('team-a'), 1);
            throw StateError('Run creation failed');
          }),
          throwsStateError,
        );

        expect((await peer.teamDao.getTeam('team-a'))!.runNumber, 1);
        expect(
          await peer.transaction(
            () => peer.teamDao.allocateRunNumber('team-a'),
          ),
          1,
        );
      });

      test(
        'settings updates and reseeding preserve an advanced counter',
        () async {
          final staleTeam = (await db.teamDao.getTeam('team-a'))!;
          await peer.transaction(
            () => peer.teamDao.allocateRunNumber('team-a'),
          );

          await db.teamDao.updateTeam(staleTeam.copyWith(name: 'Updated team'));
          await db.seedDao.ensureTestTeam(
            teamId: 'team-a',
            installationId: 222,
          );

          final saved = (await peer.teamDao.getTeam('team-a'))!;
          expect(saved.name, 'Updated team');
          expect(saved.installationIds, [...staleTeam.installationIds, 222]);
          expect(saved.runNumber, 2);
          expect(
            await peer.transaction(
              () => peer.teamDao.allocateRunNumber('team-a'),
            ),
            2,
          );
        },
      );

      for (final invalid in [0, -1]) {
        test('rejects counter $invalid without updating it', () async {
          await (db.update(
            db.teams,
          )..where((row) => row.id.equals('team-a'))).write(
            TeamsCompanion(runNumber: Value(invalid)),
          );

          await expectLater(
            peer.teamDao.allocateRunNumber('team-a'),
            throwsStateError,
          );

          expect((await db.teamDao.getTeam('team-a'))!.runNumber, invalid);
        });
      }
    },
    skip: databaseUrl == null ? 'Set OPENCI_TEST_DATABASE_URL' : false,
  );
}
