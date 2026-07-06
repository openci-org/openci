import 'dart:io';

import 'process.dart';

Future<void> stop({
  required String name,
  bool showLogs = true,
  ProcessRunner runProcess = Process.run,
}) async {
  if (showLogs) {
    print('Stopping macOS VM "$name" via Lume...');
  }

  final result = await runProcess(resolveLumeExecutable(), ['stop', name]);
  if (result.exitCode != 0) {
    throw StateError('Failed to stop VM via Lume: ${result.stderr}');
  }
  if (showLogs) {
    print('VM stopped successfully: "$name"');
  }
}
