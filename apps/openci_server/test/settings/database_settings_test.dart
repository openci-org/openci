import 'package:openci_server/settings/database_settings.dart';
import 'package:test/test.dart';

void main() {
  group('loadDatabaseUrl Tests', () {
    test('uses DATABASE_URL environment variable if specified', () {
      final url = loadDatabaseUrl(environment: {
        'DATABASE_URL': 'postgres://test-db:5432/test',
      });
      expect(url, equals('postgres://test-db:5432/test'));
    });

    test('throws StateError in production if DATABASE_URL is missing', () {
      expect(
        () => loadDatabaseUrl(environment: {'APP_ENV': 'production'}),
        throwsStateError,
      );
    });

    test('falls back to local development URL in non-production', () {
      final url = loadDatabaseUrl(environment: {'APP_ENV': 'development'});
      expect(url, equals('postgres://postgres:password@localhost:5432/openci'));
    });
  });
}
