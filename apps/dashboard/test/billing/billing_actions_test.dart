import 'dart:async';
import 'dart:convert';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/billing/billing_actions.dart';
import 'package:dashboard/billing/billing_identity.dart';
import 'package:dashboard/billing/billing_provider.dart';
import 'package:dashboard/billing/billing_response.dart';
import 'package:dashboard/billing/billing_status.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';

void main() {
  const cloud = ConnectionProfile(
    id: 'cloud',
    name: 'Cloud',
    apiUrl: 'https://api.example.com',
    firebase: {},
  );
  late ProviderContainer container;
  late BillingIdentity? identity;
  late List<http.Request> requests;
  late Future<http.Response> Function() respond;
  var canCheckout = true;
  var canManage = true;

  http.Response redirect(String url) => http.Response(
    jsonEncode({'url': url}),
    200,
    headers: {'content-type': 'application/json'},
  );

  setUp(() {
    identity = (connection: cloud, userId: 'user-1');
    requests = [];
    canCheckout = true;
    canManage = true;
    respond = () async =>
        redirect('https://checkout.stripe.com/c/pay/cs_test#fid-example');
    final client = http.runWithClient(
      () => createOpenCIChopperClient(
        baseUrl: cloud.apiUrl,
        tokenProvider: () => 'firebase-token',
      ),
      () => MockClient((request) {
        requests.add(request);
        return respond();
      }),
    );
    addTearDown(client.dispose);
    container = ProviderContainer.test(
      overrides: [
        billingIdentityProvider.overrideWith((ref) => identity),
        openciApiServiceProvider.overrideWith(
          (ref) async => OpenCIApiService.create(client),
        ),
        billingStatusProvider('team-1').overrideWith(
          (ref) async => BillingStatus(
            billingEnabled: true,
            planId: null,
            canStartCi: false,
            blockReason: 'payment_required',
            paidUntil: null,
            canCheckout: canCheckout,
            canManageBilling: canManage,
            cancelAtPeriodEnd: false,
          ),
        ),
      ],
    );
  });

  Future<BillingActions> actions() async {
    container.listen(billingStatusProvider('team-1'), (_, _) {});
    await container.read(billingStatusProvider('team-1').future);
    return container
        .listen(billingActionsProvider('team-1'), (_, _) {})
        .read()!;
  }

  test(
    'Checkout returns only the Stripe destination without granting access',
    () async {
      final result = await (await actions()).checkout('light');
      expect(result.host, 'checkout.stripe.com');
      expect(result.fragment, 'fid-example');
      expect(jsonDecode(requests.single.body), {'planId': 'light'});
      expect(
        container
            .read(billingStatusProvider('team-1'))
            .requireValue!
            .canStartCi,
        isFalse,
      );
    },
  );

  test(
    'Portal uses the team endpoint and its own allowed Stripe host',
    () async {
      respond = () async =>
          redirect('https://billing.stripe.com/p/session/test');
      expect((await (await actions()).portal()).host, 'billing.stripe.com');
      expect(requests.single.url.path, '/teams/team-1/billing/portal');
    },
  );

  test('Portal accepts a session secret in the query string', () async {
    const url = 'https://billing.stripe.com/p/session?secret=test_session';
    respond = () async => redirect(url);

    expect(await (await actions()).portal(), Uri.parse(url));
    expect(requests.single.url.path, '/teams/team-1/billing/portal');
  });

  test('Portal rejects missing secrets and unsafe query session URLs', () async {
    final action = await actions();
    for (final url in [
      'https://billing.stripe.com/p/session',
      'https://billing.stripe.com/p/session?secret=',
      'https://billing.stripe.com/p/session?secret=%20',
      'https://billing.stripe.com/other?secret=test_session',
      'https://billing.stripe.com.attacker.example/p/session?secret=test_session',
      'http://billing.stripe.com/p/session?secret=test_session',
      'https://billing.stripe.com:8443/p/session?secret=test_session',
      'https://user@billing.stripe.com/p/session?secret=test_session',
    ]) {
      respond = () async => redirect(url);
      await expectLater(
        action.portal(),
        throwsA(
          isA<BillingException>().having(
            (e) => e.code,
            'code',
            'invalid_redirect',
          ),
        ),
        reason: url,
      );
    }
  });

  test(
    'server capabilities prevent ineligible actions before network access',
    () async {
      canCheckout = false;
      canManage = false;
      final action = await actions();
      await expectLater(
        action.checkout('pro'),
        throwsA(isA<BillingException>()),
      );
      await expectLater(action.portal(), throwsA(isA<BillingException>()));
      expect(requests, isEmpty);
    },
  );

  test(
    'duplicate clicks produce only one request and errors allow retry',
    () async {
      final response = Completer<http.Response>();
      respond = () => response.future;
      final action = await actions();
      final first = action.checkout('light');
      final firstResult = expectLater(first, throwsA(isA<BillingException>()));
      await expectLater(
        action.checkout('light'),
        throwsA(
          isA<BillingException>().having(
            (e) => e.code,
            'code',
            'request_in_progress',
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      expect(requests, hasLength(1));
      response.complete(http.Response('unavailable', 503));
      await firstResult;
      respond = () async =>
          redirect('https://checkout.stripe.com/c/pay/cs_test');
      await action.checkout('light');
      expect(requests, hasLength(2));
    },
  );

  test(
    'sign-out rejects a pending redirect and future use of the old action',
    () async {
      final response = Completer<http.Response>();
      respond = () => response.future;
      final action = await actions();
      final result = expectLater(
        action.checkout('light'),
        throwsA(
          isA<BillingException>().having(
            (e) => e.code,
            'code',
            'context_changed',
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);
      identity = null;
      container.invalidate(billingIdentityProvider);
      await container.pump();
      response.complete(redirect('https://checkout.stripe.com/c/pay/cs_test'));
      await result;
      await expectLater(action.portal(), throwsA(isA<BillingException>()));
      expect(requests, hasLength(1));
    },
  );

  test(
    'rejects unexpected schemes, hosts, ports, credentials, and paths',
    () async {
      final action = await actions();
      for (final url in [
        'javascript:alert(1)',
        'http://checkout.stripe.com/c/pay/cs_test',
        'https://checkout.stripe.com.attacker.example/c/pay/cs_test',
        'https://attacker.example/c/pay/cs_test',
        'https://user@checkout.stripe.com/c/pay/cs_test',
        'https://checkout.stripe.com:8443/c/pay/cs_test',
        'https://checkout.stripe.com/other',
        'https://billing.stripe.com/p/session/test',
      ]) {
        respond = () async => redirect(url);
        await expectLater(
          action.checkout('light'),
          throwsA(
            isA<BillingException>().having(
              (e) => e.code,
              'code',
              'invalid_redirect',
            ),
          ),
          reason: url,
        );
      }
    },
  );
}
