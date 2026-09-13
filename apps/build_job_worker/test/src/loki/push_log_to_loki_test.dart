import 'dart:convert';

import 'package:build_job_worker/build_job_worker.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

class _MockHttpClient extends Mock implements http.Client {}

void main() {
  group('pushLogToLoki', () {
    test(
      'sends one UTF-8 log with the existing labels and timestamp',
      () async {
        late http.Request request;
        final client = MockClient((incoming) async {
          request = incoming;
          return http.Response('', 204);
        });
        addTearDown(client.close);
        final before = DateTime.now().microsecondsSinceEpoch * 1000;
        const message = 'ビルド開始 🚀 "quoted"\nnext line';

        await pushLogToLoki(
          client: client,
          lokiUrl: 'http://loki:3100/',
          runId: 'run-1',
          jobId: 'job-1',
          message: message,
        );

        final after = DateTime.now().microsecondsSinceEpoch * 1000;
        expect(request.method, 'POST');
        expect(request.url.toString(), 'http://loki:3100/loki/api/v1/push');
        expect(
          request.headers['content-type'],
          'application/json; charset=utf-8',
        );
        final payload =
            jsonDecode(utf8.decode(request.bodyBytes)) as Map<String, dynamic>;
        final streams = payload['streams'] as List<dynamic>;
        expect(streams, hasLength(1));
        final entry = streams.single as Map<String, dynamic>;
        expect(entry['stream'], {
          'stream': 'stdout',
          'type': 'step_log',
          'run_id': 'run-1',
          'build_job_id': 'job-1',
        });
        final values = entry['values'] as List<dynamic>;
        expect(values, hasLength(1));
        final value = values.single as List<dynamic>;
        expect(value, hasLength(2));
        expect(value[0], isA<String>());
        expect(int.parse(value[0] as String), inInclusiveRange(before, after));
        expect(value[1], message);
      },
    );

    test('preserves a URL prefix and optional labels', () async {
      late http.Request request;
      final client = MockClient((incoming) async {
        request = incoming;
        return http.Response('', 204);
      });
      addTearDown(client.close);

      await pushLogToLoki(
        client: client,
        lokiUrl: 'https://logs.example.com/proxy/',
        runId: 'run-1',
        jobId: 'job-1',
        message: 'checkout failed',
        stream: 'stderr',
        type: 'step_event',
        stepId: 'checkout',
        command: 'git checkout',
      );

      expect(request.url.path, '/proxy/loki/api/v1/push');
      final payload = jsonDecode(request.body) as Map<String, dynamic>;
      final entry =
          (payload['streams'] as List<dynamic>).single as Map<String, dynamic>;
      expect(entry['stream'], {
        'stream': 'stderr',
        'type': 'step_event',
        'run_id': 'run-1',
        'build_job_id': 'job-1',
        'step_id': 'checkout',
        'command': 'git checkout',
      });
    });

    for (final status in [200, 260, 400, 429, 500]) {
      test('reports HTTP $status instead of accepting the log', () async {
        final client = MockClient(
          (_) async => http.Response('rejected', status),
        );
        addTearDown(client.close);

        await expectLater(
          pushLogToLoki(
            client: client,
            lokiUrl: 'http://loki:3100',
            runId: 'run-1',
            jobId: 'job-1',
            message: 'build output',
          ),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('HTTP $status'),
            ),
          ),
        );
      });
    }

    test('propagates transport errors', () async {
      final error = http.ClientException('Connection refused');
      final client = MockClient((_) async => throw error);
      addTearDown(client.close);

      await expectLater(
        pushLogToLoki(
          client: client,
          lokiUrl: 'http://loki:3100',
          runId: 'run-1',
          jobId: 'job-1',
          message: 'build output',
        ),
        throwsA(same(error)),
      );
    });

    test(
      'leaves the shared HTTP client open after success and failure',
      () async {
        final client = _MockHttpClient();
        final uri = Uri.parse('http://loki:3100/loki/api/v1/push');
        for (final status in [204, 500]) {
          when(
            () => client.post(
              uri,
              headers: any(named: 'headers'),
              body: any(named: 'body'),
            ),
          ).thenAnswer((_) async => http.Response('', status));

          final result = pushLogToLoki(
            client: client,
            lokiUrl: 'http://loki:3100',
            runId: 'run-1',
            jobId: 'job-1',
            message: 'build output',
          );
          if (status == 204) {
            await result;
          } else {
            await expectLater(result, throwsStateError);
          }
        }

        verifyNever(client.close);
      },
    );
  });
}
