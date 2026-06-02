import 'dart:convert';
import 'dart:io';

import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:gcp_secret_manager/gcp_secret_manager.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:openci_shared/openci_shared.dart';

const workerOptions = HttpsOptions(
  region: Region(SupportedRegion.asiaNortheast1),
);

// Map 内の Timestamp 型やその他の非シリアライズ可能オブジェクトをシリアライズ可能な型に変換する
dynamic sanitizeForJson(dynamic value) {
  if (value is Map) {
    return value.map((k, v) => MapEntry(k as String, sanitizeForJson(v)));
  } else if (value is List) {
    return value.map(sanitizeForJson).toList();
  } else if (value is Timestamp) {
    return value.toDate().toUtc().toIso8601String();
  } else if (value is DateTime) {
    return value.toUtc().toIso8601String();
  }
  return value;
}

// HTTP レスポンス用の共通ヘルパー
Response jsonResponse(Map<String, dynamic> data, {int status = 200}) {
  return Response(
    status,
    body: jsonEncode(sanitizeForJson(data)),
    headers: {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
    },
  );
}

Response optionsResponse() {
  return Response(
    204,
    headers: {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Headers': 'Content-Type, Authorization',
      'Access-Control-Allow-Methods': 'POST, OPTIONS',
    },
  );
}

// 認証トークンの検証処理（簡易版 & エミュレータバイパス）
bool verifyAuth(Request request) {
  final isEmulator =
      const bool.fromEnvironment('FUNCTIONS_EMULATOR') ||
      const String.fromEnvironment('FUNCTIONS_EMULATOR') == 'true';
  if (isEmulator) {
    return true;
  }

  final authHeader =
      request.headers['Authorization'] ?? request.headers['authorization'];
  if (authHeader == null || !authHeader.startsWith('Bearer ')) {
    return false;
  }

  final token = authHeader.substring(7);
  final parts = token.split('.');
  if (parts.length != 3) {
    return false;
  }

  try {
    final payloadNormalized = base64Url.normalize(parts[1]);
    final payloadString = utf8.decode(base64Url.decode(payloadNormalized));
    final payload = jsonDecode(payloadString) as Map<String, dynamic>;

    final iss = payload['iss'] as String?;
    final email = payload['email'] as String?;

    if (iss == null || email == null) return false;

    final isGoogleIss =
        iss.contains('accounts.google.com') ||
        iss.contains('oauth2.googleapis.com') ||
        iss.startsWith('https://securetoken.google.com');
    if (!isGoogleIss) return false;

    if (!email.contains('gserviceaccount.com') && !email.contains('openci')) {
      return false;
    }

    return true;
  } catch (_) {
    return false;
  }
}

Future<Response> handleRequest(
  Request request,
  Future<Response> Function(Map<String, dynamic> body) handler,
) async {
  if (request.method == 'OPTIONS') {
    return optionsResponse();
  }

  if (request.method != 'POST') {
    return jsonResponse({'error': 'Method Not Allowed'}, status: 405);
  }

  if (!verifyAuth(request)) {
    return jsonResponse({'error': 'Unauthorized'}, status: 401);
  }

  try {
    final bodyString = await request.readAsString();
    final body = bodyString.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(bodyString) as Map<String, dynamic>;
    return await handler(body);
  } catch (e) {
    return jsonResponse({
      'error': 'Bad Request',
      'details': e.toString(),
    }, status: 400);
  }
}

// GitHub API Base URL の正規化ヘルパー
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

