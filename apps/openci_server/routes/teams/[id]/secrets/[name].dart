import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/auth/worker_auth.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/secret/secret_crypter.dart';

FutureOr<Response> onRequest(RequestContext context, String id, String name) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id, name),
    HttpMethod.delete => _delete(context, id, name),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(
  RequestContext context,
  String teamId,
  String name,
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
      final workerAuthError = verifyWorkerAuth(context, uid);
      if (workerAuthError != null) {
        return Response.json(
          statusCode: HttpStatus.forbidden,
          body: {'success': false, 'error': 'Forbidden'},
        );
      }
    }

    final secret = await db.secretDao.getSecret(teamId, name);
    if (secret == null) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Secret not found'},
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

    final decryptedValue = await crypter.decrypt(secret.encryptedValue);

    return Response.json(
      body: {
        'success': true,
        'value': decryptedValue,
      },
    );
  } catch (e, s) {
    stderr.writeln('Failed to get secret $name for team $teamId: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': 'Internal server error'},
    );
  }
}

Future<Response> _delete(
  RequestContext context,
  String teamId,
  String name,
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

    // Only team members can delete secrets
    final isMember = await db.teamDao.isTeamMember(uid, teamId);
    if (!isMember) {
      return Response.json(
        statusCode: HttpStatus.forbidden,
        body: {'success': false, 'error': 'Forbidden'},
      );
    }

    final deletedCount = await db.secretDao.deleteSecret(teamId, name);
    if (deletedCount == 0) {
      return Response.json(
        statusCode: HttpStatus.notFound,
        body: {'success': false, 'error': 'Secret not found'},
      );
    }

    return Response.json(
      body: {'success': true},
    );
  } catch (e, s) {
    stderr.writeln('Failed to delete secret $name for team $teamId: $e\n$s');
    return Response.json(
      statusCode: HttpStatus.internalServerError,
      body: {'success': false, 'error': 'Internal server error'},
    );
  }
}
