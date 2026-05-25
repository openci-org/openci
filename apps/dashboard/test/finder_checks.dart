import 'package:checks/context.dart';
import 'package:flutter_test/flutter_test.dart';

extension FinderChecks on Subject<Finder> {
  void findsOneWidget() {
    context.expect(() => const ['finds one widget'], (actual) {
      final elements = actual.evaluate();
      if (elements.length == 1) return null;
      return Rejection(
        which: [
          'does not find exactly one widget (found ${elements.length})',
        ],
      );
    });
  }

  void findsNothing() {
    context.expect(() => const ['finds nothing'], (actual) {
      final elements = actual.evaluate();
      if (elements.isEmpty) return null;
      return Rejection(
        which: ['found ${elements.length} widgets, expected none'],
      );
    });
  }
}
