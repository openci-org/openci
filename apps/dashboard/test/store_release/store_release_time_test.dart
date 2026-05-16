import 'package:dashboard/store_release/store_release_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatAscTimestampJst', () {
    test('formats UTC timestamps as JST', () {
      expect(
        formatAscTimestampJst('2026-05-15T12:04:30Z'),
        '5/15 21:04 JST',
      );
    });

    test('formats offset timestamps as JST', () {
      expect(
        formatAscTimestampJst('2026-05-15T04:04:30-07:00'),
        '5/15 20:04 JST',
      );
    });

    test('can include the year for submitted build details', () {
      expect(
        formatAscTimestampJst(
          '2026-05-15T12:04:30Z',
          includeYear: true,
        ),
        '2026/5/15 21:04 JST',
      );
    });

    test('treats timestamps without explicit timezone as UTC', () {
      expect(
        formatAscTimestampJst('2026-05-15T12:04:30'),
        '5/15 21:04 JST',
      );
    });

    test('returns null for missing or invalid timestamps', () {
      expect(formatAscTimestampJst(null), isNull);
      expect(formatAscTimestampJst(''), isNull);
      expect(formatAscTimestampJst('invalid'), isNull);
    });
  });
}
