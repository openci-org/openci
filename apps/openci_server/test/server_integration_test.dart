import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:openci_server/middleware.dart';
import 'package:openci_server/router.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:test/test.dart';

void main() {
  group('Server Integration Tests', () {
    late HttpServer server;
    late int port;

    setUpAll(() async {
      // ポートに0を指定すると、システムが空いているポートを自動的に割り当てます
      final handler = applyMiddleware(router);
      server = await shelf_io.serve(handler, InternetAddress.loopbackIPv4, 0);
      port = server.port;
    });

    tearDownAll(() async {
      await server.close(force: true);
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
