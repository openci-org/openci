import 'dart:io';

import 'package:drift/drift.dart';
import 'package:meta/meta.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_service.dart';
import 'package:openci_server/github/parse_github_api_base_uri.dart';
import 'package:openci_server/github/read_active_github_connections.dart';
import 'package:http/http.dart' as http;

Future<void> createQueuedCheckRun({
  required AppDatabase db,
  required DriftBuildJob job,
  Map<String, String>? environment,
  http.Client? client,
  @visibleForTesting Duration timeout = const Duration(seconds: 10),
}) async {
  if (job.checkRunId?.isNotEmpty ?? false) return;

  final installationId = int.tryParse(job.installationId ?? '', radix: 10);
  final commitSha = job.commitSha;
  if (installationId == null ||
      installationId <= 0 ||
      commitSha == null ||
      commitSha.isEmpty) {
    throw StateError('A valid installationId and commitSha are required');
  }
  final teamId = job.teamId;
  if (teamId == null || teamId.isEmpty) {
    throw StateError('A team is required to create a GitHub check');
  }

  final env = environment ?? Platform.environment;
  final githubEnvironment = {
    ...env,
    'GITHUB_API_BASE_URL': parseGitHubApiBaseUri(
      env['GITHUB_API_BASE_URL'],
    ).toString(),
  };
  final connections = await readActiveGitHubConnections(
    db: db,
    teamId: teamId,
    environment: githubEnvironment,
  );
  if (!connections.any(
    (connection) => connection.installationId == installationId,
  )) {
    throw StateError('An active verified GitHub connection is required');
  }

  final githubClient = client ?? http.Client();
  final String checkRunId;
  try {
    final repositoryInstallationId =
        await GitHubService.getRepositoryInstallationId(
          owner: job.owner,
          repo: job.repo,
          environment: githubEnvironment,
          client: githubClient,
        ).timeout(timeout);
    if (repositoryInstallationId != installationId.toString()) {
      throw StateError('The repository does not match the GitHub connection');
    }

    checkRunId = await GitHubService.createGitHubCheckRun(
      owner: job.owner,
      repo: job.repo,
      installationIdStr: installationId.toString(),
      name: job.workflowName,
      headSha: commitSha,
      externalId: job.id,
      runStatus: 'queued',
      environment: githubEnvironment,
      client: githubClient,
    ).timeout(timeout);
  } finally {
    if (client == null) githubClient.close();
  }

  await (db.update(db.buildJobs)..where((row) => row.id.equals(job.id))).write(
    BuildJobsCompanion(checkRunId: Value(checkRunId)),
  );
}
