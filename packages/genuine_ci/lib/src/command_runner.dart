import 'dart:convert';
import 'dart:io';

Future<void> runCommand(
  String command, {
  required String workingDirectory,
}) async {
  final process = await Process.start(
    'sh',
    ['-c', command],
    workingDirectory: workingDirectory,
  );

  final stdoutDone = _pipeLines(
    process.stdout,
    (line) => stdout.writeln('[STDOUT] $line'),
  );
  final stderrDone = _pipeLines(
    process.stderr,
    (line) => stderr.writeln('[STDERR] $line'),
  );

  await Future.wait([stdoutDone, stderrDone]);

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

Future<void> _pipeLines(
  Stream<List<int>> stream,
  void Function(String line) onLine,
) {
  return stream
      .transform(utf8.decoder)
      .map((chunk) => chunk.replaceAll('\r', '\n'))
      .transform(const LineSplitter())
      .forEach(onLine);
}
