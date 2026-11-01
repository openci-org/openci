import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dart_frog/dart_frog.dart';
import 'package:stacked_pr_app/src/environment.dart';
import 'package:stacked_pr_app/src/runtime.dart';

AppRuntime? _runtime;
HttpServer? _server;
final _signals = <StreamSubscription<ProcessSignal>>[];

// Dart Frog calls init once, so hot reload does not start another SQLite worker.
Future<void> init(InternetAddress ip, int port) async {
  try {
    _runtime = await AppRuntime.create();
  } catch (_) {
    stderr.writeln('Startup failed. Check configuration, App credentials, and data directory.');
    exit(1);
  }
}

Future<HttpServer> run(Handler handler, InternetAddress ip, int port) async {
  final runtime = _runtime!;
  final server = await serve(
    handler.use(provider<AppRuntime>((_) => runtime)),
    loadEnvironment()['HOST'] ?? ip,
    port,
    poweredByHeader: null,
  );
  server.idleTimeout = const Duration(seconds: 10);
  _server = server;
  if (_signals.isEmpty) {
    runtime.worker.start();
    for (final signal in [ProcessSignal.sigterm, ProcessSignal.sigint]) {
      _signals.add(
        signal.watch().listen((_) {
          unawaited(_shutdown());
        }),
      );
    }
  }
  stdout.writeln(jsonEncode({'event': 'listening', 'host': server.address.address, 'port': port}));
  return server;
}

var _stopping = false;
Future<void> _shutdown() async {
  if (_stopping) return;
  _stopping = true;
  await _server?.close(force: true);
  await _runtime?.close();
  for (final subscription in _signals) {
    await subscription.cancel();
  }
}
