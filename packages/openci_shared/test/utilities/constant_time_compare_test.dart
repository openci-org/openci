import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('constantTimeCompare', () {
    test('should return true for identical lists', () {
      expect(constantTimeCompare([1, 2, 3], [1, 2, 3]), isTrue);
    });

    test('should return false for lists of different lengths', () {
      expect(constantTimeCompare([1, 2, 3], [1, 2]), isFalse);
      expect(constantTimeCompare([1, 2], [1, 2, 3]), isFalse);
    });

    test(
      'should return false for lists of the same length but different content',
      () {
        expect(constantTimeCompare([9, 2, 3], [1, 2, 3]), isFalse);
        expect(constantTimeCompare([1, 9, 3], [1, 2, 3]), isFalse);
        expect(constantTimeCompare([1, 2, 9], [1, 2, 3]), isFalse);
      },
    );

    test('should return true for empty lists', () {
      expect(constantTimeCompare([], []), isTrue);
    });
  });

  group('constantTimeCompareString', () {
    test('should return true for identical strings', () {
      expect(constantTimeCompareString('hello', 'hello'), isTrue);
    });

    test('should return false for strings of different lengths', () {
      expect(constantTimeCompareString('hello', 'hell'), isFalse);
      expect(constantTimeCompareString('hell', 'hello'), isFalse);
    });

    test(
      'should return false for strings of the same length but different content',
      () {
        expect(constantTimeCompareString('xello', 'hello'), isFalse);
        expect(constantTimeCompareString('hexlo', 'hello'), isFalse);
        expect(constantTimeCompareString('hellx', 'hello'), isFalse);
      },
    );

    test('should return true for empty strings', () {
      expect(constantTimeCompareString('', ''), isTrue);
    });
  });
}
