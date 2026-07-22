import 'dart:async';

import 'package:openci_build_job_processor_linux/src/incus/incus_service.dart';
import 'package:openci_job_processor_shared/openci_job_processor_shared.dart';
import 'package:sentry/sentry.dart';

class IncusVmService implements VmService {
  IncusVmService({required IncusService incusService})
    : _incusService = incusService;

  final IncusService _incusService;

  @override
  Future<void> prepare({
    required String baseInstanceName,
    required String containerName,
    required void Function() onCreated,
  }) async {
    try {
      await _incusService.stopContainer(containerName);
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }
    try {
      await _incusService.deleteContainer(containerName);
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }

    await _incusService.cloneContainer(baseInstanceName, containerName);
    onCreated();

    await _incusService.startContainer(containerName);
  }

  @override
  Future<void> cleanup(String containerName) async {
    try {
      await _incusService.stopContainer(containerName);
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }

    try {
      await _incusService.deleteContainer(containerName);
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
    }
  }

  @override
  Future<int> executeCommandStreaming({
    required String containerName,
    required List<String> command,
    required void Function(String line) onLog,
    required Future<bool> Function() isCancelled,
  }) {
    return _incusService.executeCommandStreaming(
      containerName: containerName,
      command: command,
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
  }) {
    return _incusService.writeFile(
      containerName,
      filePath,
      content,
      mode: mode ?? '0600',
    );
  }
}
