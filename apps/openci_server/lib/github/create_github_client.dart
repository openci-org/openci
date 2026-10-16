import 'dart:io';

import 'package:github/github.dart';
import 'package:http/http.dart' as http;

GitHub createGitHubClient({
  required String accessToken,
  Map<String, String>? environment,
}) {
  if (accessToken.isEmpty || accessToken.contains(RegExp(r'\s'))) {
    throw ArgumentError('A valid GitHub user access token is required');
  }
  final baseUri = Uri.tryParse(
    (environment ?? Platform.environment)['GITHUB_API_BASE_URL']?.trim() ?? '',
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
