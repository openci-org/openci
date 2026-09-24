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
      (HttpMethod.get, null),
      (HttpMethod.post, null),
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
          '$method rejects uid=$uid token=$token before accessing secrets',
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
              body: 'not-json',
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

    test('allows the former internal UID as an ordinary team member', () async {
      await db.teamDao.addTeamMember('team-123', 'system-job-processor');

      final saved = await request(
        method: HttpMethod.post,
        uid: 'system-job-processor',
        body: jsonEncode({'name': 'API_KEY', 'value': 'replacement'}),
      );
      expect(saved.statusCode, HttpStatus.ok);

      final listed = await request(
        method: HttpMethod.get,
        uid: 'system-job-processor',
      );
      expect(listed.statusCode, HttpStatus.ok);
      final body = await listed.json() as Map<String, dynamic>;
      final secrets = body['secrets'] as List<dynamic>;
      expect(secrets, hasLength(1));
      expect(secrets.single['name'], 'API_KEY');
      expect(secrets.single['encryptedValue'], '[REDACTED]');
    });

    for (final name in [null]) {
      test('unsupported method for $name returns 405', () async {
        final response = await request(method: HttpMethod.patch, name: name);
        expect(response.statusCode, HttpStatus.methodNotAllowed);
        expect(await db.secretDao.getSecret('team-123', 'API_KEY'), isNotNull);
      });
    }

    for (final payload in [
      '{',
      '[]',
      jsonEncode({'value': 'value'}),
      jsonEncode({'name': '  ', 'value': 'value'}),
      jsonEncode({'name': 1, 'value': 'value'}),
      jsonEncode({'name': 'NEW_SECRET'}),
      jsonEncode({'name': 'NEW_SECRET', 'value': '  '}),
      jsonEncode({'name': 'NEW_SECRET', 'value': 1}),
    ]) {
      test('invalid payload $payload is rejected before storage', () async {
        final response = await request(method: HttpMethod.post, body: payload);
        expect(response.statusCode, HttpStatus.badRequest);
        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], isNotEmpty);
        expect(await db.secretDao.getSecretsForTeam('team-123'), hasLength(1));
      });
    }

    for (final (method, name) in [
      (HttpMethod.post, null),
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
      (HttpMethod.get, null),
      (HttpMethod.post, null),
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
    group('POST /teams/<id>/secrets', () {
      test('responds with 401 Unauthorized when uid is null', () async {
        final context = TestRequestContext(
          path: '/teams/team-123/secrets',
          method: HttpMethod.post,
          body: jsonEncode({'name': 'MY_SECRET', 'value': 'my-value'}),
        );
        context.provide<AppDatabase>(db);
        context.provide<String?>(null);
        context.provide<Map<String, String>>(env);
        context.provide<InternalApiKeyValidator>(
          const InternalApiKeyValidator.forTesting(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          ),
        );

        final response = await index_route.onRequest(
          context.context,
          'team-123',
        );
        expect(response.statusCode, equals(HttpStatus.unauthorized));
      });

      test(
        'responds with 403 Forbidden when user is not team member',
        () async {
          final context = TestRequestContext(
            path: '/teams/team-123/secrets',
            method: HttpMethod.post,
            body: jsonEncode({'name': 'MY_SECRET', 'value': 'my-value'}),
          );
          context.provide<AppDatabase>(db);
          context.provide<String?>('non-member-user');
          context.provide<Map<String, String>>(env);
          context.provide<InternalApiKeyValidator>(
            const InternalApiKeyValidator.forTesting(
              environment: {'INTERNAL_API_KEY': 'test-internal-key'},
            ),
          );

          final response = await index_route.onRequest(
            context.context,
            'team-123',
          );
          expect(response.statusCode, equals(HttpStatus.forbidden));
        },
      );

      test(
        'responds with 200 OK and encrypts and stores secret in database',
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
            path: '/teams/team-123/secrets',
            method: HttpMethod.post,
            body: jsonEncode({'name': 'MY_SECRET', 'value': 'my-value'}),
          );
          context.provide<AppDatabase>(db);
          context.provide<String?>('user-1');
          context.provide<Map<String, String>>(env);
          context.provide<InternalApiKeyValidator>(
            const InternalApiKeyValidator.forTesting(
              environment: {'INTERNAL_API_KEY': 'test-internal-key'},
            ),
          );

          final response = await index_route.onRequest(
            context.context,
            'team-123',
          );
          expect(response.statusCode, equals(HttpStatus.ok));

          final body = await response.json() as Map<String, dynamic>;
          expect(body['success'], isTrue);

          final retrieved = await db.secretDao.getSecret(
            'team-123',
            'MY_SECRET',
          );
          expect(retrieved, isNotNull);
          expect(retrieved!.encryptedValue, isNot(equals('my-value')));
        },
      );

      test(
        'encrypts and stores a secret with an internal key and no UID',
        () async {
          final context = TestRequestContext(
            path: '/teams/team-123/secrets',
            method: HttpMethod.post,
            body: jsonEncode({'name': 'WORKER_SECRET', 'value': 'worker-val'}),
            headers: {'Authorization': 'Bearer test-internal-key'},
          );
          context.provide<AppDatabase>(db);
          context.provide<String?>(null);
          context.provide<Map<String, String>>(env);
          context.provide<InternalApiKeyValidator>(
            const InternalApiKeyValidator.forTesting(
              environment: {'INTERNAL_API_KEY': 'test-internal-key'},
            ),
          );

          final response = await index_route.onRequest(
            context.context,
            'team-123',
          );
          expect(response.statusCode, equals(HttpStatus.ok));

          final body = await response.json() as Map<String, dynamic>;
          expect(body['success'], isTrue);

          final retrieved = await db.secretDao.getSecret(
            'team-123',
            'WORKER_SECRET',
          );
          expect(retrieved, isNotNull);
          expect(retrieved!.encryptedValue, isNot(equals('worker-val')));
        },
      );
    });

    group('GET /teams/<id>/secrets', () {
      test(
        'responds with 200 OK and lists redacted secrets for members',
        () async {
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
            path: '/teams/team-123/secrets',
            method: HttpMethod.get,
          );
          context.provide<AppDatabase>(db);
          context.provide<String?>('user-1');
          context.provide<Map<String, String>>(env);
          context.provide<InternalApiKeyValidator>(
            const InternalApiKeyValidator.forTesting(
              environment: {'INTERNAL_API_KEY': 'test-internal-key'},
            ),
          );

          final response = await index_route.onRequest(
            context.context,
            'team-123',
          );
          expect(response.statusCode, equals(HttpStatus.ok));

          final body = await response.json() as Map<String, dynamic>;
          expect(body['success'], isTrue);

          final secrets = body['secrets'] as List<dynamic>;
          expect(secrets, hasLength(1));
          expect(secrets[0]['name'], equals('API_KEY'));
          expect(secrets[0]['encryptedValue'], equals('[REDACTED]'));
        },
      );

      test(
        'lists redacted secrets with an internal key and no UID',
        () async {
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
            path: '/teams/team-123/secrets',
            method: HttpMethod.get,
            headers: {'Authorization': 'Bearer test-internal-key'},
          );
          context.provide<AppDatabase>(db);
          context.provide<String?>(null);
          context.provide<Map<String, String>>(env);
          context.provide<InternalApiKeyValidator>(
            const InternalApiKeyValidator.forTesting(
              environment: {'INTERNAL_API_KEY': 'test-internal-key'},
            ),
          );

          final response = await index_route.onRequest(
            context.context,
            'team-123',
          );
          expect(response.statusCode, equals(HttpStatus.ok));
          final body = await response.json() as Map<String, dynamic>;
          final secrets = body['secrets'] as List<dynamic>;
          expect(secrets, hasLength(1));
          expect(secrets.single['name'], 'API_KEY');
          expect(secrets.single['encryptedValue'], '[REDACTED]');
        },
      );
    });
  });
}
