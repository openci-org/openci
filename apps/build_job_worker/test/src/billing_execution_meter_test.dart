import 'dart:async';

import 'package:build_job_worker/src/billing_execution_meter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:openci_shared/test_helpers.dart';
import 'package:test/test.dart';

class _Api extends Mock implements OpenCIApiService {}

void main() {
  late OpenCIApiService api;
  late BillingExecutionMeter meter;
  late List<Object> errors;
  final identity = {
    'admissionId': 'admission-1',
    'jobId': 'job-1',
    'runId': 'run-1',
    'workerHost': 'worker-1',
  };

  setUp(() {
    api = _Api();
    errors = [];
    meter = BillingExecutionMeter(
      api: api,
      job: BuildJob(
        id: 'job-1',
        status: BuildJobStatus.IN_PROGRESS,
        owner: 'owner',
        repo: 'repo',
        workflowName: 'CI',
        workflowFileName: 'ci.dart',
        commitSha: 'sha',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        billingAdmissionId: 'admission-1',
        workerHost: 'worker-1',
      ),
      runId: 'run-1',
      onError: (error, _) => errors.add(error),
    );
    when(() => api.startBillingExecution(any())).thenAnswer(
      (_) async => createMockResponse(<String, dynamic>{
        'active': true,
        'measurementIncomplete': false,
      }),
    );
    when(() => api.reportBillingExecution(any())).thenAnswer(
      (invocation) async => createMockResponse(<String, dynamic>{
        'active': !(invocation.positionalArguments.single as Map).containsKey(
          'outcome',
        ),
        'measurementIncomplete': false,
      }),
    );
  });

  tearDown(() async {
    try {
      await meter.finish(BuildJobStatus.CANCELLED);
    } catch (_) {}
  });

  test(
    'uses only server-timed identity and stops reporting after completion',
    () async {
      await meter.start();
      await meter.heartbeat();
      await meter.finish(BuildJobStatus.SUCCESS);
      await meter.heartbeat();

      verify(() => api.startBillingExecution(identity)).called(1);
      verify(() => api.reportBillingExecution(identity)).called(1);
      verify(
        () => api.reportBillingExecution({...identity, 'outcome': 'success'}),
      ).called(1);
      verifyNoMoreInteractions(api);
      expect(errors, isEmpty);
    },
  );

  test(
    'a transient heartbeat failure is redacted and permits the next report',
    () async {
      await meter.start();
      var calls = 0;
      when(() => api.reportBillingExecution(identity)).thenAnswer((_) async {
        if (calls++ == 0) throw StateError('secret-key');
        return createMockResponse(<String, dynamic>{
          'active': true,
          'measurementIncomplete': false,
        });
      });

      await meter.heartbeat();
      await meter.heartbeat();

      expect(calls, 2);
      expect(errors, hasLength(1));
      expect(errors.single.toString(), isNot(contains('secret-key')));
    },
  );

  test(
    'coalesces overlapping heartbeats without delaying finalization',
    () async {
      await meter.start();
      final release = Completer<void>();
      when(() => api.reportBillingExecution(identity)).thenAnswer((_) async {
        await release.future;
        return createMockResponse(<String, dynamic>{
          'active': true,
          'measurementIncomplete': false,
        });
      });

      final first = meter.heartbeat();
      final second = meter.heartbeat();
      await meter.finish(BuildJobStatus.SUCCESS);
      release.complete();
      await Future.wait([first, second]);
      await meter.heartbeat();

      verify(() => api.reportBillingExecution(identity)).called(1);
      verify(
        () => api.reportBillingExecution({...identity, 'outcome': 'success'}),
      ).called(1);
    },
  );

  test(
    'an expired execution stops heartbeats and surfaces incomplete measurement',
    () async {
      await meter.start();
      when(() => api.reportBillingExecution(identity)).thenAnswer(
        (_) async => createMockResponse(<String, dynamic>{
          'active': false,
          'measurementIncomplete': true,
        }),
      );

      await meter.heartbeat();
      await meter.heartbeat();

      verify(() => api.reportBillingExecution(identity)).called(1);
      expect(errors, hasLength(1));
      await meter.finish(BuildJobStatus.FAILURE);
    },
  );

  for (final body in <Map<String, dynamic>>[
    {},
    {'active': 'true', 'measurementIncomplete': false},
    {'active': false, 'measurementIncomplete': false},
    {'active': true, 'measurementIncomplete': true},
  ]) {
    test('rejects an unusable start acknowledgement: $body', () async {
      when(
        () => api.startBillingExecution(any()),
      ).thenAnswer((_) async => createMockResponse(body));
      await expectLater(meter.start(), throwsStateError);
    });
  }

  test('does not include a rejected response body in the error', () async {
    when(() => api.startBillingExecution(any())).thenAnswer(
      (_) async => createMockResponse(<String, dynamic>{
        'secret': 'secret-key',
      }, statusCode: 503),
    );
    await expectLater(
      meter.start(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Billing execution request failed: HTTP 503.',
        ),
      ),
    );
  });

  for (final (status, outcome) in [
    (BuildJobStatus.SUCCESS, 'success'),
    (BuildJobStatus.FAILURE, 'failure'),
    (BuildJobStatus.CANCELLED, 'cancelled'),
    (BuildJobStatus.TIMED_OUT, 'timed_out'),
  ]) {
    test('reports $outcome once the execution finishes', () async {
      await meter.start();
      await meter.finish(status);
      verify(
        () => api.reportBillingExecution({...identity, 'outcome': outcome}),
      ).called(1);
    });
  }
}
