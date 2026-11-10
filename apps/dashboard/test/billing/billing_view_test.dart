import 'package:dashboard/app_strings.dart';
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
    String blockReason = 'payment_required',
    String? planId,
    bool returned = false,
    CardSetupStatus card = CardSetupStatus.unregistered,
    VoidCallback? portal,
    VoidCallback? reload,
  }) => tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(
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
                  blockReason: blockReason,
                  paidUntil: null,
                  canCheckout: canCheckout,
                  canManageBilling: canManage,
                  cancelAtPeriodEnd: false,
                  cardSetupStatus: card,
                ),
                pending: pending,
                returnedFromStripe: returned,
                onPortal: portal ?? () {},
                onSetupCard: () {},
                onReload: reload ?? () {},
              ),
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets('offers card registration and hides legacy plan purchases', (
    tester,
  ) async {
    await show(tester);
    expect(find.text('支払い方法を登録'), findsOneWidget);
    expect(find.text('Lightを選ぶ'), findsNothing);
    expect(find.text('Proを選ぶ'), findsNothing);
  });

  testWidgets('registered cards expose one management action', (
    tester,
  ) async {
    var managed = 0;
    await show(
      tester,
      canCheckout: false,
      planId: 'pro',
      canStart: true,
      card: CardSetupStatus.registered,
      portal: () => managed++,
    );
    expect(find.text('後払い用のカードは登録済みです。'), findsOneWidget);
    expect(find.text('CIを利用できます'), findsOneWidget);
    expect(find.text('Lightを選ぶ'), findsNothing);
    expect(find.text('Proを選ぶ'), findsNothing);
    await tester.scrollUntilVisible(find.text('支払い方法・請求履歴を開く'), 200);
    await tester.tap(find.text('支払い方法・請求履歴を開く'));
    expect(managed, 1);
  });

  testWidgets('pending actions disable purchases, management, and reload', (
    tester,
  ) async {
    var calls = 0;
    await show(
      tester,
      pending: true,
      portal: () => calls++,
      reload: () => calls++,
    );
    for (final label in ['支払い方法を登録', '支払い方法・請求履歴を開く', '再読み込み']) {
      await tester.scrollUntilVisible(find.text(label), 200);
      await tester.tap(find.text(label));
    }
    expect(calls, 0);
    expect(find.text('Stripeを開く準備をしています…'), findsOneWidget);
  });

  testWidgets('unpaid renewals direct members to manage billing', (
    tester,
  ) async {
    var managed = 0;
    await show(
      tester,
      canCheckout: false,
      planId: 'light',
      portal: () => managed++,
    );
    expect(
      find.text('CIを開始するには、このチームの請求用カードを登録してください。'),
      findsOneWidget,
    );
    expect(find.text('CIの利用にはプランの購入が必要です。'), findsNothing);
    expect(find.text('Lightを選ぶ'), findsNothing);
    expect(find.text('Proを選ぶ'), findsNothing);
    await tester.scrollUntilVisible(find.text('支払い方法・請求履歴を開く'), 200);
    await tester.tap(find.text('支払い方法・請求履歴を開く'));
    expect(managed, 1);
  });

  testWidgets('unavailable allowance keeps management and reload accessible', (
    tester,
  ) async {
    var managed = 0;
    var reloaded = 0;
    await show(
      tester,
      canCheckout: false,
      planId: 'light',
      blockReason: 'allowance_exhausted',
      portal: () => managed++,
      reload: () => reloaded++,
    );
    expect(find.text('新しいCIを開始できる利用枠がありません。'), findsOneWidget);
    expect(find.text('Lightを選ぶ'), findsNothing);
    expect(find.text('Proを選ぶ'), findsNothing);
    await tester.scrollUntilVisible(find.text('支払い方法・請求履歴を開く'), 200);
    await tester.tap(find.text('支払い方法・請求履歴を開く'));
    await tester.scrollUntilVisible(find.text('再読み込み'), 200);
    await tester.tap(find.text('再読み込み'));
    expect(managed, 1);
    expect(reloaded, 1);
  });

  testWidgets('a Stripe return does not change the server access decision', (
    tester,
  ) async {
    var reloads = 0;
    await show(tester, returned: true, reload: () => reloads++);
    expect(find.textContaining('Stripeから戻りました'), findsOneWidget);
    expect(find.text('CIを利用できます'), findsNothing);
    expect(find.text('CIを開始するには、このチームの請求用カードを登録してください。'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('再読み込み'), 200);
    await tester.tap(find.text('再読み込み'));
    expect(reloads, 1);
  });

  testWidgets('disabled billing hides payment controls', (tester) async {
    await show(tester, enabled: false);
    expect(find.textContaining('課金機能を利用できません'), findsOneWidget);
    expect(find.text('Lightを選ぶ'), findsNothing);
    expect(find.text('支払い方法・請求履歴を開く'), findsNothing);
    expect(find.text('m.aoki@openci.org'), findsNothing);
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
