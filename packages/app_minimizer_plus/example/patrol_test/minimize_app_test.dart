import 'dart:io';

import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('minimizes app when minimize button is tapped (iOS only)', (
    $,
  ) async {
    await $.pumpWidgetAndSettle(const MyApp());

    expect($(#minimizeButton), findsOneWidget);

    if (Platform.isIOS) {
      await $(#minimizeButton).tap();

      await Future<void>.delayed(const Duration(seconds: 2));

      final lifecycleState = WidgetsBinding.instance.lifecycleState;
      expect(
        lifecycleState,
        equals(AppLifecycleState.paused),
        reason: 'App should be paused, but was $lifecycleState',
      );
    }
  });
}
