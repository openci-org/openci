import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef PubProcessRunner =
    Future<int> Function(
      String executable,
      List<String> arguments, {
      required String workingDirectory,
      required Map<String, String> environment,
      required List<String> secrets,
      required Duration timeout,
    });

/// Runs pub without a shell, keeping newly generated credentials out of logs.
Future<int> runPubProcess(
  String executable,
  List<String> arguments, {
  required String workingDirectory,
  required Map<String, String> environment,
  required List<String> secrets,
  required Duration timeout,
}) async {
  final Process process;
  try {
    process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
    );
  } on ProcessException {
    throw StateError('Could not start Dart. Make sure dart is on PATH.');
  }
  final sensitive = secrets.where((value) => value.isNotEmpty).toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  String redact(String line) {
    for (final secret in sensitive) {
      line = line.replaceAll(secret, '[REDACTED]');
    }
    return line;
  }

  final subscriptions = <StreamSubscription<String>>[];
  Future<void> forward(Stream<List<int>> input, IOSink output) {
    final done = Completer<void>();
    subscriptions.add(
      input
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .listen(
            (line) => output.writeln(redact(line)),
            onDone: done.complete,
            onError: (Object error, StackTrace stack) =>
                done.completeError(error, stack),
          ),
    );
    return done.future;
  }

  try {
    await process.stdin.close();
    final results = await Future.wait<Object?>([
      process.exitCode,
      forward(process.stdout, stdout),
      forward(process.stderr, stderr),
    ]).timeout(timeout);
    return results.first as int;
  } on TimeoutException {
    process.kill(ProcessSignal.sigkill);
    try {
      await process.exitCode.timeout(const Duration(seconds: 5));
    } catch (_) {
      // Preserve the original timeout even if the process cannot be reaped.
    }
    throw TimeoutException(
      'Dart pub timed out. A publication may already have been accepted; '
      'check pub.dev before retrying.',
      timeout,
    );
  } finally {
    for (final subscription in subscriptions) {
      await subscription.cancel();
    }
  }
}
