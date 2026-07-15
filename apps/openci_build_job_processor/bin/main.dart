import 'dart:io';
import 'package:openci_build_job_processor/openci_build_job_processor.dart';

Future<void> main() async {
  final config = ProcessorConfig.fromEnvironment();

  final rawKeyFile = File('/tmp/jump_host_key_raw');
  if (rawKeyFile.existsSync()) {
    try {
      final keyContent = rawKeyFile.readAsStringSync();
      final file = File('/tmp/jump_host_key');
      file.writeAsStringSync('${keyContent.trim()}\n');
      Process.runSync('chmod', ['600', '/tmp/jump_host_key']);
    } catch (_) {}
  } else {
    final secretFile = File('/run/secrets/jump_host_key');
    if (secretFile.existsSync()) {
      try {
        final keyContent = secretFile.readAsStringSync();
        final file = File('/tmp/jump_host_key');
        file.writeAsStringSync('${keyContent.trim()}\n');
        Process.runSync('chmod', ['600', '/tmp/jump_host_key']);
      } catch (_) {}
    } else {
      final jumpKey = Platform.environment['JUMP_HOST_PRIVATE_KEY'];
      if (jumpKey != null && jumpKey.isNotEmpty) {
        try {
          final file = File('/tmp/jump_host_key');
          file.writeAsStringSync('${jumpKey.trim()}\n');
          Process.runSync('chmod', ['600', '/tmp/jump_host_key']);
        } catch (_) {}
      }
    }
  }

  await initializeSentry(config.sentryDsn);

  final jobPoller = JobPoller(config: config);
  await jobPoller.startPolling(config.runsOnPattern);
}
