import 'dart:io';

import 'package:openci_server/environment_value/environment_value.dart';
import 'package:openci_server/router.dart';
import 'package:openci_server/storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

Future<void> main() async {
  final container = ProviderContainer();

  final EnvironmentValue envValue;
  try {
    envValue = container.read(environmentValueProvider);
  } catch (e) {
    stderr.writeln('Error loading environment values: $e');
    exit(1);
  }

  try {
    await container.read(storageProvider).initialize();
  } catch (e) {
    stderr.writeln('Failed to initialize storage connection: $e');
    container.dispose();
    exit(1);
  }

  final Handler handler;
  try {
    handler = container.read(handlerProvider);
  } catch (e) {
    stderr.writeln('Failed to build request handler: $e');
    container.dispose();
    exit(1);
  }

  HttpServer server;
  try {
    server = await shelf_io.serve(
      handler,
      envValue.host,
      envValue.port,
    );
  } catch (e) {
    stderr.writeln('Failed to start server: $e');
    container.dispose();
    exit(1);
  }
  stdout.writeln(
    'OpenCI Shelf Server listening on http://${server.address.host}:${server.port}',
  );
}
