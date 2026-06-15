import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/middleware/apply_middleware.dart';
import 'package:openci_server/router.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../storage/fake_storage.dart';

void main() {
  group('Server API Tests', () {
    late Handler handler;
    late FakeStorageManager storage;
    late AppDatabase db;
    const localHost = "http://localhost";

    setUp(() {
      storage = FakeStorageManager();
      db = AppDatabase(NativeDatabase.memory());
      handler = applyMiddleware(getRouter(storage, db: db));
    });

    tearDown(() async {
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

    test('OPTIONS / returns 200 and CORS headers', () async {
      final request = Request(
        'OPTIONS',
        Uri.parse('$localHost/'),
        headers: {'Origin': 'http://localhost'},
      );
      final response = await handler(request);

      expect(response.statusCode, equals(200));
      expect(
        response.headers['Access-Control-Allow-Origin'],
        equals('http://localhost'),
      );
      expect(
        response.headers['Access-Control-Allow-Credentials'],
        equals('true'),
      );
      expect(
        response.headers['Access-Control-Allow-Methods'],
        contains('GET'),
      );
      expect(
        response.headers['Access-Control-Allow-Headers'],
        contains('Authorization'),
      );
    });

    test('GET / response includes CORS headers for localhost', () async {
      final request = Request(
        'GET',
        Uri.parse('$localHost/'),
        headers: {'Origin': 'http://localhost'},
      );
      final response = await handler(request);

      expect(response.statusCode, equals(200));
      expect(
        response.headers['Access-Control-Allow-Origin'],
        equals('http://localhost'),
      );
      expect(
        response.headers['Access-Control-Allow-Credentials'],
        equals('true'),
      );
    });

    test(
      'GET / response includes CORS headers for official dashboard',
      () async {
        final request = Request(
          'GET',
          Uri.parse('$localHost/'),
          headers: {'Origin': 'https://dashboard.openci.org'},
        );
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        expect(
          response.headers['Access-Control-Allow-Origin'],
          equals('https://dashboard.openci.org'),
        );
        expect(
          response.headers['Access-Control-Allow-Credentials'],
          equals('true'),
        );
      },
    );

    test(
      'GET / with unauthorized Origin does not return CORS headers',
      () async {
        final request = Request(
          'GET',
          Uri.parse('$localHost/'),
          headers: {'Origin': 'http://evil.com'},
        );
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        expect(response.headers['Access-Control-Allow-Origin'], isNull);
        expect(response.headers['Access-Control-Allow-Credentials'], isNull);
      },
    );

    test('GET / with custom allowed origin from environment', () async {
      final customHandler = applyMiddleware(
        getRouter(storage, db: db),
        environment: {'ALLOWED_ORIGINS': 'https://my-custom-dashboard.com'},
      );

      final request = Request(
        'GET',
        Uri.parse('$localHost/'),
        headers: {'Origin': 'https://my-custom-dashboard.com'},
      );
      final response = await customHandler(request);

      expect(response.statusCode, equals(200));
      expect(
        response.headers['Access-Control-Allow-Origin'],
        equals('https://my-custom-dashboard.com'),
      );
      expect(
        response.headers['Access-Control-Allow-Credentials'],
        equals('true'),
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

    test(
      'POST /test-upload uploads artifact and returns presigned url',
      () async {
        final request = Request(
          'POST',
          Uri.parse('$localHost/test-upload'),
        );
        final response = await handler(request);

        expect(response.statusCode, equals(200));
        final body = await response.readAsString();
        expect(body, contains('"success":true'));
        expect(body, contains('downloadUrl'));
      },
    );

    test(
      'POST /test-upload returns 403 forbidden in production environment',
      () async {
        final prodHandler = applyMiddleware(
          getRouter(storage, db: db, environment: {'APP_ENV': 'production'}),
        );
        final request = Request(
          'POST',
          Uri.parse('$localHost/test-upload'),
        );
        final response = await prodHandler(request);

        expect(response.statusCode, equals(403));
        final body = await response.readAsString();
        expect(body, contains('"success":false'));
        expect(
          body,
          contains('Test upload is disabled in production environment.'),
        );
      },
    );
  });
}
