import 'dart:convert';

import 'package:openci_shared/openci_shared.dart';

import 'genuine_ci_parser.dart';
import 'github_webhook_payload.dart';

Future<List<BuildJobPlan>> planWebhookTask({
  required WebhookTask task,
  required OpenCiApiService api,
}) async {
  final Map<String, dynamic> rawJson;
  try {
    rawJson = jsonDecode(task.payload) as Map<String, dynamic>;
  } catch (error) {
    throw FormatException('Invalid WebhookTask JSON payload: $error');
  }

  final event = GitHubWebhookPayload.fromRawJson(
    eventType: task.eventType,
    rawJson: rawJson,
  );
  if (event.isDeleted) {
    return const [];
  }

  final teamResponse = await api.getTeamByInstallationId(event.installationId);
  if (teamResponse.statusCode == 404) {
    return const [];
  }

  final team = teamResponse.body;
  if (!teamResponse.isSuccessful || team == null) {
    throw StateError(
      'Failed to resolve team for installation ${event.installationId}: '
      'HTTP ${teamResponse.statusCode} - ${teamResponse.error}',
    );
  }

  final filesResponse = await api.fetchGenuineCiFiles(
    team.id,
    event.repo,
    event.commitSha,
    owner: event.owner,
    installationId: event.installationId,
  );
  final rawFiles = filesResponse.body;
  if (!filesResponse.isSuccessful || rawFiles == null) {
    throw StateError(
      'Failed to fetch GenuineCI files for ${event.owner}/${event.repo}: '
      'HTTP ${filesResponse.statusCode} - ${filesResponse.error}',
    );
  }

  final matchingWorkflows = rawFiles
      .map(GenuineCiFile.fromJson)
      .map((file) => parseGenuineCiWorkflow(file.content, file.name))
      .whereType<ParsedWorkflow>()
      .where(
        (workflow) => workflow.matches(
          eventType: event.triggerType,
          branch: event.triggerBranch,
        ),
      );

  return matchingWorkflows
      .map(
        (workflow) => BuildJobPlan(
          owner: event.owner,
          repo: event.repo,
          workflowName: workflow.workflowName,
          workflowFileName: workflow.workflowFileName,
          teamId: team.id,
          commitSha: event.commitSha,
          commitMessage: event.commitMessage,
          pullRequestNumber: event.pullRequestNumber,
          branch: event.branch,
          runsOn: 'macos-latest',
          githubBaseUrl: team.githubBaseUrl ?? 'https://github.com',
          installationId: event.installationId.toString(),
        ),
      )
      .toList();
}
