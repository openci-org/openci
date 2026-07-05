import 'dart:io';

import 'process.dart';

Future<void> delete({
  required String name,
  bool showLogs = true,
  ProcessRunner runProcess = Process.run,
}) async {
  if (showLogs) {
    print('Deleting macOS VM "$name" via Lume...');
  }

  final result = await runProcess('lume', ['delete', name, '--force']);
  if (result.exitCode != 0) {
    throw StateError('Failed to delete VM via Lume: ${result.stderr}');
  }
  if (showLogs) {
    print('VM deleted successfully: "$name"');
  }
}
