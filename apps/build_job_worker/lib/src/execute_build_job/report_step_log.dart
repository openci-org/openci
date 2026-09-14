import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

import '../loki/push_log_to_loki.dart';

class ReportStepLog {
  const ReportStepLog({
    required http.Client lokiClient,
    required String lokiUrl,
    required String jobId,
    required String runId,
    required void Function(Object error, StackTrace stackTrace) onError,
    Duration logTimeout = const Duration(seconds: 10),
  }) : _lokiClient = lokiClient,
       _lokiUrl = lokiUrl,
       _jobId = jobId,
       _runId = runId,
       _onError = onError,
       _logTimeout = logTimeout;

  final http.Client _lokiClient;
  final String _lokiUrl;
  final String _jobId;
  final String _runId;
  final void Function(Object error, StackTrace stackTrace) _onError;
  final Duration _logTimeout;

  Future<void> send({
    required StepLog log,
    String? stepId,
    String stream = 'stdout',
  }) async {
    try {
      await pushLogToLoki(
        client: _lokiClient,
        lokiUrl: _lokiUrl,
        runId: _runId,
        jobId: _jobId,
        stepId: stepId,
        type: 'step_log',
        message: log.message,
        stream: stream,
      ).timeout(_logTimeout);
    } catch (error, stackTrace) {
      _onError(error, stackTrace);
    }
  }
}
