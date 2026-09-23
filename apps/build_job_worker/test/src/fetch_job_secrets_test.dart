import 'dart:async';

import 'package:build_job_worker/build_job_worker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:openci_shared/test_helpers.dart';
import 'package:test/test.dart';

class _MockOpenCIApiService extends Mock implements OpenCIApiService {}

void main() {
  late OpenCIApiService api;
  const jobId = 'job-123';
  const secret = 'test-only-secret';
  const secretsContent =
      'TOKEN=$secret\r\n'
      r'''SPECIAL=  日本語 ' " $HOME $(command) = \n  '''
      '\n';

  setUp(() {
    api = _MockOpenCIApiService();
  });

  Future<String> fetch() => fetchJobSecrets(api: api, jobId: jobId);

  group('fetchJobSecrets', () {
    test('returns secrets verbatim for the requested job', () async {
      when(() => api.getJobSecrets(jobId)).thenAnswer(
        (_) async => createMockResponse(<String, dynamic>{
          'success': true,
          'secretsContent': secretsContent,
        }),
      );

      expect(await fetch(), secretsContent);

      verify(() => api.getJobSecrets(jobId)).called(1);
      verifyNoMoreInteractions(api);
    });

    test('accepts an empty secrets string', () async {
      when(() => api.getJobSecrets(jobId)).thenAnswer(
        (_) async => createMockResponse(<String, dynamic>{
          'success': true,
          'secretsContent': '',
        }),
      );

      expect(await fetch(), isEmpty);
    });

    test('reports HTTP failure without response body or error', () async {
      when(() => api.getJobSecrets(jobId)).thenAnswer(
        (_) async => createMockResponse(<String, dynamic>{
          'success': true,
          'secretsContent': secretsContent,
        }, statusCode: 503).copyWith<Map<String, dynamic>>(bodyError: secret),
      );

      await expectLater(
        fetch(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Failed to fetch job secrets: HTTP 503.',
          ),
        ),
      );
    });

    for (final testCase in <String, Map<String, dynamic>?>{
      'a missing body': null,
      'a missing success flag': {'secretsContent': secretsContent},
      'a failure result': {'success': false, 'secretsContent': secretsContent},
      'a non-boolean success flag': {
        'success': 'true',
        'secretsContent': secretsContent,
      },
      'missing secretsContent': {'success': true},
      'null secretsContent': {'success': true, 'secretsContent': null},
      'numeric secretsContent': {'success': true, 'secretsContent': 123},
      'object secretsContent': {
        'success': true,
        'secretsContent': {'value': secret},
      },
      'list secretsContent': {
        'success': true,
        'secretsContent': [secret],
      },
    }.entries) {
      test('rejects ${testCase.key} without response content', () async {
        when(() => api.getJobSecrets(jobId)).thenAnswer(
          (_) async => createMockResponse<Map<String, dynamic>?>(
            testCase.value,
          ).copyWith<Map<String, dynamic>>(),
        );

        await expectLater(
          fetch(),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Invalid job secrets response: '
                  '"success" must be true and "secretsContent" must be a string.',
            ),
          ),
        );
      });
    }

    for (final exception in [
      Exception('Connection failed: $secret'),
      const FormatException('Invalid JSON', secretsContent),
      TimeoutException('Request timed out: $secret'),
    ]) {
      test(
        'redacts ${exception.runtimeType} and preserves its stack',
        () async {
          final stackTrace = StackTrace.fromString(
            'Secrets request failed here',
          );
          when(
            () => api.getJobSecrets(jobId),
          ).thenAnswer((_) => Future.error(exception, stackTrace));

          try {
            await fetch();
            fail('Expected secrets retrieval to fail');
          } on StateError catch (error, actualStackTrace) {
            expect(
              error.message,
              'Failed to fetch job secrets: ${exception.runtimeType}.',
            );
            expect(actualStackTrace.toString(), stackTrace.toString());
          }
        },
      );
    }

    test('redacts synchronous API failures', () async {
      when(
        () => api.getJobSecrets(jobId),
      ).thenThrow(StateError('Request failed: $secret'));

      await expectLater(
        fetch(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Failed to fetch job secrets: StateError.',
          ),
        ),
      );
    });
  });
}
