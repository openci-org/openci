import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:openci_server/github/github_repository_url.dart';

Future<String> exchangeGitHubAuthorizationCode({
  required String code,
  required String codeVerifier,
  Map<String, String>? environment,
  @visibleForTesting Duration timeout = const Duration(seconds: 10),
}) async {
  final request = _createTokenRequest(
    code,
    codeVerifier,
    environment ?? Platform.environment,
  );
  final client = http.Client();
  try {
    final response = await client
        .send(request)
        .then(http.Response.fromStream)
        .timeout(timeout);
    if (response.statusCode != HttpStatus.ok) {
      throw const HttpException('Unexpected GitHub token response status');
    }
    return _readAccessToken(response.body);
  } catch (_) {
    // Upstream bodies and exception messages may contain credentials.
    throw const HttpException('Failed to exchange GitHub authorization code');
  } finally {
    client.close();
  }
}

http.Request _createTokenRequest(
  String code,
  String codeVerifier,
  Map<String, String> environment,
) {
  if (code.trim().isEmpty || codeVerifier.trim().isEmpty) {
    throw ArgumentError('GitHub code and code verifier are required');
  }
  final clientId = _requiredSetting(environment, 'GITHUB_APP_CLIENT_ID');
  final clientSecret = _requiredSetting(
    environment,
    'GITHUB_APP_CLIENT_SECRET',
  );
  final redirectUri = Uri.tryParse(
    _requiredSetting(environment, 'GITHUB_OAUTH_REDIRECT_URI'),
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
  final baseUri = Uri.parse(
    githubRepositoryBaseUrl(environment: environment),
  );
  final tokenUri = baseUri.replace(
    path: '${baseUri.path}/login/oauth/access_token',
  );

  return http.Request('POST', tokenUri)
    ..followRedirects = false
    ..headers['Accept'] = 'application/json'
    ..headers['User-Agent'] = 'OpenCI-Server'
    ..bodyFields = {
      'client_id': clientId,
      'client_secret': clientSecret,
      'redirect_uri': redirectUri.toString(),
      'code': code,
      'code_verifier': codeVerifier,
    };
}

String _requiredSetting(Map<String, String> environment, String name) {
  final value = environment[name]?.trim();
  if (value == null || value.isEmpty) {
    throw StateError('$name is not configured');
  }
  return value;
}

String _readAccessToken(String body) {
  final data = jsonDecode(body);
  if (data is! Map<String, dynamic> || data.containsKey('error')) {
    throw const FormatException('Invalid GitHub token response');
  }
  final token = data['access_token'];
  final tokenType = data['token_type'];
  if (token is! String ||
      token.isEmpty ||
      token.contains(RegExp(r'\s')) ||
      tokenType is! String ||
      tokenType.toLowerCase() != 'bearer') {
    throw const FormatException('Invalid GitHub access token');
  }
  return token;
}
