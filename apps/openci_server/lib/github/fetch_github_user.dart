import 'dart:io';

import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';

Future<GitHubUser> fetchGitHubUser({
  required String accessToken,
  Map<String, String>? environment,
  @visibleForTesting Duration timeout = const Duration(seconds: 10),
}) async {
  final github = _createGitHub(
    accessToken,
    environment ?? Platform.environment,
  );
  try {
    return await github
        .getJSON<Map<String, dynamic>, GitHubUser>(
          '/user',
          statusCode: HttpStatus.ok,
          convert: _readUser,
        )
        .timeout(timeout);
  } catch (_) {
    // Response bodies and transport errors may contain private information.
    throw const HttpException('Failed to fetch GitHub user');
  } finally {
    github.dispose();
  }
}

GitHub _createGitHub(
  String accessToken,
  Map<String, String> environment,
) {
  if (accessToken.isEmpty || accessToken.contains(RegExp(r'\s'))) {
    throw ArgumentError('A valid GitHub user access token is required');
  }
  final baseUri = Uri.tryParse(
    environment['GITHUB_API_BASE_URL']?.trim() ?? '',
  );
  if (baseUri == null ||
      (baseUri.scheme != 'https' && baseUri.scheme != 'http') ||
      baseUri.host.isEmpty ||
      baseUri.userInfo.isNotEmpty ||
      baseUri.hasQuery ||
      baseUri.hasFragment) {
    throw StateError(
      'GITHUB_API_BASE_URL must be an HTTP(S) URL without credentials, query, '
      'or fragment.',
    );
  }
  final path = baseUri.path.replaceFirst(RegExp(r'/+$'), '');

  return GitHub(
    auth: Authentication.bearerToken(accessToken),
    endpoint: baseUri.replace(path: path).toString(),
    client: _NoRedirectClient(),
  );
}

GitHubUser _readUser(Map<String, dynamic> data) {
  // CurrentUser.fromJson truncates fractional IDs, so validate the raw value.
  final id = data['id'];
  final login = data['login'];
  if (id is! int || id <= 0 || login is! String || login.trim().isEmpty) {
    throw const FormatException('Invalid GitHub user');
  }
  return GitHubUser(id: id, login: login);
}

class _NoRedirectClient extends http.BaseClient {
  final _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.followRedirects = false;
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

class GitHubUser {
  const GitHubUser({required this.id, required this.login});

  final int id;
  final String login;
}
