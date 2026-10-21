import 'package:dashboard/billing/billing_status.dart';
import 'package:dashboard/billing/billing_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> show(
    WidgetTester tester, {
    bool pending = false,
    bool canCheckout = true,
    bool canManage = true,
    bool enabled = true,
    bool canStart = false,
    String? planId,
    bool returned = false,
    ValueChanged<String>? checkout,
    VoidCallback? portal,
    VoidCallback? reload,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 640,
            child: BillingView(
              teamName: 'チームA',
              status: BillingStatus(
                billingEnabled: enabled,
                planId: planId,
                canStartCi: canStart,
                blockReason: 'payment_required',
                paidUntil: null,
                canCheckout: canCheckout,
                canManageBilling: canManage,
                cancelAtPeriodEnd: false,
              ),
              pending: pending,
              returnedFromStripe: returned,
              onCheckout: checkout ?? (_) {},
              onPortal: portal ?? () {},
              onReload: reload ?? () {},
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('shows approved offers and sends the selected plan key', (
    tester,
  ) async {
    final selected = <String>[];
    await show(tester, checkout: selected.add);
    expect(find.text('US\$10 / 月'), findsOneWidget);
    expect(find.text('US\$100 / 月'), findsOneWidget);
    expect(find.text('チーム共有 600分 / 月'), findsOneWidget);
    expect(find.text('チーム共有 6,000分 / 月'), findsOneWidget);
    await tester.tap(find.text('Lightを選ぶ'));
    await tester.scrollUntilVisible(find.text('Proを選ぶ'), 200);
    await tester.tap(find.text('Proを選ぶ'));
    expect(selected, ['light', 'pro']);
  });

  testWidgets('current subscriptions expose one generic management action', (
    tester,
  ) async {
    var managed = 0;
    await show(
      tester,
      canCheckout: false,
      planId: 'pro',
      canStart: true,
      portal: () => managed++,
    );
    expect(find.text('現在のプラン'), findsOneWidget);
    expect(find.text('CIを利用できます'), findsOneWidget);
    expect(find.text('Lightを選ぶ'), findsNothing);
    expect(find.text('Proを選ぶ'), findsNothing);
    await tester.scrollUntilVisible(find.text('契約を管理'), 200);
    await tester.tap(find.text('契約を管理'));
    expect(managed, 1);
  });

  testWidgets('pending actions disable purchases, management, and reload', (
    tester,
  ) async {
    var calls = 0;
    await show(
      tester,
      pending: true,
      checkout: (_) => calls++,
      portal: () => calls++,
      reload: () => calls++,
    );
    for (final label in ['Lightを選ぶ', 'Proを選ぶ', '契約を管理', '再読み込み']) {
      await tester.scrollUntilVisible(find.text(label), 200);
      await tester.tap(find.text(label));
    }
    expect(calls, 0);
    expect(find.text('Stripeを開く準備をしています…'), findsOneWidget);
  });

  testWidgets('a Stripe return does not change the server access decision', (
    tester,
  ) async {
    var reloads = 0;
    await show(tester, returned: true, reload: () => reloads++);
    expect(find.textContaining('Stripeから戻りました'), findsOneWidget);
    expect(find.text('CIを利用できます'), findsNothing);
    expect(find.text('CIの利用にはプランの購入が必要です。'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('再読み込み'), 200);
    await tester.tap(find.text('再読み込み'));
    expect(reloads, 1);
  });

  testWidgets('disabled billing hides payment controls', (tester) async {
    await show(tester, enabled: false);
    expect(find.textContaining('課金機能を利用できません'), findsOneWidget);
    expect(find.text('Lightを選ぶ'), findsNothing);
    expect(find.text('契約を管理'), findsNothing);
  });

  testWidgets('fits a narrow viewport with enlarged text', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await show(tester, returned: true);
    await tester.scrollUntilVisible(find.text('再読み込み'), 200);
    expect(tester.takeException(), isNull);
  });
}
