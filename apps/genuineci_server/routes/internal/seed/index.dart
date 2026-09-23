import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:http/http.dart' as http;
import 'package:genuineci_server/database.dart';
import 'package:genuineci_server/github/github_service.dart';

// Pin the openci/worker_smoke.dart fixture for reproducible local verification.
const _smokeCommitSha = '5cb05f76d8941ea1edc3593eb753ce808f0f290e';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final db = context.read<AppDatabase>();
  try {
    Map<String, dynamic> bodyJson = {};
    try {
      bodyJson = (await context.request.json()) as Map<String, dynamic>;
    } catch (_) {
      // Body is optional
    }

    final userId =
        bodyJson['userId'] as String? ?? bodyJson['userUid'] as String?;
    final teamId = bodyJson['teamId'] as String? ?? 'test-team';
    final teamName = bodyJson['name'] as String? ?? 'Test Team';
    final owner = bodyJson['owner'] as String? ?? 'openci-org';
    final repo = bodyJson['repo'] as String? ?? 'openci';
    var installationId = bodyJson['installationId'] as String?;
    if (installationId == null) {
      Map<String, String>? environment;
      try {
        environment = context.read<Map<String, String>>();
      } catch (_) {
        // GitHubService uses the server's process configuration by default.
      }
      http.Client? client;
      try {
        client = context.read<http.Client>();
      } catch (_) {
        // GitHubService creates its own HTTP requests by default.
      }
      installationId = await GitHubService.getRepositoryInstallationId(
        owner: owner,
        repo: repo,
        environment: environment,
        client: client,
      );
    }
    final installationNumber = int.tryParse(installationId);
    if (installationNumber == null || installationNumber <= 0) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'installationId must be positive'},
      );
    }

    await db.seedDao.ensureTestTeam(
      teamId: teamId,
      name: teamName,
      userId: userId,
      installationId: installationNumber,
    );

    final job = await db.seedDao.createTestBuildJob(
      runsOn: bodyJson['runsOn'] as String? ?? 'macos-latest',
      owner: owner,
      repo: repo,
      workflowName:
          bodyJson['workflowName'] as String? ?? 'Build job worker smoke',
      workflowFileName:
          bodyJson['workflowFileName'] as String? ?? 'worker_smoke.dart',
      teamId: teamId,
      installationId: installationId,
      commitSha: bodyJson['commitSha'] as String? ?? _smokeCommitSha,
      commitMessage:
          bodyJson['commitMessage'] as String? ??
          'feat: Test build job created by seed',
      branch:
          bodyJson['branch'] as String? ?? 'test/build-job-worker-smoke-openci',
    );

    return Response.json(
      body: {
        'success': true,
        'message': 'Test team and build job seeded successfully',
        'jobId': job.id,
        'teamId': teamId,
        'runsOn': job.runsOn,
        'owner': job.owner,
        'repo': job.repo,
        'branch': job.branch,
        'workflowFileName': job.workflowFileName,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Failed to seed test team and build job: $e',
      },
    );
  }
}
