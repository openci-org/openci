import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_exception.dart';
import 'package:openci_server/github/persist_github_connection.dart';
import 'package:openci_server/github/save_github_connection_and_consume_session.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';

Future<Response> onRequest(RequestContext context, String id) async {
  final response = switch (context.request.method) {
    HttpMethod.post => await _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
  return response.copyWith(
    headers: {
      ...response.headers,
      HttpHeaders.cacheControlHeader: 'no-store',
      'Referrer-Policy': 'no-referrer',
    },
  );
}

Future<Response> _post(RequestContext context, String teamId) async {
  try {
    final uid = context.read<String?>();
    if (uid == null) {
      return _error(HttpStatus.unauthorized, 'Authentication required');
    }

    final request = await _readConfirmation(context);
    if (request == null) {
      return _error(HttpStatus.badRequest, 'Invalid GitHub connection request');
    }

    final connection = await persistGitHubConnection(
      db: context.read<AppDatabase>(),
      reference: request.reference,
      userId: uid,
      teamId: teamId,
      installationId: request.installationId,
      environment: _environment(context),
    );
    if (connection == null) {
      return _error(
        HttpStatus.conflict,
        'GitHub connection conflict',
        code: 'github_connection_conflict',
      );
    }

    return Response.json(body: {'success': true});
  } on InvalidGitHubConnectionSessionException {
    return _error(
      HttpStatus.forbidden,
      'Invalid or expired GitHub connection session',
    );
  } on GitHubConnectionException catch (error) {
    return _githubError(error.failure);
  } on HttpException {
    return _githubError(GitHubConnectionFailure.unavailable);
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to confirm GitHub connection',
    );
  }
}

Future<({String reference, int installationId})?> _readConfirmation(
  RequestContext context,
) async {
  try {
    final body = await context.jsonBody();
    final reference = body['reference'];
    final installationId = body['installationId'];
    if (body.length != 2 ||
        reference is! String ||
        reference.trim().isEmpty ||
        installationId is! int ||
        installationId <= 0) {
      return null;
    }
    return (reference: reference, installationId: installationId);
  } on BadRequestException {
    // JSON parsing errors can contain the reference; do not log or return them.
    return null;
  }
}

Map<String, String> _environment(RequestContext context) {
  try {
    return context.read<Map<String, String>>();
  } catch (_) {
    return Platform.environment;
  }
}

Response _githubError(GitHubConnectionFailure failure) => switch (failure) {
  GitHubConnectionFailure.reauthorizationRequired => _error(
    HttpStatus.conflict,
    'GitHub reauthorization required',
    code: 'github_reauthorization_required',
  ),
  GitHubConnectionFailure.permissionsRequired => _error(
    HttpStatus.forbidden,
    'GitHub permissions required',
    code: 'github_permissions_required',
  ),
  GitHubConnectionFailure.unavailable => _error(
    HttpStatus.badGateway,
    'Failed to confirm GitHub connection',
    code: 'github_unavailable',
  ),
};

Response _error(int statusCode, String message, {String? code}) =>
    Response.json(
      statusCode: statusCode,
      body: {'success': false, 'error': message, 'code': ?code},
    );
