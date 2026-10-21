import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/billing/billing_proxy.dart';
import 'package:openci_server/billing/billing_proxy_config.dart';
import 'package:test/test.dart';

void main() {
  group('BillingProxyConfig', () {
    test('disabled and Self-hosted do not require billing settings', () {
      expect(BillingProxyConfig.fromEnvironment({}), isNull);
      expect(
        BillingProxyConfig.fromEnvironment({
          'SERVER_ACCESS_MODE': 'self_hosted',
          'BILLING_ENABLED': 'invalid',
        }),
        isNull,
      );
      expect(
        BillingProxyConfig.fromEnvironment({
          'SERVER_ACCESS_MODE': 'cloud',
          'BILLING_ENABLED': 'false',
        }),
        isNull,
      );
    });

    test('rejects credentials, paths, query, fragment, and short token', () {
      for (final uri in [
        'https://user:secret@billing.example',
        'https://billing.example/path',
        'https://billing.example?',
        'https://billing.example#',
      ]) {
        expect(
          () => BillingProxyConfig.fromEnvironment({
            ...billingProxyEnvironment(),
            'GENUINECI_SERVER_URL': uri,
          }),
          throwsFormatException,
        );
      }
      expect(
        () => BillingProxyConfig.fromEnvironment({
          ...billingProxyEnvironment(),
          'BILLING_INTERNAL_TOKEN': 'short',
        }),
        throwsFormatException,
      );
    });
  });

  group('BillingProxy', () {
    test(
      'sends only trusted identity, server token, plan, and escaped team path',
      () async {
        final client = MockClient((request) async {
          expect(request.url.pathSegments, [
            'internal',
            'billing',
            'teams',
            'team/with?query',
            'checkout',
          ]);
          expect(
            request.headers['authorization'],
            'Bearer ${billingProxyEnvironment()['BILLING_INTERNAL_TOKEN']}',
          );
          expect(request.headers['x-genuineci-user-id'], 'verified-user');
          expect(request.followRedirects, isFalse);
          expect(jsonDecode(request.body), {'planId': 'light'});
          return http.Response(
            '{"url":"https://checkout.stripe.com/c/pay/test","private":"hidden"}',
            200,
          );
        });
        addTearDown(client.close);
        final proxy = BillingProxy(
          BillingProxyConfig.fromEnvironment(billingProxyEnvironment())!,
          client,
        );
        final response = await proxy.request(
          operation: BillingOperation.checkout,
          teamId: 'team/with?query',
          uid: 'verified-user',
          planId: 'light',
        );
        expect(response.statusCode, HttpStatus.ok);
        expect(response.headers['cache-control'], 'no-store');
        expect(await response.json(), {
          'url': 'https://checkout.stripe.com/c/pay/test',
        });
      },
    );

    test('sanitizes upstream errors and rejects redirects', () async {
      for (final status in [301, 401, 500]) {
        final client = MockClient(
          (_) async => http.Response('{"error":"private-token"}', status),
        );
        addTearDown(client.close);
        final proxy = BillingProxy(
          BillingProxyConfig.fromEnvironment(billingProxyEnvironment())!,
          client,
        );
        final response = await proxy.request(
          operation: BillingOperation.status,
          teamId: 'team-1',
          uid: 'user-1',
        );
        expect(response.statusCode, HttpStatus.serviceUnavailable);
        expect(await response.json(), {'error': 'billing_unavailable'});
      }
    });

    test('preserves only known actionable error codes', () async {
      final client = MockClient(
        (_) async => http.Response(
          '{"error":"payment_pending","private":"hidden"}',
          409,
        ),
      );
      addTearDown(client.close);
      final proxy = BillingProxy(
        BillingProxyConfig.fromEnvironment(billingProxyEnvironment())!,
        client,
      );
      final response = await proxy.request(
        operation: BillingOperation.checkout,
        teamId: 'team-1',
        uid: 'user-1',
        planId: 'pro',
      );
      expect(response.statusCode, HttpStatus.conflict);
      expect(await response.json(), {'error': 'payment_pending'});
    });

    test('status responses omit private provider fields', () async {
      final client = MockClient(
        (_) async => http.Response(
          jsonEncode({
            'billingEnabled': true,
            'planId': null,
            'canStartCi': false,
            'blockReason': 'payment_required',
            'paidUntil': null,
            'canCheckout': true,
            'canManageBilling': false,
            'cancelAtPeriodEnd': false,
            'stripeCustomerId': 'cus_private',
          }),
          200,
        ),
      );
      addTearDown(client.close);
      final proxy = BillingProxy(
        BillingProxyConfig.fromEnvironment(billingProxyEnvironment())!,
        client,
      );
      final response = await proxy.request(
        operation: BillingOperation.status,
        teamId: 'team-1',
        uid: 'user-1',
      );
      expect(response.statusCode, HttpStatus.ok);
      expect(await response.json(), isNot(contains('stripeCustomerId')));
    });
  });
}

Map<String, String> billingProxyEnvironment() => {
  'SERVER_ACCESS_MODE': 'cloud',
  'BILLING_ENABLED': 'true',
  'GENUINECI_SERVER_URL': 'http://genuineci-server:8081',
  'BILLING_INTERNAL_TOKEN': '01234567890123456789012345678901',
};
