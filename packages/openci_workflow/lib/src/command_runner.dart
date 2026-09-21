import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

import 'loki/log_buffer.dart';
import 'loki/push_log.dart';

Future<void> runCommand(
  String command, {
  required String workingDirectory,
}) async {
  final process = await Process.start(
    'sh',
    ['-c', command],
    workingDirectory: workingDirectory,
  );

  await _printProcessLogs(process, command: command);

  final exitCode = await process.exitCode;

  if (exitCode == 0) {
    stdout.writeln('[OK] command "$command" executed successfully');
    return;
  }
  stderr.writeln(
    '[ERROR] command "$command" failed with exit code $exitCode',
  );
  exit(exitCode);
}

Future<void> _printProcessLogs(
  Process process, {
  String? command,
}) async {
  final lokiUrl = Platform.environment['LOKI_URL'];
  final isLoki = lokiUrl != null && lokiUrl.isNotEmpty;
  final client = isLoki ? http.Client() : null;
  var forwardingFailed = false;

  Future<void> forwardStream(
    Stream<List<int>> bytes, {
    required IOSink output,
    required String stream,
  }) async {
    final buffer = isLoki
        ? LokiLogBuffer(
            sendBatch: (values) async {
              if (forwardingFailed) return;
              await pushLogsToLoki(
                client: client!,
                lokiUrl: lokiUrl,
                values: values,
                stream: stream,
                command: command,
              ).timeout(const Duration(seconds: 10));
            },
            onError: (error) {
              if (forwardingFailed) return;
              forwardingFailed = true;
              client!.close();
              stderr.writeln(
                '[WARN] Loki log forwarding stopped for this command: $error',
              );
            },
          )
        : null;

    try {
      await for (final line in byteStreamToLines(bytes)) {
        output.writeln('[${stream.toUpperCase()}] $line');
        if (!forwardingFailed) await buffer?.add(line);
      }
    } finally {
      await buffer?.close();
    }
  }

  try {
    await Future.wait([
      forwardStream(process.stdout, output: stdout, stream: 'stdout'),
      forwardStream(process.stderr, output: stderr, stream: 'stderr'),
    ]);
  } finally {
    client?.close();
  }
}

@visibleForTesting
Stream<String> byteStreamToLines(Stream<List<int>> stream) =>
    stream.transform(utf8.decoder).transform(const LineSplitter());
