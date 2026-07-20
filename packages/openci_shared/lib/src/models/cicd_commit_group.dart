import 'package:freezed_annotation/freezed_annotation.dart';

import 'build_job.dart';

part 'cicd_commit_group.freezed.dart';
part 'cicd_commit_group.g.dart';

@freezed
abstract class CicdCommitGroup with _$CicdCommitGroup {
  const factory CicdCommitGroup({
    required String branch,
    required String commitSha,
    required String commitMessage,
    required BuildJobStatus status,
    required DateTime createdAt,
    required List<CicdWorkflowGroup> workflows,
  }) = _CicdCommitGroup;

  factory CicdCommitGroup.fromJson(Map<String, Object?> json) =>
      _$CicdCommitGroupFromJson(json);
}

@freezed
abstract class CicdWorkflowGroup with _$CicdWorkflowGroup {
  const factory CicdWorkflowGroup({
    required String fileName,
    required BuildJobStatus status,
    required Duration duration,
    required List<List<CicdJobGroup>> stages,
  }) = _CicdWorkflowGroup;

  factory CicdWorkflowGroup.fromJson(Map<String, Object?> json) =>
      _$CicdWorkflowGroupFromJson(json);
}

@freezed
abstract class CicdJobGroup with _$CicdJobGroup {
  const factory CicdJobGroup({
    required String id,
    required String label,
    required BuildJobStatus status,
  }) = _CicdJobGroup;

  factory CicdJobGroup.fromJson(Map<String, Object?> json) =>
      _$CicdJobGroupFromJson(json);
}
