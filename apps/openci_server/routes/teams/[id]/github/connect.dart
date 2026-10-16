import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/build_github_authorization_url.dart';
import 'package:openci_server/github/create_github_connection_request.dart';
import 'package:openci_server/request/error_handler.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _post(RequestContext context, String teamId) async {
  try {
    final uid = context.read<String?>();
    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

    final db = context.read<AppDatabase>();
    if (!await db.teamDao.isTeamMember(uid, teamId)) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    var environment = Platform.environment;
    try {
      environment = context.read<Map<String, String>>();
    } catch (_) {
      // Use the process environment when no override is provided.
    }

    final clientId = environment['GITHUB_APP_CLIENT_ID']?.trim();
    if (clientId == null || clientId.isEmpty) {
      throw StateError('GITHUB_APP_CLIENT_ID is not configured');
    }

    final redirectUri = Uri.tryParse(
      environment['GITHUB_OAUTH_REDIRECT_URI']?.trim() ?? '',
    );
    if (redirectUri == null ||
        (redirectUri.scheme != 'https' && redirectUri.scheme != 'http') ||
        redirectUri.host.isEmpty ||
        redirectUri.userInfo.isNotEmpty ||
        redirectUri.hasQuery ||
        redirectUri.hasFragment) {
      throw StateError(
        'GITHUB_OAUTH_REDIRECT_URI must be an absolute HTTP(S) URL without '
        'credentials, query, or fragment.',
      );
    }

    return await db.transaction(() async {
      final request = await createGitHubConnectionRequest(
        db: db,
        userId: uid,
        teamId: teamId,
      );
      final authorizationUrl = buildGitHubAuthorizationUrl(
        clientId: clientId,
        redirectUri: redirectUri,
        state: request.state,
        codeChallenge: request.codeChallenge,
        environment: environment,
      );

      return Response.json(
        headers: {HttpHeaders.cacheControlHeader: 'no-store'},
        body: {
          'success': true,
          'authorizationUrl': authorizationUrl.toString(),
          'expiresAt': request.expiresAt.toIso8601String(),
        },
      );
    });
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to start GitHub connection for team $teamId',
    );
  }
}
