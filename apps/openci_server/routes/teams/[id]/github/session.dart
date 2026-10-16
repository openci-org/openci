import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/read_github_connection_session.dart';
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

    final reference = await _readReference(context);
    if (reference == null) {
      return _error(
        HttpStatus.badRequest,
        'Invalid GitHub connection reference',
      );
    }

    final session = await readGitHubConnectionSession(
      db: context.read<AppDatabase>(),
      reference: reference,
      userId: uid,
      teamId: teamId,
    );
    if (session == null) {
      return _error(
        HttpStatus.forbidden,
        'Invalid or expired GitHub connection session',
      );
    }

    return Response.json(
      body: {
        'success': true,
        'session': {
          'teamId': session.teamId,
          'githubUserId': session.githubUserId,
          'expiresAt': session.expiresAt.toUtc().toIso8601String(),
        },
      },
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to read GitHub connection session',
    );
  }
}

Future<String?> _readReference(RequestContext context) async {
  try {
    final body = await context.jsonBody();
    final reference = body['reference'];
    return reference is String && reference.trim().isNotEmpty
        ? reference
        : null;
  } on BadRequestException {
    // JSON parsing errors can contain the reference; do not log or return them.
    return null;
  }
}

Response _error(int statusCode, String message) {
  return Response.json(
    statusCode: statusCode,
    body: {'success': false, 'error': message},
  );
}
