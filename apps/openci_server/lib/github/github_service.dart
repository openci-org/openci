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

  static Future<List<Map<String, dynamic>>> listRepositories({
    required String installationIdStr,
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

    final url = '$githubApiBaseUrlStr/installation/repositories';
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'OpenCI-Server',
    };

    final response = client != null
        ? await client.get(Uri.parse(url), headers: headers)
        : await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode >= 300) {
      throw HttpException(
        'Failed to list repositories from GitHub: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final repositories = data['repositories'] as List<dynamic>? ?? [];

    return repositories.map((item) {
      final map = item as Map<String, dynamic>;
      final owner = map['owner'] as Map<String, dynamic>?;
      return {
        'fullName': map['full_name'] as String? ?? '',
        'name': map['name'] as String? ?? '',
        'owner': owner?['login'] as String? ?? '',
        'private': map['private'] as bool? ?? false,
        'defaultBranch': map['default_branch'] as String? ?? 'main',
      };
    }).toList();
  }

  static Future<List<String>> listBranches({
    required String owner,
    required String repo,
    required String installationIdStr,
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

    final url = '$githubApiBaseUrlStr/repos/$owner/$repo/branches';
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'OpenCI-Server',
    };

    final response = client != null
        ? await client.get(Uri.parse(url), headers: headers)
        : await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode >= 300) {
      throw HttpException(
        'Failed to list branches from GitHub: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) {
          final map = item as Map<String, dynamic>;
          return map['name'] as String? ?? '';
        })
        .where((name) => name.isNotEmpty)
        .toList();
  }

  static Future<String> fetchWorkflowContent({
    required String owner,
    required String repo,
    required String workflowFileName,
    required String installationIdStr,
    String? token,
    String? commitSha,
    String? branch,
    Map<String, String>? environment,
    http.Client? client,
  }) async {
    final actualToken =
        token ??
        await getInstallationToken(
          installationIdStr: installationIdStr,
          environment: environment,
          client: client,
        );

    final env = environment ?? Platform.environment;
    final githubApiBaseUrlStr =
        env['GITHUB_API_BASE_URL'] ?? 'https://api.github.com';

    final ref = commitSha ?? branch;
    final query = ref != null && ref.isNotEmpty
        ? '?ref=${Uri.encodeComponent(ref)}'
        : '';
    final url =
        '$githubApiBaseUrlStr/repos/$owner/$repo/contents/.openci/$workflowFileName$query';

    final headers = {
      'Authorization': 'Bearer $actualToken',
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'OpenCI-Server',
    };

    final response = client != null
        ? await client.get(Uri.parse(url), headers: headers)
        : await http.get(Uri.parse(url), headers: headers);

    if (response.statusCode != 200) {
      throw HttpException(
        'Failed to fetch workflow content: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = data['content'] as String?;
    if (content == null) {
      throw StateError('No content in GitHub response');
    }

    final encoding = data['encoding'] as String? ?? 'base64';
    if (encoding == 'base64') {
      final cleaned = content.replaceAll(RegExp(r'\s+'), '');
      return utf8.decode(base64.decode(cleaned));
    }

    return content;
  }
}
