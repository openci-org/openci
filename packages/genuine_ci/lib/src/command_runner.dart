import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

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
  final client = isLoki ? HttpClient() : null;
  final lokiTasks = <Future<void>>[];

  try {
    final stdoutDone = byteStreamToLines(process.stdout).forEach((line) {
      stdout.writeln('[STDOUT] $line');
      if (isLoki) {
        lokiTasks.add(
          pushLogToLoki(
            client: client!,
            lokiUrl: lokiUrl,
            message: line,
            stream: 'stdout',
            command: command,
          ),
        );
      }
    });

    final stderrDone = byteStreamToLines(process.stderr).forEach((line) {
      stderr.writeln('[STDERR] $line');
      if (isLoki) {
        lokiTasks.add(
          pushLogToLoki(
            client: client!,
            lokiUrl: lokiUrl,
            message: line,
            stream: 'stderr',
            command: command,
          ),
        );
      }
    });

    await Future.wait([stdoutDone, stderrDone]);
    if (lokiTasks.isNotEmpty) {
      await Future.wait(lokiTasks);
    }
  } finally {
    client?.close();
  }
}

@visibleForTesting
Stream<String> byteStreamToLines(Stream<List<int>> stream) =>
    stream.transform(utf8.decoder).transform(const LineSplitter());
