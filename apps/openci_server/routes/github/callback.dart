import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/consume_github_connection_request.dart';
import 'package:openci_server/github/exchange_github_authorization_code.dart';
import 'package:openci_server/github/fetch_github_user.dart';
import 'package:openci_server/request/error_handler.dart';

Future<Response> onRequest(RequestContext context) async {
  final response = switch (context.request.method) {
    HttpMethod.get => await _get(context),
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

Future<Response> _get(RequestContext context) async {
  try {
    final parameters = context.request.uri.queryParametersAll;
    if (!_hasValidParameters(parameters)) {
      return _error(HttpStatus.badRequest, 'Invalid GitHub callback');
    }

    final db = context.read<AppDatabase>();
    final request = await consumeGitHubConnectionRequest(
      db: db,
      state: parameters['state']!.single,
    );
    if (request == null) {
      return _error(HttpStatus.badRequest, 'Invalid or expired GitHub state');
    }

    if (parameters.containsKey('error')) {
      return _error(HttpStatus.badRequest, 'GitHub authorization failed');
    }
    if (!await db.teamDao.isTeamMember(request.userId, request.teamId)) {
      return _error(HttpStatus.forbidden, 'Forbidden');
    }

    final environment = _environment(context);
    final accessToken = await exchangeGitHubAuthorizationCode(
      code: parameters['code']!.single,
      codeVerifier: request.codeVerifier,
      environment: environment,
    );

    try {
      await fetchGitHubUser(
        accessToken: accessToken,
        environment: environment,
      );
    } on HttpException {
      return _error(HttpStatus.badGateway, 'Failed to fetch GitHub user');
    }

    return _error(
      HttpStatus.notImplemented,
      'GitHub connection completion is not implemented yet',
    );
  } on HttpException {
    return _error(
      HttpStatus.badGateway,
      'Failed to exchange GitHub authorization code',
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to handle GitHub authorization callback',
    );
  }
}

Map<String, String> _environment(RequestContext context) {
  try {
    return context.read<Map<String, String>>();
  } catch (_) {
    return Platform.environment;
  }
}

bool _hasValidParameters(Map<String, List<String>> parameters) {
  final state = parameters['state']?.singleOrNull;
  if (state == null || state.trim().isEmpty) return false;

  if (parameters.containsKey('error')) {
    final error = parameters['error']?.singleOrNull;
    return error != null &&
        error.trim().isNotEmpty &&
        !parameters.containsKey('code');
  }

  final code = parameters['code']?.singleOrNull;
  return code != null && code.trim().isNotEmpty;
}

Response _error(int statusCode, String message) {
  return Response.json(
    statusCode: statusCode,
    body: {'success': false, 'error': message},
  );
}