// GitHub Check Run の更新ヘルパー
Future<void> updateCheckRunInternal(
  Map<String, dynamic> buildJob,
  String runStatus,
  String? conclusion, {
  Firebase? firebase,
}) async {
  var checkRunId = buildJob['checkRunId'];
  var installationToken = buildJob['installationToken'] as String?;
  var owner = buildJob['owner'] as String?;
  var repo = buildJob['repo'] as String?;
  var apiBaseRaw = buildJob['githubApiBaseUrl'] as String?;

  // The worker's BuildJob model does not carry checkRunId/installationToken, so
  // they are missing from the posted JSON. When a Firebase handle is available,
  // pull the check-run fields from Firestore and (re)mint a fresh installation
  // access token, so the GitHub check run can be updated even for re-queued or
  // long-running jobs whose cached token has expired.
  final buildJobId = buildJob['id'] as String?;
  if (firebase != null && buildJobId != null && buildJobId.isNotEmpty) {
    try {
      final snap = await firebase.adminApp
          .firestore()
          .collection(buildJobsCollection)
          .doc(buildJobId)
          .get();
      if (snap.exists) {
        final data = snap.data()!;
        checkRunId ??= data['checkRunId'];
        owner ??= data['owner'] as String?;
        repo ??= data['repo'] as String?;
        apiBaseRaw ??= data['githubApiBaseUrl'] as String?;
      }
      final fresh = await resolveFreshInstallationToken(firebase, buildJobId);
      if (fresh != null && fresh.isNotEmpty) {
        installationToken = fresh;
      }
    } catch (e) {
      logger.warn('Failed to resolve check-run context from Firestore: $e');
    }
  }

  if (checkRunId == null ||
      installationToken == null ||
      installationToken.isEmpty) {
    return;
  }

  final githubApiBaseUrl = normalizeGitHubApiBaseUrl(apiBaseRaw);

  final url = '$githubApiBaseUrl/repos/$owner/$repo/check-runs/$checkRunId';

  final client = HttpClient();
  try {
    final request = await client.patchUrl(Uri.parse(url));
    request.headers.set('Authorization', 'Bearer $installationToken');
    request.headers.set('Accept', 'application/vnd.github+json');
    request.headers.set('X-GitHub-Api-Version', '2022-11-28');
    request.headers.set('Content-Type', 'application/json');

    final body = {
      'status': runStatus,
      if (runStatus == 'completed' && conclusion != null)
        'conclusion': conclusion,
      'details_url':
          'https://dashboard.openci.org/runs/${Uri.encodeComponent(buildJob['id'] as String)}',
    };

    request.write(jsonEncode(body));
    final response = await request.close();
    if (response.statusCode >= 300) {
      final responseBody = await response.transform(utf8.decoder).join();
      logger.warn(
        'Failed to update GitHub check run: ${response.statusCode} $responseBody',
      );
    }
  } catch (e) {
    logger.warn('Error updating GitHub check run: $e');
  } finally {
    client.close();
  }
}

/// Returns a valid GitHub App installation access token for [buildJobId],
/// minting a fresh one from the App JWT + installationId (and caching it back
/// to Firestore) when the cached token is missing or close to expiry. Returns
/// the cached token (or null) on best-effort failure.
Future<String?> resolveFreshInstallationToken(
  Firebase firebase,
  String buildJobId,
) async {
  final firestore = firebase.adminApp.firestore();
  final docRef = firestore.collection(buildJobsCollection).doc(buildJobId);
  final snap = await docRef.get();
  if (!snap.exists) return null;

  final jobData = snap.data()!;
  final currentToken = jobData['installationToken'] as String?;
  final tokenExpiresAt = jobData['tokenExpiresAt'] as String?;
  if (currentToken != null &&
      currentToken.isNotEmpty &&
      _isInstallationTokenFresh(tokenExpiresAt)) {
    return currentToken;
  }

  final installationId = jobData['installationId'];
  if (installationId == null) return currentToken;

  final projectId = Platform.environment['GCLOUD_PROJECT'] ?? 'openci-b1b91';
  final appId = await GcpSecretManager.fetchSecretValue(
    'projects/$projectId/secrets/GITHUB_APP_ID',
  );
  final privateKey = await GcpSecretManager.fetchSecretValue(
    'projects/$projectId/secrets/GITHUB_PRIVATE_KEY',
  );
  if (appId.isEmpty || privateKey.isEmpty) return currentToken;

  final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final jwt = JWT({
    'iat': nowSeconds - 60,
    'exp': nowSeconds + 540,
    'iss': appId.trim(),
  });
  final jwtToken = jwt.sign(
    RSAPrivateKey(privateKey),
    algorithm: JWTAlgorithm.RS256,
  );

  final githubApiBaseUrl = normalizeGitHubApiBaseUrl(
    jobData['githubApiBaseUrl'] as String?,
  );
  final url =
      '$githubApiBaseUrl/app/installations/$installationId/access_tokens';

  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(url));
    request.headers.set('Authorization', 'Bearer $jwtToken');
    request.headers.set('Accept', 'application/vnd.github+json');
    request.headers.set('X-GitHub-Api-Version', '2022-11-28');
    request.headers.set('User-Agent', 'OpenCI-Worker-Functions');
    request.headers.set('Content-Type', 'application/json');

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode >= 300) {
      logger.warn(
        'Failed to mint installation token: ${response.statusCode} $responseBody',
      );
      return currentToken;
    }

    final data = jsonDecode(responseBody) as Map<String, dynamic>;
    final token = data['token'] as String?;
    final expiresAt = data['expires_at'] as String?;
    if (token == null) return currentToken;

    await docRef.update({
      FieldPath.from('installationToken'): token,
      FieldPath.from('tokenExpiresAt'): ?expiresAt,
      FieldPath.from('updatedAt'): DateTime.now().toUtc().toIso8601String(),
    });
    return token;
  } catch (e) {
    logger.warn('Error minting installation token: $e');
    return currentToken;
  } finally {
    client.close();
  }
}

bool _isInstallationTokenFresh(String? expiresAt) {
  if (expiresAt == null) return false;
  final dt = DateTime.tryParse(expiresAt);
  if (dt == null) return false;
  return dt.difference(DateTime.now().toUtc()).inMinutes > 5;
}
