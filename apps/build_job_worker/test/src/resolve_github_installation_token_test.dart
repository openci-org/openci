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
  const token = 'test-only-installation-token';

  setUp(() {
    api = _MockOpenCIApiService();
  });

  Future<String> resolve() =>
      resolveGitHubInstallationToken(api: api, jobId: jobId);

  group('resolveGitHubInstallationToken', () {
    test('returns the token for the requested job', () async {
      when(() => api.resolveInstallationToken(jobId)).thenAnswer(
        (_) async => createMockResponse(<String, dynamic>{'token': token}),
      );

      expect(await resolve(), token);

      verify(() => api.resolveInstallationToken(jobId)).called(1);
      verifyNoMoreInteractions(api);
    });

    test('reports HTTP failure without response body or error', () async {
      when(() => api.resolveInstallationToken(jobId)).thenAnswer(
        (_) async => createMockResponse(<String, dynamic>{
          'token': token,
        }, statusCode: 503).copyWith<Map<String, dynamic>>(bodyError: token),
      );

      await expectLater(
        resolve(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Failed to resolve GitHub installation token: HTTP 503.',
          ),
        ),
      );
    });

    for (final testCase in <String, Map<String, dynamic>?>{
      'a missing body': null,
      'a missing token': {},
      'a null token': {'token': null},
      'an empty token': {'token': ''},
      'a numeric token': {'token': 123},
      'an object token': {
        'token': {'value': token},
      },
      'a list token': {
        'token': [token],
      },
    }.entries) {
      test('rejects ${testCase.key} without response content', () async {
        when(() => api.resolveInstallationToken(jobId)).thenAnswer(
          (_) async => createMockResponse<Map<String, dynamic>?>(
            testCase.value,
          ).copyWith<Map<String, dynamic>>(),
        );

        await expectLater(
          resolve(),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Invalid GitHub installation token response: '
                  '"token" must be a non-empty string.',
            ),
          ),
        );
      });
    }

    for (final exception in [
      Exception('Connection failed: $token'),
      const FormatException('Invalid JSON', token),
      TimeoutException('Request timed out: $token'),
    ]) {
      test(
        'redacts ${exception.runtimeType} and preserves its stack',
        () async {
          final stackTrace = StackTrace.fromString('Token request failed here');
          when(
            () => api.resolveInstallationToken(jobId),
          ).thenAnswer((_) => Future.error(exception, stackTrace));

          try {
            await resolve();
            fail('Expected token resolution to fail');
          } on StateError catch (error, actualStackTrace) {
            expect(
              error.message,
              'Failed to resolve GitHub installation token: '
              '${exception.runtimeType}.',
            );
            expect(actualStackTrace.toString(), stackTrace.toString());
          }
        },
      );
    }

    test('redacts synchronous API failures', () async {
      when(
        () => api.resolveInstallationToken(jobId),
      ).thenThrow(StateError('Request failed: $token'));

      await expectLater(
        resolve(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Failed to resolve GitHub installation token: StateError.',
          ),
        ),
      );
    });
  });
}
