import 'package:openci_shared/openci_shared.dart';
import 'package:test/test.dart';

void main() {
  group('getRequiredEnv', () {
    test('returns value when environment variable exists and is not empty', () {
      final env = {'API_KEY': 'secret123'};
      expect(getRequiredEnv('API_KEY', environment: env), equals('secret123'));
    });

    test('throws StateError when environment variable is not set', () {
      final env = <String, String>{};
      expect(
        () => getRequiredEnv('MISSING_KEY', environment: env),
        throwsStateError,
      );
    });

    test('throws StateError when environment variable is empty', () {
      final env = {'EMPTY_KEY': ''};
      expect(
        () => getRequiredEnv('EMPTY_KEY', environment: env),
        throwsStateError,
      );
    });

    test('falls back to Platform.environment when environment is omitted', () {
      expect(
        () => getRequiredEnv('__DEFINITELY_NON_EXISTENT_KEY_12345__'),
        throwsStateError,
      );
    });
  });
}
