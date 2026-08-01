import 'dart:async';
import 'dart:convert';

import 'package:openci_job_processor_shared/src/orchard/orchard_api_client.dart';
import 'package:openci_job_processor_shared/src/vm/vm_service.dart';

class OrchardVmService implements VmService {
  final OrchardApiClient apiClient;

  final Map<String, OrchardLease> _activeLeases = {};

  OrchardVmService({required this.apiClient});

  @override
  String generateVmName(String jobId) {
    return 'orchard-vm-$jobId';
  }

  @override
  Future<void> prepare({
    required String baseInstanceName,
    required String containerName,
    required void Function() onCreated,
  }) async {
    final lease = await apiClient.createLease(
      imageName: baseInstanceName,
      vmName: containerName,
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

  @override
  Future<void> cleanup(String containerName) async {
    final lease = _activeLeases.remove(containerName);
    final targetId = lease?.id.isNotEmpty == true ? lease!.id : containerName;
    try {
      await apiClient.deleteLease(targetId);
    } catch (_) {}
  }

  @override
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

  @override
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
