import 'package:freezed_annotation/freezed_annotation.dart';

part 'step_log.freezed.dart';
part 'step_log.g.dart';

@freezed
abstract class StepLog with _$StepLog {
  const factory StepLog({
    required String message,
  }) = _StepLog;

  factory StepLog.fromJson(Map<String, Object?> json) =>
      _$StepLogFromJson(json);
}
