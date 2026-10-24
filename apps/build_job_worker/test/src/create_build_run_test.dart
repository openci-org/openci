import 'dart:async';

import 'package:build_job_worker/build_job_worker.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:openci_shared/test_helpers.dart';
import 'package:test/test.dart';

class _MockOpenCIApiService extends Mock implements OpenCIApiService {}

void main() {
  late OpenCIApiService api;
  const jobId = 'job-123';
  const runId = 'run-456';
  const secret = 'test-only-secret';

  setUp(() {
    api = _MockOpenCIApiService();
  });

  Future<int> create() => createBuildRun(api: api, jobId: jobId, runId: runId);

  group('createBuildRun', () {
    test('binds the paid run to the claimed admission and worker', () async {
      final payload = {
        'id': runId,
        'billingAdmissionId': 'admission-1',
        'workerHost': 'worker-1',
      };
      when(() => api.createRun(jobId, payload)).thenAnswer(
        (_) async => createMockResponse(<String, dynamic>{
          'success': true,
          'runNumber': 42,
        }),
      );

      final runNumber = await createBuildRun(
        api: api,
        jobId: jobId,
        runId: runId,
        billingAdmissionId: 'admission-1',
        workerHost: 'worker-1',
      );

      expect(runNumber, 42);
      verify(() => api.createRun(jobId, payload)).called(1);
    });

    test('rejects a paid run without its worker identity', () async {
      await expectLater(
        createBuildRun(
          api: api,
          jobId: jobId,
          runId: runId,
          billingAdmissionId: 'admission-1',
        ),
        throwsArgumentError,
      );
      verifyZeroInteractions(api);
    });

    test('creates one run and returns the server-assigned number', () async {
      when(() => api.createRun(jobId, {'id': runId})).thenAnswer(
        (_) async => createMockResponse(<String, dynamic>{
          'success': true,
          'runNumber': 1,
        }),
      );

      expect(await create(), 1);

      verify(() => api.createRun(jobId, {'id': runId})).called(1);
      verifyNoMoreInteractions(api);
    });

    for (final testCase in <String, Map<String, dynamic>?>{
      'a missing body': null,
      'a missing success flag': {'runNumber': 42},
      'a failure result': {'success': false, 'runNumber': 42},
      'a non-boolean success flag': {'success': 'true', 'runNumber': 42},
      'a missing run number': {'success': true},
      'a null run number': {'success': true, 'runNumber': null},
      'a zero run number': {'success': true, 'runNumber': 0},
      'a negative run number': {'success': true, 'runNumber': -1},
      'a string run number': {'success': true, 'runNumber': '42'},
      'a double run number': {'success': true, 'runNumber': 42.0},
      'a boolean run number': {'success': true, 'runNumber': true},
      'an object run number': {
        'success': true,
        'runNumber': {'value': secret},
      },
      'a list run number': {
        'success': true,
        'runNumber': [secret],
      },
    }.entries) {
      test('rejects ${testCase.key} without exposing response content', () async {
        when(() => api.createRun(jobId, {'id': runId})).thenAnswer(
          (_) async => createMockResponse<Map<String, dynamic>?>(
            testCase.value,
          ).copyWith<Map<String, dynamic>>(),
        );

        await expectLater(
          create(),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Invalid build run response: '
                  '"success" must be true and "runNumber" must be a positive integer.',
            ),
          ),
        );
        verify(() => api.createRun(jobId, {'id': runId})).called(1);
        verifyNoMoreInteractions(api);
      });
    }

    for (final statusCode in [400, 401, 404, 409, 503]) {
      test(
        'reports HTTP $statusCode without retrying or exposing errors',
        () async {
          when(() => api.createRun(jobId, {'id': runId})).thenAnswer(
            (_) async => createMockResponse<Map<String, dynamic>>(
              {},
              statusCode: statusCode,
            ).copyWith<Map<String, dynamic>>(bodyError: secret),
          );

          await expectLater(
            create(),
            throwsA(
              isA<StateError>().having(
                (error) => error.message,
                'message',
                'Failed to create build run: HTTP $statusCode.',
              ),
            ),
          );

          verify(() => api.createRun(jobId, {'id': runId})).called(1);
          verifyNoMoreInteractions(api);
        },
      );
    }

    for (final exception in [
      http.ClientException('Connection failed: $secret'),
      TimeoutException('Request timed out: $secret'),
      const FormatException('Invalid JSON', secret),
    ]) {
      test(
        'redacts ${exception.runtimeType} and preserves its stack',
        () async {
          final stackTrace = StackTrace.fromString('Run creation failed here');
          when(
            () => api.createRun(jobId, {'id': runId}),
          ).thenAnswer((_) => Future.error(exception, stackTrace));

          try {
            await create();
            fail('Expected run creation to fail');
          } on StateError catch (error, actualStackTrace) {
            expect(
              error.message,
              'Failed to create build run: ${exception.runtimeType}.',
            );
            expect(actualStackTrace.toString(), stackTrace.toString());
          }

          verify(() => api.createRun(jobId, {'id': runId})).called(1);
          verifyNoMoreInteractions(api);
        },
      );
    }

    test('redacts synchronous API failures', () async {
      when(
        () => api.createRun(jobId, {'id': runId}),
      ).thenThrow(StateError('Request failed: $secret'));

      await expectLater(
        create(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Failed to create build run: StateError.',
          ),
        ),
      );

      verify(() => api.createRun(jobId, {'id': runId})).called(1);
      verifyNoMoreInteractions(api);
    });
  });
}
