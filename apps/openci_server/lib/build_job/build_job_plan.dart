import 'package:openci_shared/openci_shared.dart';

class BuildJobPlan {
  const BuildJobPlan({
    required this.owner,
    required this.repo,
    required this.workflowName,
    required this.workflowFileName,
    required this.teamId,
    required this.commitSha,
    required this.branch,
    required this.runsOn,
    required this.githubBaseUrl,
    required this.installationId,
    this.workflowId,
    this.commitMessage,
    this.pullRequestNumber,
    this.tagName,
    this.jobKey,
    this.workflowJobKey,
    this.matrix,
    this.matrixLabel,
    this.workflowRunId,
    this.needs,
  });

  factory BuildJobPlan.fromJson(Map<String, Object?> json) {
    final unsupportedFields = json.keys
        .where((key) => !_supportedFields.contains(key))
        .toList();
    if (unsupportedFields.isNotEmpty) {
      throw FormatException(
        'Unsupported fields: ${unsupportedFields.join(', ')}',
      );
    }

    return BuildJobPlan(
      owner: _requiredString(json, 'owner'),
      repo: _requiredString(json, 'repo'),
      workflowName: _requiredString(json, 'workflowName'),
      workflowFileName: _requiredString(json, 'workflowFileName'),
      teamId: _requiredString(json, 'teamId'),
      workflowId: _optionalString(json, 'workflowId'),
      commitSha: _requiredString(json, 'commitSha'),
      commitMessage: _optionalString(json, 'commitMessage'),
      pullRequestNumber: _optionalInt(json, 'pullRequestNumber'),
      tagName: _optionalString(json, 'tagName'),
      branch: _requiredString(json, 'branch'),
      jobKey: _optionalString(json, 'jobKey'),
      workflowJobKey: _optionalString(json, 'workflowJobKey'),
      matrix: _optionalMap(json, 'matrix'),
      matrixLabel: _optionalString(json, 'matrixLabel'),
      workflowRunId: _optionalString(json, 'workflowRunId'),
      needs: _optionalStringList(json, 'needs'),
      runsOn: _requiredString(json, 'runsOn'),
      githubBaseUrl: _requiredString(json, 'githubBaseUrl'),
      installationId: _requiredString(json, 'installationId'),
    );
  }

  static const _supportedFields = <String>{
    'owner',
    'repo',
    'workflowName',
    'workflowFileName',
    'teamId',
    'workflowId',
    'commitSha',
    'commitMessage',
    'pullRequestNumber',
    'tagName',
    'branch',
    'jobKey',
    'workflowJobKey',
    'matrix',
    'matrixLabel',
    'workflowRunId',
    'needs',
    'runsOn',
    'githubBaseUrl',
    'installationId',
  };

  final String owner;
  final String repo;
  final String workflowName;
  final String workflowFileName;
  final String teamId;
  final String? workflowId;
  final String commitSha;
  final String? commitMessage;
  final int? pullRequestNumber;
  final String? tagName;
  final String branch;
  final String? jobKey;
  final String? workflowJobKey;
  final Map<String, Object?>? matrix;
  final String? matrixLabel;
  final String? workflowRunId;
  final List<String>? needs;
  final String runsOn;
  final String githubBaseUrl;
  final String installationId;

  BuildJob createBuildJob({
    required String id,
    required DateTime timestamp,
  }) {
    return BuildJob(
      id: id,
      status: BuildJobStatus.QUEUED,
      owner: owner,
      repo: repo,
      workflowName: workflowName,
      workflowFileName: workflowFileName,
      teamId: teamId,
      workflowId: workflowId,
      commitSha: commitSha,
      commitMessage: commitMessage,
      pullRequestNumber: pullRequestNumber,
      runCount: 0,
      tagName: tagName,
      branch: branch,
      jobKey: jobKey,
      workflowJobKey: workflowJobKey,
      matrix: matrix,
      matrixLabel: matrixLabel,
      workflowRunId: workflowRunId,
      needs: needs,
      runsOn: runsOn,
      githubBaseUrl: githubBaseUrl,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }
}

String _requiredString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('$field must be a non-empty string');
  }
  return value;
}

String? _optionalString(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is! String) {
    throw FormatException('$field must be a string');
  }
  return value;
}

int? _optionalInt(Map<String, Object?> json, String field) {
  final value = json[field];
  if (value == null) return null;
  if (value is! int) {
    throw FormatException('$field must be an integer');
  }
  return value;
}

Map<String, Object?>? _optionalMap(
  Map<String, Object?> json,
  String field,
) {
  final value = json[field];
  if (value == null) return null;
  if (value is! Map) {
    throw FormatException('$field must be an object');
  }
  try {
    return Map<String, Object?>.from(value);
  } catch (_) {
    throw FormatException('$field must have string keys');
  }
}

List<String>? _optionalStringList(
  Map<String, Object?> json,
  String field,
) {
  final value = json[field];
  if (value == null) return null;
  if (value is! List || value.any((item) => item is! String)) {
    throw FormatException('$field must be a list of strings');
  }
  return value.cast<String>();
}
