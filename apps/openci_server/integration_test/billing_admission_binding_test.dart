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
        run_id text UNIQUE, start_by_ms bigint, closed_at_ms bigint, claimed_at_ms bigint DEFAULT 0
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

      const attempt = BillingWorkerAttempt(
        admissionId: 'admission-1',
        jobId: 'job-1',
        runId: 'run-1',
        workerHost: 'worker-1',
      );

      Future<void> markBound() async {
        await db.customStatement(
          "UPDATE billing_admissions SET run_id = 'run-1'",
        );
        await db.customStatement(
          "UPDATE build_jobs SET latest_run_id = 'run-1'",
        );
      }

      test(
        'current bound completion keeps unrelated job fields and can repeat',
        () async {
          await markBound();
          await store.completeJob(attempt, BuildJobStatus.SUCCESS);
          await store.completeJob(attempt, BuildJobStatus.SUCCESS);
          final job = (await db.buildJobDao.getBuildJob('job-1'))!;
          expect(job.status, BuildJobStatus.SUCCESS);
          expect(job.latestRunId, 'run-1');
          expect(job.owner, 'org');
          expect(job.completedAt, isNotNull);
          expect(
            (await db
                    .customSelect('SELECT closed_at_ms FROM billing_admissions')
                    .getSingle())
                .readNullable<int>('closed_at_ms'),
            isNotNull,
          );
        },
      );

      test(
        'failure before run creation closes only the current open admission',
        () async {
          await store.completeJob(attempt, BuildJobStatus.FAILURE);
          expect(
            (await db.buildJobDao.getBuildJob('job-1'))!.status,
            BuildJobStatus.FAILURE,
          );
          await db.customStatement(
            "UPDATE build_jobs SET status = 'IN_PROGRESS'",
          );
          await expectLater(
            store.completeJob(attempt, BuildJobStatus.FAILURE),
            throwsA(isA<BillingAdmissionNotCurrent>()),
          );
        },
      );

      test('unbound success cannot complete a job', () async {
        await expectLater(
          store.completeJob(attempt, BuildJobStatus.SUCCESS),
          throwsA(isA<BillingAdmissionNotCurrent>()),
        );
      });

      test(
        'a rejected action rolls back changes while holding current attempt',
        () async {
          await markBound();
          await expectLater(
            store.withCurrentAttempt<void>(attempt, BuildJobStatus.SUCCESS, (
              _,
            ) async {
              await db.customStatement(
                "UPDATE build_jobs SET status = 'SUCCESS'",
              );
              throw StateError('downstream failed');
            }),
            throwsStateError,
          );
          expect(
            (await db.buildJobDao.getBuildJob('job-1'))!.status,
            BuildJobStatus.IN_PROGRESS,
          );
        },
      );

      for (final (name, sql) in [
        ('a new run', "UPDATE build_jobs SET latest_run_id = 'new-run'"),
        ('a new unbound claim', "UPDATE build_jobs SET latest_run_id = NULL"),
        ('another worker', "UPDATE build_jobs SET worker_host = 'other'"),
        ('another team', "UPDATE billing_admissions SET team_id = 'other'"),
        ('a rerun queue', "UPDATE build_jobs SET status = 'QUEUED'"),
        ('a cancellation', "UPDATE build_jobs SET status = 'CANCELLED'"),
      ]) {
        test('late completion cannot overwrite $name', () async {
          await markBound();
          await db.customStatement(sql);
          var called = false;
          await expectLater(
            store.withCurrentAttempt<void>(attempt, BuildJobStatus.SUCCESS, (
              _,
            ) async {
              called = true;
            }),
            throwsA(isA<BillingAdmissionNotCurrent>()),
          );
          expect(called, isFalse);
        });
      }

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
