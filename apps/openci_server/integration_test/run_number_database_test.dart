import 'dart:io';

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
          31,
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
}
