import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:drift/native.dart';
import 'package:genuineci_server/auth/internal_api_key_validator.dart';
import 'package:genuineci_server/build_job/build_job_dao.dart';
import 'package:genuineci_server/database.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:test/test.dart';

import '../../routes/_middleware.dart' as root;
import '../../routes/internal/_middleware.dart' as internal;
import '../../routes/internal/seed/teams.dart' as seed_teams;
import '../../routes/teams/by-installation/[installationId].dart'
    as installation;
import '../../routes/teams/index.dart' as teams;
import '../../routes/webhooks/_middleware.dart' as webhooks;
import '../../routes/webhooks/claim.dart' as webhook_claim;
import '../../routes/worker/_middleware.dart' as worker;
import '../../routes/worker/jobs/claim.dart' as job_claim;

class _MockDatabase extends Mock implements AppDatabase {}

class _MockBuildJobDao extends Mock implements BuildJobDao {}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
  });

  Future<http.Response> request({
    required String path,
    required Handler route,
    String method = 'GET',
    Map<String, String> headers = const {},
    AppDatabase? database,
    bool internalEnabled = true,
  }) async {
    final handler = route
        .use(root.databaseProvider(database ?? db))
        .use(root.authProvider(null))
        .use(
          provider<InternalApiKeyValidator>(
            (_) => const InternalApiKeyValidator.forTesting(
              environment: {'INTERNAL_API_KEY': 'test-internal-key'},
            ),
          ),
        )
        .use(root.corsMiddleware(environment: const {}))
        .use(
          root.internalRoutesMiddleware(
            environment: {'ENABLE_INTERNAL_API': '$internalEnabled'},
          ),
        );
    final server = await serve(handler, InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final uri = Uri(
      scheme: 'http',
      host: server.address.address,
      port: server.port,
    ).resolve(path);
    final client = http.Client();
    addTearDown(client.close);
    final message = http.Request(method, uri)
      ..headers.addAll(headers)
      ..body = '{}';
    return http.Response.fromStream(await client.send(message));
  }

  test(
    'the internal key can claim jobs through root and worker authentication',
    () async {
      final database = _MockDatabase();
      final dao = _MockBuildJobDao();
      when(() => database.buildJobDao).thenReturn(dao);
      when(() => dao.claimNextJob()).thenAnswer((_) async => null);

      final response = await request(
        path: '/worker/jobs/claim',
        route: worker.middleware(job_claim.onRequest),
        method: 'POST',
        headers: {'Authorization': 'Bearer test-internal-key'},
        database: database,
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(jsonDecode(response.body), {'job': null});
      verify(() => dao.claimNextJob()).called(1);
    },
  );

  test(
    'the internal key can claim webhooks through root authentication',
    () async {
      final response = await request(
        path: '/webhooks/claim',
        route: webhooks.middleware(webhook_claim.onRequest),
        method: 'POST',
        headers: {'Authorization': 'Bearer test-internal-key'},
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(jsonDecode(response.body), {'task': null});
    },
  );

  test('the internal key can seed teams through root authentication', () async {
    final response = await request(
      path: '/internal/seed/teams',
      route: internal.middleware(seed_teams.onRequest),
      method: 'POST',
      headers: {'Authorization': 'Bearer test-internal-key'},
    );

    expect(response.statusCode, HttpStatus.ok);
    expect(jsonDecode(response.body)['success'], isTrue);
    expect(await db.teamDao.getTeam('test-team'), isNotNull);
  });

  for (final (path, route) in <(String, Handler)>[
    (
      '/worker/jobs/claim',
      worker.middleware(job_claim.onRequest),
    ),
    (
      '/webhooks/claim',
      webhooks.middleware(webhook_claim.onRequest),
    ),
    (
      '/internal/seed/teams',
      internal.middleware(seed_teams.onRequest),
    ),
  ]) {
    group('root authentication with POST $path', () {
      for (final token in [null, '', 'incorrect-key']) {
        test('rejects token=$token before database access', () async {
          final database = _MockDatabase();
          final response = await request(
            path: path,
            route: route,
            method: 'POST',
            headers: {
              if (token != null) 'Authorization': 'Bearer $token',
            },
            database: database,
          );

          expect(response.statusCode, HttpStatus.unauthorized);
          expect(jsonDecode(response.body), {
            'success': false,
            'error': 'Authentication required',
          });
          verifyZeroInteractions(database);
        });
      }
    });
  }

  test('an internal key can resolve a team through a shared route', () async {
    await db.teamDao.createTeamAndMember(
      DriftTeam(
        id: 'team-1',
        name: 'OpenCI',
        installationIds: const [12345],
        aiEnabled: false,
        runNumber: 1,
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      'member-1',
    );

    final response = await request(
      path: '/teams/by-installation/12345',
      route: (context) => installation.onRequest(context, '12345'),
      headers: {'Authorization': 'Bearer test-internal-key'},
    );

    expect(response.statusCode, HttpStatus.ok);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    expect(body['id'], 'team-1');
    expect(body['members'], ['member-1']);
  });

  for (final method in ['GET', 'POST']) {
    test(
      'an internal key cannot use the user-only $method /teams route',
      () async {
        final database = _MockDatabase();
        final response = await request(
          path: '/teams',
          route: teams.onRequest,
          method: method,
          headers: {'Authorization': 'Bearer test-internal-key'},
          database: database,
        );

        expect(response.statusCode, HttpStatus.unauthorized);
        expect(jsonDecode(response.body), {
          'success': false,
          'error': 'Authentication required',
        });
        verifyZeroInteractions(database);
      },
    );
  }

  test(
    'a wrong Bearer token cannot fall back to an internal query key',
    () async {
      final database = _MockDatabase();
      final response = await request(
        path:
            '/worker/jobs/claim?token=test-internal-key&auth=test-internal-key',
        route: worker.middleware(job_claim.onRequest),
        method: 'POST',
        headers: {'Authorization': 'Bearer incorrect-key'},
        database: database,
      );

      expect(response.statusCode, HttpStatus.unauthorized);
      verifyZeroInteractions(database);
    },
  );

  test(
    'CORS preflight succeeds before root and worker authentication',
    () async {
      final database = _MockDatabase();
      final response = await request(
        path: '/worker/jobs/claim',
        route: worker.middleware(job_claim.onRequest),
        method: 'OPTIONS',
        headers: {'Origin': 'https://dashboard.openci.org'},
        database: database,
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(
        response.headers['access-control-allow-origin'],
        'https://dashboard.openci.org',
      );
      verifyZeroInteractions(database);
    },
  );

  for (final method in ['POST', 'OPTIONS']) {
    test(
      'disabled internal APIs return 404 for $method with a valid key',
      () async {
        final database = _MockDatabase();
        final response = await request(
          path: '/internal/seed/teams',
          route: internal.middleware(seed_teams.onRequest),
          method: method,
          headers: {
            'Authorization': 'Bearer test-internal-key',
            'Origin': 'https://dashboard.openci.org',
          },
          database: database,
          internalEnabled: false,
        );

        expect(response.statusCode, HttpStatus.notFound);
        expect(
          response.headers,
          isNot(contains('access-control-allow-origin')),
        );
        verifyZeroInteractions(database);
      },
    );
  }
}
