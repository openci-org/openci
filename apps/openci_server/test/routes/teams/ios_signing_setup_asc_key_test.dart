import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:test/test.dart';

import '../../../routes/teams/[id]/ios-signing/setup-asc-key.dart'
    as setup_asc_key_route;

void main() {
  late AppDatabase db;
  late Map<String, String> testEnv;
  const encryptionKey = 'cTN0Nnc5eiRDJkYpSkBOY1FmVGZXblpyNHU3eCFBJUQ=';

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.teams)
        .insert(
          DriftTeam(
            id: 'team-123',
            name: 'Test Team',
            installationIds: const [98765],
            aiEnabled: false,
            runNumber: 1,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );

    testEnv = {
      'SECRET_ENCRYPTION_KEY': encryptionKey,
    };
  });

  tearDown(() async {
    await db.close();
  });

  group('setup-asc-key endpoint', () {
    test('responds with 401 Unauthorized when uid is null', () async {
      final context = TestRequestContext(
        path: '/teams/team-123/ios-signing/setup-asc-key',
        method: HttpMethod.post,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>(null);

      final response = await setup_asc_key_route.onRequest(
        context.context,
        'team-123',
      );
      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('responds with 403 Forbidden when user is not team member', () async {
      final context = TestRequestContext(
        path: '/teams/team-123/ios-signing/setup-asc-key',
        method: HttpMethod.post,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>('stranger-danger');

      final response = await setup_asc_key_route.onRequest(
        context.context,
        'team-123',
      );
      expect(response.statusCode, equals(HttpStatus.forbidden));
    });

    test(
      'responds with 400 Bad Request when request body is missing parameters',
      () async {
        await db
            .into(db.teamMembers)
            .insert(
              TeamMembersCompanion.insert(
                teamId: 'team-123',
                userId: 'user-1',
              ),
            );

        final context = TestRequestContext(
          path: '/teams/team-123/ios-signing/setup-asc-key',
          method: HttpMethod.post,
          body: '{"issuerId": "iss-123"}',
        );
        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');
        context.provide<Map<String, String>>(testEnv);

        final response = await setup_asc_key_route.onRequest(
          context.context,
          'team-123',
        );
        expect(response.statusCode, equals(HttpStatus.badRequest));
      },
    );

    test(
      'responds with 200 OK and stores issuerId, keyId, and privateKey encrypted',
      () async {
        await db
            .into(db.teamMembers)
            .insert(
              TeamMembersCompanion.insert(
                teamId: 'team-123',
                userId: 'user-1',
              ),
            );

        final context = TestRequestContext(
          path: '/teams/team-123/ios-signing/setup-asc-key',
          method: HttpMethod.post,
          body:
              '{"issuerId": "iss-123", "keyId": "key-456", "privateKey": "pem-content"}',
        );
        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');
        context.provide<Map<String, String>>(testEnv);

        final response = await setup_asc_key_route.onRequest(
          context.context,
          'team-123',
        );
        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isTrue);

        final crypter = SecretCrypter(encryptionKey);

        final issuer = await db.secretDao.getSecret(
          'team-123',
          'OPENCI_ASC_ISSUER_ID',
        );
        expect(issuer, isNotNull);
        expect(
          await crypter.decrypt(issuer!.encryptedValue),
          equals('iss-123'),
        );

        final keyId = await db.secretDao.getSecret(
          'team-123',
          'OPENCI_ASC_KEY_ID',
        );
        expect(keyId, isNotNull);
        expect(await crypter.decrypt(keyId!.encryptedValue), equals('key-456'));

        final privateKey = await db.secretDao.getSecret(
          'team-123',
          'OPENCI_ASC_PRIVATE_KEY',
        );
        expect(privateKey, isNotNull);
        expect(
          await crypter.decrypt(privateKey!.encryptedValue),
          equals('pem-content'),
        );
      },
    );
  });
}
