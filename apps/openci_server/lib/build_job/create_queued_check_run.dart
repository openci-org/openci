import 'dart:io';

import 'package:drift/drift.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_service.dart';
import 'package:http/http.dart' as http;

Future<void> createQueuedCheckRun({
  required AppDatabase db,
  required DriftBuildJob job,
  Map<String, String>? environment,
  http.Client? client,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final installationId = job.installationId;
  final commitSha = job.commitSha;
  if (installationId == null ||
      installationId.isEmpty ||
      installationId == '12345678' ||
      commitSha == null ||
      commitSha.isEmpty ||
      (job.checkRunId?.isNotEmpty ?? false)) {
    return;
  }

  final githubClient = client ?? http.Client();
  final String checkRunId;
  try {
    checkRunId = await GitHubService.createGitHubCheckRun(
      owner: job.owner,
      repo: job.repo,
      installationIdStr: installationId,
      name: job.workflowName,
      headSha: commitSha,
      externalId: job.id,
      runStatus: 'queued',
      environment: environment,
      client: githubClient,
    ).timeout(timeout);
  } catch (error) {
    // The run-start endpoint retries creation when no Check ID was saved.
    stderr.writeln(
      'Failed to queue GitHub check run for job ${job.id}: $error',
    );
    return;
  } finally {
    if (client == null) githubClient.close();
  }

  await (db.update(db.buildJobs)..where((row) => row.id.equals(job.id))).write(
    BuildJobsCompanion(checkRunId: Value(checkRunId)),
  );
}
