import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

String generateGitHubAppJwt(String appId, String privateKeyPem) {
  final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final jwt = JWT({
    'iat': nowSeconds - 60,
    'exp': nowSeconds + 540,
    'iss': appId.trim(),
  });
  return jwt.sign(
    RSAPrivateKey(privateKeyPem),
    algorithm: JWTAlgorithm.RS256,
  );
}

String normalizeGitHubApiBaseUrl(String? apiBaseUrl) {
  if (apiBaseUrl == null || apiBaseUrl.isEmpty) return 'https://api.github.com';
  final normalized = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  if (normalized == 'https://api.github.com' ||
      normalized == 'https://github.com' ||
      normalized == 'https://api.github.com/graphql') {
    return 'https://api.github.com';
  }
  if (normalized.endsWith('/api/v3')) return normalized;
  try {
    final uri = Uri.parse(normalized);
    if (normalized.endsWith('/api/graphql') ||
        normalized.endsWith('/graphql')) {
      return '${uri.scheme}://${uri.host}/api/v3';
    }
    return '${uri.scheme}://${uri.host}/api/v3';
  } catch (_) {
    return 'https://api.github.com';
  }
}

Future<String> getInstallationToken({
  required String installationIdStr,
  required String? githubApiBaseUrlStr,
}) async {
  final env = Platform.environment;
  final appId = env['GITHUB_APP_ID'];
  final privateKeyPath = env['GITHUB_PRIVATE_KEY_PATH'];

  if (appId == null ||
      appId.isEmpty ||
      privateKeyPath == null ||
      privateKeyPath.isEmpty) {
    throw StateError('GitHub App credentials not configured');
  }

  final privateKeyFile = File(privateKeyPath);
  if (!privateKeyFile.existsSync()) {
    throw StateError('GitHub private key file not found');
  }
  final privateKeyPem = privateKeyFile.readAsStringSync();

  final jwtToken = generateGitHubAppJwt(appId, privateKeyPem);
  final githubApiBaseUrl = normalizeGitHubApiBaseUrl(githubApiBaseUrlStr);
  final tokenUrl =
      '$githubApiBaseUrl/app/installations/$installationIdStr/access_tokens';

  final response = await http.post(
    Uri.parse(tokenUrl),
    headers: {
      'Authorization': 'Bearer $jwtToken',
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'OpenCI-Server',
    },
  );

  if (response.statusCode >= 300) {
    throw HttpException(
      'Failed to retrieve installation token from GitHub: ${response.statusCode} ${response.body}',
    );
  }

  final tokenData = jsonDecode(response.body) as Map<String, dynamic>;
  return tokenData['token'] as String;
}

Future<void> updateGitHubCheckRun({
  required String owner,
  required String repo,
  required String checkRunIdStr,
  required String installationIdStr,
  required String? githubApiBaseUrlStr,
  required String runStatus,
  String? conclusion,
}) async {
  final token = await getInstallationToken(
    installationIdStr: installationIdStr,
    githubApiBaseUrlStr: githubApiBaseUrlStr,
  );

  final githubApiBaseUrl = normalizeGitHubApiBaseUrl(githubApiBaseUrlStr);
  final checkRunUrl =
      '$githubApiBaseUrl/repos/$owner/$repo/check-runs/$checkRunIdStr';

  final patchBody = <String, dynamic>{
    'status': runStatus,
    'conclusion': ?conclusion,
    if (runStatus == 'completed')
      'completed_at': DateTime.now().toUtc().toIso8601String(),
  };

  final patchResponse = await http.patch(
    Uri.parse(checkRunUrl),
    headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'OpenCI-Server',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(patchBody),
  );

  if (patchResponse.statusCode >= 300) {
    throw HttpException(
      'Failed to update GitHub check run: ${patchResponse.statusCode} ${patchResponse.body}',
    );
  }
}
