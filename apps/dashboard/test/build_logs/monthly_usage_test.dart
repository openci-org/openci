import 'dart:async';

import 'package:dashboard/app_strings.dart';
import 'package:dashboard/billing/billing_provider.dart';
import 'package:dashboard/billing/billing_status.dart';
import 'package:dashboard/cicd_log/cicd_log_providers.dart';
import 'package:dashboard/cicd_log/cicd_logs_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

BillingStatus _status({String? amount, bool unavailable = false}) {
  return BillingStatus(
    billingEnabled: true,
    monthlyUsage: amount == null
        ? null
        : BillingMonthlyUsage(
            month: '2026-11',
            billableMinutes: '47',
            amountJpyTaxIncluded: amount,
            nextInvoiceDate: '2026-12-01',
          ),
    monthlyUsageUnavailable: unavailable,
    planId: null,
    canStartCi: true,
    blockReason: '',
    paidUntil: null,
    canCheckout: false,
    canManageBilling: true,
    cancelAtPeriodEnd: false,
  );
}

void main() {
  late GoRouter router;
  late Future<BillingStatus?> Function(String teamId) load;
  late List<String> requests;

  setUp(() {
    requests = [];
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, state) => CicdLogsPage(
            teamId: state.uri.queryParameters['teamId'] ?? 'one',
          ),
        ),
        GoRoute(path: '/billing', builder: (_, _) => const SizedBox.shrink()),
      ],
    );
    addTearDown(router.dispose);
  });

  Future<void> show(WidgetTester tester) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: ProviderScope(
          overrides: [
            cicdCommitGroupsProvider.overrideWithBuild(
              (ref, _) => Stream.value([]),
            ),
            billingStatusProvider.overrideWith((ref, teamId) {
              requests.add(teamId);
              return load(teamId);
            }),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the server estimate, reloads it and opens team billing', (
    tester,
  ) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(320, 640);
    addTearDown(tester.view.reset);
    load = (_) async => _status(amount: '0');
    await show(tester);
    expect(find.text('税込見込額 0円'), findsOneWidget);
    expect(find.text('今月の利用状況（2026-11）'), findsOneWidget);
    expect(find.text(t.logs.empty), findsOneWidget);

    load = (_) async => _status(amount: '1240');
    await tester.tap(find.byTooltip(t.common.reload));
    await tester.pumpAndSettle();
    expect(requests, ['one', 'one']);
    await tester.tap(find.text('税込見込額 1240円'));
    await tester.pumpAndSettle();
    expect(router.state.uri, Uri.parse('/billing?teamId=one'));
  });

  testWidgets(
    'a late response for the previous team cannot replace the selected estimate',
    (tester) async {
      final previous = Completer<BillingStatus?>();
      load = (id) =>
          id == 'one' ? previous.future : Future.value(_status(amount: '62'));
      await show(tester);
      expect(find.text(t.logs.empty), findsOneWidget);

      router.go('/?teamId=two');
      await tester.pumpAndSettle();
      previous.complete(_status(amount: '99'));
      await tester.pumpAndSettle();
      expect(requests, ['one', 'two']);
      expect(find.text('税込見込額 99円'), findsNothing);
      await tester.tap(find.text('税込見込額 62円'));
      await tester.pumpAndSettle();
      expect(router.state.uri.queryParameters['teamId'], 'two');
    },
  );

  testWidgets(
    'an unavailable estimate is retryable without hiding the build list',
    (tester) async {
      load = (_) async => _status(unavailable: true);
      await show(tester);
      expect(find.text(t.billing.usageUnavailable), findsOneWidget);
      expect(find.text('税込見込額 0円'), findsNothing);

      load = (_) async => throw StateError('offline');
      await tester.tap(find.byTooltip(t.common.reload));
      await tester.pumpAndSettle();
      expect(find.text(t.billing.usageUnavailable), findsOneWidget);
      expect(find.text(t.logs.empty), findsOneWidget);

      load = (_) async => _status(amount: '5');
      await tester.tap(find.byTooltip(t.common.reload));
      await tester.pumpAndSettle();
      expect(find.text('税込見込額 5円'), findsOneWidget);
    },
  );

  testWidgets(
    'hides the summary when billing or monthly usage is inapplicable',
    (tester) async {
      load = (id) async => id == 'one' ? null : _status();
      await show(tester);
      expect(find.byType(ListTile), findsNothing);
      router.go('/?teamId=two');
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNothing);
      expect(find.text(t.logs.empty), findsOneWidget);
    },
  );
}
