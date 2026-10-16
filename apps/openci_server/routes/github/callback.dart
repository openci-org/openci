import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/consume_github_connection_request.dart';
import 'package:openci_server/github/create_github_connection_session.dart';
import 'package:openci_server/github/exchange_github_authorization_code.dart';
import 'package:openci_server/github/fetch_github_user.dart';
import 'package:openci_server/github/parse_github_connection_return_uri.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/secret/secret_crypter.dart';

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
  Uri? returnUri;
  try {
    final environment = _environment(context);
    returnUri = parseGitHubConnectionReturnUri(
      environment['GITHUB_CONNECTION_RETURN_URL'],
    );
    final parameters = context.request.uri.queryParametersAll;
    if (!_hasValidParameters(parameters)) {
      return _redirect(returnUri, {'error': 'invalid_callback'});
    }

    final db = context.read<AppDatabase>();
    final request = await consumeGitHubConnectionRequest(
      db: db,
      state: parameters['state']!.single,
    );
    if (request == null) {
      return _redirect(returnUri, {'error': 'invalid_state'});
    }

    if (parameters.containsKey('error')) {
      final error = parameters['error']!.single == 'access_denied'
          ? 'access_denied'
          : 'connection_failed';
      return _redirect(returnUri, {'error': error});
    }
    if (!await db.teamDao.isTeamMember(request.userId, request.teamId)) {
      return _redirect(returnUri, {'error': 'forbidden'});
    }

    final crypter = _createSecretCrypter(environment);
    final accessToken = await exchangeGitHubAuthorizationCode(
      code: parameters['code']!.single,
      codeVerifier: request.codeVerifier,
      environment: environment,
    );

    final user = await fetchGitHubUser(
      accessToken: accessToken,
      environment: environment,
    );

    if (!await db.teamDao.isTeamMember(request.userId, request.teamId)) {
      return _redirect(returnUri, {'error': 'forbidden'});
    }

    final session = await createGitHubConnectionSession(
      db: db,
      crypter: crypter,
      userId: request.userId,
      teamId: request.teamId,
      githubUserId: user.id,
      accessToken: accessToken,
    );

    return _redirect(returnUri, {'reference': session.reference});
  } catch (e, s) {
    final response = await handleRouteException(
      e,
      s,
      logMessage: 'Failed to handle GitHub authorization callback',
    );
    return returnUri == null
        ? response
        : _redirect(returnUri, {'error': 'connection_failed'});
  }
}

SecretCrypter _createSecretCrypter(Map<String, String> environment) {
  try {
    return SecretCrypter(environment['SECRET_ENCRYPTION_KEY'] ?? '');
  } catch (_) {
    // Invalid key errors can include the configured secret.
    throw StateError('GitHub connection encryption is not configured');
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

Response _redirect(Uri returnUri, Map<String, String> result) {
  // Keep the result out of the Dashboard server's request URL and logs.
  final fragment = Uri(queryParameters: result).query;
  return Response(
    statusCode: HttpStatus.seeOther,
    headers: {
      HttpHeaders.locationHeader: returnUri
          .replace(fragment: fragment)
          .toString(),
    },
  );
}
