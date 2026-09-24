import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/secret/secret_table.dart';
import 'package:test/test.dart';

import '../../../../../routes/teams/[id]/secrets/[name].dart' as name_route;
import '../../../../../routes/teams/[id]/secrets/index.dart' as index_route;

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  const encryptionKey = 'A9hs566HtB6B0ZEB2aKkAZpC81VGQxKMlFspt+vA5F4=';
  final env = {
    'SECRET_ENCRYPTION_KEY': encryptionKey,
  };

  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db
        .into(db.teams)
        .insert(
          DriftTeam(
            id: 'team-123',
            name: 'Test Team',
            installationIds: const [],
            aiEnabled: false,
            runNumber: 1,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Future<Response> request({
    required HttpMethod method,
    String? name,
    String? uid = 'user-1',
    String? body,
    Map<String, String> headers = const {},
    Map<String, String>? environment,
    AppDatabase? database,
  }) async {
    final context = TestRequestContext(
      path: '/teams/team-123/secrets${name == null ? '' : '/$name'}',
      method: method,
      body: body,
      headers: headers,
    );
    context.provide<AppDatabase>(database ?? db);
    context.provide<String?>(uid);
    context.provide<Map<String, String>>(environment ?? env);
    context.provide<InternalApiKeyValidator>(
      const InternalApiKeyValidator.forTesting(
        environment: {'INTERNAL_API_KEY': 'test-internal-key'},
      ),
    );
    return name == null
        ? index_route.onRequest(context.context, 'team-123')
        : name_route.onRequest(context.context, 'team-123', name);
  }

  group('secret authorization and failures', () {
    setUp(() async {
      await db.teamDao.addTeamMember('team-123', 'user-1');
      final now = DateTime.now().toUtc();
      await db.secretDao.insertOrUpdateSecret(
        DriftSecret(
          name: 'API_KEY',
          teamId: 'team-123',
          encryptedValue: 'stored-ciphertext',
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    for (final (method, name) in [
      (HttpMethod.get, 'API_KEY'),
      (HttpMethod.delete, 'API_KEY'),
    ]) {
      for (final (uid, token, status) in [
        (null, null, HttpStatus.unauthorized),
        (null, '', HttpStatus.unauthorized),
        (null, 'incorrect-key', HttpStatus.unauthorized),
        ('stranger', null, HttpStatus.forbidden),
        ('system-job-processor', null, HttpStatus.forbidden),
        ('system-job-processor', 'incorrect-key', HttpStatus.forbidden),
      ]) {
        test(
          '$method $name rejects uid=$uid token=$token before accessing secrets',
          () async {
            final authDb = MockAppDatabase();
            when(() => authDb.teamDao).thenReturn(db.teamDao);
            final response = await request(
              method: method,
              name: name,
              uid: uid,
              headers: {
                if (token != null) 'Authorization': 'Bearer $token',
              },
              database: authDb,
            );

            expect(response.statusCode, status);
            final body = await response.json() as Map<String, dynamic>;
            expect(body['success'], isFalse);
            expect(body, isNot(contains('value')));
            expect(body, isNot(contains('secrets')));
            verifyNever(() => authDb.secretDao);
            if (uid == null) verifyZeroInteractions(authDb);
            expect(
              await db.secretDao.getSecret('team-123', 'API_KEY'),
              isNotNull,
            );
          },
        );
      }
    }

    test(
      'an internal key cannot delete a secret through the former internal UID',
      () async {
        final response = await request(
          method: HttpMethod.delete,
          name: 'API_KEY',
          uid: 'system-job-processor',
          headers: {'Authorization': 'Bearer test-internal-key'},
        );
        expect(response.statusCode, HttpStatus.forbidden);
        expect(await db.secretDao.getSecret('team-123', 'API_KEY'), isNotNull);
      },
    );

    test('an internal key without a UID cannot delete a secret', () async {
      final response = await request(
        method: HttpMethod.delete,
        name: 'API_KEY',
        uid: null,
        headers: {'Authorization': 'Bearer test-internal-key'},
      );
      expect(response.statusCode, HttpStatus.unauthorized);
      expect(await db.secretDao.getSecret('team-123', 'API_KEY'), isNotNull);
    });

    test('a member with the former internal UID can read a secret', () async {
      await db.teamDao.addTeamMember('team-123', 'system-job-processor');
      final saved = await request(
        method: HttpMethod.post,
        body: jsonEncode({'name': 'API_KEY', 'value': 'member-value'}),
      );
      expect(saved.statusCode, HttpStatus.ok);

      final response = await request(
        method: HttpMethod.get,
        name: 'API_KEY',
        uid: 'system-job-processor',
      );
      expect(response.statusCode, HttpStatus.ok);
      expect(await response.json(), {'success': true, 'value': 'member-value'});
    });

    test(
      'deleting a missing secret returns 404 and preserves other secrets',
      () async {
        final response = await request(
          method: HttpMethod.delete,
          name: 'MISSING',
        );
        expect(response.statusCode, HttpStatus.notFound);
        expect(await response.json(), {
          'success': false,
          'error': 'Secret not found',
        });
        expect(await db.secretDao.getSecret('team-123', 'API_KEY'), isNotNull);
      },
    );

    for (final name in ['API_KEY']) {
      test('unsupported method for $name returns 405', () async {
        final response = await request(method: HttpMethod.patch, name: name);
        expect(response.statusCode, HttpStatus.methodNotAllowed);
        expect(await db.secretDao.getSecret('team-123', 'API_KEY'), isNotNull);
      });
    }

    test(
      'member can retrieve the decrypted value after updating a secret',
      () async {
        final updated = await request(
          method: HttpMethod.post,
          body: jsonEncode({'name': ' API_KEY ', 'value': ' new-value '}),
        );
        expect(updated.statusCode, HttpStatus.ok);
        final response = await request(method: HttpMethod.get, name: 'API_KEY');
        expect(response.statusCode, HttpStatus.ok);
        expect(await response.json(), {'success': true, 'value': 'new-value'});
        final stored = await db.secretDao.getSecret('team-123', 'API_KEY');
        expect(stored!.encryptedValue, isNot('new-value'));
        expect(await db.secretDao.getSecretsForTeam('team-123'), hasLength(1));
      },
    );

    for (final (method, name) in [
      (HttpMethod.get, 'API_KEY'),
    ]) {
      test(
        '$method rejects an invalid encryption key without changing storage',
        () async {
          final response = await request(
            method: method,
            name: name,
            body: jsonEncode({'name': 'API_KEY', 'value': 'replacement'}),
            environment: {'SECRET_ENCRYPTION_KEY': 'invalid-key'},
          );
          expect(response.statusCode, HttpStatus.internalServerError);
          expect(await response.json(), {
            'success': false,
            'error': 'Invalid encryption key configuration',
          });
          final stored = await db.secretDao.getSecret('team-123', 'API_KEY');
          expect(stored!.encryptedValue, 'stored-ciphertext');
        },
      );
    }

    for (final (method, name) in [
      (HttpMethod.get, 'API_KEY'),
      (HttpMethod.delete, 'API_KEY'),
    ]) {
      test('$method $name hides database failure details', () async {
        final failingDb = MockAppDatabase();
        when(() => failingDb.teamDao).thenReturn(db.teamDao);
        when(
          () => failingDb.secretDao,
        ).thenThrow(StateError('private-db-detail'));
        final response = await request(
          method: method,
          name: name,
          body: jsonEncode({'name': 'API_KEY', 'value': 'replacement'}),
          database: failingDb,
        );
        expect(response.statusCode, HttpStatus.internalServerError);
        expect(await response.json(), {
          'success': false,
          'error': 'Internal server error',
        });
        final stored = await db.secretDao.getSecret('team-123', 'API_KEY');
        expect(stored!.encryptedValue, 'stored-ciphertext');
      });
    }
  });

  group('Secrets Endpoints', () {
    group('GET /teams/<id>/secrets/<name>', () {
      test(
        'returns the decrypted secret with an internal key and no UID',
        () async {
          await db
              .into(db.teamMembers)
              .insert(
                TeamMembersCompanion.insert(
                  teamId: 'team-123',
                  userId: 'user-1',
                ),
              );

          final postContext = TestRequestContext(
            path: '/teams/team-123/secrets',
            method: HttpMethod.post,
            body: jsonEncode({
              'name': 'DB_PASSWORD',
              'value': 'secret-pass-99',
            }),
          );
          postContext.provide<AppDatabase>(db);
          postContext.provide<String?>('user-1');
          postContext.provide<Map<String, String>>(env);
          postContext.provide<InternalApiKeyValidator>(
            const InternalApiKeyValidator.forTesting(
              environment: {'INTERNAL_API_KEY': 'test-internal-key'},
            ),
          );
          final saved = await index_route.onRequest(
            postContext.context,
            'team-123',
          );
          expect(saved.statusCode, HttpStatus.ok);

          final getContext = TestRequestContext(
            path: '/teams/team-123/secrets/DB_PASSWORD',
            method: HttpMethod.get,
            headers: {'Authorization': 'Bearer test-internal-key'},
          );
          getContext.provide<AppDatabase>(db);
          getContext.provide<String?>(null);
          getContext.provide<Map<String, String>>(env);
          getContext.provide<InternalApiKeyValidator>(
            const InternalApiKeyValidator.forTesting(
              environment: {'INTERNAL_API_KEY': 'test-internal-key'},
            ),
          );

          final response = await name_route.onRequest(
            getContext.context,
            'team-123',
            'DB_PASSWORD',
          );
          expect(response.statusCode, equals(HttpStatus.ok));

          final body = await response.json() as Map<String, dynamic>;
          expect(body['success'], isTrue);
          expect(body['value'], equals('secret-pass-99'));
        },
      );

      test('responds with 404 when secret is not found', () async {
        final getContext = TestRequestContext(
          path: '/teams/team-123/secrets/NOT_FOUND',
          method: HttpMethod.get,
          headers: {'Authorization': 'Bearer test-internal-key'},
        );
        getContext.provide<AppDatabase>(db);
        getContext.provide<String?>(null);
        getContext.provide<Map<String, String>>(env);
        getContext.provide<InternalApiKeyValidator>(
          const InternalApiKeyValidator.forTesting(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          ),
        );

        final response = await name_route.onRequest(
          getContext.context,
          'team-123',
          'NOT_FOUND',
        );
        expect(response.statusCode, equals(HttpStatus.notFound));
      });
    });

    group('DELETE /teams/<id>/secrets/<name>', () {
      test('responds with 200 OK and deletes secret for member', () async {
        await db
            .into(db.teamMembers)
            .insert(
              TeamMembersCompanion.insert(
                teamId: 'team-123',
                userId: 'user-1',
              ),
            );

        final now = DateTime.now().toUtc();
        await db.secretDao.insertOrUpdateSecret(
          DriftSecret(
            name: 'API_KEY',
            teamId: 'team-123',
            encryptedValue: 'super-secret-ciphertext',
            createdAt: now,
            updatedAt: now,
          ),
        );

        final context = TestRequestContext(
          path: '/teams/team-123/secrets/API_KEY',
          method: HttpMethod.delete,
        );
        context.provide<AppDatabase>(db);
        context.provide<String?>('user-1');
        context.provide<Map<String, String>>(env);

        final response = await name_route.onRequest(
          context.context,
          'team-123',
          'API_KEY',
        );
        expect(response.statusCode, equals(HttpStatus.ok));

        final retrieved = await db.secretDao.getSecret('team-123', 'API_KEY');
        expect(retrieved, isNull);
      });
    });
  });
}
