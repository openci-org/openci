// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_run.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CheckRun _$CheckRunFromJson(Map<String, dynamic> json) => _CheckRun(
  completedAt: json['completed_at'] == null
      ? null
      : DateTime.parse(json['completed_at'] as String),
  conclusion: json['conclusion'] == null
      ? null
      : Conclusion3.fromJson(json['conclusion'] as String),
  detailsUrl: json['details_url'] as String,
  externalId: json['external_id'] as String,
  headSha: json['head_sha'] as String,
  htmlUrl: json['html_url'] as String,
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  nodeId: json['node_id'] as String,
  startedAt: DateTime.parse(json['started_at'] as String),
  status: Status7.fromJson(json['Status'] as String),
  url: json['url'] as String,
);

Map<String, dynamic> _$CheckRunToJson(_CheckRun instance) => <String, dynamic>{
  'completed_at': instance.completedAt?.toIso8601String(),
  'conclusion': _$Conclusion3EnumMap[instance.conclusion],
  'details_url': instance.detailsUrl,
  'external_id': instance.externalId,
  'head_sha': instance.headSha,
  'html_url': instance.htmlUrl,
  'id': instance.id,
  'name': instance.name,
  'node_id': instance.nodeId,
  'started_at': instance.startedAt.toIso8601String(),
  'Status': _$Status7EnumMap[instance.status]!,
  'url': instance.url,
};

const _$Conclusion3EnumMap = {
  Conclusion3.success: 'success',
  Conclusion3.failure: 'failure',
  Conclusion3.neutral: 'neutral',
  Conclusion3.cancelled: 'cancelled',
  Conclusion3.timedOut: 'timed_out',
  Conclusion3.actionRequired: 'action_required',
  Conclusion3.stale: 'stale',
  Conclusion3.valueNull: 'null',
  Conclusion3.skipped: 'skipped',
  Conclusion3.$unknown: r'$unknown',
};

const _$Status7EnumMap = {
  Status7.queued: 'queued',
  Status7.inProgress: 'in_progress',
  Status7.completed: 'completed',
  Status7.waiting: 'waiting',
  Status7.pending: 'pending',
  Status7.$unknown: r'$unknown',
};
