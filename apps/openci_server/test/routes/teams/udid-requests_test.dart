import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:openci_server/database.dart';
import 'package:test/test.dart';

import '../../../routes/teams/[id]/udid-requests.dart' as route;

void main() {
  late AppDatabase db;

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

    test('POST registers UDID request successfully', () async {
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

      final response = await route.onRequest(context.context, 'team-123');
      expect(response.statusCode, equals(HttpStatus.created));

      final json = jsonDecode(await response.body()) as Map<String, dynamic>;
      expect(json['success'], isTrue);
      expect(json['request']['udid'], equals('00008030-000A1D8A2D3C4E5F'));

      final requests = await db.udidRequestDao.getRequestsByTeamId('team-123');
      expect(requests, hasLength(1));
      expect(requests.first.udid, equals('00008030-000A1D8A2D3C4E5F'));
    });

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
