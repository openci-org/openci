import 'package:openci_server/database.dart';
import 'package:test/test.dart';

void main() {
  group('loadDatabaseUrl Tests', () {
    test('uses DATABASE_URL environment variable if specified', () {
      final url = loadDatabaseUrl(
        environment: {
          'DATABASE_URL': 'postgres://test-db:5432/test',
        },
      );
      expect(url, equals('postgres://test-db:5432/test'));
    });

    test('throws StateError if DATABASE_URL is missing', () {
      expect(
        () => loadDatabaseUrl(environment: {}),
        throwsStateError,
      );
    });
  });
}
