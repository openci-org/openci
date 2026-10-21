import 'dart:async';
import 'dart:convert';

import 'package:dashboard/api/openci_api_client.dart';
import 'package:dashboard/billing/billing_identity.dart';
import 'package:dashboard/billing/billing_page.dart';
import 'package:dashboard/connections/connection_profile.dart';
import 'package:dashboard/team/selected_team_provider.dart';
import 'package:dashboard/team/team_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_shared/openci_shared.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';

void main() {
  const cloud = ConnectionProfile(
    id: 'cloud',
    name: 'Cloud',
    apiUrl: 'https://api.example.com',
    firebase: {},
  );
  late BillingIdentity? identity;
  late ProviderContainer container;
  late List<http.Request> requests;
  late _Launcher launcher;
  late Future<http.Response> Function(http.Request) respond;
  var paid = false;

  http.Response jsonResponse(Object body, {int status = 200}) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  setUp(() {
    identity = (connection: cloud, userId: 'user-1');
    requests = [];
    paid = false;
    final original = UrlLauncherPlatform.instance;
    launcher = _Launcher();
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = original);
    respond = (request) async {
      if (request.method == 'POST') {
        return jsonResponse({
          'url': request.url.path.endsWith('/portal')
              ? 'https://billing.stripe.com/p/session/test'
              : 'https://checkout.stripe.com/c/pay/test',
        });
      }
      return jsonResponse({
        'billingEnabled': true,
        'planId': paid ? 'light' : null,
        'canStartCi': paid,
        'blockReason': paid ? '' : 'payment_required',
        'paidUntil': paid ? '2026-11-21T12:00:00Z' : null,
        'canCheckout': !paid,
        'canManageBilling': true,
        'cancelAtPeriodEnd': false,
      });
    };
  });

  Future<void> show(
    WidgetTester tester, {
    String? teamId = 'team-1',
    String? result,
  }) async {
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
        teamListProvider.overrideWith(
          (ref) async => [
            for (final id in ['team-1', 'team-2'])
              Team(
                id: id,
                name: id,
                members: const ['user-1'],
                createdAt: DateTime.utc(2026),
                updatedAt: DateTime.utc(2026),
              ),
          ],
        ),
        selectedTeamIdProvider.overrideWithBuild(
          (ref, notifier) async => 'team-2',
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: BillingPage(teamId: teamId, result: result),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an explicit Stripe return team wins over the selected team', (
    tester,
  ) async {
    await show(tester, result: 'success');
    expect(requests.single.url.path, '/teams/team-1/billing');
    expect(find.text('team-1'), findsOneWidget);
    expect(find.text('CIを利用できます'), findsNothing);
    expect(find.text('CIの利用にはプランの購入が必要です。'), findsOneWidget);
    await tester.pump(const Duration(minutes: 10));
    expect(requests, hasLength(1));
    paid = true;
    await tester.scrollUntilVisible(find.text('再読み込み'), 200);
    await tester.pump();
    await tester.tap(find.text('再読み込み'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('CIを利用できます'), -200);
    await tester.pump();
    expect(find.text('CIを利用できます'), findsOneWidget);
    expect(requests, hasLength(2));
  });

  testWidgets('uses the selected team only when no explicit ID is given', (
    tester,
  ) async {
    await show(tester, teamId: null);
    expect(requests.single.url.path, '/teams/team-2/billing');
  });

  testWidgets('a new Stripe return refreshes an already mounted billing page', (
    tester,
  ) async {
    await show(tester);
    paid = true;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: BillingPage(teamId: 'team-1', result: 'portal'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(requests.where((r) => r.method == 'GET'), hasLength(2));
    expect(find.text('CIを利用できます'), findsOneWidget);
  });

  for (final id in ['', 'missing']) {
    testWidgets('does not fall back from an inaccessible explicit team "$id"', (
      tester,
    ) async {
      await show(tester, teamId: id);
      expect(find.textContaining('このチームにアクセスできません'), findsOneWidget);
      expect(requests, isEmpty);
      expect(find.text('Lightを選ぶ'), findsNothing);
    });
  }

  testWidgets('Checkout opens the validated destination in the same window', (
    tester,
  ) async {
    await show(tester);
    await tester.tap(find.text('Lightを選ぶ'));
    await tester.pumpAndSettle();
    expect(jsonDecode(requests.last.body), {'planId': 'light'});
    expect(launcher.url, 'https://checkout.stripe.com/c/pay/test');
    expect(launcher.options?.webOnlyWindowName, '_self');
    expect(requests.where((r) => r.method == 'GET'), hasLength(1));
  });

  testWidgets('Portal and launch failures preserve the team and allow retry', (
    tester,
  ) async {
    launcher.success = false;
    await show(tester);
    await tester.scrollUntilVisible(find.text('契約を管理'), 200);
    await tester.pump();
    await tester.tap(find.text('契約を管理'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('Stripeを開けませんでした'),
      200,
    );
    expect(find.textContaining('Stripeを開けませんでした'), findsOneWidget);
    launcher.success = true;
    await tester.scrollUntilVisible(find.text('契約を管理'), -200);
    await tester.pump();
    await tester.tap(find.text('契約を管理'));
    await tester.pumpAndSettle();
    expect(launcher.url, 'https://billing.stripe.com/p/session/test');
    expect(requests.last.url.path, '/teams/team-1/billing/portal');
  });

  testWidgets('membership loss during a purchase hides stale billing data', (
    tester,
  ) async {
    await show(tester);
    respond = (_) async => jsonResponse({'error': 'forbidden'}, status: 403);
    await tester.tap(find.text('Lightを選ぶ'));
    await tester.pumpAndSettle();
    expect(find.text('このチームの課金情報にアクセスできません。'), findsOneWidget);
    expect(find.text('Lightを選ぶ'), findsNothing);
    expect(find.text('team-1'), findsNothing);
    expect(launcher.url, isNull);
  });

  testWidgets('sign-out suppresses a delayed Checkout redirect', (
    tester,
  ) async {
    await show(tester);
    final response = Completer<http.Response>();
    respond = (_) => response.future;
    await tester.tap(find.text('Lightを選ぶ'));
    await tester.pump(Duration.zero);
    identity = null;
    container.invalidate(billingIdentityProvider);
    await tester.pump(Duration.zero);
    response.complete(
      jsonResponse({'url': 'https://checkout.stripe.com/c/pay/test'}),
    );
    await tester.pumpAndSettle();
    expect(launcher.url, isNull);
    expect(find.text('Lightを選ぶ'), findsNothing);
  });
}

class _Launcher extends UrlLauncherPlatform {
  String? url;
  LaunchOptions? options;
  bool success = true;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    this.url = url;
    this.options = options;
    return success;
  }
}
