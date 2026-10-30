import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';

Future<void> runCommand(
  String command, {
  required String workingDirectory,
}) async {
  final process = await Process.start(
    'sh',
    ['-c', command],
    workingDirectory: workingDirectory,
  );

  await _printProcessLogs(process);

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

// The executor captures these streams and persists them in SQL Connect.
Future<void> _printProcessLogs(Process process) async {
  Future<void> forward(
    Stream<List<int>> bytes,
    IOSink output,
    String stream,
  ) async {
    await for (final line in byteStreamToLines(bytes)) {
      output.writeln('[$stream] $line');
    }
  }

  await Future.wait([
    forward(process.stdout, stdout, 'STDOUT'),
    forward(process.stderr, stderr, 'STDERR'),
  ]);
}

@visibleForTesting
Stream<String> byteStreamToLines(Stream<List<int>> stream) =>
    stream.transform(utf8.decoder).transform(const LineSplitter());
