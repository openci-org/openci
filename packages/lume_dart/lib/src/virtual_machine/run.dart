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
    final process = await startProcess(resolveLumeExecutable(), [
      'run',
      ...args,
    ]);
    if (showLogs) {
      process.stdout.listen((data) => stdout.add(data));
      process.stderr.listen((data) => stderr.add(data));
    } else {
      process.stdout.listen((_) {});
      process.stderr.listen((_) {});
    }
    return process;
  } catch (e) {
    throw StateError('Failed to start VM via Lume: $e');
  }
}
