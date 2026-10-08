import 'dart:async';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/ios_signing/ios_signing_service.dart';
import 'package:openci_server/request/error_handler.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:openci_server/secret/secret_table.dart';

const _secretName = 'OPENCI_GENERATED_IOS_CERTIFICATE_PRIVATE_KEY';

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

    if (await db.secretDao.getSecret(teamId, _secretName) != null) {
      return Response.json(body: {'success': true});
    }

    Map<String, String> env;
    try {
      env = context.read<Map<String, String>>();
    } catch (_) {
      env = Platform.environment;
    }

    final encryptionKey = env['SECRET_ENCRYPTION_KEY']!;

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

    final privateKeyPem = await IosSigningService.generatePrivateKey();

    final encryptedValue = await crypter.encrypt(privateKeyPem);
    final now = DateTime.now().toUtc();

    final driftSecret = DriftSecret(
      name: _secretName,
      teamId: teamId,
      encryptedValue: encryptedValue,
      createdAt: now,
      updatedAt: now,
    );

    // Another request may have saved a key while OpenSSL was running.
    await db.secretDao.insertSecretIfAbsent(driftSecret);

    return Response.json(
      body: {'success': true},
    );
  } catch (e, s) {
    return handleRouteException(
      e,
      s,
      logMessage:
          'Failed to generate iOS certificate private key for team $teamId',
    );
  }
}
