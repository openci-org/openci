import 'dart:convert';
import 'dart:io';

import 'package:github/github.dart';
import 'package:http/http.dart' as http;

import 'generate_github_app_jwt.dart';

class GitHubAuthClient {
  GitHubAuthClient({
    required this.appId,
    required this.privateKeyPem,
    required this.apiBaseUrl,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client(),
       _isSelfGeneratedClient = httpClient == null;

  final String appId;
  final String privateKeyPem;
  final String apiBaseUrl;
  final http.Client _httpClient;
  final bool _isSelfGeneratedClient;

  Future<String> _getInstallationToken({
    required int installationId,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final jwtToken = generateGitHubAppJwt(
      appId: appId,
      privateKeyPem: privateKeyPem,
    );

    final tokenUrl =
        '$apiBaseUrl/app/installations/$installationId/access_tokens';
    final http.Response response;
    try {
      response = await _httpClient
          .post(
            Uri.parse(tokenUrl),
            headers: {
              'Authorization': 'Bearer $jwtToken',
              'Accept': 'application/vnd.github+json',
              'X-GitHub-Api-Version': '2022-11-28',
              'User-Agent': 'OpenCI-GitHub-Webhook-Processor',
            },
          )
          .timeout(timeout);
    } catch (e) {
      throw HttpException('Access token request timed out or failed: $e');
    }

    if (response.statusCode >= 300) {
      throw HttpException(
        'Failed to retrieve installation token: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw const FormatException(
        'Response did not contain an installation token',
      );
    }

    return token;
  }

  Future<GitHub> getInstallationClient({
    required int installationId,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final token = await _getInstallationToken(
      installationId: installationId,
      timeout: timeout,
    );

    return GitHub(
      auth: Authentication.withToken(token),
      endpoint: apiBaseUrl,
      client: _httpClient,
    );
  }

  void close() {
    if (_isSelfGeneratedClient) {
      _httpClient.close();
    }
  }
}
