import 'package:openci_server/db.dart';
import 'package:test/test.dart';

void main() {
  group('DatabaseManager - parseEndpoint Tests', () {
    test('標準的な PostgreSQL URI を正しくパースできる', () {
      final endpoint = DatabaseManager.parseEndpoint(
        'postgres://user:pass@localhost:5432/openci',
      );
      expect(endpoint.host, equals('localhost'));
      expect(endpoint.port, equals(5432));
      expect(endpoint.database, equals('openci'));
      expect(endpoint.username, equals('user'));
      expect(endpoint.password, equals('pass'));
    });

    test('ポートが省略された場合はデフォルトの 5432 を使用する', () {
      final endpoint = DatabaseManager.parseEndpoint(
        'postgres://user:pass@localhost/openci_dev',
      );
      expect(endpoint.host, equals('localhost'));
      expect(endpoint.port, equals(5432));
      expect(endpoint.database, equals('openci_dev'));
      expect(endpoint.username, equals('user'));
      expect(endpoint.password, equals('pass'));
    });

    test('パスワードがない場合も正しく動作する', () {
      final endpoint = DatabaseManager.parseEndpoint(
        'postgres://user@127.0.0.1:5432/openci',
      );
      expect(endpoint.host, equals('127.0.0.1'));
      expect(endpoint.port, equals(5432));
      expect(endpoint.database, equals('openci'));
      expect(endpoint.username, equals('user'));
      expect(endpoint.password, isNull);
    });

    test('ユーザー名もパスワードもない場合も正しく動作する', () {
      final endpoint = DatabaseManager.parseEndpoint(
        'postgres://localhost:5432/openci',
      );
      expect(endpoint.host, equals('localhost'));
      expect(endpoint.port, equals(5432));
      expect(endpoint.database, equals('openci'));
      expect(endpoint.username, isNull);
      expect(endpoint.password, isNull);
    });

    test('DB名のスラッシュを正しく削除できる', () {
      final endpoint = DatabaseManager.parseEndpoint(
        'postgres://localhost:5432/openci_test_db',
      );
      expect(endpoint.database, equals('openci_test_db'));
    });
  });
}
