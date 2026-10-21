import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/billing/billing_proxy.dart';
import 'package:openci_server/billing/billing_proxy_config.dart';
import 'package:test/test.dart';

import 'billing_proxy_test.dart' show billingProxyEnvironment;

void main() {
  test('worker transport uses only the fixed path and service token', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/internal/billing/worker/claim');
      expect(request.method, 'POST');
      expect(request.followRedirects, isFalse);
      expect(request.headers['x-genuineci-user-id'], isNull);
      expect(
        request.headers['authorization'],
        'Bearer ${billingProxyEnvironment()['BILLING_INTERNAL_TOKEN']}',
      );
      expect(jsonDecode(request.body), {'workerHost': 'worker-1'});
      return http.Response(
        jsonEncode({
          'claim': {
            'jobId': 'job-1',
            'admissionId': 'admission-1',
            'private': 'hidden',
          },
        }),
        200,
      );
    });
    addTearDown(client.close);
    final proxy = BillingProxy(
      BillingProxyConfig.fromEnvironment(billingProxyEnvironment())!,
      client,
    );
    final response = await proxy.workerRequest(
      operation: WorkerBillingOperation.claim,
      payload: {'workerHost': 'worker-1'},
    );
    expect(response.statusCode, 200);
    expect(response.headers['cache-control'], 'no-store');
    expect(await response.json(), {
      'claim': {'jobId': 'job-1', 'admissionId': 'admission-1'},
    });
  });

  for (final operation in WorkerBillingOperation.values) {
    test('$operation validates success and sanitizes errors', () async {
      final success = operation == WorkerBillingOperation.claim
          ? {'claim': null}
          : {'active': false, 'measurementIncomplete': true};
      for (final (status, body, expected) in <(int, Object, int)>[
        (200, {...success, 'private': 'hidden'}, 200),
        (200, {'active': 'true'}, 503),
        (
          200,
          {
            'claim': {'jobId': '', 'admissionId': 'a'},
          },
          503,
        ),
        (200, 'x' * 65537, 503),
        (302, {'error': 'private-token'}, 503),
        (500, {'error': 'private-token'}, 503),
        (409, {'error': 'admission_not_current', 'private': 'hidden'}, 409),
      ]) {
        final client = MockClient(
          (_) async => http.Response(jsonEncode(body), status),
        );
        addTearDown(client.close);
        final proxy = BillingProxy(
          BillingProxyConfig.fromEnvironment(billingProxyEnvironment())!,
          client,
        );
        final response = await proxy.workerRequest(
          operation: operation,
          payload: {},
        );
        expect(response.statusCode, expected);
        final result = await response.json();
        expect(result, isNot(contains('private')));
        if (expected == 200) expect(result, success);
        if (expected == 503) expect(result, {'error': 'billing_unavailable'});
      }
    });
  }
}
