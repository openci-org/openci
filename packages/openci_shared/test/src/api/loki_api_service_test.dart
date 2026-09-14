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
}
