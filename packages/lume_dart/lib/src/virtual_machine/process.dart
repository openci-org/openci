import 'dart:io';

typedef ProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

typedef ProcessStarter =
    Future<Process> Function(String executable, List<String> arguments);

String resolveLumeExecutable() {
  final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home != null) {
    final localBinLume = File('$home/.local/bin/lume');
    if (localBinLume.existsSync()) {
      return localBinLume.path;
    }
  }
  return 'lume';
}
