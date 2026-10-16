import 'dart:io';

import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/github/parse_github_api_base_uri.dart';

GitHub createGitHubClient({
  required String accessToken,
  Map<String, String>? environment,
}) {
  if (accessToken.isEmpty || accessToken.contains(RegExp(r'\s'))) {
    throw ArgumentError('A valid GitHub user access token is required');
  }
  final baseUri = parseGitHubApiBaseUri(
    (environment ?? Platform.environment)['GITHUB_API_BASE_URL'],
  );

  return GitHub(
    auth: Authentication.bearerToken(accessToken),
    endpoint: baseUri.toString(),
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
