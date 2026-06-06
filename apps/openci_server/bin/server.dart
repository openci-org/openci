import 'dart:io';

import 'package:openci_server/config.dart';
import 'package:openci_server/db.dart';
import 'package:openci_server/middleware.dart';
import 'package:openci_server/router.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main(List<String> args) async {
  final databaseUrl =
      Platform.environment['DATABASE_URL'] ??
      'postgres://postgres:password@localhost:5432/openci';
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
