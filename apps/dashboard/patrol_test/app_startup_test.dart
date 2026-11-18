import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/main.dart' as app;
import 'package:dashboard/root.dart';
import 'package:dashboard/root/dashboard_root.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('Dashboard resumes and signs in with email and password', (
    $,
  ) async {
    const email = String.fromEnvironment('DASHBOARD_PATROL_EMAIL');
    const password = String.fromEnvironment('DASHBOARD_PATROL_PASSWORD');
    if (email.isEmpty || password.isEmpty) {
      fail('Set DASHBOARD_PATROL_EMAIL and DASHBOARD_PATROL_PASSWORD.');
    }

    await app.main();

    await $(AuthPage).waitUntilVisible(timeout: const Duration(seconds: 30));
    expect($(Root), findsOneWidget);
    expect($('OpenCI'), findsOneWidget);
    expect($(TextFormField), findsNWidgets(2));

    final signInButton = $(
      find.widgetWithText(FilledButton, t.auth.continueWithGoogle),
    );
    await signInButton.waitUntilVisible();
    expect($.tester.widget<FilledButton>(signInButton).onPressed, isNotNull);
    expect($.tester.takeException(), isNull);

    await $.platform.mobile.pressHome();
    await $.platform.mobile.openApp();

    await $(AuthPage).waitUntilVisible();
    await signInButton.waitUntilVisible();
    expect($(Root), findsOneWidget);
    expect($.tester.takeException(), isNull);

    final emailField = $(find.widgetWithText(TextFormField, t.auth.email));
    await $.tester.ensureVisible(emailField);
    await emailField.enterText(
      email,
      description: 'Enter the test account email',
    );

    final passwordField = $(
      find.widgetWithText(TextFormField, t.auth.password),
    );
    await $.tester.ensureVisible(passwordField);
    await passwordField.enterText(
      password,
      description: 'Enter the test account password',
    );

    final login = $(find.widgetWithText(OutlinedButton, t.auth.login));
    await $.tester.ensureVisible(login);
    await login.tap(settlePolicy: SettlePolicy.noSettle);

    await $(
      DashboardRoot,
    ).waitUntilVisible(timeout: const Duration(seconds: 60));
    expect($(AuthPage), findsNothing);
    expect($.tester.takeException(), isNull);
  });
}
