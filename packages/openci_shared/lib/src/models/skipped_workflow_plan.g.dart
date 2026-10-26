// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'skipped_workflow_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SkippedWorkflowPlan _$SkippedWorkflowPlanFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const [
      'owner',
      'repo',
      'workflowName',
      'workflowFileName',
      'teamId',
      'commitSha',
      'installationId',
      'reason',
    ],
  );
  return _SkippedWorkflowPlan(
    owner: json['owner'] as String,
    repo: json['repo'] as String,
    workflowName: json['workflowName'] as String,
    workflowFileName: json['workflowFileName'] as String,
    teamId: json['teamId'] as String,
    commitSha: json['commitSha'] as String,
    installationId: json['installationId'] as String,
    reason: json['reason'] as String,
  );
}

Map<String, dynamic> _$SkippedWorkflowPlanToJson(
  _SkippedWorkflowPlan instance,
) => <String, dynamic>{
  'owner': instance.owner,
  'repo': instance.repo,
  'workflowName': instance.workflowName,
  'workflowFileName': instance.workflowFileName,
  'teamId': instance.teamId,
  'commitSha': instance.commitSha,
  'installationId': instance.installationId,
  'reason': instance.reason,
};
