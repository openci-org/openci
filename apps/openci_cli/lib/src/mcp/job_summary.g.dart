// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JobSummary _$JobSummaryFromJson(Map<String, dynamic> json) => JobSummary(
  id: json['job_id'] as String,
  workflowName: json['workflow'] as String,
  status: json['status'] as String,
  commitSha: json['commit_sha'] as String?,
  matrixLabel: json['matrix_label'] as String?,
  latestRunId: json['latest_run_id'] as String?,
  retryCount: JobSummary._readRetryCount(json['retry_count']),
  recentRuns: JobSummary._readRecentRuns(json['recent_runs']),
);

const _$JobSummaryFieldMap = <String, String>{
  'id': 'job_id',
  'workflowName': 'workflow',
  'status': 'status',
  'commitSha': 'commit_sha',
  'matrixLabel': 'matrix_label',
  'latestRunId': 'latest_run_id',
  'retryCount': 'retry_count',
  'recentRuns': 'recent_runs',
};

Map<String, dynamic> _$JobSummaryToJson(JobSummary instance) =>
    <String, dynamic>{
      'job_id': instance.id,
      'workflow': instance.workflowName,
      'status': instance.status,
      'commit_sha': instance.commitSha,
      'matrix_label': ?instance.matrixLabel,
      'latest_run_id': ?instance.latestRunId,
      'retry_count': ?instance.retryCount,
      'recent_runs': ?instance.recentRuns,
    };
