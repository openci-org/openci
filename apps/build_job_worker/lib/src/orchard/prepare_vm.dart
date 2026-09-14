import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'orchard_api_client.dart';

Future<OrchardLease> prepareVm({
  required OrchardApiClient api,
  required String baseVmName,
  required String vmName,
  Duration startupTimeout = const Duration(minutes: 15),
}) async {
  final lease = await api.createLease(imageName: baseVmName, vmName: vmName);
  final leaseId = lease.id.isNotEmpty ? lease.id : vmName;
  final stopwatch = Stopwatch()..start();

  try {
    final runningLease = await api.waitForVmRunning(
      leaseId,
      timeout: startupTimeout,
    );
    while (true) {
      final remaining = startupTimeout - stopwatch.elapsed;
      if (remaining <= Duration.zero) {
        throw TimeoutException(
          'Timed out waiting for SSH on Orchard VM ($leaseId).',
          startupTimeout,
        );
      }
      try {
        // Running VMs can still be booting. Probe without executing build work.
        final exitCode = await api
            .execCommandWebSocket(
              vmName: leaseId,
              command: 'true',
              onLog: (_, _) {},
              waitSeconds: min(10, max(1, remaining.inSeconds)),
            )
            .timeout(remaining);
        if (exitCode != 0) {
          throw StateError('SSH probe failed on Orchard VM ($leaseId).');
        }
        return runningLease;
      } on WebSocketException catch (error) {
        if (error.httpStatusCode != HttpStatus.serviceUnavailable) rethrow;
        final delay = startupTimeout - stopwatch.elapsed;
        if (delay > Duration.zero) {
          await Future<void>.delayed(
            delay < const Duration(seconds: 1)
                ? delay
                : const Duration(seconds: 1),
          );
        }
      }
    }
  } catch (error, stackTrace) {
    try {
      await api.deleteLease(leaseId);
    } catch (cleanupError) {
      Error.throwWithStackTrace(
        StateError(
          'Failed to prepare Orchard VM ($leaseId): $error; '
          'also failed to delete it: $cleanupError',
        ),
        stackTrace,
      );
    }
    rethrow;
  }
}
