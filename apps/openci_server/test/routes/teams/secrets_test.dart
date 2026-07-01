import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/secret/secret_table.dart';
import 'package:test/test.dart';

import '../../../routes/teams/[id]/secrets/[name].dart' as name_route;
import '../../../routes/teams/[id]/secrets/index.dart' as index_route;

class MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  const encryptionKey = 'A9hs566HtB6B0ZEB2aKkAZpC81VGQxKMlFspt+vA5F4=';
  final env = {
    'SECRET_ENCRYPTION_KEY': encryptionKey,
    'ALLOWED_WORKER_UIDS': 'worker-1',
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
        'responds with 200 OK and encrypts and stores secret for authorized worker',
        () async {
          final context = TestRequestContext(
            path: '/teams/team-123/secrets',
            method: HttpMethod.post,
            body: jsonEncode({'name': 'WORKER_SECRET', 'value': 'worker-val'}),
          );
          context.provide<AppDatabase>(db);
          context.provide<String?>('worker-1');
          context.provide<Map<String, String>>(env);

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
        'responds with 200 OK and lists redacted secrets for authorized workers',
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
          );
          context.provide<AppDatabase>(db);
          context.provide<String?>('worker-1');
          context.provide<Map<String, String>>(env);

          final response = await index_route.onRequest(
            context.context,
            'team-123',
          );
          expect(response.statusCode, equals(HttpStatus.ok));
        },
      );
    });

    group('GET /teams/<id>/secrets/<name>', () {
      test(
        'responds with 200 OK and decrypted value for authorized worker',
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
          await index_route.onRequest(postContext.context, 'team-123');

          final getContext = TestRequestContext(
            path: '/teams/team-123/secrets/DB_PASSWORD',
            method: HttpMethod.get,
          );
          getContext.provide<AppDatabase>(db);
          getContext.provide<String?>('worker-1');
          getContext.provide<Map<String, String>>(env);

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
        );
        getContext.provide<AppDatabase>(db);
        getContext.provide<String?>('worker-1');
        getContext.provide<Map<String, String>>(env);

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
