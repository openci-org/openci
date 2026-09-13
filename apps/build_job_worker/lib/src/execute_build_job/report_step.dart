import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:openci_shared/openci_shared.dart';

import '../loki/push_log_to_loki.dart';

enum _StepEntryType {
  stepEvent('step_event'),
  stepLog('step_log');

  const _StepEntryType(this.value);

  final String value;
}

Future<void> reportStep({
  required http.Client lokiClient,
  required String lokiUrl,
  required String jobId,
  required String runId,
  required BuildStep step,
  required void Function(Object error, StackTrace stackTrace) onError,
  String? logMessage,
}) async {
  for (final entry in <_StepEntryType, String>{
    _StepEntryType.stepEvent: jsonEncode(step.toJson()),
    _StepEntryType.stepLog: ?logMessage,
  }.entries) {
    try {
      await pushLogToLoki(
        client: lokiClient,
        lokiUrl: lokiUrl,
        runId: runId,
        jobId: jobId,
        stepId: step.id,
        type: entry.key.value,
        message: entry.value,
      ).timeout(const Duration(seconds: 10));
    } catch (error, stackTrace) {
      onError(error, stackTrace);
    }
  }
}
