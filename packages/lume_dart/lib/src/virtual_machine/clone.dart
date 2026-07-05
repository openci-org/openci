import 'dart:io';

Future<ProcessResult> Function(String, List<String>) runProcess = Process.run;

Future<void> clone({
  required String sourceName,
  required String targetName,
  bool showLogs = true,
}) async {
  if (showLogs) {
    print('Cloning macOS VM "$sourceName" to "$targetName" via Lume...');
  }

  final result = await runProcess('lume', ['clone', sourceName, targetName]);
  if (result.exitCode != 0) {
    throw StateError('Failed to clone VM via Lume: ${result.stderr}');
  }
  if (showLogs) {
    print('VM cloned successfully: "$sourceName" -> "$targetName"');
  }
}
