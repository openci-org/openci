import 'package:freezed_annotation/freezed_annotation.dart';

part 'build_job_plan.freezed.dart';
part 'build_job_plan.g.dart';

@freezed
abstract class BuildJobPlan with _$BuildJobPlan {
  // ignore: invalid_annotation_target
  @JsonSerializable(
    disallowUnrecognizedKeys: true,
    includeIfNull: false,
  )
  const factory BuildJobPlan({
    required String owner,
    required String repo,
    required String workflowName,
    required String workflowFileName,
    required String teamId,
    required String commitSha,
    required String branch,
    required String runsOn,
    required String githubBaseUrl,
    required String installationId,
    String? workflowId,
    String? commitMessage,
    int? pullRequestNumber,
    String? tagName,
    String? jobKey,
    String? workflowJobKey,
    Map<String, Object?>? matrix,
    String? matrixLabel,
    String? workflowRunId,
  }) = _BuildJobPlan;

  factory BuildJobPlan.fromJson(Map<String, Object?> json) =>
      _validatedBuildJobPlanFromJson(json);
}

BuildJobPlan _validatedBuildJobPlanFromJson(Map<String, Object?> json) {
  for (final field in _requiredStringFields) {
    final value = json[field];
    if (value is String && value.trim().isEmpty) {
      throw FormatException('$field must be a non-empty string');
    }
  }
  return _$BuildJobPlanFromJson(json);
}

const _requiredStringFields = <String>{
  'owner',
  'repo',
  'workflowName',
  'workflowFileName',
  'teamId',
  'commitSha',
  'branch',
  'runsOn',
  'githubBaseUrl',
  'installationId',
};
