import 'package:dashboard/settings/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsPage', () {
    testWidgets('displays logout and delete account buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsPage()),
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('shows confirmation dialog when delete account is tapped',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsPage()),
      );

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsNWidgets(2));
      expect(
        find.text(
          'Are you sure you want to delete your account? '
          'This action cannot be undone and all your data will be permanently deleted.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('dialog closes when cancel is tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsPage()),
      );

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('delete button in dialog has red color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: SettingsPage()),
      );

      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      final deleteButtonFinder = find.text('Delete');
      final deleteButtonWidget = tester.widget<Text>(deleteButtonFinder);
      expect(deleteButtonWidget.style?.color, Colors.red);
    });
  });
}
