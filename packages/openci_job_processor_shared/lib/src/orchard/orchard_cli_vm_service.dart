import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:logging/logging.dart';
import 'package:openci_job_processor_shared/src/vm/vm_service.dart';

class OrchardCliVmService implements VmService {
  final String orchardBinPath;
  final String? controllerUrl;
  final String? serviceAccountToken;
  final bool noPki;
  final _log = Logger('OrchardCliVmService');

  OrchardCliVmService({
    this.orchardBinPath = 'orchard',
    this.controllerUrl = 'https://127.0.0.1:6120',
    this.serviceAccountToken,
    this.noPki = true,
  });

  List<String> get _globalFlags {
    return [
      if (serviceAccountToken != null) ...[
        '--context-token',
        serviceAccountToken!,
      ],
    ];
  }

  @override
  String generateVmName(String jobId) {
    final shortId = jobId.length > 8 ? jobId.substring(0, 8) : jobId;
    return 'openci-vm-$shortId';
  }

  @override
  Future<void> prepare({
    required String baseInstanceName,
    required String containerName,
    required void Function() onCreated,
  }) async {
    _log.info(
      'Creating Orchard VM: $containerName with image $baseInstanceName',
    );

    final args = [
      'create',
      'vm',
      containerName,
      '--image',
      baseInstanceName,
      ..._globalFlags,
    ];

    final result = await Process.run(orchardBinPath, args);
    if (result.exitCode != 0) {
      throw Exception(
        'Failed to create Orchard VM ($containerName): ${result.stderr}',
      );
    }

    onCreated();
  }

  @override
  Future<void> cleanup(String containerName) async {
    _log.info('Deleting Orchard VM: $containerName');

    final args = ['delete', 'vm', containerName, ..._globalFlags];
    final result = await Process.run(orchardBinPath, args);

    if (result.exitCode != 0) {
      _log.warning(
        'Failed to delete Orchard VM ($containerName): ${result.stderr}',
      );
    }
  }

  Future<Map<String, dynamic>?> getVmInfo(String containerName) async {
    final args = ['get', 'vm', containerName, ..._globalFlags];
    final result = await Process.run(orchardBinPath, args);

    if (result.exitCode != 0) {
      return null;
    }

    try {
      final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
      return json;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<int> executeCommandStreaming({
    required String containerName,
    required List<String> command,
    required void Function(String line) onLog,
    required Future<bool> Function() isCancelled,
  }) async {
    return 0;
  }

  @override
  Future<void> writeFile(
    String containerName,
    String filePath,
    String content, {
    String? mode,
  }) async {
    // VM file write implementation
  }
}
