// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cicd_commit_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CicdCommitGroup _$CicdCommitGroupFromJson(Map<String, dynamic> json) =>
    _CicdCommitGroup(
      branch: json['branch'] as String,
      commitSha: json['commitSha'] as String,
      commitMessage: json['commitMessage'] as String,
      status: $enumDecode(_$BuildJobStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      workflows: (json['workflows'] as List<dynamic>)
          .map((e) => CicdWorkflowGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CicdCommitGroupToJson(_CicdCommitGroup instance) =>
    <String, dynamic>{
      'branch': instance.branch,
      'commitSha': instance.commitSha,
      'commitMessage': instance.commitMessage,
      'status': _$BuildJobStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'workflows': instance.workflows,
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

_CicdWorkflowGroup _$CicdWorkflowGroupFromJson(Map<String, dynamic> json) =>
    _CicdWorkflowGroup(
      fileName: json['fileName'] as String,
      status: $enumDecode(_$BuildJobStatusEnumMap, json['status']),
      duration: Duration(microseconds: (json['duration'] as num).toInt()),
      stages: (json['stages'] as List<dynamic>)
          .map(
            (e) => (e as List<dynamic>)
                .map((e) => CicdJobGroup.fromJson(e as Map<String, dynamic>))
                .toList(),
          )
          .toList(),
    );

Map<String, dynamic> _$CicdWorkflowGroupToJson(_CicdWorkflowGroup instance) =>
    <String, dynamic>{
      'fileName': instance.fileName,
      'status': _$BuildJobStatusEnumMap[instance.status]!,
      'duration': instance.duration.inMicroseconds,
      'stages': instance.stages,
    };

_CicdJobGroup _$CicdJobGroupFromJson(Map<String, dynamic> json) =>
    _CicdJobGroup(
      id: json['id'] as String,
      label: json['label'] as String,
      status: $enumDecode(_$BuildJobStatusEnumMap, json['status']),
    );

Map<String, dynamic> _$CicdJobGroupToJson(_CicdJobGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'status': _$BuildJobStatusEnumMap[instance.status]!,
    };
