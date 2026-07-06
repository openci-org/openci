import 'dart:convert';
import 'dart:io';
import 'models.dart';
import 'process.dart';

Future<List<LumeVM>> ls({
  bool showLogs = true,
  ProcessRunner runProcess = Process.run,
}) async {
  if (showLogs) {
    print('Listing macOS VMs via Lume...');
  }

  final result = await runProcess(resolveLumeExecutable(), [
    'ls',
    '--format',
    'json',
  ]);
  if (result.exitCode != 0) {
    throw StateError('Failed to list VMs via Lume: ${result.stderr}');
  }

  final decoded = jsonDecode(result.stdout as String) as List<dynamic>;
  return decoded
      .map((item) => LumeVM.fromJson(item as Map<String, dynamic>))
      .toList();
}
