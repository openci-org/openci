import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/decrypt_github_connection_token.dart';
import 'package:openci_server/github/fetch_github_installations.dart';
import 'package:openci_server/github/github_connection_exception.dart';
import 'package:openci_server/github/read_github_connection_session.dart';
import 'package:openci_server/github/verify_github_installation.dart';
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

    final db = context.read<AppDatabase>();
    final session = await readGitHubConnectionSession(
      db: db,
      reference: reference,
      userId: uid,
      teamId: teamId,
    );
    if (session == null) return _invalidSession();

    final environment = _environment(context);
    final accessToken = await decryptGitHubConnectionToken(
      session.encryptedAccessToken!,
      environment,
    );
    final candidates = await fetchGitHubConnectionCandidates(
      accessToken: accessToken,
      environment: environment,
    );

    final currentSession = await readGitHubConnectionSession(
      db: db,
      reference: reference,
      userId: uid,
      teamId: teamId,
    );
    if (currentSession == null) return _invalidSession();

    return _candidatesResponse(candidates);
  } on GitHubConnectionException catch (error) {
    return _githubError(error.failure);
  } on HttpException {
    return _githubError(GitHubConnectionFailure.unavailable);
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to read GitHub connection candidates',
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

Map<String, String> _environment(RequestContext context) {
  try {
    return context.read<Map<String, String>>();
  } catch (_) {
    return Platform.environment;
  }
}

Response _candidatesResponse(List<GitHubInstallation> candidates) {
  return Response.json(
    body: {
      'success': true,
      'candidates': candidates
          .map(
            (candidate) => {
              'installationId': candidate.id,
              'accountLogin': candidate.accountLogin,
              'accountType': candidate.accountType,
            },
          )
          .toList(),
    },
  );
}

Response _invalidSession() => _error(
  HttpStatus.forbidden,
  'Invalid or expired GitHub connection session',
);

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
    'Failed to fetch GitHub connection candidates',
    code: 'github_unavailable',
  ),
};

Response _error(int statusCode, String message, {String? code}) {
  return Response.json(
    statusCode: statusCode,
    body: {'success': false, 'error': message, 'code': ?code},
  );
}
