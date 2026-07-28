import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';

Future<Response> onRequest(RequestContext context) async {
  final db = context.read<AppDatabase>();

  if (context.request.method == HttpMethod.delete) {
    try {
      final teamId = context.request.uri.queryParameters['teamId'];
      if (teamId != null && teamId.isNotEmpty) {
        await (db.delete(
          db.buildJobs,
        )..where((j) => j.teamId.equals(teamId))).go();
      } else {
        await db.delete(db.buildJobs).go();
      }
      return Response.json(
        body: {
          'success': true,
          'message': 'Build jobs cleared successfully',
        },
      );
    } catch (e) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {
          'success': false,
          'error': 'Failed to clear build jobs: $e',
        },
      );
    }
  }

  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

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

    await db.seedDao.ensureTestTeam(
      teamId: teamId,
      userId: userId,
    );

    final customScript = bodyJson['customScript'] as String?;
    final workflowYaml = bodyJson['workflowYaml'] as String?;

    final job = await db.seedDao.createTestBuildJob(
      runsOn: bodyJson['runsOn'] as String? ?? 'macos-latest',
      owner: bodyJson['owner'] as String? ?? 'openci-org',
      repo: bodyJson['repo'] as String? ?? 'openci',
      workflowName: bodyJson['workflowName'] as String? ?? 'Test Workflow',
      workflowFileName: bodyJson['workflowFileName'] as String? ?? 'ci.yml',
      teamId: teamId,
      installationId: bodyJson['installationId'] as String? ?? '12345678',
      commitSha: bodyJson['commitSha'] as String? ?? 'main',
      commitMessage:
          bodyJson['commitMessage'] as String? ??
          'feat: Test build job created by seed',
      branch: bodyJson['branch'] as String? ?? 'main',
      customScript: customScript,
    );

    return Response.json(
      body: {
        'success': true,
        'message': 'Test build job created successfully',
        'jobId': job.id,
        'teamId': job.teamId,
        'runsOn': job.runsOn,
        'owner': job.owner,
        'repo': job.repo,
        'branch': job.branch,
        'workflowFileName': job.workflowFileName,
        'workflowYaml': ?workflowYaml,
      },
    );
  } catch (e) {
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {
        'success': false,
        'error': 'Failed to create test build job: $e',
      },
    );
  }
}
