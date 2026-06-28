import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/asc/asc_service.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/secret/secret_crypter.dart';

FutureOr<Response> onRequest(
  RequestContext context,
  String id,
  String buildId,
) {
  return switch (context.request.method) {
    HttpMethod.post => _post(context, id, buildId),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _post(
  RequestContext context,
  String teamId,
  String buildId,
) async {
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

    final betaGroupName = await ascService.submitToTestFlight(
      db,
      teamId,
      buildId,
      crypter,
    );

    return Response.json(
      body: {
        'success': true,
        'betaGroupName': betaGroupName,
      },
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage:
          'Failed to submit build $buildId to TestFlight in team $teamId',
    );
  }
}
