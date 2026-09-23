import 'dart:async';
import 'dart:convert';

import 'package:genuineci_cli/src/secrets/fetch_secret_names.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  final responseBody = <String, dynamic>{
    'success': true,
    'secrets': [
      {
        'name': 'ASC_KEY',
        'teamId': 'test-team',
        'encryptedValue': '[REDACTED]',
        'createdAt': '2026-09-09T00:00:00.000Z',
        'updatedAt': '2026-09-09T00:00:00.000Z',
      },
      {'name': 'FIREBASE_OPTIONS'},
    ],
  };

  group('parseSecretNamesResponse', () {
    test('extracts only names from secret metadata', () {
      expect(parseSecretNamesResponse(responseBody), [
        'ASC_KEY',
        'FIREBASE_OPTIONS',
      ]);
    });

    test('accepts an empty list of secrets', () {
      expect(
        parseSecretNamesResponse({'success': true, 'secrets': []}),
        isEmpty,
      );
    });

    test('preserves names, order and duplicates for the generator', () {
      final body = <String, dynamic>{
        'success': true,
        'secrets': [
          {'name': 'ZULU'},
          {'name': 'ascKey'},
          {'name': 'ASC_KEY'},
          {'name': 'ZULU'},
          {'name': 'MY-KEY'},
        ],
      };

      expect(parseSecretNamesResponse(body), [
        'ZULU',
        'ascKey',
        'ASC_KEY',
        'ZULU',
        'MY-KEY',
      ]);
    });

    for (final (label, body) in <(String, Map<String, dynamic>?)>[
      ('null response', null),
      ('missing success', {'secrets': []}),
      ('failed response', {'success': false, 'secrets': []}),
      ('non-boolean success', {'success': 'true', 'secrets': []}),
      ('missing secrets', {'success': true}),
      ('null secrets', {'success': true, 'secrets': null}),
      ('non-list secrets', {'success': true, 'secrets': {}}),
      (
        'null entry',
        {
          'success': true,
          'secrets': [null],
        },
      ),
      (
        'missing name',
        {
          'success': true,
          'secrets': [{}],
        },
      ),
      (
        'null name',
        {
          'success': true,
          'secrets': [
            {'name': null},
          ],
        },
      ),
      (
        'non-string name',
        {
          'success': true,
          'secrets': [
            {'name': 42},
          ],
        },
      ),
      (
        'valid entry followed by an invalid entry',
        {
          'success': true,
          'secrets': [
            {'name': 'ASC_KEY'},
            {'name': 42},
          ],
        },
      ),
    ]) {
      test('rejects $label without exposing the response body', () {
        expect(
          () => parseSecretNamesResponse(body),
          throwsA(
            isA<FormatException>()
                .having(
                  (error) => error.message,
                  'message',
                  'Invalid secrets response',
                )
                .having((error) => error.source, 'source', isNull),
          ),
        );
      });
    }
  });

  group('fetchSecretNames', () {
    OpenCIApiService createApi(MockClientHandler handler) {
      final httpClient = MockClient(handler);
      final client = http.runWithClient(
        () => createOpenCIChopperClient(
          baseUrl: 'http://localhost:8080',
          tokenProvider: () => 'local-test-token',
          services: [OpenCIApiService.create()],
        ),
        () => httpClient,
      );
      addTearDown(client.dispose);
      return client.getService<OpenCIApiService>();
    }

    test('fetches names through the shared authenticated API', () async {
      final requests = <http.Request>[];
      final api = createApi((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode(responseBody),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final names = await fetchSecretNames(api, 'test-team');

      expect(names, ['ASC_KEY', 'FIREBASE_OPTIONS']);
      final request = requests.single;
      expect(request.method, 'GET');
      expect(
        request.url,
        Uri.parse('http://localhost:8080/teams/test-team/secrets'),
      );
      expect(request.headers['Authorization'], 'Bearer local-test-token');
      expect(request.body, isEmpty);
    });

    test('encodes the team as one path segment', () async {
      final requests = <http.Request>[];
      final api = createApi((request) async {
        requests.add(request);
        return http.Response(
          '{"success":true,"secrets":[]}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      expect(await fetchSecretNames(api, 'team/with space?#'), isEmpty);
      expect(
        requests.single.url,
        Uri.parse(
          'http://localhost:8080/teams/team%2Fwith%20space%3F%23/secrets',
        ),
      );
    });

    test(
      'leaves the caller-owned API usable for subsequent requests',
      () async {
        var requests = 0;
        final api = createApi((_) async {
          requests++;
          return http.Response(
            jsonEncode(responseBody),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        expect(await fetchSecretNames(api, 'test-team'), [
          'ASC_KEY',
          'FIREBASE_OPTIONS',
        ]);
        expect(await fetchSecretNames(api, 'test-team'), [
          'ASC_KEY',
          'FIREBASE_OPTIONS',
        ]);
        expect(requests, 2);
      },
    );

    for (final status in [401, 403, 404, 429, 500, 302]) {
      test('reports HTTP $status without exposing the response body', () async {
        final api = createApi(
          (_) async => http.Response('unexpected-private-response', status),
        );

        await expectLater(
          fetchSecretNames(api, 'test-team'),
          throwsA(
            isA<SecretNamesHttpException>()
                .having((error) => error.statusCode, 'statusCode', status)
                .having(
                  (error) => error.toString(),
                  'message',
                  'Failed to fetch secret names (HTTP $status).',
                ),
          ),
        );
      });
    }

    for (final (label, body) in [
      ('null body', 'null'),
      ('invalid metadata', '{"success":true,"secrets":[{"name":42}]}'),
    ]) {
      test('rejects $label returned by the shared API', () async {
        final api = createApi(
          (_) async => http.Response(
            body,
            200,
            headers: {'content-type': 'application/json'},
          ),
        );

        await expectLater(
          fetchSecretNames(api, 'test-team'),
          throwsFormatException,
        );
      });
    }

    for (final (label, error) in [
      ('network failures', http.ClientException('Connection failed')),
      ('timeouts', TimeoutException('Request timed out')),
    ]) {
      test('propagates $label from the shared API', () async {
        final api = createApi((_) async => throw error);

        await expectLater(
          fetchSecretNames(api, 'test-team'),
          throwsA(same(error)),
        );
      });
    }
  });
}
