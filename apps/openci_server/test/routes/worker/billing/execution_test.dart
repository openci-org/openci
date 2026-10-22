import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/billing/billing_proxy.dart';
import 'package:openci_server/billing/billing_proxy_config.dart';
import 'package:test/test.dart';

import '../../../../routes/worker/_middleware.dart' as worker;
import '../../../../routes/worker/billing/report.dart' as report;
import '../../../../routes/worker/billing/start.dart' as start;

void main() {
  const identity = {
    'admissionId': 'admission-1',
    'jobId': 'job-1',
    'runId': 'run-1',
    'workerHost': 'worker-1',
  };
  for (final (name, route) in [
    ('start', start.onRequest),
    ('report', report.onRequest),
  ]) {
    test('$name authenticates and validates lifecycle requests', () async {
      final forwarded = <http.Request>[];
      final upstream = MockClient((request) async {
        forwarded.add(request);
        return http.Response(
          '{"active":true,"measurementIncomplete":false,"private":"hidden"}',
          200,
        );
      });
      addTearDown(upstream.close);
      final proxy = BillingProxy(
        BillingProxyConfig.fromEnvironment(const {
          'SERVER_ACCESS_MODE': 'cloud',
          'BILLING_ENABLED': 'true',
          'GENUINECI_SERVER_URL': 'http://genuineci-server:8081',
          'BILLING_INTERNAL_TOKEN': '01234567890123456789012345678901',
        })!,
        upstream,
      );
      final handler = worker
          .middleware(
            (context) => route(context.provide<BillingProxy?>(() => proxy)),
          )
          .use(
            provider<InternalApiKeyValidator>(
              (_) => const InternalApiKeyValidator(
                environment: {'INTERNAL_API_KEY': 'worker-key'},
              ),
            ),
          );
      final server = await serve(handler, InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final uri = Uri.parse(
        'http://127.0.0.1:${server.port}/worker/billing/$name',
      );
      final client = http.Client();
      addTearDown(client.close);

      for (final token in ['', 'firebase-user-token']) {
        final response = await client.post(
          uri,
          body: jsonEncode(identity),
          headers: {'authorization': 'Bearer $token'},
        );
        expect(response.statusCode, 401);
      }
      expect(forwarded, isEmpty);
      const headers = {'authorization': 'Bearer worker-key'};
      expect((await client.get(uri, headers: headers)).statusCode, 405);
      for (final body in <Object>[
        {},
        {...identity, 'runId': ''},
        {...identity, 'startedAt': 'client-time'},
        {...identity, 'teamId': 'other-team'},
        {...identity, 'outcome': 'unknown'},
      ]) {
        expect(
          (await client.post(
            uri,
            headers: headers,
            body: jsonEncode(body),
          )).statusCode,
          400,
        );
      }
      expect(
        (await client.post(uri, headers: headers, body: 'x' * 4097)).statusCode,
        413,
      );
      expect(forwarded, isEmpty);
      final response = await client.post(
        uri,
        headers: headers,
        body: jsonEncode(identity),
      );
      expect(response.statusCode, 200);
      expect(jsonDecode(response.body), {
        'active': true,
        'measurementIncomplete': false,
      });
      expect(forwarded.single.url.path, '/internal/billing/worker/$name');
      expect(jsonDecode(forwarded.single.body), identity);
    });

    test('$name is unavailable with billing disabled', () async {
      final handler = worker
          .middleware(
            (context) => route(context.provide<BillingProxy?>(() => null)),
          )
          .use(
            provider<InternalApiKeyValidator>(
              (_) => const InternalApiKeyValidator(
                environment: {'INTERNAL_API_KEY': 'worker-key'},
              ),
            ),
          );
      final server = await serve(handler, InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final response = await http.post(
        Uri.parse('http://127.0.0.1:${server.port}/worker/billing/$name'),
        headers: {'authorization': 'Bearer worker-key'},
        body: jsonEncode(identity),
      );
      expect(response.statusCode, 404);
    });
  }
}
