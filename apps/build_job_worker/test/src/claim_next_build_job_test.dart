import 'package:build_job_worker/build_job_worker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:openci_shared/test_helpers.dart';
import 'package:test/test.dart';

class _MockOpenCiApiService extends Mock implements OpenCiApiService {}

void main() {
  late OpenCiApiService api;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    api = _MockOpenCiApiService();
  });

  group('claimNextBuildJob', () {
    test('returns a BuildJob when a queued job is claimed', () async {
      final now = DateTime.utc(2026, 9, 5);
      final jobData = {
        'id': 'job-123',
        'status': 'IN_PROGRESS',
        'owner': 'openci-org',
        'repo': 'openci',
        'workflowName': 'CI',
        'workflowFileName': 'ci.dart',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };
      when(
        () => api.claimNextJob(any()),
      ).thenAnswer((_) async => createMockResponse({'job': jobData}));

      final job = await claimNextBuildJob(api);

      expect(job, isNotNull);
      expect(job!.id, 'job-123');
      expect(job.status, BuildJobStatus.IN_PROGRESS);
      expect(job.workflowFileName, 'ci.dart');
      final requestBody =
          verify(() => api.claimNextJob(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(requestBody, isEmpty);
    });

    test('returns null when no queued job exists', () async {
      when(
        () => api.claimNextJob(any()),
      ).thenAnswer((_) async => createMockResponse({'job': null}));

      final job = await claimNextBuildJob(api);

      expect(job, isNull);
    });

    test('throws StateError when the API request fails', () async {
      when(() => api.claimNextJob(any())).thenAnswer(
        (_) async => createMockResponse({
          'error': 'Service unavailable',
        }, statusCode: 503),
      );

      await expectLater(
        claimNextBuildJob(api),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Failed to claim build job: HTTP 503'),
          ),
        ),
      );
    });

    test('throws StateError when job is missing from the response', () async {
      when(
        () => api.claimNextJob(any()),
      ).thenAnswer((_) async => createMockResponse(<String, dynamic>{}));

      await expectLater(
        claimNextBuildJob(api),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Invalid claim response: missing "job".',
          ),
        ),
      );
    });

    test('throws StateError when job is not an object', () async {
      when(
        () => api.claimNextJob(any()),
      ).thenAnswer((_) async => createMockResponse({'job': 'job-123'}));

      await expectLater(
        claimNextBuildJob(api),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Invalid claim response: "job" must be an object or null.',
          ),
        ),
      );
    });
  });
}
