import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  late ChopperClient client;
  late OpenCIApiService api;
  late List<http.Request> requests;
  late Object body;
  late int status;

  setUp(() {
    requests = [];
    status = 200;
    body = {
      'billingEnabled': true,
      'planId': 'light',
      'canStartCi': true,
      'blockReason': '',
      'paidUntil': '2026-11-21T12:00:00Z',
      'canCheckout': false,
      'canManageBilling': true,
      'cancelAtPeriodEnd': false,
    };
    client = http.runWithClient(
      () => createOpenCIChopperClient(
        baseUrl: 'https://api.openci.test',
        tokenProvider: () async => 'firebase-token',
        services: [OpenCIApiService.create()],
      ),
      () => MockClient((request) async {
        requests.add(request);
        return http.Response(
          body is String ? body as String : jsonEncode(body),
          status,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    api = client.getService<OpenCIApiService>();
  });

  tearDown(() => client.dispose());

  test(
    'Portal sends an authenticated team request without provider fields',
    () async {
      body = {'url': 'https://billing.stripe.com/p/session/test'};
      final response = await api.createBillingPortal('team-2');
      final request = requests.single;
      expect(request.method, 'POST');
      expect(
        request.url.toString(),
        'https://api.openci.test/teams/team-2/billing/portal',
      );
      expect(request.headers['Authorization'], 'Bearer firebase-token');
      expect(request.body, isEmpty);
      expect(response.body, body);
    },
  );

  test('Portal preserves customer-missing and forbidden responses', () async {
    for (final entry in [(409, 'customer_missing'), (403, 'forbidden')]) {
      status = entry.$1;
      body = {'error': entry.$2};
      final response = await api.createBillingPortal('team-1');
      expect(response.statusCode, status);
      expect(response.body, isNull);
      expect(jsonDecode(response.error as String), body);
    }
  });

  test(
    'Checkout sends only the plan to the authenticated team endpoint',
    () async {
      body = {'url': 'https://checkout.stripe.com/c/pay/test'};
      final response = await api.createBillingCheckout('team-2', 'pro');
      final request = requests.single;
      expect(request.method, 'POST');
      expect(
        request.url.toString(),
        'https://api.openci.test/teams/team-2/billing/checkout',
      );
      expect(request.headers['Authorization'], 'Bearer firebase-token');
      expect(jsonDecode(request.body), {'planId': 'pro'});
      expect(response.body, body);
    },
  );

  test('Checkout preserves payment-pending and conflict responses', () async {
    status = 409;
    for (final error in [
      'payment_pending',
      'subscription_exists',
      'checkout_conflict',
    ]) {
      body = {'error': error};
      final response = await api.createBillingCheckout('team-1', 'light');
      expect(response.statusCode, 409);
      expect(response.body, isNull);
      expect(jsonDecode(response.error as String), body);
    }
  });

  test(
    'reads team billing using Firebase auth without a refresh flag',
    () async {
      final response = await api.getBillingStatus('team-1');
      final request = requests.single;
      expect(request.method, 'GET');
      expect(
        request.url.toString(),
        'https://api.openci.test/teams/team-1/billing',
      );
      expect(request.headers['Authorization'], 'Bearer firebase-token');
      expect(request.body, isEmpty);
      expect(response.body, body);
    },
  );

  test(
    'preserves auth, membership, disabled rollout, and non-JSON failures',
    () async {
      for (final code in [401, 403, 404, 503]) {
        status = code;
        body = code == 503
            ? 'temporarily unavailable'
            : {'error': 'not_available'};
        final response = await api.getBillingStatus('team-1');
        expect(response.statusCode, code);
        expect(response.body, isNull);
        expect(response.error, isNotNull);
      }
    },
  );
}
