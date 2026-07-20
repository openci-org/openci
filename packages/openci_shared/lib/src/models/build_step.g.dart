// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_step.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuildStep _$BuildStepFromJson(Map<String, dynamic> json) => _BuildStep(
  id: json['id'] as String,
  runId: json['runId'] as String,
  name: json['name'] as String,
  status: $enumDecode(_$BuildJobStatusEnumMap, json['status']),
  durationMs: (json['durationMs'] as num).toInt(),
  stepOrder: (json['stepOrder'] as num).toInt(),
  createdAt: const DateTimeConverter().fromJson(json['createdAt'] as Object),
  updatedAt: const DateTimeConverter().fromJson(json['updatedAt'] as Object),
);

Map<String, dynamic> _$BuildStepToJson(_BuildStep instance) =>
    <String, dynamic>{
      'id': instance.id,
      'runId': instance.runId,
      'name': instance.name,
      'status': _$BuildJobStatusEnumMap[instance.status]!,
      'durationMs': instance.durationMs,
      'stepOrder': instance.stepOrder,
      'createdAt': const DateTimeConverter().toJson(instance.createdAt),
      'updatedAt': const DateTimeConverter().toJson(instance.updatedAt),
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
