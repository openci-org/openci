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
  time: json['time'] == null ? null : DateTime.parse(json['time'] as String),
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
      'time': instance.time?.toIso8601String(),
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
