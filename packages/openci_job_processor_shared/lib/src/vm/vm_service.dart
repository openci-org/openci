import 'dart:async';

abstract class VmService {
  String generateVmName(String jobId);

  Future<void> prepare({
    required String baseInstanceName,
    required String containerName,
    required void Function() onCreated,
  });

  Future<void> cleanup(String containerName);

  Future<int> executeCommandStreaming({
    required String containerName,
    required List<String> command,
    required void Function(String line) onLog,
    required Future<bool> Function() isCancelled,
  });

  Future<void> writeFile(
    String containerName,
    String filePath,
    String content, {
    String? mode,
  });
}
