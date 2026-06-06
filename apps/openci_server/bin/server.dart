import 'dart:io';

import 'package:openci_server/config.dart';
import 'package:openci_server/db.dart';
import 'package:openci_server/middleware.dart';
import 'package:openci_server/router.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main(List<String> args) async {
  final databaseUrlEnv = Platform.environment['DATABASE_URL'];
  final appEnv = Platform.environment['APP_ENV'] ?? 'development';

  if (databaseUrlEnv == null && appEnv == 'production') {
    stderr.writeln(
      'Error: DATABASE_URL environment variable must be specified in production.',
    );
    exit(1);
  }

  final databaseUrl =
      databaseUrlEnv ?? 'postgres://postgres:password@localhost:5432/openci';
  if (databaseUrlEnv == null) {
    stdout.writeln(
      'Warning: DATABASE_URL is missing. Falling back to local development URL.',
    );
  }

  final db = DatabaseManager(databaseUrl);

  final handler = applyMiddleware(getRouter(db));

  HttpServer server;
  try {
    server = await shelf_io.serve(handler, ip, port);
  } catch (e) {
    stderr.writeln('Failed to start server: $e');
    exit(1);
  }
  stdout.writeln(
    'OpenCI Shelf Server listening on http://${server.address.host}:${server.port}',
  );
}
