import 'package:dashboard/navigation_bar_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('navigation_bar_page_test', () {
    const pageA = Text('A');
    const pageB = Text('B');
    const pages = [pageA, pageB];
    testWidgets('initial_state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NavigationBarPage(pages)),
      );
      expect(find.text('Create'), findsOneWidget);
      expect(find.text('List'), findsOneWidget);

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.folder_outlined), findsOneWidget);

      final navigationBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navigationBar.selectedIndex, 0);
      expect(find.byWidget(pageA), findsOneWidget);
    });

    testWidgets('tap_create_icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NavigationBarPage(pages)),
      );
      expect(find.text('Create'), findsOneWidget);
      expect(find.text('List'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.folder_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.folder), findsOneWidget);

      final navigationBar = tester.widget<NavigationBar>(
        find.byType(NavigationBar),
      );
      expect(navigationBar.selectedIndex, 1);
      expect(find.byWidget(pageB), findsOneWidget);
    });
  });
}
