import 'package:checks/checks.dart';
import 'package:dashboard/build_logs/app_distributions_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../finder_checks.dart';

void main() {
  testWidgets('QrCodeWidget renders successfully with standard data', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: QrCodeWidget(
            data: 'https://example.com',
            size: 160,
            color: Colors.black,
          ),
        ),
      ),
    );

    check(find.text('QR Code error')).findsNothing();
    check(
      find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is QrPainter,
      ),
    ).findsOneWidget();
  });

  testWidgets(
    'QrCodeWidget renders successfully with very long data (manifest url > 150 chars)',
    (tester) async {
      final longData =
          'itms-services://?action=download-manifest&url=${Uri.encodeComponent('https://dashboard.openci.org/iosManifest?buildJobId=f6fded22-76e0-44e0-bb12-72b3f37307eb&extra_query_parameter_to_make_it_extremely_long_so_it_exceeds_version_6_limit=true_value_for_testing')}';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QrCodeWidget(
              data: longData,
              size: 160,
              color: Colors.black,
            ),
          ),
        ),
      );

      check(find.text('QR Code error')).findsNothing();
      check(
        find.byWidgetPredicate(
          (widget) => widget is CustomPaint && widget.painter is QrPainter,
        ),
      ).findsOneWidget();
    },
  );
}
