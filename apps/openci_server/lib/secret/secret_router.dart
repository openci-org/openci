import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/secret/encryption_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class SecretRouter {
  final AppDatabase db;
  final String? _encryptionKey;

  SecretRouter({required this.db, String? encryptionKey})
    : _encryptionKey = encryptionKey;

  String _getEncryptionKey() {
    final key = _encryptionKey ?? Platform.environment['SECRET_ENCRYPTION_KEY'];
    if (key == null || key.trim().isEmpty) {
      throw StateError(
        'SECRET_ENCRYPTION_KEY environment variable is missing.',
      );
    }
    return key;
  }

  Response _forbiddenResponse(String error) {
    return Response.forbidden(
      jsonEncode({'success': false, 'error': error}),
      headers: {'content-type': 'application/json'},
    );
  }

  Router get router {
    final router = Router();

    // 1. GET /<teamId>/secrets (List secrets metadata)
    router.get('/<teamId>/secrets', (Request request, String teamId) async {
      final uid = request.context['uid'] as String?;
      if (uid == null) {
        return _forbiddenResponse('Unauthorized');
      }

      try {
        final isMember = await db.teamDao.isTeamMember(uid, teamId);
        if (!isMember) {
          return _forbiddenResponse('Forbidden: Not a member of this team');
        }

        final teamSecrets = await (db.select(
          db.secrets,
        )..where((t) => t.teamId.equals(teamId))).get();

        final result = teamSecrets
            .map(
              (s) => {
                'name': s.name,
                'teamId': s.teamId,
                'createdAt': s.createdAt.toUtc().toIso8601String(),
                'updatedAt': s.updatedAt.toUtc().toIso8601String(),
              },
            )
            .toList();

        return Response.ok(
          jsonEncode(result),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, s) {
        stderr.writeln('Failed to list secrets for team $teamId: $e\n$s');
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'Internal server error',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    // 2. POST /<teamId>/secrets (Create encrypted secret)
    router.post('/<teamId>/secrets', (Request request, String teamId) async {
      final uid = request.context['uid'] as String?;
      if (uid == null) {
        return _forbiddenResponse('Unauthorized');
      }

      try {
        final isMember = await db.teamDao.isTeamMember(uid, teamId);
        if (!isMember) {
          return _forbiddenResponse('Forbidden: Not a member of this team');
        }

        final payload =
            jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final name = payload['name'] as String?;
        final value = payload['value'] as String?;

        if (name == null || name.isEmpty || value == null || value.isEmpty) {
          return Response.badRequest(
            body: jsonEncode({
              'success': false,
              'error': 'name and value are required',
            }),
            headers: {'content-type': 'application/json'},
          );
        }

        final encrypter = EncryptionService(_getEncryptionKey());
        final encryptedValue = await encrypter.encrypt(value);
        final now = DateTime.now().toUtc();

        final driftSecret = DriftSecret(
          name: name,
          teamId: teamId,
          encryptedValue: encryptedValue,
          createdAt: now,
          updatedAt: now,
        );

        await db.into(db.secrets).insert(driftSecret);

        return Response.ok(
          jsonEncode({'success': true, 'name': name}),
          headers: {'content-type': 'application/json'},
        );
      } on FormatException catch (e) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'Invalid JSON format: $e',
          }),
          headers: {'content-type': 'application/json'},
        );
      } on TypeError catch (e) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'Invalid payload structure: $e',
          }),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, s) {
        stderr.writeln('Failed to create secret for team $teamId: $e\n$s');
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'Internal server error',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    // 3. PATCH /<teamId>/secrets/<name> (Update encrypted secret value)
    router.patch('/<teamId>/secrets/<name>', (
      Request request,
      String teamId,
      String name,
    ) async {
      final uid = request.context['uid'] as String?;
      if (uid == null) {
        return _forbiddenResponse('Unauthorized');
      }

      try {
        final isMember = await db.teamDao.isTeamMember(uid, teamId);
        if (!isMember) {
          return _forbiddenResponse('Forbidden: Not a member of this team');
        }

        final payload =
            jsonDecode(await request.readAsString()) as Map<String, dynamic>;
        final value = payload['value'] as String?;

        final existingSecret =
            await (db.select(db.secrets)
                  ..where((t) => t.name.equals(name) & t.teamId.equals(teamId)))
                .getSingleOrNull();

        if (existingSecret == null) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Secret not found'}),
            headers: {'content-type': 'application/json'},
          );
        }

        final now = DateTime.now().toUtc();
        var updatedSecret = existingSecret.copyWith(updatedAt: now);

        if (value != null && value.isNotEmpty) {
          final encrypter = EncryptionService(_getEncryptionKey());
          final encryptedValue = await encrypter.encrypt(value);
          updatedSecret = updatedSecret.copyWith(
            encryptedValue: encryptedValue,
          );
        }

        await db.update(db.secrets).replace(updatedSecret);

        return Response.ok(
          jsonEncode({'success': true}),
          headers: {'content-type': 'application/json'},
        );
      } on FormatException catch (e) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'Invalid JSON format: $e',
          }),
          headers: {'content-type': 'application/json'},
        );
      } on TypeError catch (e) {
        return Response.badRequest(
          body: jsonEncode({
            'success': false,
            'error': 'Invalid payload structure: $e',
          }),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, s) {
        stderr.writeln(
          'Failed to update secret $name for team $teamId: $e\n$s',
        );
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'Internal server error',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    // 4. GET /<teamId>/secrets/<name>/value (Get decrypted value - worker API)
    router.get('/<teamId>/secrets/<name>/value', (
      Request request,
      String teamId,
      String name,
    ) async {
      final uid = request.context['uid'] as String?;
      if (uid == null) {
        return _forbiddenResponse('Unauthorized');
      }

      try {
        final isMember = await db.teamDao.isTeamMember(uid, teamId);
        if (!isMember) {
          return _forbiddenResponse('Forbidden: Not a member of this team');
        }

        final secret =
            await (db.select(db.secrets)
                  ..where((t) => t.teamId.equals(teamId) & t.name.equals(name)))
                .getSingleOrNull();

        if (secret == null) {
          return Response.notFound(
            jsonEncode({'success': false, 'error': 'Secret not found'}),
            headers: {'content-type': 'application/json'},
          );
        }

        final encrypter = EncryptionService(_getEncryptionKey());
        final decryptedValue = await encrypter.decrypt(secret.encryptedValue);

        return Response.ok(
          jsonEncode({'success': true, 'value': decryptedValue}),
          headers: {'content-type': 'application/json'},
        );
      } catch (e, s) {
        stderr.writeln(
          'Failed to get secret value for name $name in team $teamId: $e\n$s',
        );
        return Response.internalServerError(
          body: jsonEncode({
            'success': false,
            'error': 'Internal server error',
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    });

    return router;
  }
}
