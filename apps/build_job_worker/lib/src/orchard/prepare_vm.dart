import 'orchard_api_client.dart';

Future<OrchardLease> prepareVm({
  required OrchardApiClient api,
  required String baseVmName,
  required String vmName,
  Duration startupTimeout = const Duration(minutes: 15),
}) async {
  final lease = await api.createLease(imageName: baseVmName, vmName: vmName);
  final leaseId = lease.id.isNotEmpty ? lease.id : vmName;

  try {
    return await api.waitForVmRunning(leaseId, timeout: startupTimeout);
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
