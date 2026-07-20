// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuildJob _$BuildJobFromJson(Map<String, dynamic> json) => _BuildJob(
  id: json['id'] as String,
  status: $enumDecode(_$BuildJobStatusEnumMap, json['status']),
  owner: json['owner'] as String,
  repo: json['repo'] as String,
  workflowName: json['workflowName'] as String,
  teamId: json['teamId'] as String?,
  workflowId: json['workflowId'] as String?,
  workflowFileName: json['workflowFileName'] as String?,
  commitSha: json['commitSha'] as String?,
  commitMessage: json['commitMessage'] as String?,
  pullRequestNumber: (json['pullRequestNumber'] as num?)?.toInt(),
  runCount: (json['runCount'] as num?)?.toInt(),
  latestRunId: json['latestRunId'] as String?,
  tagName: json['tagName'] as String?,
  branch: json['branch'] as String?,
  jobKey: json['jobKey'] as String?,
  workflowJobKey: json['workflowJobKey'] as String?,
  matrix: json['matrix'] as Map<String, dynamic>?,
  matrixLabel: json['matrixLabel'] as String?,
  workflowRunId: json['workflowRunId'] as String?,
  needs: (json['needs'] as List<dynamic>?)?.map((e) => e as String).toList(),
  runsOn: json['runsOn'] as String?,
  failureSummary: json['failureSummary'] as String?,
  failureSummaryModel: json['failureSummaryModel'] as String?,
  failureSummaryStatus: json['failureSummaryStatus'] as String?,
  failureSummaryDurationMs: (json['failureSummaryDurationMs'] as num?)?.toInt(),
  provisionedUdids: (json['provisionedUdids'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  ipaUrl: json['ipaUrl'] as String?,
  hasIpa: json['hasIpa'] as bool?,
  bundleId: json['bundleId'] as String?,
  ipaVersion: json['ipaVersion'] as String?,
  appName: json['appName'] as String?,
  githubBaseUrl: json['githubBaseUrl'] as String?,
  createdAt: const DateTimeConverter().fromJson(json['createdAt'] as Object),
  updatedAt: const DateTimeConverter().fromJson(json['updatedAt'] as Object),
  completedAt: _$JsonConverterFromJson<Object, DateTime>(
    json['completedAt'],
    const DateTimeConverter().fromJson,
  ),
);

Map<String, dynamic> _$BuildJobToJson(_BuildJob instance) => <String, dynamic>{
  'id': instance.id,
  'status': _$BuildJobStatusEnumMap[instance.status]!,
  'owner': instance.owner,
  'repo': instance.repo,
  'workflowName': instance.workflowName,
  'teamId': instance.teamId,
  'workflowId': instance.workflowId,
  'workflowFileName': instance.workflowFileName,
  'commitSha': instance.commitSha,
  'commitMessage': instance.commitMessage,
  'pullRequestNumber': instance.pullRequestNumber,
  'runCount': instance.runCount,
  'latestRunId': instance.latestRunId,
  'tagName': instance.tagName,
  'branch': instance.branch,
  'jobKey': instance.jobKey,
  'workflowJobKey': instance.workflowJobKey,
  'matrix': instance.matrix,
  'matrixLabel': instance.matrixLabel,
  'workflowRunId': instance.workflowRunId,
  'needs': instance.needs,
  'runsOn': instance.runsOn,
  'failureSummary': instance.failureSummary,
  'failureSummaryModel': instance.failureSummaryModel,
  'failureSummaryStatus': instance.failureSummaryStatus,
  'failureSummaryDurationMs': instance.failureSummaryDurationMs,
  'provisionedUdids': instance.provisionedUdids,
  'ipaUrl': instance.ipaUrl,
  'hasIpa': instance.hasIpa,
  'bundleId': instance.bundleId,
  'ipaVersion': instance.ipaVersion,
  'appName': instance.appName,
  'githubBaseUrl': instance.githubBaseUrl,
  'createdAt': const DateTimeConverter().toJson(instance.createdAt),
  'updatedAt': const DateTimeConverter().toJson(instance.updatedAt),
  'completedAt': _$JsonConverterToJson<Object, DateTime>(
    instance.completedAt,
    const DateTimeConverter().toJson,
  ),
};

const _$BuildJobStatusEnumMap = {
  BuildJobStatus.WAITING: 'WAITING',
  BuildJobStatus.QUEUED: 'QUEUED',
  BuildJobStatus.IN_PROGRESS: 'IN_PROGRESS',
  BuildJobStatus.SUCCESS: 'SUCCESS',
  BuildJobStatus.FAILURE: 'FAILURE',
  BuildJobStatus.CANCELLED: 'CANCELLED',
  BuildJobStatus.SKIPPED: 'SKIPPED',
  BuildJobStatus.TIMED_OUT: 'TIMED_OUT',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
