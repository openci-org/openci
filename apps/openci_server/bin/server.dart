import 'dart:io';

import 'package:openci_server/db.dart';
import 'package:openci_server/middleware.dart';
import 'package:openci_server/router.dart';
import 'package:openci_server/settings.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

void main(List<String> args) async {
  String databaseUrl;
  try {
    databaseUrl = loadDatabaseUrl();
  } catch (e) {
    stderr.writeln('Error loading database settings: $e');
    exit(1);
  }

  final db = DatabaseManager(databaseUrl);

  final handler = applyMiddleware(getRouter(db));

  HttpServer server;
  try {
    final serverSettings = loadServerSettings();

    server = await shelf_io.serve(
      handler,
      serverSettings.ip,
      serverSettings.port,
    );
  } catch (e) {
    stderr.writeln('Failed to start server: $e');
    exit(1);
  }
  stdout.writeln(
    'OpenCI Shelf Server listening on http://${server.address.host}:${server.port}',
  );
}
