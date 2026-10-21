import 'dart:async';
import 'dart:convert';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/auth/auth_provider.dart';
import 'package:dashboard/billing/billing_identity.dart';
import 'package:dashboard/billing/billing_provider.dart';
import 'package:dashboard/billing/billing_response.dart';
import 'package:dashboard/connections/active_connection_profile_provider.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/connections/connection_snapshot.dart';
import 'package:dashboard/connections/connection_store.dart';
import 'package:dashboard/connections/connection_store_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const cloud = ConnectionProfile(
    id: 'cloud',
    name: 'Cloud',
    apiUrl: 'https://api.example.com',
    firebase: {},
  );
  late BillingIdentity? identity;
  late ProviderContainer container;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) respond;

  http.Response statusResponse({String plan = 'light'}) => http.Response(
    jsonEncode({
      'billingEnabled': true,
      'planId': plan,
      'canStartCi': false,
      'blockReason': 'allowance_exhausted',
      'paidUntil': '2026-11-21T12:00:00Z',
      'canCheckout': false,
      'canManageBilling': true,
      'cancelAtPeriodEnd': false,
    }),
    200,
    headers: {'content-type': 'application/json'},
  );

  setUp(() {
    identity = (connection: cloud, userId: 'user-1');
    requests = [];
    respond = (_) async => statusResponse();
    final client = http.runWithClient(
      () => createOpenCIChopperClient(
        baseUrl: cloud.apiUrl,
        tokenProvider: () => 'firebase-token',
      ),
      () => MockClient((request) {
        requests.add(request);
        return respond(request);
      }),
    );
    addTearDown(client.dispose);
    container = ProviderContainer.test(
      overrides: [
        billingIdentityProvider.overrideWith((ref) => identity),
        openciApiServiceProvider.overrideWith(
          (ref) async => OpenCIApiService.create(client),
        ),
      ],
    );
  });

  testWidgets('fetches only on page subscription and explicit reload', (
    tester,
  ) async {
    final provider = billingStatusProvider('team-1');
    container.listen(provider, (_, _) {});
    await tester.pump(Duration.zero);
    final status = container.read(provider).requireValue!;
    expect(status.planId, 'light');
    expect(status.canStartCi, isFalse);
    expect(status.blockReason, 'allowance_exhausted');
    expect(status.paidUntil, DateTime.utc(2026, 11, 21, 12));
    expect(requests, hasLength(1));
    await tester.pump(const Duration(minutes: 10));
    expect(requests, hasLength(1));
    container.invalidate(provider);
    await tester.pump(Duration.zero);
    expect(requests, hasLength(2));
  });

  for (final entry in [
    (401, 'authentication_required'),
    (403, 'forbidden'),
    (404, 'billing_disabled'),
    (503, 'billing_unavailable'),
  ]) {
    testWidgets('sanitizes ${entry.$1} and never retries automatically', (
      tester,
    ) async {
      respond = (_) async => http.Response('private upstream error', entry.$1);
      final provider = billingStatusProvider('team-1');
      container.listen(provider, (_, _) {});
      await tester.pump(Duration.zero);
      expect(
        container.read(provider).error,
        isA<BillingException>().having((e) => e.code, 'code', entry.$2),
      );
      await tester.pump(const Duration(minutes: 10));
      expect(requests, hasLength(1));
    });
  }

  test('keeps team responses separate', () async {
    respond = (request) async => statusResponse(
      plan: request.url.path.contains('team-2') ? 'pro' : 'light',
    );
    final first = container.listen(billingStatusProvider('team-1'), (_, _) {});
    final second = container.listen(billingStatusProvider('team-2'), (_, _) {});
    expect(
      (await container.read(billingStatusProvider('team-1').future))!.planId,
      'light',
    );
    expect(
      (await container.read(billingStatusProvider('team-2').future))!.planId,
      'pro',
    );
    expect(first.read().requireValue!.planId, 'light');
    expect(second.read().requireValue!.planId, 'pro');
  });

  testWidgets('sign-out discards an in-flight status response', (tester) async {
    final response = Completer<http.Response>();
    respond = (_) => response.future;
    final provider = billingStatusProvider('team-1');
    container.listen(provider, (_, _) {});
    await tester.pump(Duration.zero);
    expect(requests, hasLength(1));
    identity = null;
    container.invalidate(billingIdentityProvider);
    await tester.pump(Duration.zero);
    expect(container.read(provider).requireValue, isNull);
    response.complete(statusResponse());
    await tester.pump(Duration.zero);
    expect(container.read(provider).requireValue, isNull);
  });

  testWidgets('a different signed-in user gets a fresh status', (tester) async {
    final provider = billingStatusProvider('team-1');
    container.listen(provider, (_, _) {});
    await tester.pump(Duration.zero);
    respond = (_) async => statusResponse(plan: 'pro');
    identity = (connection: cloud, userId: 'user-2');
    container.invalidate(billingIdentityProvider);
    await tester.pump(Duration.zero);
    expect(container.read(provider).requireValue!.planId, 'pro');
    expect(requests, hasLength(2));
  });

  test('rejects a client belonging to a different connection', () async {
    identity = (
      connection: cloud.copyWith(apiUrl: 'https://another.example'),
      userId: 'user-1',
    );
    final provider = billingStatusProvider('team-1');
    container.listen(provider, (_, _) {});
    await expectLater(
      container.read(provider.future),
      throwsA(isA<BillingException>()),
    );
    expect(requests, isEmpty);
  });

  test('a malformed successful status never grants access', () async {
    respond = (_) async => http.Response(
      '{"canStartCi":true}',
      200,
      headers: {'content-type': 'application/json'},
    );
    final provider = billingStatusProvider('team-1');
    container.listen(provider, (_, _) {});
    await expectLater(
      container.read(provider.future),
      throwsA(isA<BillingException>()),
    );
  });

  testWidgets('disposing the page drops state and reopening fetches again', (
    tester,
  ) async {
    final provider = billingStatusProvider('team-1');
    final subscription = container.listen(provider, (_, _) {});
    await tester.pump(Duration.zero);
    subscription.close();
    await tester.pump(Duration.zero);
    expect(container.exists(provider), isFalse);
    container.listen(provider, (_, _) {});
    await tester.pump(Duration.zero);
    expect(requests, hasLength(2));
  });

  test(
    'Native does not initialize connection, authentication, or API',
    () async {
      final native = ProviderContainer.test(
        overrides: [
          billingWebSupportedProvider.overrideWithValue(false),
          connectionStoreProvider.overrideWith(
            (ref) => throw StateError('must not read'),
          ),
          openciApiServiceProvider.overrideWith(
            (ref) => throw StateError('must not read'),
          ),
        ],
      );
      native.listen(billingStatusProvider('team-1'), (_, _) {});
      expect(await native.read(billingStatusProvider('team-1').future), isNull);
    },
  );

  test(
    'Self-hosted does not initialize authentication or billing API',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = ConnectionStore(
        await SharedPreferences.getInstance(),
        cloud,
      );
      await store.save(
        ConnectionSnapshot(
          profiles: [
            cloud,
            cloud.copyWith(id: 'self-hosted'),
          ],
          activeId: 'self-hosted',
        ),
      );
      final selfHosted = ProviderContainer.test(
        overrides: [
          billingWebSupportedProvider.overrideWithValue(true),
          connectionStoreProvider.overrideWithValue(store),
          openciApiServiceProvider.overrideWith(
            (ref) => throw StateError('must not read'),
          ),
        ],
      );
      selfHosted.listen(billingStatusProvider('team-1'), (_, _) {});
      await selfHosted.read(activeConnectionProfileProvider(store).future);
      expect(
        await selfHosted.read(billingStatusProvider('team-1').future),
        isNull,
      );
    },
  );

  test(
    'connection changes and sign-out clear the real billing identity',
    () async {
      SharedPreferences.setMockInitialValues({});
      final store = ConnectionStore(
        await SharedPreferences.getInstance(),
        cloud,
      );
      await store.save(
        ConnectionSnapshot(
          profiles: [
            cloud,
            cloud.copyWith(id: 'self-hosted'),
          ],
          activeId: 'cloud',
        ),
      );
      final changes = StreamController<User?>();
      addTearDown(changes.close);
      final identities = ProviderContainer.test(
        overrides: [
          billingWebSupportedProvider.overrideWithValue(true),
          connectionStoreProvider.overrideWithValue(store),
          authStateChangesProvider.overrideWith((ref) => changes.stream),
        ],
      );
      identities.listen(billingIdentityProvider, (_, _) {});
      await identities.read(activeConnectionProfileProvider(store).future);
      await identities.pump();
      changes.add(_User('user-1'));
      await identities.read(authStateChangesProvider.future);
      await identities.pump();
      expect(identities.read(billingIdentityProvider)?.userId, 'user-1');
      changes.add(null);
      await identities.pump();
      expect(identities.read(billingIdentityProvider), isNull);
      changes.add(_User('user-2'));
      await identities.pump();
      expect(identities.read(billingIdentityProvider)?.userId, 'user-2');
      await identities
          .read(activeConnectionProfileProvider(store).notifier)
          .select('self-hosted');
      await identities.pump();
      expect(identities.read(billingIdentityProvider), isNull);
    },
  );
}

class _User extends Fake implements User {
  _User(this.uid);

  @override
  final String uid;
}
