import 'dart:io';

import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/database.dart';
import 'package:openci_server/router.dart';
import 'package:openci_server/environment_value/environment_value.dart';
import 'package:openci_server/storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

import '../storage/fake_storage.dart';

void main() {
  group('Server Integration Tests', () {
    late HttpServer server;
    late int port;
    late FakeStorageManager storage;
    late AppDatabase db;

    setUpAll(() async {
      storage = FakeStorageManager();
      db = AppDatabase(NativeDatabase.memory());
      const emptyPort = 0;
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
      final handler = container.read(handlerProvider);
      server = await shelf_io.serve(
        handler,
        InternetAddress.loopbackIPv4,
        emptyPort,
      );
      port = server.port;
    });

    tearDownAll(() async {
      await server.close(force: true);
      await db.close();
    });

    test('GET / returns 200 via actual HTTP request', () async {
      final response = await http.get(Uri.parse('http://localhost:$port/'));

      expect(response.statusCode, equals(200));
      expect(response.body, contains('OpenCI Server (Shelf) is running!'));
    });

    test('GET /invalid-path returns 404 via actual HTTP request', () async {
      final response = await http.get(
        Uri.parse('http://localhost:$port/invalid-path'),
      );

      expect(response.statusCode, equals(404));
    });
  });
}
