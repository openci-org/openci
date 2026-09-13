import 'orchard_api_client.dart';

/// Executes a command in the VM and returns its exit code.
Future<int> executeCommand({
  required OrchardApiClient api,
  required String vmName,
  required String command,
  int waitSeconds = 300,
}) async => api.execCommandWebSocket(
  vmName: vmName,
  command: command,
  waitSeconds: waitSeconds,
  onLog: (line, stream) {},
);
