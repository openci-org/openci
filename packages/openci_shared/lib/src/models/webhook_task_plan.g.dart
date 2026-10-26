// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webhook_task_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WebhookTaskPlan _$WebhookTaskPlanFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const [
      'jobs',
      'skippedWorkflows',
      'changedFilesFallbackReason',
    ],
    disallowNullValues: const ['skippedWorkflows'],
  );
  return _WebhookTaskPlan(
    jobs: (json['jobs'] as List<dynamic>)
        .map((e) => BuildJobPlan.fromJson(e as Map<String, dynamic>))
        .toList(),
    skippedWorkflows:
        (json['skippedWorkflows'] as List<dynamic>?)
            ?.map(
              (e) => SkippedWorkflowPlan.fromJson(e as Map<String, dynamic>),
            )
            .toList() ??
        const <SkippedWorkflowPlan>[],
    changedFilesFallbackReason: json['changedFilesFallbackReason'] as String?,
  );
}

Map<String, dynamic> _$WebhookTaskPlanToJson(
  _WebhookTaskPlan instance,
) => <String, dynamic>{
  'jobs': instance.jobs.map((e) => e.toJson()).toList(),
  'skippedWorkflows': instance.skippedWorkflows.map((e) => e.toJson()).toList(),
  'changedFilesFallbackReason': ?instance.changedFilesFallbackReason,
};
