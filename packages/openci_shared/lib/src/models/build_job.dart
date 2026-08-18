import 'package:freezed_annotation/freezed_annotation.dart';

import '../utilities/date_time_converter.dart';

part 'build_job.freezed.dart';
part 'build_job.g.dart';

enum BuildJobStatus {
  // ignore: constant_identifier_names
  WAITING,
  // ignore: constant_identifier_names
  QUEUED,
  // ignore: constant_identifier_names
  IN_PROGRESS,
  // ignore: constant_identifier_names
  SUCCESS,
  // ignore: constant_identifier_names
  FAILURE,
  // ignore: constant_identifier_names
  CANCELLED,
  // ignore: constant_identifier_names
  SKIPPED,
  // ignore: constant_identifier_names
  TIMED_OUT,
}

@freezed
abstract class BuildJob with _$BuildJob {
  const BuildJob._();

  const factory BuildJob({
    required String id,
    required BuildJobStatus status,
    required String owner,
    required String repo,
    required String workflowName,
    required String workflowFileName,
    String? teamId,
    String? workflowId,
    String? commitSha,
    String? commitMessage,
    int? pullRequestNumber,
    int? runCount,
    String? latestRunId,
    String? tagName,
    String? branch,
    String? jobKey,
    String? workflowJobKey,
    Map<String, Object?>? matrix,
    String? matrixLabel,
    String? workflowRunId,
    List<String>? needs,
    String? runsOn,
    String? failureSummary,
    String? failureSummaryModel,
    String? failureSummaryStatus,
    int? failureSummaryDurationMs,
    List<String>? provisionedUdids,
    String? ipaUrl,
    bool? hasIpa,
    String? bundleId,
    String? ipaVersion,
    String? appName,
    String? githubBaseUrl,
    String? vmName,
    String? workerHost,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
    @DateTimeConverter() DateTime? completedAt,
  }) = _BuildJob;

  factory BuildJob.fromJson(Map<String, Object?> json) =>
      _$BuildJobFromJson(json);

  String? get displayMatrixLabel {
    if (matrixLabel != null && matrixLabel!.isNotEmpty) {
      return matrixLabel;
    }
    if (matrix == null || matrix!.isEmpty) {
      return null;
    }
    if (matrix!.containsKey('name') && matrix!['name'] is String) {
      return matrix!['name'] as String;
    }
    return matrix!.values.map((v) => v.toString()).join(' / ');
  }
}
