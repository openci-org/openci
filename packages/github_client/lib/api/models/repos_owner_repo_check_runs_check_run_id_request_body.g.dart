// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repos_owner_repo_check_runs_check_run_id_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReposOwnerRepoCheckRunsCheckRunIdRequestBody
_$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyFromJson(
  Map<String, dynamic> json,
) => _ReposOwnerRepoCheckRunsCheckRunIdRequestBody(
  name: json['name'] as String?,
  detailsUrl: json['details_url'] as String?,
  externalId: json['external_id'] as String?,
  startedAt: json['started_at'] == null
      ? null
      : DateTime.parse(json['started_at'] as String),
  status: json['Status'] == null
      ? null
      : Status.fromJson(json['Status'] as String),
  conclusion: json['conclusion'] == null
      ? null
      : Conclusion.fromJson(json['conclusion'] as String),
  completedAt: json['completed_at'] == null
      ? null
      : DateTime.parse(json['completed_at'] as String),
  output: json['output'] == null
      ? null
      : Output2.fromJson(json['output'] as Map<String, dynamic>),
  actions: (json['actions'] as List<dynamic>?)
      ?.map((e) => Actions2.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ReposOwnerRepoCheckRunsCheckRunIdRequestBodyToJson(
  _ReposOwnerRepoCheckRunsCheckRunIdRequestBody instance,
) => <String, dynamic>{
  'name': instance.name,
  'details_url': instance.detailsUrl,
  'external_id': instance.externalId,
  'started_at': instance.startedAt?.toIso8601String(),
  'Status': _$StatusEnumMap[instance.status],
  'conclusion': _$ConclusionEnumMap[instance.conclusion],
  'completed_at': instance.completedAt?.toIso8601String(),
  'output': instance.output,
  'actions': instance.actions,
};

const _$StatusEnumMap = {
  Status.queued: 'queued',
  Status.inProgress: 'in_progress',
  Status.completed: 'completed',
  Status.waiting: 'waiting',
  Status.requested: 'requested',
  Status.pending: 'pending',
  Status.$unknown: r'$unknown',
};

const _$ConclusionEnumMap = {
  Conclusion.actionRequired: 'action_required',
  Conclusion.cancelled: 'cancelled',
  Conclusion.failure: 'failure',
  Conclusion.neutral: 'neutral',
  Conclusion.success: 'success',
  Conclusion.skipped: 'skipped',
  Conclusion.stale: 'stale',
  Conclusion.timedOut: 'timed_out',
  Conclusion.$unknown: r'$unknown',
};
