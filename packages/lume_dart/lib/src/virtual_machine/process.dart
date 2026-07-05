import 'dart:io';

typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments,
);

typedef ProcessStarter = Future<Process> Function(
  String executable,
  List<String> arguments,
);
