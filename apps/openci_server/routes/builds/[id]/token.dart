import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:http/http.dart' as http;
import 'package:openci_server/database.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context, String id) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();

    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

    final driftJob = await db.buildJobDao.getBuildJob(id);
    if (driftJob == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Build job not found'},
      );
    }

    final teamId = driftJob.teamId;
    if (teamId == null) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final isMember = await db.teamDao.isTeamMember(uid, teamId);
    if (!isMember) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final installationIdStr = driftJob.installationId;
    if (installationIdStr == null || installationIdStr.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'No installationId found for job'},
      );
    }
    final installationId = int.parse(installationIdStr);

    final env = Platform.environment;
    final appId = env['GITHUB_APP_ID'];
    final privateKeyPath = env['GITHUB_PRIVATE_KEY_PATH'];

    if (appId == null ||
        appId.isEmpty ||
        privateKeyPath == null ||
        privateKeyPath.isEmpty) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {
          'success': false,
          'error': 'GitHub App credentials not configured',
        },
      );
    }

    final privateKeyFile = File(privateKeyPath);
    if (!privateKeyFile.existsSync()) {
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {'success': false, 'error': 'GitHub private key file not found'},
      );
    }
    final privateKeyPem = privateKeyFile.readAsStringSync();

    // Generate App JWT
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final jwt = JWT({
      'iat': nowSeconds - 60,
      'exp': nowSeconds + 540,
      'iss': appId.trim(),
    });
    final jwtToken = jwt.sign(
      RSAPrivateKey(privateKeyPem),
      algorithm: JWTAlgorithm.RS256,
    );

    final githubApiBaseUrl = normalizeGitHubApiBaseUrl(
      driftJob.githubApiBaseUrl,
    );
    final tokenUrl =
        '$githubApiBaseUrl/app/installations/$installationId/access_tokens';

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
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {
          'success': false,
          'error': 'Failed to retrieve installation token from GitHub',
        },
      );
    }

    final tokenData = jsonDecode(response.body) as Map<String, dynamic>;
    final token = tokenData['token'] as String;

    return Response.json(body: {'token': token});
  } catch (e, s) {
    stderr.writeln('Failed to resolve token for job $id: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': 'Internal server error'},
    );
  }
}

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
