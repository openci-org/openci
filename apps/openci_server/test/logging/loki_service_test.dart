import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/logging/loki_service.dart';
import 'package:test/test.dart';

void main() {
  LokiService createService(MockClient client) {
    addTearDown(client.close);
    return LokiService(lokiUrl: 'http://loki.test:3100', client: client);
  }

  group('getLogsForRun', () {
    for (final stepId in [null, '', 'step-1']) {
      test('queries the run with stepId=$stepId and a custom limit', () async {
        final earliestStart = DateTime.now().toUtc().subtract(
          const Duration(days: 7),
        );
        late http.Request request;
        final service = createService(
          MockClient((value) async {
            request = value;
            return _queryResponse([]);
          }),
        );

        expect(
          await service.getLogsForRun(
            runId: 'run-1',
            stepId: stepId,
            limit: 42,
          ),
          isEmpty,
        );
        expect(request.method, 'GET');
        expect(request.url.origin, 'http://loki.test:3100');
        expect(request.url.path, '/loki/api/v1/query_range');
        expect(
          request.url.queryParameters['query'],
          stepId == 'step-1'
              ? '{run_id="run-1", step_id="step-1", type!="step_event"}'
              : '{run_id="run-1", type!="step_event"}',
        );
        expect(request.url.queryParameters['limit'], '42');
        expect(request.url.queryParameters['direction'], 'FORWARD');
        final start = BigInt.parse(request.url.queryParameters['start']!);
        expect(
          start,
          greaterThanOrEqualTo(
            BigInt.from(earliestStart.microsecondsSinceEpoch) *
                BigInt.from(1000),
          ),
        );
        expect(
          start,
          lessThanOrEqualTo(
            BigInt.from(
                  DateTime.now()
                      .toUtc()
                      .subtract(const Duration(days: 7))
                      .microsecondsSinceEpoch,
                ) *
                BigInt.from(1000),
          ),
        );
      });
    }

    test('merges streams chronologically and excludes step events', () async {
      late http.Request request;
      final service = createService(
        MockClient((value) async {
          request = value;
          return _queryResponse([
            {
              'values': [
                ['30', 'third'],
                ['10', 'first'],
                ['11', ' {"runId":"run-1"}'],
                ['12', '{"status":"SUCCESS"}'],
              ],
            },
            {
              'values': [
                ['20', '{"message":"second"}'],
              ],
            },
          ]);
        }),
      );

      expect(await service.getLogsForRun(runId: 'run-1'), [
        'first',
        '{"message":"second"}',
        'third',
      ]);
      expect(request.url.queryParameters['limit'], '5000');
    });

    test(
      'ignores malformed entries while retaining usable log lines',
      () async {
        final service = createService(
          MockClient(
            (_) async => _queryResponse([
              null,
              {},
              {
                'values': [
                  null,
                  [],
                  ['10'],
                  ['not-a-timestamp', 'fallback timestamp'],
                  [20, 123],
                ],
              },
            ]),
          ),
        );

        expect(await service.getLogsForRun(runId: 'run-1'), [
          'fallback timestamp',
          '123',
        ]);
      },
    );
  });

  group('getStepSummariesForRun', () {
    test('keeps the latest event per step and orders steps', () async {
      late http.Request request;
      final service = createService(
        MockClient((value) async {
          request = value;
          return _queryResponse([
            null,
            {},
            {
              'values': [
                [],
                ['0', 'invalid json'],
                ['1', '{"id":""}'],
                ['2', '{}'],
                ['3', '{"id":"build","stepOrder":2,"status":"running"}'],
                ['4', '{"id":"setup","stepOrder":1,"status":"RUNNING"}'],
                ['5', '{"id":"build","stepOrder":2,"status":"SUCCESS"}'],
                ['6', '{"id":"prepare"}'],
              ],
            },
          ]);
        }),
      );

      expect(await service.getStepSummariesForRun(runId: 'run-1'), [
        {'id': 'prepare'},
        {'id': 'setup', 'stepOrder': 1, 'status': 'IN_PROGRESS'},
        {'id': 'build', 'stepOrder': 2, 'status': 'SUCCESS'},
      ]);
      expect(
        request.url.queryParameters['query'],
        '{run_id="run-1", type="step_event"}',
      );
      expect(request.url.queryParameters['limit'], '1000');
      expect(request.url.queryParameters['direction'], 'FORWARD');
      expect(
        BigInt.parse(request.url.queryParameters['start']!),
        greaterThan(BigInt.zero),
      );
    });
  });

  final queries = <String, Future<List<Object?>> Function(LokiService)>{
    'logs': (service) => service.getLogsForRun(runId: 'run-1'),
    'steps': (service) => service.getStepSummariesForRun(runId: 'run-1'),
  };
  for (final query in queries.entries) {
    group('${query.key} query failures', () {
      final responses = {
        'HTTP failure': http.Response('unavailable', 503),
        'Loki failure': http.Response('{"status":"error"}', 200),
        'missing data': http.Response('{"status":"success"}', 200),
        'missing results': http.Response('{"status":"success","data":{}}', 200),
        'empty results': _queryResponse([]),
        'invalid JSON': http.Response('invalid json', 200),
      };
      for (final response in responses.entries) {
        test('returns no entries for ${response.key}', () async {
          final service = createService(
            MockClient((_) async => response.value),
          );

          expect(await query.value(service), isEmpty);
        });
      }

      test('returns no entries when the HTTP request fails', () async {
        final service = createService(
          MockClient((_) async => throw TimeoutException('Loki unavailable')),
        );

        expect(await query.value(service), isEmpty);
      });
    });
  }

  group('parseTailFrame', () {
    test('preserves stream labels and converts messages to strings', () {
      final entries = LokiService.parseTailFrame(
        jsonEncode({
          'streams': [
            null,
            {
              'stream': {'run_id': 'run-1'},
            },
            {
              'stream': {'run_id': 'run-1', 'attempt': 2},
              'values': [
                [],
                ['1'],
                ['2', 'hello'],
                ['3', 42],
              ],
            },
            {
              'values': [
                ['4', 'without labels'],
              ],
            },
          ],
        }),
      );

      expect(entries.map((entry) => entry.value), [
        'hello',
        '42',
        'without labels',
      ]);
      expect(entries[0].key, {'run_id': 'run-1', 'attempt': '2'});
      expect(entries[1].key, entries[0].key);
      expect(entries[2].key, isEmpty);
    });

    for (final frame in ['invalid json', '[]', '{}', '{"streams":[]}']) {
      test('ignores invalid or empty frame: $frame', () {
        expect(LokiService.parseTailFrame(frame), isEmpty);
      });
    }
  });
}

http.Response _queryResponse(List<Object?> streams) => http.Response(
  jsonEncode({
    'status': 'success',
    'data': {'result': streams},
  }),
  200,
);
