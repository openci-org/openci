import 'dart:io';

import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

import 'helpers/billing_worker_bridge.dart';

void main() {
  final databaseUrl = Platform.environment['OPENCI_TEST_DATABASE_URL'];
  group(
    'Dart and Go paid worker bridge',
    () {
      late Directory artifacts;
      late String binary;
      late BillingWorkerBridge bridge;

      setUpAll(() async {
        artifacts = await Directory.systemTemp.createTemp(
          'billing_bridge_build_',
        );
        addTearDown(() => artifacts.delete(recursive: true));
        binary = '${artifacts.path}/worker_bridge';
        final result = await Process.run('go', [
          'build',
          '-o',
          binary,
          './integration_test/worker_bridge',
        ], workingDirectory: '../genuineci_server');
        expect(result.exitCode, 0, reason: result.stderr.toString());
      });

      setUp(() async {
        bridge = await BillingWorkerBridge.create(databaseUrl!, binary);
      });

      test('claim, bind, measure and finish after entitlement ends', () async {
        expect((await bridge.status())['canStartCi'], isTrue);
        final job = await bridge.claim();
        expect(job, isNotNull);
        final identity = bridge.execution(job!);
        await bridge.bind(job);
        expect(await bridge.post('/worker/billing/start', identity), {
          'active': true,
          'measurementIncomplete': false,
        });
        expect(await bridge.post('/worker/billing/report', identity), {
          'active': true,
          'measurementIncomplete': false,
        });

        await bridge.db.customStatement(
          "UPDATE billing_periods SET allowance_seconds = 0",
        );
        expect(await bridge.claim(workerHost: 'worker-2'), isNull);
        expect((await bridge.status())['blockReason'], 'allowance_exhausted');
        await bridge.db.customStatement(
          "UPDATE billing_stripe_state SET subscription_status = 'canceled'",
        );
        expect(await bridge.post('/worker/billing/report', identity), {
          'active': true,
          'measurementIncomplete': false,
        });
        expect(
          await bridge.post('/worker/billing/report', {
            ...identity,
            'outcome': 'success',
          }),
          {
            'active': false,
            'measurementIncomplete': false,
          },
        );
        expect(
          await bridge.post('/builds/job-1', {
            ...bridge.attempt(job),
            'status': 'SUCCESS',
          }, method: 'PATCH'),
          {'success': true},
        );
        final stored = (await bridge.db.buildJobDao.getBuildJob('job-1'))!;
        expect(stored.status, BuildJobStatus.SUCCESS);
        expect(stored.latestRunId, 'run-1');
        final execution = await bridge.db
            .customSelect('SELECT * FROM billing_executions')
            .getSingle();
        expect(execution.read<String>('outcome'), 'success');
        expect(execution.read<bool>('measurement_incomplete'), isFalse);
        expect(
          execution.read<int>('finished_at_ms'),
          greaterThanOrEqualTo(execution.read<int>('started_at_ms')),
        );
        expect(await bridge.claim(), isNull);
      });

      test(
        'expired bound admission is reclaimed and old callbacks are rejected',
        () async {
          final old = (await bridge.claim())!;
          await bridge.bind(old);
          await bridge.db.customStatement(
            'UPDATE billing_admissions SET claimed_at_ms = 0, start_by_ms = 1',
          );
          final current = (await bridge.claim())!;
          expect(current.id, old.id);
          expect(current.billingAdmissionId, isNot(old.billingAdmissionId));
          await bridge.post(
            '/worker/billing/start',
            bridge.execution(old),
            expectedStatus: 409,
          );
          await bridge.post(
            '/builds/job-1',
            {...bridge.attempt(old), 'status': 'FAILURE'},
            method: 'PATCH',
            expectedStatus: 409,
          );
          final stored = (await bridge.db.buildJobDao.getBuildJob('job-1'))!;
          expect(stored.status, BuildJobStatus.IN_PROGRESS);
          expect(stored.latestRunId, isNull);
          expect(
            await bridge.db
                .customSelect('SELECT * FROM billing_executions')
                .get(),
            isEmpty,
          );
          expect(
            (await bridge.db.buildRunDao.getBuildRuns(
              'job-1',
            )).single.conclusion,
            'failure',
          );
        },
      );

      test(
        'untrusted workers cannot claim or alter paid execution identity',
        () async {
          await bridge.post(
            '/worker/jobs/claim',
            {'workerHost': 'worker-1'},
            token: 'invalid',
            expectedStatus: 401,
          );
          final job = (await bridge.claim())!;
          await bridge.bind(job);
          await bridge.post('/worker/billing/start', {
            ...bridge.execution(job),
            'workerHost': 'other',
          }, expectedStatus: 409);
          await bridge.post('/worker/billing/start', {
            ...bridge.execution(job),
            'startedAt': 0,
          }, expectedStatus: 400);
          expect(
            await bridge.db
                .customSelect('SELECT * FROM billing_executions')
                .get(),
            isEmpty,
          );
        },
      );
    },
    skip: databaseUrl == null ? 'Set OPENCI_TEST_DATABASE_URL' : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
