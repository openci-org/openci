import 'dart:io';

import 'process.dart';

Future<Process> run({
  required String name,
  bool noDisplay = true,
  bool showLogs = true,
  ProcessStarter startProcess = Process.start,
}) async {
  if (showLogs) {
    print('Starting macOS VM "$name" via Lume...');
  }

  final args = <String>[];
  if (noDisplay) {
    args.add('--no-display');
  }
  args.add(name);

  try {
    return await startProcess(resolveLumeExecutable(), ['run', ...args]);
  } catch (e) {
    throw StateError('Failed to start VM via Lume: $e');
  }
}
