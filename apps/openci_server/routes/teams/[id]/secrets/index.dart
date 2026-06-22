import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/auth/worker_auth.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/request/request_extension.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:openci_server/secret/secret_table.dart';

FutureOr<Response> onRequest(RequestContext context, String id) {
  return switch (context.request.method) {
    HttpMethod.get => _get(context, id),
    HttpMethod.post => _post(context, id),
    _ => Response(statusCode: HttpStatus.methodNotAllowed),
  };
}

Future<Response> _get(RequestContext context, String teamId) async {
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

    final driftSecrets = await db.secretDao.getSecretsForTeam(teamId);
    final jsonList = driftSecrets.map((s) => s.toJson()).toList();

    return Response.json(
      body: {'success': true, 'secrets': jsonList},
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to get secrets for team $teamId',
    );
  }
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

    final Map<String, dynamic> payload;
    try {
      payload = await context.jsonBody();
    } on BadRequestException catch (e) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': e.message},
      );
    }

    final name = payload['name'];
    final value = payload['value'];

    if (name is! String || name.trim().isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'name must be a non-empty string'},
      );
    }

    if (value is! String || value.trim().isEmpty) {
      return Response.json(
        statusCode: HttpStatus.badRequest,
        body: {'success': false, 'error': 'value must be a non-empty string'},
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

    final encryptedValue = await crypter.encrypt(value.trim());
    final now = DateTime.now().toUtc();

    final driftSecret = DriftSecret(
      name: name.trim(),
      teamId: teamId,
      encryptedValue: encryptedValue,
      createdAt: now,
      updatedAt: now,
    );

    await db.secretDao.insertOrUpdateSecret(driftSecret);

    return Response.json(
      body: {'success': true},
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage: 'Failed to create secret for team $teamId',
    );
  }
}
