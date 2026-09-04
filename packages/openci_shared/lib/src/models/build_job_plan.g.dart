// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'build_job_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BuildJobPlan _$BuildJobPlanFromJson(Map<String, dynamic> json) {
  $checkKeys(
    json,
    allowedKeys: const [
      'owner',
      'repo',
      'workflowName',
      'workflowFileName',
      'teamId',
      'commitSha',
      'branch',
      'runsOn',
      'githubBaseUrl',
      'installationId',
      'workflowId',
      'commitMessage',
      'pullRequestNumber',
      'tagName',
      'jobKey',
      'workflowJobKey',
      'matrix',
      'matrixLabel',
      'workflowRunId',
    ],
  );
  return _BuildJobPlan(
    owner: json['owner'] as String,
    repo: json['repo'] as String,
    workflowName: json['workflowName'] as String,
    workflowFileName: json['workflowFileName'] as String,
    teamId: json['teamId'] as String,
    commitSha: json['commitSha'] as String,
    branch: json['branch'] as String,
    runsOn: json['runsOn'] as String,
    githubBaseUrl: json['githubBaseUrl'] as String,
    installationId: json['installationId'] as String,
    workflowId: json['workflowId'] as String?,
    commitMessage: json['commitMessage'] as String?,
    pullRequestNumber: (json['pullRequestNumber'] as num?)?.toInt(),
    tagName: json['tagName'] as String?,
    jobKey: json['jobKey'] as String?,
    workflowJobKey: json['workflowJobKey'] as String?,
    matrix: json['matrix'] as Map<String, dynamic>?,
    matrixLabel: json['matrixLabel'] as String?,
    workflowRunId: json['workflowRunId'] as String?,
  );
}

Map<String, dynamic> _$BuildJobPlanToJson(_BuildJobPlan instance) =>
    <String, dynamic>{
      'owner': instance.owner,
      'repo': instance.repo,
      'workflowName': instance.workflowName,
      'workflowFileName': instance.workflowFileName,
      'teamId': instance.teamId,
      'commitSha': instance.commitSha,
      'branch': instance.branch,
      'runsOn': instance.runsOn,
      'githubBaseUrl': instance.githubBaseUrl,
      'installationId': instance.installationId,
      'workflowId': ?instance.workflowId,
      'commitMessage': ?instance.commitMessage,
      'pullRequestNumber': ?instance.pullRequestNumber,
      'tagName': ?instance.tagName,
      'jobKey': ?instance.jobKey,
      'workflowJobKey': ?instance.workflowJobKey,
      'matrix': ?instance.matrix,
      'matrixLabel': ?instance.matrixLabel,
      'workflowRunId': ?instance.workflowRunId,
    };
