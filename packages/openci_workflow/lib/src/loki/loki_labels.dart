import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

part 'loki_labels.freezed.dart';

@freezed
abstract class LokiLabels with _$LokiLabels {
  const factory LokiLabels({
    required String stream,
    @Default('step_log') String type,
    String? command,
    String? runId,
    String? buildJobId,
    String? stepId,
  }) = _LokiLabels;

  const LokiLabels._();

  factory LokiLabels.fromEnvironment({
    required String stream,
    String? command,
  }) {
    return LokiLabels(
      stream: stream,
      command: command,
      runId: Platform.environment['GENUINE_CI_RUN_ID'],
      buildJobId: Platform.environment['GENUINE_CI_BUILD_JOB_ID'],
      stepId: Platform.environment['GENUINE_CI_STEP_ID'],
    );
  }

  Map<String, String> toLabelsMap() {
    final map = <String, String>{
      'stream': stream,
      'type': type,
    };
    if (command != null) map['command'] = command!;
    if (runId != null) map['run_id'] = runId!;
    if (buildJobId != null) map['build_job_id'] = buildJobId!;
    if (stepId != null) map['step_id'] = stepId!;
    return map;
  }
}
