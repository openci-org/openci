import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:openci_server/secret/secret_table.dart';
import 'package:test/test.dart';

import '../../../../../routes/teams/[id]/ios-signing/generate-key.dart'
    as generate_key_route;

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

  group('Generate Key Endpoint', () {
    Future<void> addMember() => db
        .into(db.teamMembers)
        .insert(
          TeamMembersCompanion.insert(teamId: 'team-123', userId: 'user-1'),
        );

    Future<Response> generate({
      String? uid = 'user-1',
      Map<String, String>? env,
    }) {
      final context = TestRequestContext(
        path: '/teams/team-123/ios-signing/generate-key',
        method: HttpMethod.post,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>(uid);
      context.provide<Map<String, String>>(env ?? testEnv);
      return Future.value(
        generate_key_route.onRequest(context.context, 'team-123'),
      );
    }

    Future<DriftSecret> saveExistingKey() async {
      final time = DateTime.utc(2025, 1, 1);
      await db.secretDao.insertOrUpdateSecret(
        DriftSecret(
          name: 'OPENCI_GENERATED_IOS_CERTIFICATE_PRIVATE_KEY',
          teamId: 'team-123',
          encryptedValue: await SecretCrypter(
            encryptionKey,
          ).encrypt('existing-private-key'),
          createdAt: time,
          updatedAt: time,
        ),
      );
      return (await db.secretDao.getSecret(
        'team-123',
        'OPENCI_GENERATED_IOS_CERTIFICATE_PRIVATE_KEY',
      ))!;
    }

    test(
      'keeps an existing key without requiring generation configuration',
      () async {
        await addMember();
        final original = await saveExistingKey();

        final response = await generate(env: {});

        expect(response.statusCode, HttpStatus.ok);
        expect(await response.json(), {'success': true});
        final saved = (await db.secretDao.getSecret(
          'team-123',
          original.name,
        ))!;
        expect(saved.encryptedValue, original.encryptedValue);
        expect(saved.createdAt, original.createdAt);
        expect(saved.updatedAt, original.updatedAt);
      },
    );

    for (final (uid, status) in [
      (null, HttpStatus.unauthorized),
      ('non-member-user', HttpStatus.forbidden),
    ]) {
      test(
        'checks authorization before reusing an existing key: $status',
        () async {
          final original = await saveExistingKey();

          final response = await generate(uid: uid);

          expect(response.statusCode, status);
          final saved = (await db.secretDao.getSecret(
            'team-123',
            original.name,
          ))!;
          expect(saved.encryptedValue, original.encryptedValue);
        },
      );
    }

    test('rejects unsupported methods without creating a key', () async {
      final context = TestRequestContext(
        path: '/teams/team-123/ios-signing/generate-key',
        method: HttpMethod.get,
      );

      final response = await generate_key_route.onRequest(
        context.context,
        'team-123',
      );

      expect(response.statusCode, HttpStatus.methodNotAllowed);
      expect(await db.secretDao.getSecretsForTeam('team-123'), isEmpty);
    });

    for (final (key, error) in [
      (null, 'Internal server error'),
      ('invalid', 'Invalid encryption key configuration'),
    ]) {
      test(
        'does not save a key with invalid encryption config: $key',
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
            path: '/teams/team-123/ios-signing/generate-key',
            method: HttpMethod.post,
          );
          context.provide<AppDatabase>(db);
          context.provide<String?>('user-1');
          context.provide<Map<String, String>>({
            'SECRET_ENCRYPTION_KEY': ?key,
          });

          final response = await generate_key_route.onRequest(
            context.context,
            'team-123',
          );

          expect(response.statusCode, HttpStatus.internalServerError);
          expect(await response.json(), {'success': false, 'error': error});
          expect(await db.secretDao.getSecretsForTeam('team-123'), isEmpty);
        },
      );
    }

    test('responds with 401 Unauthorized when uid is null', () async {
      final context = TestRequestContext(
        path: '/teams/team-123/ios-signing/generate-key',
        method: HttpMethod.post,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>(null);
      context.provide<Map<String, String>>(testEnv);

      final response = await generate_key_route.onRequest(
        context.context,
        'team-123',
      );
      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test('responds with 403 Forbidden when user is not team member', () async {
      final context = TestRequestContext(
        path: '/teams/team-123/ios-signing/generate-key',
        method: HttpMethod.post,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>('non-member-user');
      context.provide<Map<String, String>>(testEnv);

      final response = await generate_key_route.onRequest(
        context.context,
        'team-123',
      );
      expect(response.statusCode, equals(HttpStatus.forbidden));
    });

    test(
      'responds with 200 OK, generates RSA private key and saves it encrypted',
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
          path: '/teams/team-123/ios-signing/generate-key',
          method: HttpMethod.post,
        );
        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');
        context.provide<Map<String, String>>(testEnv);

        final response = await generate_key_route.onRequest(
          context.context,
          'team-123',
        );
        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isTrue);

        final secret = await db.secretDao.getSecret(
          'team-123',
          'OPENCI_GENERATED_IOS_CERTIFICATE_PRIVATE_KEY',
        );
        expect(secret, isNotNull);
        expect(
          secret!.name,
          equals('OPENCI_GENERATED_IOS_CERTIFICATE_PRIVATE_KEY'),
        );
        expect(secret.teamId, equals('team-123'));

        final crypter = SecretCrypter(encryptionKey);
        final decrypted = await crypter.decrypt(secret.encryptedValue);
        expect(decrypted, contains('-----BEGIN PRIVATE KEY-----'));
        expect(decrypted, contains('-----END PRIVATE KEY-----'));

        final retry = await generate();
        expect(retry.statusCode, HttpStatus.ok);
        expect(await retry.json(), {'success': true});
        final reused = (await db.secretDao.getSecret('team-123', secret.name))!;
        expect(reused.encryptedValue, secret.encryptedValue);
        expect(reused.createdAt, secret.createdAt);
        expect(reused.updatedAt, secret.updatedAt);
      },
    );
  });
}
