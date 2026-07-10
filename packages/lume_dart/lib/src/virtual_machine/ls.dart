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

  return parseLumeVms(result.stdout as String);
}

List<LumeVM> parseLumeVms(String stdoutStr) {
  final lines = LineSplitter.split(stdoutStr);
  final jsonLines = <String>[];
  final logPattern = RegExp(
    r'^\[\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z\]',
  );

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    if (logPattern.hasMatch(trimmed)) {
      continue;
    }
    jsonLines.add(line);
  }

  final jsonStr = jsonLines.join('\n').trim();
  if (jsonStr.isEmpty) {
    throw FormatException('No JSON output found in Lume output: $stdoutStr');
  }

  final decoded = jsonDecode(jsonStr) as List<dynamic>;
  return decoded
      .map((item) => LumeVM.fromJson(item as Map<String, dynamic>))
      .toList();
}
