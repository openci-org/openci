import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:openci_shared/converters/date_time_converter.dart';

part 'build_job.freezed.dart';
part 'build_job.g.dart';

@freezed
abstract class BuildJob with _$BuildJob {
  const factory BuildJob({
    required String id,
    required String status,
    required String owner,
    required String repo,
    String? teamId,
    String? workflowId,
    String? workflowFileName,
    String? installationToken,
    String? commitSha,
    int? pullRequestNumber,
    int? runCount,
    String? latestRunId,
    String? tagName,
    String? branch,
    String? jobKey,
    String? workflowRunId,
    List<String>? needs,
    String? githubBaseUrl,
    String? githubApiBaseUrl,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? updatedAt,
  }) = _BuildJob;

  factory BuildJob.fromJson(Map<String, dynamic> json) =>
      _$BuildJobFromJson(json);
}
