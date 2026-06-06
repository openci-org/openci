import 'package:openci_server/db.dart';
import 'package:openci_server/middleware.dart';
import 'package:openci_server/router.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  group('Server API Tests', () {
    late Handler handler;
    late DatabaseManager db;
    const localHost = "http://localhost";

    setUpAll(() {
      db = DatabaseManager(
        'postgres://postgres:password@localhost:5432/openci_test',
      );
    });

    setUp(() {
      handler = applyMiddleware(getRouter(db));
    });

    tearDownAll(() async {
      await db.close();
    });

    test('GET / returns 200 and welcome message', () async {
      final request = Request('GET', Uri.parse('$localHost/'));
      final response = await handler(request);

      expect(response.statusCode, equals(200));
      expect(
        await response.readAsString(),
        contains('OpenCI Server (Shelf) is running!'),
      );
    });

    test('GET /invalid-path returns 404', () async {
      final request = Request(
        'GET',
        Uri.parse('$localHost/invalid-path'),
      );
      final response = await handler(request);

      expect(response.statusCode, equals(404));
    });

    test('GET /health returns 500 when database is disconnected', () async {
      final request = Request(
        'GET',
        Uri.parse('$localHost/health'),
      );
      final response = await handler(request);

      expect(response.statusCode, equals(500));
      final body = await response.readAsString();
      expect(body, contains('disconnected'));
      expect(body, contains('error'));
    });
  });
}
