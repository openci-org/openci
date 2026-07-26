import 'dart:async';
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
    final lease = await apiClient.createLease(imageName: baseInstanceName);
    _activeLeases[containerName] = lease;
    onCreated();
  }

  @override
  Future<void> cleanup(String containerName) async {
    final lease = _activeLeases.remove(containerName);
    if (lease != null && lease.id.isNotEmpty) {
      await apiClient.deleteLease(lease.id);
    }
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

    return 0;
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
  }
}
