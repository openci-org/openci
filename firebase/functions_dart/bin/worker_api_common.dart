import 'dart:convert';
import 'dart:io';
import 'package:firebase_functions/firebase_functions.dart';

const workerOptions = HttpsOptions(
  region: Region(SupportedRegion.asiaNortheast1),
);

// HTTP レスポンス用の共通ヘルパー
Response jsonResponse(Map<String, dynamic> data, {int status = 200}) {
  return Response(
    status,
    body: jsonEncode(data),
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
  final isEmulator = const bool.fromEnvironment('FUNCTIONS_EMULATOR') ||
      const String.fromEnvironment('FUNCTIONS_EMULATOR') == 'true';
  if (isEmulator) {
    return true;
  }

  final authHeader = request.headers['Authorization'] ?? request.headers['authorization'];
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
    
    final isGoogleIss = iss.contains('accounts.google.com') || 
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

Future<Response> handleRequest(Request request, Future<Response> Function(Map<String, dynamic> body) handler) async {
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
    final body = bodyString.isEmpty ? <String, dynamic>{} : jsonDecode(bodyString) as Map<String, dynamic>;
    return await handler(body);
  } catch (e) {
    return jsonResponse({'error': 'Bad Request', 'details': e.toString()}, status: 400);
  }
}

// GitHub API Base URL の正規化ヘルパー
String normalizeGitHubApiBaseUrl(String? apiBaseUrl) {
  if (apiBaseUrl == null || apiBaseUrl.isEmpty) return 'https://api.github.com';
  final normalized = apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
  if (normalized == 'https://api.github.com' || normalized == 'https://github.com' || normalized == 'https://api.github.com/graphql') {
    return 'https://api.github.com';
  }
  if (normalized.endsWith('/api/v3')) return normalized;
  try {
    final uri = Uri.parse(normalized);
    if (normalized.endsWith('/api/graphql') || normalized.endsWith('/graphql')) {
      return '${uri.scheme}://${uri.host}/api/v3';
    }
    return '${uri.scheme}://${uri.host}/api/v3';
  } catch (_) {
    return 'https://api.github.com';
  }
}

// GitHub Check Run の更新ヘルパー
Future<void> updateCheckRunInternal(Map<String, dynamic> buildJob, String runStatus, String? conclusion) async {
  final checkRunId = buildJob['checkRunId'];
  final installationToken = buildJob['installationToken'] as String?;
  if (checkRunId == null || installationToken == null || installationToken.isEmpty) return;

  final owner = buildJob['owner'] as String?;
  final repo = buildJob['repo'] as String?;
  final githubApiBaseUrl = normalizeGitHubApiBaseUrl(buildJob['githubApiBaseUrl'] as String?);

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
      if (runStatus == 'completed' && conclusion != null) 'conclusion': conclusion,
      'details_url': 'https://dashboard.openci.org/runs/${Uri.encodeComponent(buildJob['id'] as String)}',
    };

    request.write(jsonEncode(body));
    final response = await request.close();
    if (response.statusCode >= 300) {
      final responseBody = await response.transform(utf8.decoder).join();
      logger.warn('Failed to update GitHub check run: ${response.statusCode} $responseBody');
    }
  } catch (e) {
    logger.warn('Error updating GitHub check run: $e');
  } finally {
    client.close();
  }
}
