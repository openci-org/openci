import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';

Future<Response> onRequest(RequestContext context) async {
  if (context.request.method != HttpMethod.post) {
    return Response(statusCode: HttpStatus.methodNotAllowed);
  }

  final db = context.read<AppDatabase>();
  try {
    await db.seedDao.ensureTestTeam();

    Map<String, dynamic> bodyJson = {};
    try {
      bodyJson = (await context.request.json()) as Map<String, dynamic>;
    } catch (_) {
      // Body is optional
    }

    final customScript = bodyJson['customScript'] as String?;

    final job = await db.seedDao.createTestBuildJob(
      runsOn: bodyJson['runsOn'] as String? ?? 'macos-latest',
      owner: bodyJson['owner'] as String? ?? 'openci-org',
      repo: bodyJson['repo'] as String? ?? 'openci',
      workflowName: bodyJson['workflowName'] as String? ?? 'Test Workflow',
      workflowFileName: bodyJson['workflowFileName'] as String? ?? 'ci.yml',
      teamId: bodyJson['teamId'] as String? ?? 'test-team',
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
        'message': 'Test team and build job seeded successfully',
        'jobId': job.id,
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
        'error': 'Failed to seed test team: $e',
      },
    );
  }
}
