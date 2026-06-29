import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/secret/secret_crypter.dart';
import 'package:openci_server/secret/secret_table.dart';
import 'package:test/test.dart';

import '../../../routes/teams/[id]/udid-requests.dart' as route;

const testEcPrivateKey = '''
-----BEGIN EC PRIVATE KEY-----
MHcCAQEEIEx9STNCGtFqfd8vYnBx9DRbFep08RvD9Sn9THZMoRqkoAoGCCqGSM49
AwEHoUQDQgAEURIjr4CE+BXTTtbFqt2Swq+I0RIfKyEgmld7mV+GfC5LHR+emoXh
QyoA0WQ8BvnS8losZmYLLPXf0Mb4lxJI7Q==
-----END EC PRIVATE KEY-----
''';

const encryptionKey = 'cTN0Nnc5eiRDJkYpSkBOY1FmVGZXblpyNHU3eCFBJUQ=';

void main() {
  late AppDatabase db;
  late Map<String, String> testEnv;

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
    await db
        .into(db.teamMembers)
        .insert(
          TeamMembersCompanion.insert(
            teamId: 'team-123',
            userId: 'user-123',
          ),
        );

    testEnv = {
      'SECRET_ENCRYPTION_KEY': encryptionKey,
    };
  });

  tearDown(() async {
    await db.close();
  });

  group('UDID Requests Endpoint', () {
    test('POST responds with 401 Unauthorized when uid is null', () async {
      final context = TestRequestContext(
        path: '/teams/team-123/udid-requests',
        method: HttpMethod.post,
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>(null);

      final response = await route.onRequest(context.context, 'team-123');
      expect(response.statusCode, equals(HttpStatus.unauthorized));
    });

    test(
      'POST responds with 403 Forbidden when user is not a member',
      () async {
        final context = TestRequestContext(
          path: '/teams/team-123/udid-requests',
          method: HttpMethod.post,
        );
        context.provide<AppDatabase>(db);
        context.provide<String?>('other-user');

        final response = await route.onRequest(context.context, 'team-123');
        expect(response.statusCode, equals(HttpStatus.forbidden));
      },
    );

    test(
      'POST registers UDID request successfully and skips auto-register if no ASC secrets',
      () async {
        final requestBody = jsonEncode({
          'udid': '00008030-000A1D8A2D3C4E5F',
        });

        final context = TestRequestContext(
          path: '/teams/team-123/udid-requests',
          method: HttpMethod.post,
          body: requestBody,
        );
        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<Map<String, String>>(testEnv);

        final response = await route.onRequest(context.context, 'team-123');
        expect(response.statusCode, equals(HttpStatus.created));

        final json = jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(json['success'], isTrue);
        expect(json['request']['udid'], equals('00008030-000A1D8A2D3C4E5F'));
        expect(json['autoRegistered'], isFalse);

        final requests = await db.udidRequestDao.getRequestsByTeamId(
          'team-123',
        );
        expect(requests, hasLength(1));
        expect(requests.first.udid, equals('00008030-000A1D8A2D3C4E5F'));
      },
    );

    test(
      'POST registers UDID request and triggers auto-register successfully',
      () async {
        final crypter = SecretCrypter(encryptionKey);
        final now = DateTime.now().toUtc();
        await db
            .into(db.secrets)
            .insert(
              DriftSecret(
                name: 'OPENCI_ASC_ISSUER_ID',
                teamId: 'team-123',
                encryptedValue: await crypter.encrypt('issuer-abc'),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db
            .into(db.secrets)
            .insert(
              DriftSecret(
                name: 'OPENCI_ASC_KEY_ID',
                teamId: 'team-123',
                encryptedValue: await crypter.encrypt('key-def'),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db
            .into(db.secrets)
            .insert(
              DriftSecret(
                name: 'OPENCI_ASC_PRIVATE_KEY',
                teamId: 'team-123',
                encryptedValue: await crypter.encrypt(testEcPrivateKey),
                createdAt: now,
                updatedAt: now,
              ),
            );

        final mockHttpClient = MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.toString() ==
                  'https://api.appstoreconnect.apple.com/v1/devices') {
            final body = jsonDecode(request.body) as Map<String, dynamic>;
            final attributes =
                body['data']['attributes'] as Map<String, dynamic>;
            expect(attributes['udid'], equals('00008030-000A1D8A2D3C4E5F'));

            return http.Response(
              jsonEncode({
                'data': {'id': 'device-999', 'type': 'devices'},
              }),
              201,
            );
          }
          return http.Response('Not Found', 404);
        });

        final requestBody = jsonEncode({
          'udid': '00008030-000A1D8A2D3C4E5F',
        });

        final context = TestRequestContext(
          path: '/teams/team-123/udid-requests',
          method: HttpMethod.post,
          body: requestBody,
        );
        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<Map<String, String>>(testEnv);
        context.provide<http.Client>(mockHttpClient);

        final response = await route.onRequest(context.context, 'team-123');
        expect(response.statusCode, equals(HttpStatus.created));

        final json = jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(json['success'], isTrue);
        expect(json['autoRegistered'], isTrue);
        expect(json['alreadyRegistered'], isFalse);
      },
    );

    test(
      'POST registers UDID request and handles already registered device (409 Conflict)',
      () async {
        final crypter = SecretCrypter(encryptionKey);
        final now = DateTime.now().toUtc();
        await db
            .into(db.secrets)
            .insert(
              DriftSecret(
                name: 'OPENCI_ASC_ISSUER_ID',
                teamId: 'team-123',
                encryptedValue: await crypter.encrypt('issuer-abc'),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db
            .into(db.secrets)
            .insert(
              DriftSecret(
                name: 'OPENCI_ASC_KEY_ID',
                teamId: 'team-123',
                encryptedValue: await crypter.encrypt('key-def'),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await db
            .into(db.secrets)
            .insert(
              DriftSecret(
                name: 'OPENCI_ASC_PRIVATE_KEY',
                teamId: 'team-123',
                encryptedValue: await crypter.encrypt(testEcPrivateKey),
                createdAt: now,
                updatedAt: now,
              ),
            );

        final mockHttpClient = MockClient((request) async {
          if (request.method == 'POST' &&
              request.url.toString() ==
                  'https://api.appstoreconnect.apple.com/v1/devices') {
            return http.Response(
              jsonEncode({
                'errors': [
                  {
                    'code': 'ENTITY_LIMIT_EXCEEDED',
                    'status': '409',
                    'title': 'The device has already been registered',
                  },
                ],
              }),
              409,
            );
          }
          return http.Response('Not Found', 404);
        });

        final requestBody = jsonEncode({
          'udid': '00008030-000A1D8A2D3C4E5F',
        });

        final context = TestRequestContext(
          path: '/teams/team-123/udid-requests',
          method: HttpMethod.post,
          body: requestBody,
        );
        context.provide<AppDatabase>(db);
        context.provide<String?>('user-123');
        context.provide<Map<String, String>>(testEnv);
        context.provide<http.Client>(mockHttpClient);

        final response = await route.onRequest(context.context, 'team-123');
        expect(response.statusCode, equals(HttpStatus.created));

        final json = jsonDecode(await response.body()) as Map<String, dynamic>;
        expect(json['success'], isTrue);
        expect(json['autoRegistered'], isFalse);
        expect(json['alreadyRegistered'], isTrue);
      },
    );

    test('GET retrieves UDID requests for team', () async {
      final requestBody = jsonEncode({
        'udid': '00008030-000A1D8A2D3C4E5F',
      });

      final contextPost = TestRequestContext(
        path: '/teams/team-123/udid-requests',
        method: HttpMethod.post,
        body: requestBody,
      );
      contextPost.provide<AppDatabase>(db);
      contextPost.provide<String?>('user-123');

      await route.onRequest(contextPost.context, 'team-123');

      final contextGet = TestRequestContext(
        path: '/teams/team-123/udid-requests',
        method: HttpMethod.get,
      );
      contextGet.provide<AppDatabase>(db);
      contextGet.provide<String?>('user-123');

      final response = await route.onRequest(contextGet.context, 'team-123');
      expect(response.statusCode, equals(HttpStatus.ok));

      final json = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(json['success'], isTrue);
      expect(json['requests'], hasLength(1));
      expect(json['requests'][0]['udid'], equals('00008030-000A1D8A2D3C4E5F'));
    });
  });
}
