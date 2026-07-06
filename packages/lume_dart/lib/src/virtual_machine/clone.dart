import 'dart:io';

import 'process.dart';

Future<void> clone({
  required String sourceName,
  required String targetName,
  bool showLogs = true,
  ProcessRunner runProcess = Process.run,
}) async {
  if (showLogs) {
    print('Cloning macOS VM "$sourceName" to "$targetName" via Lume...');
  }

  final result = await runProcess(resolveLumeExecutable(), ['clone', sourceName, targetName]);
  if (result.exitCode != 0) {
    throw StateError('Failed to clone VM via Lume: ${result.stderr}');
  }
  if (showLogs) {
    print('VM cloned successfully: "$sourceName" -> "$targetName"');
  }
}
