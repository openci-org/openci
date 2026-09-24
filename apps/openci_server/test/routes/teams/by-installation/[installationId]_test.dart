import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../../../routes/teams/by-installation/[installationId].dart'
    as route;

class _MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final team = DriftTeam(
      id: 'team-1',
      name: 'OpenCI',
      githubBaseUrl: 'https://github.example.com',
      installationIds: const [12345, 67890],
      aiEnabled: false,
      runNumber: 42,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026, 2),
    );
    await db.teamDao.createTeamAndMember(
      team.copyWith(id: 'other-team', installationIds: [99999]),
      'other-member',
    );
    await db.teamDao.createTeamAndMember(team, 'member-1');
    await db.teamDao.addTeamMember(team.id, 'member-2');
  });

  tearDown(() => db.close());

  TestRequestContext createContext({
    String installationId = '12345',
    String? uid,
    String? token,
    AppDatabase? database,
  }) {
    final context = TestRequestContext(
      path: '/teams/by-installation/$installationId',
      method: HttpMethod.get,
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    context.provide<AppDatabase>(database ?? db);
    context.provide<String?>(uid);
    context.provide<InternalApiKeyValidator>(
      const InternalApiKeyValidator.forTesting(
        environment: {'INTERNAL_API_KEY': 'test-internal-key'},
      ),
    );
    return context;
  }

  group('GET /teams/by-installation/<installationId>', () {
    test(
      'allows a valid internal key without a UID and includes members',
      () async {
        final context = createContext(token: 'test-internal-key');

        final response = await route.onRequest(context.context, '12345');

        expect(response.statusCode, HttpStatus.ok);
        expect(await response.json(), {
          'id': 'team-1',
          'name': 'OpenCI',
          'members': unorderedEquals(['member-1', 'member-2']),
          'installationIds': [12345, 67890],
          'githubBaseUrl': 'https://github.example.com',
          'aiEnabled': false,
          'runNumber': 42,
          'createdAt': '2026-01-01T00:00:00.000Z',
          'updatedAt': '2026-02-01T00:00:00.000Z',
        });
      },
    );

    for (final uid in ['non-member', 'system-job-processor']) {
      test(
        'preserves authenticated user access for $uid without membership',
        () async {
          final context = createContext(uid: uid, token: 'firebase-id-token');

          final response = await route.onRequest(context.context, '12345');

          expect(response.statusCode, HttpStatus.ok);
          final body = await response.json() as Map<String, dynamic>;
          expect(body['id'], 'team-1');
          expect(body['members'], unorderedEquals(['member-1', 'member-2']));
        },
      );
    }

    for (final token in [null, '', 'incorrect-key']) {
      test(
        'rejects token=$token without a UID before reading the database',
        () async {
          final context = createContext(token: token);

          final response = await route.onRequest(context.context, '12345');

          expect(response.statusCode, HttpStatus.unauthorized);
          expect(await response.json(), {
            'success': false,
            'error': 'Authentication required',
          });
          verifyNever(() => context.context.read<AppDatabase>());
        },
      );
    }

    test(
      'rejects an invalid installation ID before reading the database',
      () async {
        final context = createContext(
          installationId: 'invalid',
          token: 'test-internal-key',
        );

        final response = await route.onRequest(context.context, 'invalid');

        expect(response.statusCode, HttpStatus.badRequest);
        expect(await response.json(), {
          'success': false,
          'error': 'Invalid installationId',
        });
        verifyNever(() => context.context.read<AppDatabase>());
      },
    );

    test('returns 404 when no team owns the installation', () async {
      final context = createContext(
        installationId: '54321',
        token: 'test-internal-key',
      );

      final response = await route.onRequest(context.context, '54321');

      expect(response.statusCode, HttpStatus.notFound);
      expect(await response.json(), {
        'success': false,
        'error': 'Team not found',
      });
    });

    test('hides database failure details', () async {
      final database = _MockAppDatabase();
      when(() => database.teamDao).thenThrow(
        StateError('private database connection detail'),
      );
      final context = createContext(
        token: 'test-internal-key',
        database: database,
      );

      final response = await route.onRequest(context.context, '12345');

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      verify(() => database.teamDao).called(1);
    });

    test('rejects unsupported methods before reading dependencies', () async {
      final context = TestRequestContext(
        path: '/teams/by-installation/12345',
        method: HttpMethod.put,
      );

      final response = await route.onRequest(context.context, '12345');

      expect(response.statusCode, HttpStatus.methodNotAllowed);
      verifyNever(() => context.context.read<AppDatabase>());
      verifyNever(() => context.context.read<InternalApiKeyValidator>());
    });
  });
}
