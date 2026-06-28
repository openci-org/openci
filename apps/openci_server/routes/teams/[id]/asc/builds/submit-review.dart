import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/asc/asc_service.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/secret/secret_crypter.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _post(RequestContext context, String teamId) async {
  try {
    final db = context.read<AppDatabase>();
    final uid = context.read<String?>();
    if (uid == null) {
      return Response.json(
        statusCode: HttpStatus.unauthorized,
        body: {'success': false, 'error': 'Authentication required'},
      );
    }

    final isMember = await db.teamDao.isTeamMember(uid, teamId);
    if (!isMember) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final body = await context.request.json() as Map<String, dynamic>;
    final appId = body['appId'] as String?;
    final buildId = body['buildId'] as String?;
    final versionString = body['versionString'] as String?;
    final whatsNew = body['whatsNew'] as String?;
    final platform = body['platform'] as String? ?? 'IOS';

    if (appId == null ||
        appId.trim().isEmpty ||
        buildId == null ||
        buildId.trim().isEmpty ||
        versionString == null ||
        versionString.trim().isEmpty ||
        whatsNew == null ||
        whatsNew.trim().isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {
          'success': false,
          'error':
              'Missing required parameters: appId, buildId, versionString, whatsNew',
        },
      );
    }

    Map<String, String> env;
    try {
      env = context.read<Map<String, String>>();
    } catch (_) {
      env = Platform.environment;
    }

    final encryptionKey = env['SECRET_ENCRYPTION_KEY'];
    if (encryptionKey == null || encryptionKey.trim().isEmpty) {
      stderr.writeln('SECRET_ENCRYPTION_KEY environment variable is not set');
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {
          'success': false,
          'error': 'Encryption key is not configured on the server',
        },
      );
    }

    final SecretCrypter crypter;
    try {
      crypter = SecretCrypter(encryptionKey);
    } catch (e) {
      stderr.writeln('Failed to initialize SecretCrypter: $e');
      return Response.json(
        statusCode: HttpStatus.internalServerError,
        body: {
          'success': false,
          'error': 'Invalid encryption key configuration',
        },
      );
    }

    AscService ascService;
    try {
      ascService = context.read<AscService>();
    } catch (_) {
      ascService = const AscService();
    }

    final appStoreVersionId = await ascService.submitForReview(
      db,
      teamId,
      appId: appId,
      buildId: buildId,
      versionString: versionString,
      whatsNew: whatsNew,
      platform: platform,
      crypter: crypter,
    );

    return Response.json(
      body: {
        'success': true,
        'appStoreVersionId': appStoreVersionId,
      },
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to submit build for App Store Review in team $teamId',
    );
  }
}
