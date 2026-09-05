import 'package:http/http.dart' as http;

import '../loki/push_log_to_loki.dart';
import 'orchard_api_client.dart';

/// Executes a command and waits for its queued Loki deliveries before returning.
/// The caller owns both clients; [onLogError] must report errors without throwing.
Future<int> executeCommand({
  required OrchardApiClient api,
  required http.Client lokiClient,
  required String lokiUrl,
  required String vmName,
  required String command,
  required String runId,
  required String jobId,
  required void Function(Object error, StackTrace stackTrace) onLogError,
  String? stepId,
  int waitSeconds = 300,
  Duration logTimeout = const Duration(seconds: 10),
}) async {
  var pendingLogs = Future<void>.value();

  try {
    return await api.execCommandWebSocket(
      vmName: vmName,
      command: command,
      waitSeconds: waitSeconds,
      onLog: (line, stream) {
        pendingLogs = pendingLogs.then((_) async {
          try {
            await pushLogToLoki(
              client: lokiClient,
              lokiUrl: lokiUrl,
              runId: runId,
              jobId: jobId,
              stepId: stepId,
              message: line,
              stream: stream,
            ).timeout(logTimeout);
          } catch (error, stackTrace) {
            onLogError(error, stackTrace);
          }
        });
      },
    );
  } finally {
    await pendingLogs;
  }
}
