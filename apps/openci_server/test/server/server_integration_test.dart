import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:openci_server/db.dart';
import 'package:openci_server/middleware.dart';
import 'package:openci_server/router.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

import '../storage/fake_storage.dart';

void main() {
  group('Server Integration Tests', () {
    late HttpServer server;
    late int port;
    late DatabaseManager db;
    late FakeStorageManager storage;

    setUpAll(() async {
      db = DatabaseManager(
        'postgres://postgres:password@localhost:5432/openci_test',
      );
      storage = FakeStorageManager();
      const emptyPort = 0;
      final handler = applyMiddleware(getRouter(db, storage));
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

    test(
      'GET /health returns 500 when database is disconnected via HTTP',
      () async {
        await db.close();

        final response = await http.get(
          Uri.parse('http://localhost:$port/health'),
        );

        expect(response.statusCode, equals(500));
        expect(response.body, contains('disconnected'));
        expect(response.body, contains('error'));
      },
    );
  });
}
