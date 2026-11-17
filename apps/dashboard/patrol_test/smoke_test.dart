import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  patrolTest('Flutter state survives native home navigation', ($) async {
    var count = 0;
    await $.pumpWidgetAndSettle(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            appBar: AppBar(title: const Text('OpenCI Patrol smoke test')),
            body: Center(child: Text('Count: $count')),
            floatingActionButton: FloatingActionButton(
              onPressed: () => setState(() => count++),
              child: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );

    expect($('Count: 0'), findsOneWidget);
    await $(FloatingActionButton).tap();
    expect($('Count: 1'), findsOneWidget);
    await $.platform.mobile.pressHome();
    await $.platform.mobile.openApp();
    expect($('Count: 1'), findsOneWidget);
  });
}
