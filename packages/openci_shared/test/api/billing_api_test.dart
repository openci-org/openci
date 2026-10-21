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
