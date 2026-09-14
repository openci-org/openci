import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

import '../execute_build_job/report_step_log.dart';
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
  final reportStepLog = ReportStepLog(
    lokiClient: lokiClient,
    lokiUrl: lokiUrl,
    jobId: jobId,
    runId: runId,
    onError: onLogError,
    logTimeout: logTimeout,
  );
  var pendingLogs = Future<void>.value();

  try {
    return await api.execCommandWebSocket(
      vmName: vmName,
      command: command,
      waitSeconds: waitSeconds,
      onLog: (line, stream) {
        pendingLogs = pendingLogs.then(
          (_) => reportStepLog.send(
            stepId: stepId,
            log: StepLog(message: line),
            stream: stream,
          ),
        );
      },
    );
  } finally {
    await pendingLogs;
  }
}
