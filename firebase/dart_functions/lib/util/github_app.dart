import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';

import '../secret_manager.dart' show accessSecret;
import '../util/logger.dart';

/// Creates a JWT for GitHub App authentication.
String createGitHubAppJwt(String appId, String privateKey) {
  final now = DateTime.now().toUtc();
  final jwt = JWT(
    {
      'iat': now.subtract(const Duration(seconds: 60)).millisecondsSinceEpoch ~/
          1000,
      'exp': now.add(const Duration(minutes: 10)).millisecondsSinceEpoch ~/
          1000,
      'iss': appId,
    },
  );

  return jwt.sign(RSAPrivateKey(privateKey), algorithm: JWTAlgorithm.RS256);
}

/// Gets a fresh installation access token for the given installation ID.
Future<Map<String, dynamic>> getInstallationToken(int installationId) async {
  final appId = await accessSecret('GITHUB_APP_ID');
  final privateKey = await accessSecret('GITHUB_PRIVATE_KEY');
  final jwt = createGitHubAppJwt(appId, privateKey);

  final dio = Dio();
  try {
    final response = await dio.post<Map<String, dynamic>>(
      'https://api.github.com/app/installations/$installationId/access_tokens',
      options: Options(headers: {
        'Authorization': 'Bearer $jwt',
        'Accept': 'application/vnd.github+json',
      }),
    );
    return {
      'token': response.data!['token'] as String,
      'expires_at': response.data!['expires_at'] as String,
    };
  } finally {
    dio.close();
  }
}

/// Creates a new check run on GitHub.
Future<int?> createCheckRun({
  required String token,
  required String owner,
  required String repo,
  required String name,
  required String headSha,
  required String status,
  required String detailsUrl,
}) async {
  final dio = Dio();
  try {
    final response = await dio.post<Map<String, dynamic>>(
      'https://api.github.com/repos/$owner/$repo/check-runs',
      data: {
        'name': name,
        'head_sha': headSha,
        'status': status,
        'started_at': DateTime.now().toUtc().toIso8601String(),
        'details_url': detailsUrl,
      },
      options: Options(headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github+json',
      }),
    );
    return response.data?['id'] as int?;
  } catch (e) {
    logError('Failed to create check run', null, e);
    return null;
  } finally {
    dio.close();
  }
}

/// Makes an authenticated GitHub REST API call.
Future<Map<String, dynamic>> githubGet(
  String path,
  String token, {
  Map<String, dynamic>? queryParameters,
}) async {
  final dio = Dio();
  try {
    final response = await dio.get<Map<String, dynamic>>(
      'https://api.github.com$path',
      queryParameters: queryParameters,
      options: Options(headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github+json',
      }),
    );
    return response.data!;
  } finally {
    dio.close();
  }
}

/// Makes an authenticated GitHub REST API POST call.
Future<Map<String, dynamic>> githubPost(
  String path,
  String token, {
  Object? data,
}) async {
  final dio = Dio();
  try {
    final response = await dio.post<Map<String, dynamic>>(
      'https://api.github.com$path',
      data: data,
      options: Options(headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github+json',
      }),
    );
    return response.data!;
  } finally {
    dio.close();
  }
}

/// Makes an authenticated GitHub REST API PATCH call.
Future<Map<String, dynamic>> githubPatch(
  String path,
  String token, {
  Object? data,
}) async {
  final dio = Dio();
  try {
    final response = await dio.patch<Map<String, dynamic>>(
      'https://api.github.com$path',
      data: data,
      options: Options(headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github+json',
      }),
    );
    return response.data!;
  } finally {
    dio.close();
  }
}

/// Makes an authenticated GitHub REST API PUT call.
Future<Map<String, dynamic>> githubPut(
  String path,
  String token, {
  Object? data,
}) async {
  final dio = Dio();
  try {
    final response = await dio.put<Map<String, dynamic>>(
      'https://api.github.com$path',
      data: data,
      options: Options(headers: {
        'Authorization': 'token $token',
        'Accept': 'application/vnd.github+json',
      }),
    );
    return response.data!;
  } finally {
    dio.close();
  }
}

/// Makes an authenticated GitHub GraphQL query.
Future<Map<String, dynamic>> githubGraphql(
  String query,
  String token, {
  Map<String, dynamic>? variables,
}) async {
  final dio = Dio();
  try {
    final response = await dio.post<Map<String, dynamic>>(
      'https://api.github.com/graphql',
      data: {
        'query': query,
        if (variables != null) 'variables': variables,
      },
      options: Options(headers: {
        'Authorization': 'bearer $token',
        'Accept': 'application/vnd.github+json',
      }),
    );
    return response.data!;
  } finally {
    dio.close();
  }
}

/// Dashboard URL for a build job.
String buildDashboardRunUrl(String buildJobId) {
  return 'https://dashboard.openci.org/build-jobs/$buildJobId';
}
