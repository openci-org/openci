import 'dart:convert';
import 'dart:io';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_cloud_firestore/google_cloud_firestore.dart';
import 'package:gcp_secret_manager/gcp_secret_manager.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:openci_shared/openci_shared.dart';
import 'worker_api_common.dart';

Future<Response> resolveInstallationToken(Request request, Firebase firebase) async {
  return handleRequest(request, (body) async {
    final buildJobId = body['buildJobId'] as String?;
    if (buildJobId == null || buildJobId.isEmpty) {
      return jsonResponse({'error': 'buildJobId is required'}, status: 400);
    }

    final firestore = firebase.adminApp.firestore();
    final docRef = firestore.collection(buildJobsCollection).doc(buildJobId);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      return jsonResponse({'error': 'BuildJob not found'}, status: 404);
    }

    final jobData = docSnap.data()!;
    final currentToken = jobData['installationToken'] as String?;
    final tokenExpiresAt = jobData['tokenExpiresAt'] as String?;

    // Return current token if it's still fresh
    if (currentToken != null && _isTokenFresh(tokenExpiresAt)) {
      return jsonResponse({
        'token': currentToken,
        'expiresAt': tokenExpiresAt,
      });
    }

    final installationId = jobData['installationId'];
    if (installationId == null) {
      if (currentToken != null) {
        return jsonResponse({
          'token': currentToken,
          'expiresAt': tokenExpiresAt,
        });
      }
      return jsonResponse({'error': 'installationId and currentToken are missing'}, status: 400);
    }

    final projectId = Platform.environment['GCLOUD_PROJECT'] ?? 'openci-b1b91';
    
    // Fetch GitHub App credentials from GCP Secret Manager
    final appId = await GcpSecretManager.fetchSecretValue('projects/$projectId/secrets/GITHUB_APP_ID');
    final privateKey = await GcpSecretManager.fetchSecretValue('projects/$projectId/secrets/GITHUB_PRIVATE_KEY');

    if (appId.isEmpty || privateKey.isEmpty) {
      return jsonResponse({'error': 'GITHUB_APP_ID or GITHUB_PRIVATE_KEY not configured in Secret Manager'}, status: 500);
    }

    // Generate GitHub App JWT
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final jwt = JWT({
      'iat': nowSeconds - 60,
      'exp': nowSeconds + 540,
      'iss': appId.trim(),
    });

    final key = RSAPrivateKey(privateKey);
    final jwtToken = jwt.sign(key, algorithm: JWTAlgorithm.RS256);

    // Call GitHub API to generate Installation Access Token
    final githubApiBaseUrl = normalizeGitHubApiBaseUrl(jobData['githubApiBaseUrl'] as String?);
    final url = '$githubApiBaseUrl/app/installations/$installationId/access_tokens';

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
        return jsonResponse({
          'error': 'Failed to retrieve installation token from GitHub',
          'statusCode': response.statusCode,
          'details': responseBody,
        }, status: 500);
      }

      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final token = data['token'] as String?;
      final expiresAt = data['expires_at'] as String?;

      if (token == null || expiresAt == null) {
        return jsonResponse({'error': 'Invalid response from GitHub'}, status: 500);
      }

      // Cache the token back into Firestore
      await docRef.update({
        FieldPath.from('installationToken'): token,
        FieldPath.from('tokenExpiresAt'): expiresAt,
        FieldPath.from('updatedAt'): DateTime.now().toUtc().toIso8601String(),
      });

      return jsonResponse({
        'token': token,
        'expiresAt': expiresAt,
      });
    } catch (e) {
      return jsonResponse({'error': 'Error connecting to GitHub API', 'details': e.toString()}, status: 500);
    } finally {
      client.close();
    }
  });
}

bool _isTokenFresh(String? expiresAt) {
  if (expiresAt == null) return false;
  final expiresAtDt = DateTime.tryParse(expiresAt);
  if (expiresAtDt == null) return false;
  return expiresAtDt.difference(DateTime.now().toUtc()).inMinutes > 5;
}
