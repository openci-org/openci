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

Future<void> _printProcessLogs(Process process) async {
  await Future.wait([
    byteStreamToLines(process.stdout).forEach((line) {
      stdout.writeln('[STDOUT] $line');
    }),
    byteStreamToLines(process.stderr).forEach((line) {
      stderr.writeln('[STDERR] $line');
    }),
  ]);
}

@visibleForTesting
Stream<String> byteStreamToLines(Stream<List<int>> stream) =>
    stream.transform(utf8.decoder).transform(const LineSplitter());
