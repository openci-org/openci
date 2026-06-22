import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;

class GitHubService {
  static String generateJwt(String appId, String privateKeyPem) {
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

  static Future<String> getInstallationToken({
    required String installationIdStr,
    Map<String, String>? environment,
    http.Client? client,
  }) async {
    final env = environment ?? Platform.environment;
    final appId = env['GITHUB_APP_ID'];
    final privateKeyPath = env['GITHUB_PRIVATE_KEY_PATH'];
    final githubApiBaseUrlStr = env['GITHUB_API_BASE_URL'];

    if (appId == null || appId.isEmpty) {
      throw StateError('GITHUB_APP_ID environment variable is not configured');
    }
    if (privateKeyPath == null || privateKeyPath.isEmpty) {
      throw StateError(
        'GITHUB_PRIVATE_KEY_PATH environment variable is not configured',
      );
    }
    if (githubApiBaseUrlStr == null || githubApiBaseUrlStr.isEmpty) {
      throw StateError(
        'GITHUB_API_BASE_URL environment variable is not configured',
      );
    }

    final privateKeyFile = File(privateKeyPath);
    if (!privateKeyFile.existsSync()) {
      throw StateError('GitHub private key file not found');
    }
    final privateKeyPem = privateKeyFile.readAsStringSync();

    final jwtToken = generateJwt(appId, privateKeyPem);
    final githubApiBaseUrl = githubApiBaseUrlStr;
    final tokenUrl =
        '$githubApiBaseUrl/app/installations/$installationIdStr/access_tokens';

    final headers = {
      'Authorization': 'Bearer $jwtToken',
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'OpenCI-Server',
    };

    final response = client != null
        ? await client.post(Uri.parse(tokenUrl), headers: headers)
        : await http.post(Uri.parse(tokenUrl), headers: headers);

    if (response.statusCode >= 300) {
      throw HttpException(
        'Failed to retrieve installation token from GitHub: ${response.statusCode} ${response.body}',
      );
    }

    final tokenData = jsonDecode(response.body) as Map<String, dynamic>;
    return tokenData['token'] as String;
  }

  static Future<void> updateGitHubCheckRun({
    required String owner,
    required String repo,
    required String checkRunIdStr,
    required String installationIdStr,
    required String runStatus,
    String? conclusion,
    Map<String, String>? environment,
    http.Client? client,
  }) async {
    final token = await getInstallationToken(
      installationIdStr: installationIdStr,
      environment: environment,
      client: client,
    );

    final env = environment ?? Platform.environment;
    final githubApiBaseUrlStr = env['GITHUB_API_BASE_URL'];
    if (githubApiBaseUrlStr == null || githubApiBaseUrlStr.isEmpty) {
      throw StateError(
        'GITHUB_API_BASE_URL environment variable is not configured',
      );
    }

    final githubApiBaseUrl = githubApiBaseUrlStr;
    final checkRunUrl =
        '$githubApiBaseUrl/repos/$owner/$repo/check-runs/$checkRunIdStr';

    final patchBody = <String, dynamic>{
      'status': runStatus,
      if (runStatus == 'completed' && conclusion != null)
        'conclusion': conclusion,
      if (runStatus == 'completed')
        'completed_at': DateTime.now().toUtc().toIso8601String(),
    };

    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'OpenCI-Server',
      'Content-Type': 'application/json',
    };

    final patchResponse = client != null
        ? await client.patch(
            Uri.parse(checkRunUrl),
            headers: headers,
            body: jsonEncode(patchBody),
          )
        : await http.patch(
            Uri.parse(checkRunUrl),
            headers: headers,
            body: jsonEncode(patchBody),
          );

    if (patchResponse.statusCode >= 300) {
      throw HttpException(
        'Failed to update GitHub check run: ${patchResponse.statusCode} ${patchResponse.body}',
      );
    }
  }
}
