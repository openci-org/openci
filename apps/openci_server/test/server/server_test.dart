import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/environment_value/environment_value.dart';
import 'package:openci_server/middleware/apply_middleware.dart';
import 'package:openci_server/router.dart';
import 'package:openci_server/storage.dart';
import 'package:riverpod/riverpod.dart';
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
      final envValue = EnvironmentValue.load(
        environment: {
          'DATABASE_URL': 'postgres://localhost:5432/test',
          'SECRET_ENCRYPTION_KEY': 'some_secret_key_here_1234567890',
        },
      );
      final container = ProviderContainer(
        overrides: [
          environmentValueProvider.overrideWithValue(envValue),
          databaseProvider.overrideWithValue(db),
          storageProvider.overrideWithValue(storage),
          firebaseAppProvider.overrideWithValue(null),
        ],
      );
      handler = container.read(handlerProvider);
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
      final envValue = EnvironmentValue.load(
        environment: {
          'DATABASE_URL': 'postgres://localhost:5432/test',
          'SECRET_ENCRYPTION_KEY': 'some_secret_key_here_1234567890',
        },
      );
      final container = ProviderContainer(
        overrides: [
          environmentValueProvider.overrideWithValue(envValue),
          databaseProvider.overrideWithValue(db),
          storageProvider.overrideWithValue(storage),
          firebaseAppProvider.overrideWithValue(null),
        ],
      );
      final router = container.read(routerProvider);
      final customHandler = applyMiddleware(
        router,
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
  });
}
