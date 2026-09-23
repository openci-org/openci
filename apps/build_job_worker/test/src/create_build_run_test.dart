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

  Future<void> create() => createBuildRun(api: api, jobId: jobId, runId: runId);

  group('createBuildRun', () {
    test('creates one run with the supplied job and run IDs', () async {
      when(
        () => api.createRun(jobId, {'id': runId}),
      ).thenAnswer((_) async => createMockResponse<void>(null));

      await create();

      verify(() => api.createRun(jobId, {'id': runId})).called(1);
      verifyNoMoreInteractions(api);
    });

    for (final statusCode in [400, 401, 404, 409, 503]) {
      test(
        'reports HTTP $statusCode without retrying or exposing errors',
        () async {
          when(() => api.createRun(jobId, {'id': runId})).thenAnswer(
            (_) async => createMockResponse<void>(
              null,
              statusCode: statusCode,
            ).copyWith<void>(bodyError: secret),
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
