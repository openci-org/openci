import 'package:freezed_annotation/freezed_annotation.dart';

import '../utilities/nanoseconds_duration_converter.dart';

part 'act_json_log.freezed.dart';
part 'act_json_log.g.dart';

@freezed
abstract class ActJsonLog with _$ActJsonLog {
  const factory ActJsonLog({
    String? job,
    @JsonKey(name: 'jobID') String? jobId,
    String? step,
    String? msg,
    String? level,
    DateTime? time,
    String? stepResult,
    String? jobResult,
    bool? dryrun,
    @JsonKey(name: 'raw_output') bool? rawOutput,
    String? stage,
    @JsonKey(name: 'stepID') List<String>? stepId,
    Map<String, Object?>? matrix,
    @NanosecondsDurationConverter() Duration? executionTime,
  }) = _ActJsonLog;

  factory ActJsonLog.fromJson(Map<String, Object?> json) =>
      _$ActJsonLogFromJson(json);
}
