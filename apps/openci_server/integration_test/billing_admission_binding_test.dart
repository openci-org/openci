import 'dart:io';

import 'package:drift_postgres/drift_postgres.dart';
import 'package:openci_server/billing/billing_admission_store.dart';
import 'package:openci_server/database.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:postgres/postgres.dart' as pg;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

void main() {
  final databaseUrl = Platform.environment['OPENCI_TEST_DATABASE_URL'];
  group(
    'paid admission binding',
    () {
      late AppDatabase db;
      late BillingAdmissionStore store;

      setUp(() async {
        final connection = await pg.Connection.openFromUrl(databaseUrl!);
        addTearDown(connection.close);
        final schema = 'admission_${const Uuid().v4().replaceAll('-', '')}';
        await connection.execute('CREATE SCHEMA "$schema"');
        addTearDown(() => connection.execute('DROP SCHEMA "$schema" CASCADE'));
        await connection.execute('SET search_path TO "$schema"');
        db = AppDatabase(PgDatabase.opened(connection));
        addTearDown(db.close);
        final now = DateTime.now().toUtc();
        await db.buildJobDao.insertBuildJob(
          DriftBuildJob(
            id: 'job-1',
            teamId: 'team-1',
            workerHost: 'worker-1',
            status: BuildJobStatus.IN_PROGRESS,
            owner: 'org',
            repo: 'repo',
            workflowName: 'CI',
            workflowFileName: 'ci.dart',
            createdAt: now,
            updatedAt: now,
          ),
        );
        await db.customStatement('''CREATE TABLE billing_admissions (
        id text PRIMARY KEY, job_id text, team_id text, worker_host text,
        run_id text UNIQUE, start_by_ms bigint, closed_at_ms bigint
      )''');
        await db.customStatement(
          r'''INSERT INTO billing_admissions
        (id, job_id, team_id, worker_host, start_by_ms)
        VALUES ('admission-1', 'job-1', 'team-1', 'worker-1', $1)''',
          [now.add(const Duration(minutes: 2)).millisecondsSinceEpoch],
        );
        store = BillingAdmissionStore(db);
      });

      Future<void> bind() => store.bindRun(
        admissionId: 'admission-1',
        jobId: 'job-1',
        runId: 'run-1',
        workerHost: 'worker-1',
      );

      test('commits the binding and run together', () async {
        await db.transaction(() async {
          await bind();
          final now = DateTime.now().toUtc();
          await db.buildRunDao.insertBuildRun(
            DriftBuildRun(
              id: 'run-1',
              buildJobId: 'job-1',
              status: 'in_progress',
              createdAt: now,
              updatedAt: now,
            ),
          );
          await db.buildJobDao.incrementRunCount(
            id: 'job-1',
            latestRunId: 'run-1',
            updatedAt: now,
            requireInProgress: true,
          );
        });
        expect(
          (await db
                  .customSelect('SELECT run_id FROM billing_admissions')
                  .getSingle())
              .read<String>('run_id'),
          'run-1',
        );
        expect(
          (await db.buildJobDao.getBuildJob('job-1'))!.latestRunId,
          'run-1',
        );
        await expectLater(bind(), throwsA(isA<BillingAdmissionNotCurrent>()));
      });

      test('later failure rolls back binding and permits retry', () async {
        await expectLater(
          db.transaction(() async {
            await bind();
            throw StateError('run creation failed');
          }),
          throwsStateError,
        );
        expect(
          (await db
                  .customSelect('SELECT run_id FROM billing_admissions')
                  .getSingle())
              .readNullable<String>('run_id'),
          isNull,
        );
        await bind();
      });

      for (final (name, sql) in [
        ('expired admission', 'UPDATE billing_admissions SET start_by_ms = 0'),
        ('closed admission', 'UPDATE billing_admissions SET closed_at_ms = 1'),
        ('other worker', "UPDATE build_jobs SET worker_host = 'other'"),
        ('other team', "UPDATE billing_admissions SET team_id = 'other'"),
        ('reclaimed job', "UPDATE build_jobs SET status = 'QUEUED'"),
        ('already bound', "UPDATE billing_admissions SET run_id = 'other-run'"),
      ]) {
        test('rejects $name', () async {
          await db.customStatement(sql);
          await expectLater(bind(), throwsA(isA<BillingAdmissionNotCurrent>()));
          expect(await db.buildRunDao.getBuildRuns('job-1'), isEmpty);
        });
      }
    },
    skip: databaseUrl == null ? 'Set OPENCI_TEST_DATABASE_URL' : false,
  );
}
