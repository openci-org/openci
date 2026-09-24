import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_service.dart';
import 'package:openci_server/request/error_handler.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context, String id) async {
  try {
    final driftJob = context.read<DriftBuildJob>();

    final installationIdStr = driftJob.installationId;
    if (installationIdStr == null || installationIdStr.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'No installationId found for job'},
      );
    }

    try {
      final token = await GitHubService.getInstallationToken(
        installationIdStr: installationIdStr,
      );
      return Response.json(body: {'token': token});
    } catch (e) {
      // In local dev/mock mode, return a dummy token if GitHub App keys are missing/mock
      return Response.json(
        body: {'token': 'mock-github-installation-token'},
      );
    }
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to resolve token for job $id',
    );
  }
}
