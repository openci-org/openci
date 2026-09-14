import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('LokiApiService.push', () {
    for (final (baseUrl, endpoint) in [
      (
        'https://loki.example.com',
        'https://loki.example.com/loki/api/v1/push',
      ),
      (
        'https://loki.example.com/proxy/',
        'https://loki.example.com/proxy/loki/api/v1/push',
      ),
    ]) {
      test('posts Loki JSON and accepts HTTP 204 with base $baseUrl', () async {
        const body = {
          'streams': [
            {
              'stream': {'type': 'step_log', 'run_id': 'run-1'},
              'values': [
                ['1000000000', 'ビルド開始 🚀\nnext line'],
                ['1000000001', ''],
              ],
            },
          ],
        };
        final httpClient = MockClient((request) async {
          expect(request.method, 'POST');
          expect(request.url.toString(), endpoint);
          expect(
            request.headers['content-type'],
            'application/json; charset=utf-8',
          );
          expect(jsonDecode(utf8.decode(request.bodyBytes)), body);
          return http.Response('', 204);
        });
        addTearDown(httpClient.close);
        final client = ChopperClient(
          baseUrl: Uri.parse(baseUrl),
          client: httpClient,
          converter: const JsonConverter(),
          services: [LokiApiService.create()],
        );
        addTearDown(client.dispose);

        final response = await client.getService<LokiApiService>().push(body);

        expect(response.statusCode, 204);
      });
    }
  });

  group('LokiApiService.queryRange', () {
    test('encodes query parameters and decodes the Loki response', () async {
      const query = '{run_id="run-1"} |= "確認中 & build+test"';
      const start = '1720000000000000123';
      const body = {
        'status': 'success',
        'data': {
          'resultType': 'streams',
          'result': [
            {
              'stream': {'type': 'step_log', 'run_id': 'run-1'},
              'values': [
                [start, '確認中 🚀'],
              ],
            },
          ],
        },
      };
      final httpClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.origin, 'https://loki.example.com');
        expect(request.url.path, '/proxy/loki/api/v1/query_range');
        expect(request.url.queryParameters, {
          'query': query,
          'start': start,
          'limit': '42',
          'direction': 'FORWARD',
        });
        return http.Response(
          jsonEncode(body),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      addTearDown(httpClient.close);
      final client = ChopperClient(
        baseUrl: Uri.parse('https://loki.example.com/proxy/'),
        client: httpClient,
        converter: const JsonConverter(),
        services: [LokiApiService.create()],
      );
      addTearDown(client.dispose);

      final response = await client.getService<LokiApiService>().queryRange(
        query: query,
        start: start,
        limit: 42,
        direction: 'FORWARD',
      );

      expect(response.statusCode, 200);
      expect(response.body, body);
    });
  });
}
