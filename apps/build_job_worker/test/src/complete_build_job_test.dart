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
  final finishedAt = DateTime.utc(2026, 9, 8, 12, 34, 56, 789, 123);
  const finishedAtIso = '2026-09-08T12:34:56.789123Z';
  const successPayload = {'status': 'SUCCESS', 'completedAt': finishedAtIso};

  setUp(() {
    api = _MockOpenCIApiService();
  });

  Future<void> complete(BuildJobStatus status, {DateTime? completedAt}) =>
      completeBuildJob(
        api: api,
        jobId: jobId,
        status: status,
        completedAt: completedAt ?? finishedAt,
      );

  group('completeBuildJob', () {
    for (final entry in const {
      BuildJobStatus.SUCCESS: 'SUCCESS',
      BuildJobStatus.FAILURE: 'FAILURE',
      BuildJobStatus.CANCELLED: 'CANCELLED',
      BuildJobStatus.SKIPPED: 'SKIPPED',
      BuildJobStatus.TIMED_OUT: 'TIMED_OUT',
    }.entries) {
      test(
        'completes the specified job with ${entry.value} and its end time',
        () async {
          final payload = {'status': entry.value, 'completedAt': finishedAtIso};
          when(
            () => api.completeJob(jobId, payload),
          ).thenAnswer((_) async => createMockResponse<void>(null));

          await complete(entry.key);

          verify(() => api.completeJob(jobId, payload)).called(1);
          verifyNoMoreInteractions(api);
        },
      );
    }

    test('converts a local end time to UTC without losing precision', () async {
      final localTime = finishedAt.toLocal();
      expect(localTime.isUtc, isFalse);
      when(
        () => api.completeJob(jobId, successPayload),
      ).thenAnswer((_) async => createMockResponse<void>(null));

      await complete(BuildJobStatus.SUCCESS, completedAt: localTime);

      verify(() => api.completeJob(jobId, successPayload)).called(1);
      verifyNoMoreInteractions(api);
    });

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
          when(() => api.completeJob(jobId, successPayload)).thenAnswer(
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
                'Failed to complete build job: HTTP $statusCode.',
              ),
            ),
          );

          verify(() => api.completeJob(jobId, successPayload)).called(1);
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
            'Job completion failed here',
          );
          when(
            () => api.completeJob(jobId, successPayload),
          ).thenAnswer((_) => Future.error(exception, stackTrace));

          try {
            await complete(BuildJobStatus.SUCCESS);
            fail('Expected job completion to fail');
          } on StateError catch (error, actualStackTrace) {
            expect(
              error.message,
              'Failed to complete build job: ${exception.runtimeType}.',
            );
            expect(actualStackTrace.toString(), stackTrace.toString());
          }

          verify(() => api.completeJob(jobId, successPayload)).called(1);
          verifyNoMoreInteractions(api);
        },
      );
    }

    test('redacts synchronous API failures', () async {
      when(
        () => api.completeJob(jobId, successPayload),
      ).thenThrow(StateError('Request failed: $secret'));

      await expectLater(
        complete(BuildJobStatus.SUCCESS),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Failed to complete build job: StateError.',
          ),
        ),
      );

      verify(() => api.completeJob(jobId, successPayload)).called(1);
      verifyNoMoreInteractions(api);
    });
  });
}
