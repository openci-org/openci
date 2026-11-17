import 'package:dashboard/app_strings.dart';
import 'package:dashboard/auth/auth_page.dart';
import 'package:dashboard/main.dart' as app;
import 'package:dashboard/root.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('Dashboard starts and resumes on the sign-in screen', ($) async {
    await app.main();

    await $(AuthPage).waitUntilVisible(timeout: const Duration(seconds: 30));
    expect($(Root), findsOneWidget);
    expect($('OpenCI'), findsOneWidget);
    expect($(TextFormField), findsNWidgets(2));

    final signInButton = $(find.widgetWithText(FilledButton, t.auth.login));
    await signInButton.waitUntilVisible();
    expect($.tester.widget<FilledButton>(signInButton).onPressed, isNotNull);
    expect($.tester.takeException(), isNull);

    await $.platform.mobile.pressHome();
    await $.platform.mobile.openApp();

    await $(AuthPage).waitUntilVisible();
    await signInButton.waitUntilVisible();
    expect($(Root), findsOneWidget);
    expect($.tester.takeException(), isNull);
  });
}
