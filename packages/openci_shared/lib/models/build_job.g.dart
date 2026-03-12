// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_job.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuildJob _$BuildJobFromJson(Map<String, dynamic> json) => _BuildJob(
  id: json['id'] as String,
  status: json['status'] as String,
  owner: json['owner'] as String,
  repo: json['repo'] as String,
  teamId: json['teamId'] as String?,
  workflowId: json['workflowId'] as String?,
  workflowFileName: json['workflowFileName'] as String?,
  installationToken: json['installationToken'] as String?,
  commitSha: json['commitSha'] as String?,
  pullRequestNumber: (json['pullRequestNumber'] as num?)?.toInt(),
  runCount: (json['runCount'] as num?)?.toInt(),
  latestRunId: json['latestRunId'] as String?,
  tagName: json['tagName'] as String?,
  branch: json['branch'] as String?,
  createdAt: const DateTimeConverter().fromJson(json['createdAt']),
  updatedAt: const DateTimeConverter().fromJson(json['updatedAt']),
);

Map<String, dynamic> _$BuildJobToJson(_BuildJob instance) => <String, dynamic>{
  'id': instance.id,
  'status': instance.status,
  'owner': instance.owner,
  'repo': instance.repo,
  'teamId': instance.teamId,
  'workflowId': instance.workflowId,
  'workflowFileName': instance.workflowFileName,
  'installationToken': instance.installationToken,
  'commitSha': instance.commitSha,
  'pullRequestNumber': instance.pullRequestNumber,
  'runCount': instance.runCount,
  'latestRunId': instance.latestRunId,
  'tagName': instance.tagName,
  'branch': instance.branch,
  'createdAt': _$JsonConverterToJson<dynamic, DateTime>(
    instance.createdAt,
    const DateTimeConverter().toJson,
  ),
  'updatedAt': _$JsonConverterToJson<dynamic, DateTime>(
    instance.updatedAt,
    const DateTimeConverter().toJson,
  ),
};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
