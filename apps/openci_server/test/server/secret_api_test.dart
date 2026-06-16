import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/environment_value/environment_value.dart';
import 'package:openci_server/router.dart';
import 'package:openci_server/storage.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../storage/fake_storage.dart';

void main() {
  group('Secrets API Tests', () {
    late Handler handler;
    late AppDatabase db;
    const localHost = "http://localhost";
    const teamId = 'test-team-id';
    const userId =
        'test-uid'; // Matched with test-uid from mock authMiddleware in apply_middleware.dart

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final envValue = EnvironmentValue.load(
        environment: {
          'DATABASE_URL': 'postgres://localhost:5432/test',
          'SECRET_ENCRYPTION_KEY':
              'AAECAwQFBgcICQoLDA0ODxAREhMUFRYXGBkaGxwdHh8=',
        },
      );
      final container = ProviderContainer(
        overrides: [
          environmentValueProvider.overrideWithValue(envValue),
          databaseProvider.overrideWithValue(db),
          storageProvider.overrideWithValue(FakeStorageManager()),
          firebaseAppProvider.overrideWithValue(null),
        ],
      );
      handler = container.read(handlerProvider);

      // Insert dummy team and team member for validation
      await db
          .into(db.teams)
          .insert(
            DriftTeam(
              id: teamId,
              name: 'Test Team',
              githubBaseUrl: null,
              githubApiBaseUrl: null,
              installationIds: const [],
              aiEnabled: true,
              runNumber: 1,
              createdAt: DateTime.now().toUtc(),
              updatedAt: DateTime.now().toUtc(),
            ),
          );

      await db
          .into(db.teamMembers)
          .insert(
            TeamMembersCompanion.insert(
              teamId: teamId,
              userId: userId,
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('POST /teams/<teamId>/secrets creates encrypted secret', () async {
      final request = Request(
        'POST',
        Uri.parse('$localHost/teams/$teamId/secrets'),
        body: jsonEncode({'name': 'SSH_KEY', 'value': 'my-super-secret-key'}),
      );

      final response = await handler(request);
      expect(response.statusCode, equals(200));

      final body =
          jsonDecode(await response.readAsString()) as Map<String, dynamic>;
      expect(body['success'], isTrue);
      expect(body['name'], equals('SSH_KEY'));

      // Verify it is encrypted in DB
      final dbSecret =
          await (db.select(
                db.secrets,
              )..where(
                (t) => t.name.equals('SSH_KEY') & t.teamId.equals(teamId),
              ))
              .getSingle();
      expect(dbSecret.name, equals('SSH_KEY'));
      expect(dbSecret.encryptedValue, isNot(contains('my-super-secret-key')));
      expect(
        dbSecret.encryptedValue,
        contains(':'),
      ); // check iv:ciphertext format
    });

    test('GET /teams/<teamId>/secrets lists secrets metadata only', () async {
      // 1. Create a secret
      final createReq = Request(
        'POST',
        Uri.parse('$localHost/teams/$teamId/secrets'),
        body: jsonEncode({'name': 'API_KEY', 'value': 'token123'}),
      );
      await handler(createReq);

      // 2. List secrets
      final listReq = Request(
        'GET',
        Uri.parse('$localHost/teams/$teamId/secrets'),
      );
      final response = await handler(listReq);
      expect(response.statusCode, equals(200));

      final list = jsonDecode(await response.readAsString()) as List<dynamic>;
      expect(list.length, equals(1));
      expect(list[0]['name'], equals('API_KEY'));
      expect(
        list[0]['encryptedValue'],
        isNull,
      ); // Values should be hidden in list
    });

    test(
      'GET /teams/<teamId>/secrets/<name>/value decrypts value correctly',
      () async {
        // 1. Create a secret
        final createReq = Request(
          'POST',
          Uri.parse('$localHost/teams/$teamId/secrets'),
          body: jsonEncode({'name': 'DB_PASSWORD', 'value': 'postgres123'}),
        );
        await handler(createReq);

        // 2. Get decrypted value
        final valReq = Request(
          'GET',
          Uri.parse('$localHost/teams/$teamId/secrets/DB_PASSWORD/value'),
        );
        final response = await handler(valReq);
        expect(response.statusCode, equals(200));

        final body =
            jsonDecode(await response.readAsString()) as Map<String, dynamic>;
        expect(body['success'], isTrue);
        expect(body['value'], equals('postgres123'));
      },
    );

    test('GET /teams/<teamId>/secrets fails for non-team member', () async {
      final listReq = Request(
        'GET',
        Uri.parse('$localHost/teams/non-existent-team/secrets'),
      );
      final response = await handler(listReq);
      expect(response.statusCode, equals(403)); // Forbidden
    });

    test(
      'POST /teams/<teamId>/secrets returns 409 when secret name is duplicated',
      () async {
        final request1 = Request(
          'POST',
          Uri.parse('$localHost/teams/$teamId/secrets'),
          body: jsonEncode({'name': 'DUPLICATE_KEY', 'value': 'first-value'}),
        );
        final response1 = await handler(request1);
        expect(response1.statusCode, equals(200));

        final request2 = Request(
          'POST',
          Uri.parse('$localHost/teams/$teamId/secrets'),
          body: jsonEncode({'name': 'DUPLICATE_KEY', 'value': 'second-value'}),
        );
        final response2 = await handler(request2);
        expect(response2.statusCode, equals(409));

        final body =
            jsonDecode(await response2.readAsString()) as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(
          body['error'],
          equals('a secret with this name already exists in the team'),
        );
      },
    );
  });
}
