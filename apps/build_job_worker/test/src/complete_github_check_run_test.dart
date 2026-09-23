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
  const secret = 'test-only-secret';
  const successPayload = {'status': 'completed', 'conclusion': 'success'};

  setUp(() {
    api = _MockOpenCIApiService();
  });

  Future<void> complete(BuildJobStatus status) =>
      completeGitHubCheckRun(api: api, jobId: jobId, status: status);

  group('completeGitHubCheckRun', () {
    for (final entry in const {
      BuildJobStatus.SUCCESS: 'success',
      BuildJobStatus.FAILURE: 'failure',
      BuildJobStatus.CANCELLED: 'cancelled',
      BuildJobStatus.SKIPPED: 'skipped',
      BuildJobStatus.TIMED_OUT: 'timed_out',
    }.entries) {
      test('completes the job check with ${entry.value}', () async {
        final payload = {'status': 'completed', 'conclusion': entry.value};
        when(
          () => api.updateCheckRun(jobId, payload),
        ).thenAnswer((_) async => createMockResponse<void>(null));

        await complete(entry.key);

        verify(() => api.updateCheckRun(jobId, payload)).called(1);
        verifyNoMoreInteractions(api);
      });
    }

    for (final status in [
      BuildJobStatus.WAITING,
      BuildJobStatus.QUEUED,
      BuildJobStatus.IN_PROGRESS,
    ]) {
      test('rejects ${status.name} before calling the API', () async {
        await expectLater(complete(status), throwsArgumentError);

        verifyZeroInteractions(api);
      });
    }

    for (final statusCode in [400, 401, 404, 503]) {
      test(
        'reports HTTP $statusCode without retrying or exposing errors',
        () async {
          when(() => api.updateCheckRun(jobId, successPayload)).thenAnswer(
            (_) async => createMockResponse<void>(
              null,
              statusCode: statusCode,
            ).copyWith<void>(bodyError: secret),
          );

          await expectLater(
            complete(BuildJobStatus.SUCCESS),
            throwsA(
              isA<StateError>().having(
                (error) => error.message,
                'message',
                'Failed to complete GitHub check run: HTTP $statusCode.',
              ),
            ),
          );

          verify(() => api.updateCheckRun(jobId, successPayload)).called(1);
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
          final stackTrace = StackTrace.fromString(
            'Check completion failed here',
          );
          when(
            () => api.updateCheckRun(jobId, successPayload),
          ).thenAnswer((_) => Future.error(exception, stackTrace));

          try {
            await complete(BuildJobStatus.SUCCESS);
            fail('Expected check completion to fail');
          } on StateError catch (error, actualStackTrace) {
            expect(
              error.message,
              'Failed to complete GitHub check run: ${exception.runtimeType}.',
            );
            expect(actualStackTrace.toString(), stackTrace.toString());
          }

          verify(() => api.updateCheckRun(jobId, successPayload)).called(1);
          verifyNoMoreInteractions(api);
        },
      );
    }

    test('redacts synchronous API failures', () async {
      when(
        () => api.updateCheckRun(jobId, successPayload),
      ).thenThrow(StateError('Request failed: $secret'));

      await expectLater(
        complete(BuildJobStatus.SUCCESS),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Failed to complete GitHub check run: StateError.',
          ),
        ),
      );

      verify(() => api.updateCheckRun(jobId, successPayload)).called(1);
      verifyNoMoreInteractions(api);
    });
  });
}
