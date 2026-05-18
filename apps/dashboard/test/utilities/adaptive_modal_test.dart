import 'package:dashboard/theme/app_colors.dart';
import 'package:dashboard/utilities/adaptive_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpModalHost(WidgetTester tester, Size size) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(() {
      tester.view.resetDevicePixelRatio();
      tester.view.resetPhysicalSize();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [AppColors.light],
        ),
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () {
                    showAdaptiveFormModal(
                      context: context,
                      builder: (context) => const SizedBox(
                        width: 120,
                        height: 120,
                        child: Text('modal content'),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets('uses a dialog on desktop width', (tester) async {
    await pumpModalHost(tester, const Size(900, 700));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('modal content'), findsOneWidget);
  });

  testWidgets('uses a bottom sheet on mobile width', (tester) async {
    await pumpModalHost(tester, const Size(390, 700));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('modal content'), findsOneWidget);
  });
}
