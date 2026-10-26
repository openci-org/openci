import 'package:freezed_annotation/freezed_annotation.dart';

part 'skipped_workflow_plan.freezed.dart';
part 'skipped_workflow_plan.g.dart';

@freezed
abstract class SkippedWorkflowPlan with _$SkippedWorkflowPlan {
  // ignore: invalid_annotation_target
  @JsonSerializable(disallowUnrecognizedKeys: true)
  const factory SkippedWorkflowPlan({
    required String owner,
    required String repo,
    required String workflowName,
    required String workflowFileName,
    required String teamId,
    required String commitSha,
    required String installationId,
    required String reason,
  }) = _SkippedWorkflowPlan;

  factory SkippedWorkflowPlan.fromJson(Map<String, Object?> json) =>
      _validatedSkippedWorkflowPlanFromJson(json);
}

SkippedWorkflowPlan _validatedSkippedWorkflowPlanFromJson(
  Map<String, Object?> json,
) {
  for (final field in _requiredStringFields) {
    final value = json[field];
    if (value is String && value.trim().isEmpty) {
      throw FormatException('$field must be a non-empty string');
    }
  }
  return _$SkippedWorkflowPlanFromJson(json);
}

const _requiredStringFields = <String>{
  'owner',
  'repo',
  'workflowName',
  'workflowFileName',
  'teamId',
  'commitSha',
  'installationId',
  'reason',
};
