// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repos_owner_repo_check_runs_request_body.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReposOwnerRepoCheckRunsRequestBody
_$ReposOwnerRepoCheckRunsRequestBodyFromJson(Map<String, dynamic> json) =>
    _ReposOwnerRepoCheckRunsRequestBody(
      name: json['name'] as String,
      headSha: json['head_sha'] as String,
      status: json['Status'] == null
          ? Status.queued
          : Status.fromJson(json['Status'] as String),
      detailsUrl: json['details_url'] as String?,
      externalId: json['external_id'] as String?,
      startedAt: json['started_at'] == null
          ? null
          : DateTime.parse(json['started_at'] as String),
      conclusion: json['conclusion'] == null
          ? null
          : Conclusion.fromJson(json['conclusion'] as String),
      completedAt: json['completed_at'] == null
          ? null
          : DateTime.parse(json['completed_at'] as String),
      output: json['output'] == null
          ? null
          : Output.fromJson(json['output'] as Map<String, dynamic>),
      actions: (json['actions'] as List<dynamic>?)
          ?.map((e) => Actions.fromJson(e as String))
          .toList(),
    );

Map<String, dynamic> _$ReposOwnerRepoCheckRunsRequestBodyToJson(
  _ReposOwnerRepoCheckRunsRequestBody instance,
) => <String, dynamic>{
  'name': instance.name,
  'head_sha': instance.headSha,
  'Status': _$StatusEnumMap[instance.status]!,
  'details_url': instance.detailsUrl,
  'external_id': instance.externalId,
  'started_at': instance.startedAt?.toIso8601String(),
  'conclusion': _$ConclusionEnumMap[instance.conclusion],
  'completed_at': instance.completedAt?.toIso8601String(),
  'output': instance.output,
  'actions': instance.actions?.map((e) => _$ActionsEnumMap[e]!).toList(),
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

const _$ActionsEnumMap = {
  Actions.read: 'read',
  Actions.write: 'write',
  Actions.$unknown: r'$unknown',
};
