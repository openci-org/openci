import 'dart:async';
import 'dart:convert';

import 'package:build_job_executor/src/orchard/orchard_api_client.dart';

class OrchardVmService {
  final OrchardApiClient apiClient;

  final Map<String, OrchardLease> _activeLeases = {};

  OrchardVmService({required this.apiClient});

  String generateVmName(String jobId) {
    return 'orchard-vm-$jobId';
  }

  Future<void> prepare({
    required String baseInstanceName,
    required String containerName,
    required void Function() onCreated,
    String? os,
  }) async {
    final lease = await apiClient.createLease(
      imageName: baseInstanceName,
      vmName: containerName,
      os: os ?? 'darwin',
    );
    _activeLeases[containerName] = lease;

    final targetId = lease.id.isNotEmpty ? lease.id : containerName;
    final updatedLease = await apiClient.waitForVmRunning(
      targetId,
      timeout: const Duration(minutes: 15),
    );
    _activeLeases[containerName] = updatedLease;

    onCreated();
  }

  Future<void> cleanup(String containerName) async {
    final lease = _activeLeases.remove(containerName);
    final targetId = lease?.id.isNotEmpty == true ? lease!.id : containerName;
    try {
      await apiClient.deleteLease(targetId);
    } catch (e) {
      throw Exception('Failed to cleanup VMs: $e');
    }
  }

  Future<int> executeCommandStreaming({
    required String containerName,
    required List<String> command,
    required void Function(String line) onLog,
    required Future<bool> Function() isCancelled,
  }) async {
    final lease = _activeLeases[containerName];
    if (lease == null) {
      throw StateError('No active Orchard lease found for $containerName');
    }

    final fullCommand = command.join(' ');
    final targetVmName = lease.vmName.isNotEmpty ? lease.vmName : containerName;

    return await apiClient.execCommandWebSocket(
      vmName: targetVmName,
      command: fullCommand,
      onLog: onLog,
      isCancelled: isCancelled,
    );
  }

  Future<void> writeFile(
    String containerName,
    String filePath,
    String content, {
    String? mode,
  }) async {
    final lease = _activeLeases[containerName];
    if (lease == null) {
      throw StateError('No active Orchard lease found for $containerName');
    }

    final base64Content = base64Encode(utf8.encode(content));
    final dirPath = filePath.contains('/')
        ? filePath.substring(0, filePath.lastIndexOf('/'))
        : '';
    final mkdirCmd = dirPath.isNotEmpty ? 'mkdir -p "$dirPath" && ' : '';
    final chmodCmd = (mode != null && mode.isNotEmpty)
        ? ' && chmod $mode "$filePath"'
        : '';
    final remoteCmd =
        '${mkdirCmd}echo "$base64Content" | base64 -d > "$filePath"$chmodCmd';

    final targetVmName = lease.vmName.isNotEmpty ? lease.vmName : containerName;

    await apiClient.execCommandWebSocket(
      vmName: targetVmName,
      command: remoteCmd,
      onLog: (_) {},
      isCancelled: () async => false,
    );
  }
}
