import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openci_shared/openci_shared.dart';

part 'build_step.freezed.dart';
part 'build_step.g.dart';

@freezed
abstract class BuildStep with _$BuildStep {
  const factory BuildStep({
    required String id,
    required String runId,
    required String name,
    required BuildJobStatus status,
    required int durationMs,
    required int stepOrder,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
  }) = _BuildStep;

  factory BuildStep.fromJson(Map<String, Object?> json) =>
      _$BuildStepFromJson(json);
}
