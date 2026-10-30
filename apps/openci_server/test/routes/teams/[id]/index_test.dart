import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/billing/billing_proxy.dart';
import 'package:openci_server/billing/billing_proxy_config.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/team/team_dao.dart';
import 'package:test/test.dart';

import '../../../helpers/database_failure_checks.dart';
import '../../../../routes/teams/[id]/index.dart' as route;

class MockAppDatabase extends Mock implements AppDatabase {}

class MockTeamDao extends Mock implements TeamDao {}

class MockBillingProxy extends Mock implements BillingProxy {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      DriftTeam(
        id: 'dummy',
        name: 'dummy',
        installationIds: const [],
        aiEnabled: true,
        runNumber: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('DELETE /teams/<id>', () {
    test(
      'responds with 401 Unauthorized when unauthorized (uid is null)',
      () async {
        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.delete,
        );

        context.provide<AppDatabase>(db);
        context.provide<BillingProxy?>(null);
        context.provide<String?>(null);

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.unauthorized));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Authentication required'));
      },
    );

    test(
      'responds with 403 Forbidden when user is not a member of the team',
      () async {
        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.delete,
        );

        context.provide<AppDatabase>(db);
        context.provide<BillingProxy?>(null);
        context.provide<String?>('stranger-user');

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.forbidden));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Forbidden'));
      },
    );

    test(
      'responds with 404 Not Found when team does not exist in DB',
      () async {
        await db
            .into(db.teamMembers)
            .insert(
              TeamMembersCompanion.insert(
                teamId: 'team-non-existent',
                userId: 'user-1',
              ),
            );

        final context = TestRequestContext(
          path: '/teams/team-non-existent',
          method: HttpMethod.delete,
        );

        context.provide<AppDatabase>(db);
        context.provide<BillingProxy?>(null);
        context.provide<String?>('user-1');

        final response = await route.onRequest(
          context.context,
          'team-non-existent',
        );

        expect(response.statusCode, equals(HttpStatus.notFound));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Team not found'));
      },
    );

    test(
      'responds with 200 OK and deletes team and member from database',
      () async {
        final now = DateTime.now().toUtc();
        final team = DriftTeam(
          id: 'team-123',
          name: 'Delete Me Team',
          installationIds: const [],
          aiEnabled: true,
          runNumber: 1,
          createdAt: now,
          updatedAt: now,
        );
        await db.teamDao.createTeamAndMember(team, 'user-1');

        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.delete,
        );

        context.provide<AppDatabase>(db);
        context.provide<BillingProxy?>(null);
        context.provide<String?>('user-1');

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.ok));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isTrue);

        final deletedTeam = await (db.select(
          db.teams,
        )..where((t) => t.id.equals('team-123'))).getSingleOrNull();
        expect(deletedTeam, isNull);

        final members = await (db.select(
          db.teamMembers,
        )..where((m) => m.teamId.equals('team-123'))).get();
        expect(members, isEmpty);
      },
    );

    test(
      'responds with 500 Internal Server Error when database fails on select',
      () async {
        final mockDb = MockAppDatabase();
        final mockTeamDao = MockTeamDao();

        when(() => mockDb.teamDao).thenReturn(mockTeamDao);
        when(
          () => mockTeamDao.isTeamMember(any(), any()),
        ).thenAnswer((_) async => true);

        when(
          () => mockDb.select(mockDb.teams),
        ).thenThrow(Exception('Select failed'));

        final context = TestRequestContext(
          path: '/teams/team-123',
          method: HttpMethod.delete,
        );

        context.provide<AppDatabase>(mockDb);
        context.provide<BillingProxy?>(null);
        context.provide<String?>('user-1');

        final response = await route.onRequest(context.context, 'team-123');

        expect(response.statusCode, equals(HttpStatus.internalServerError));

        final body = await response.json() as Map<String, dynamic>;
        expect(body['success'], isFalse);
        expect(body['error'], equals('Internal server error'));
      },
    );
  });

  group('Cloud billing team deletion', () {
    late List<http.Request> requests;
    late BillingProxy proxy;
    var upstreamStatus = HttpStatus.ok;
    var upstreamBody = '{"success":true,"private":"hidden"}';

    setUp(() async {
      final now = DateTime.now().toUtc();
      await db.teamDao.createTeamAndMember(
        DriftTeam(
          id: 'team-1',
          name: 'Cloud Team',
          installationIds: const [],
          aiEnabled: false,
          runNumber: 1,
          createdAt: now,
          updatedAt: now,
        ),
        'user-1',
      );
      requests = [];
      upstreamStatus = HttpStatus.ok;
      upstreamBody = '{"success":true,"private":"hidden"}';
      final client = MockClient((request) async {
        requests.add(request);
        return http.Response(upstreamBody, upstreamStatus);
      });
      addTearDown(client.close);
      proxy = BillingProxy(
        BillingProxyConfig.fromEnvironment({
          'SERVER_ACCESS_MODE': 'cloud',
          'BILLING_ENABLED': 'true',
          'GENUINECI_SERVER_URL': 'http://genuineci-server:8081',
          'BILLING_INTERNAL_TOKEN': '01234567890123456789012345678901',
        })!,
        client,
      );
    });

    Future<Response> deleteTeam({String? uid = 'user-1'}) {
      final context = TestRequestContext(
        path: '/teams/team-1',
        method: HttpMethod.delete,
        headers: {'x-genuineci-user-id': 'forged-user'},
        body: '{"userId":"forged-user","force":true}',
      );
      context.provide<AppDatabase>(db);
      context.provide<String?>(uid);
      context.provide<BillingProxy?>(proxy);
      return route.onRequest(context.context, 'team-1') as Future<Response>;
    }

    test(
      'uses Go atomic deletion with verified identity and no client body',
      () async {
        final response = await deleteTeam();
        expect(response.statusCode, HttpStatus.ok);
        expect(await response.json(), {'success': true});
        expect(response.headers['cache-control'], 'no-store');
        final request = requests.single;
        expect(request.method, 'DELETE');
        expect(request.url.path, '/internal/billing/teams/team-1');
        expect(request.headers['x-genuineci-user-id'], 'user-1');
        expect(request.body, isEmpty);
        expect(await db.teamDao.getTeam('team-1'), isNotNull);
      },
    );

    test('asynchronous proxy failures reach the route error handler', () async {
      proxy = MockBillingProxy();
      when(
        () => proxy.request(
          operation: BillingOperation.deleteTeam,
          teamId: 'team-1',
          uid: 'user-1',
        ),
      ).thenAnswer((_) async => throw StateError('proxy failed'));

      final response = await deleteTeam();

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(await db.teamDao.getTeam('team-1'), isNotNull);
    });

    test('unauthenticated callers never reach the billing server', () async {
      expect((await deleteTeam(uid: null)).statusCode, HttpStatus.unauthorized);
      expect(requests, isEmpty);
    });

    for (final code in [
      'subscription_exists',
      'payment_pending',
      'forbidden',
    ]) {
      test(
        'preserves $code without falling back to unguarded deletion',
        () async {
          upstreamStatus = code == 'forbidden'
              ? HttpStatus.forbidden
              : HttpStatus.conflict;
          upstreamBody = jsonEncode({'error': code});
          final response = await deleteTeam();
          expect(response.statusCode, upstreamStatus);
          expect(await response.json(), {'error': code});
          expect(await db.teamDao.getTeam('team-1'), isNotNull);
        },
      );
    }

    test(
      'invalid success and upstream failures never delete locally',
      () async {
        for (final status in [HttpStatus.ok, HttpStatus.internalServerError]) {
          upstreamStatus = status;
          upstreamBody = '{"success":false,"error":"private"}';
          final response = await deleteTeam();
          expect(response.statusCode, HttpStatus.serviceUnavailable);
          expect(await response.json(), {'error': 'billing_unavailable'});
          expect(await db.teamDao.getTeam('team-1'), isNotNull);
        }
      },
    );
  });

  testDatabaseFailures([
    DatabaseFailureEndpoint(
      '/teams/team-1',
      HttpMethod.delete,
      (c) => route.onRequest(c, 'team-1'),
    ),
  ]);
}
