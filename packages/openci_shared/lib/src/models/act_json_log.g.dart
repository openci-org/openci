// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'act_json_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ActJsonLog _$ActJsonLogFromJson(Map<String, dynamic> json) => _ActJsonLog(
  job: json['job'] as String?,
  jobId: json['jobID'] as String?,
  step: json['step'] as String?,
  msg: json['msg'] as String?,
  level: json['level'] as String?,
  time: _$JsonConverterFromJson<Object, DateTime>(
    json['time'],
    const DateTimeConverter().fromJson,
  ),
  stepResult: json['stepResult'] as String?,
  jobResult: json['jobResult'] as String?,
  dryrun: json['dryrun'] as bool?,
  rawOutput: json['raw_output'] as bool?,
  stage: json['stage'] as String?,
  stepId: (json['stepID'] as List<dynamic>?)?.map((e) => e as String).toList(),
  matrix: json['matrix'] as Map<String, dynamic>?,
  executionTime: const NanosecondsDurationConverter().fromJson(
    json['executionTime'],
  ),
);

Map<String, dynamic> _$ActJsonLogToJson(_ActJsonLog instance) =>
    <String, dynamic>{
      'job': instance.job,
      'jobID': instance.jobId,
      'step': instance.step,
      'msg': instance.msg,
      'level': instance.level,
      'time': _$JsonConverterToJson<Object, DateTime>(
        instance.time,
        const DateTimeConverter().toJson,
      ),
      'stepResult': instance.stepResult,
      'jobResult': instance.jobResult,
      'dryrun': instance.dryrun,
      'raw_output': instance.rawOutput,
      'stage': instance.stage,
      'stepID': instance.stepId,
      'matrix': instance.matrix,
      'executionTime': const NanosecondsDurationConverter().toJson(
        instance.executionTime,
      ),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
