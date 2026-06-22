import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_service.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _post(RequestContext context, String id) async {
  try {
    final driftJob = context.read<DriftBuildJob>();

    final Map<String, dynamic> payload;
    try {
      payload = await context.jsonBody();
    } on BadRequestException catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': e.message},
      );
    }

    final runStatus = payload['runStatus'] as String?;
    if (runStatus == null || runStatus.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'runStatus is required'},
      );
    }

    final conclusion = payload['conclusion'] as String?;

    final installationIdStr = driftJob.installationId;
    final checkRunIdStr = driftJob.checkRunId;

    if (installationIdStr == null ||
        installationIdStr.isEmpty ||
        checkRunIdStr == null ||
        checkRunIdStr.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error': 'installationId or checkRunId is missing for this build job',
        },
      );
    }

    await GitHubService.updateGitHubCheckRun(
      owner: driftJob.owner,
      repo: driftJob.repo,
      checkRunIdStr: checkRunIdStr,
      installationIdStr: installationIdStr,
      runStatus: runStatus,
      conclusion: conclusion,
    );

    return Response.json(body: {'success': true});
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to update check run for job $id',
    );
  }
}
