import 'dart:convert';

import 'package:openci_shared/openci_shared.dart';

import 'plan_jobs.dart';
import 'github_webhook_payload.dart';

Future<WebhookTaskPlan> planWebhookTask({
  required WebhookTask task,
  required OpenCIApiService api,
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
    return const WebhookTaskPlan(jobs: []);
  }

  final teamResponse = await api.getTeamByInstallationId(event.installationId);
  if (teamResponse.statusCode == 404) {
    return const WebhookTaskPlan(jobs: []);
  }

  final team = teamResponse.body;
  if (!teamResponse.isSuccessful || team == null) {
    throw StateError(
      'Failed to resolve team for installation ${event.installationId}: '
      'HTTP ${teamResponse.statusCode} - ${teamResponse.error}',
    );
  }

  final filesResponse = await api.fetchOpenCIFiles(
    team.id,
    event.repo,
    event.commitSha,
    owner: event.owner,
    installationId: event.installationId,
  );
  final rawFiles = filesResponse.body;
  if (!filesResponse.isSuccessful || rawFiles == null) {
    throw StateError(
      'Failed to fetch OpenCI files for ${event.owner}/${event.repo}: '
      'HTTP ${filesResponse.statusCode} - ${filesResponse.error}',
    );
  }

  return WebhookTaskPlan(
    jobs: planJobs(
      event: event,
      teamId: team.id,
      files: rawFiles.map(OpenCIFile.fromJson),
    ),
  );
}
