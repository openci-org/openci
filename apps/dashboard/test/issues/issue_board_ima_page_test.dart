import 'package:dashboard/issues/issue_board_ima_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldSpinCardBuildStatus', () {
    test('does not spin when any current CI job failed', () {
      expect(
        shouldSpinCardBuildStatus(failed: 1, active: 1, queuedOnly: false),
        isFalse,
      );
    });

    test('spins while non-queued jobs are still running', () {
      expect(
        shouldSpinCardBuildStatus(failed: 0, active: 1, queuedOnly: false),
        isTrue,
      );
    });

    test('does not spin for queued-only jobs', () {
      expect(
        shouldSpinCardBuildStatus(failed: 0, active: 1, queuedOnly: true),
        isFalse,
      );
    });
  });
}
