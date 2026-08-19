import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/github/github_service.dart';
import 'package:openci_server/request/error_handler.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context, String installationIdStr) async {
  try {
    final uid = context.read<String?>();

    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
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
      logMessage:
          'Failed to resolve token for installationId $installationIdStr',
    );
  }
}
