import 'dart:convert';
import 'dart:io';

import 'package:dart_frog/dart_frog.dart';
import 'package:dart_frog_test/dart_frog_test.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openci_server/auth/internal_api_key_validator.dart';
import 'package:openci_server/database.dart';
import 'package:openci_server/github/github_connection_table.dart';
import 'package:openci_server/team/team_dao.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../../../../../helpers/database_failure_checks.dart';
import '../../../../../helpers/github_app_test_key.dart';
import '../../../../../../routes/teams/[id]/repositories/[repo]/openci-files.dart'
    as route;

class _MockRequestContext extends Mock implements RequestContext {}

class _MockRequest extends Mock implements Request {}

class _MockAppDatabase extends Mock implements AppDatabase {}

class _MockTeamDao extends Mock implements TeamDao {}

void main() {
  group('GET /teams/[id]/repositories/[repo]/openci-files', () {
    late RequestContext context;
    late Request request;
    late AppDatabase db;
    late TeamDao teamDao;

    setUp(() {
      context = _MockRequestContext();
      request = _MockRequest();
      db = _MockAppDatabase();
      teamDao = _MockTeamDao();

      when(() => context.request).thenReturn(request);
      when(() => request.method).thenReturn(HttpMethod.get);
      when(() => request.headers).thenReturn({});
      when(() => context.read<InternalApiKeyValidator>()).thenReturn(
        const InternalApiKeyValidator(
          environment: {'INTERNAL_API_KEY': 'test-internal-key'},
        ),
      );
      when(() => context.read<AppDatabase>()).thenReturn(db);
      when(() => db.teamDao).thenReturn(teamDao);
      final client = MockClient(
        (_) async => fail('GitHub must not be contacted'),
      );
      addTearDown(client.close);
      when(() => context.read<http.Client>()).thenReturn(client);
      when(() => request.uri).thenReturn(
        Uri.parse(
          'http://localhost/teams/team123/repositories/my-repo/openci-files?ref=main',
        ),
      );
    });

    for (final (description, token) in [
      ('missing key', null),
      ('empty key', ''),
      ('incorrect key', 'incorrect-key'),
    ]) {
      test(
        'rejects a $description without a UID before database access',
        () async {
          when(() => context.read<String?>()).thenReturn(null);
          when(() => request.headers).thenReturn({
            if (token != null) 'authorization': 'Bearer $token',
          });

          final response = await route.onRequest(context, 'team123', 'my-repo');

          expect(response.statusCode, HttpStatus.unauthorized);
          verifyNever(() => context.read<AppDatabase>());
          verifyNever(() => context.read<http.Client>());
        },
      );
    }

    for (final uid in ['user-1', 'system-job-processor']) {
      test('rejects non-member $uid before contacting GitHub', () async {
        when(() => context.read<String?>()).thenReturn(uid);
        when(() => request.headers).thenReturn({
          'authorization': 'Bearer firebase-id-token',
        });
        when(
          () => teamDao.isTeamMember(uid, 'team123'),
        ).thenAnswer((_) async => false);

        final response = await route.onRequest(context, 'team123', 'my-repo');

        expect(response.statusCode, HttpStatus.forbidden);
        verifyNever(() => context.read<http.Client>());
      });
    }
  });

  group('OpenCI file retrieval', () {
    late AppDatabase db;
    late Directory tempDirectory;
    late Map<String, String> environment;
    late List<http.Request> requests;

    final connection = DriftGitHubConnection(
      id: 'connection-1',
      teamId: 'team-123',
      githubApiBaseUrl: 'https://api.github.test',
      githubAppId: 12345,
      installationId: 998877,
      accountId: 42,
      accountType: GitHubAccountType.organization,
      accountLogin: 'openci-org',
      verifiedByUserId: 'user-1',
      verifiedByGitHubUserId: 100,
      verifiedAt: DateTime.utc(2026),
      status: GitHubConnectionStatus.active,
    );

    Future<Response> get({
      String installationId = '998877',
      http.Response Function(http.Request)? respond,
    }) async {
      final client = MockClient((request) async {
        requests.add(request);
        return respond?.call(request) ?? fail('GitHub must not be contacted');
      });
      addTearDown(client.close);
      final context = _requestContext(
        db: db,
        path:
            '/teams/team-123/repositories/openci/openci-files'
            '?ref=commit-sha-123&owner=openci-org&installationId=$installationId',
        environment: environment,
        client: client,
      );
      return route.onRequest(context.context, 'team-123', 'openci');
    }

    setUp(() async {
      requests = [];
      db = AppDatabase(
        NativeDatabase.memory(
          setup: (database) => database.execute('PRAGMA foreign_keys = ON'),
        ),
      );
      final now = DateTime.now().toUtc();
      await db
          .into(db.teams)
          .insert(
            DriftTeam(
              id: 'team-123',
              name: 'A display name that is not the GitHub owner',
              installationIds: const [111111, 998877],
              aiEnabled: false,
              runNumber: 1,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await db.into(db.gitHubConnections).insert(connection);

      tempDirectory = Directory.systemTemp.createTempSync(
        'openci-files-test-',
      );
      final privateKeyFile = File(
        p.join(tempDirectory.path, 'private-key.pem'),
      )..writeAsStringSync(testRsaPrivateKey);
      environment = {
        'GITHUB_APP_ID': '12345',
        'GITHUB_PRIVATE_KEY_PATH': privateKeyFile.path,
        'GITHUB_API_BASE_URL': 'https://api.github.test',
      };
    });

    tearDown(() async {
      await db.close();
      tempDirectory.deleteSync(recursive: true);
    });

    test('uses verified connection without UID or legacy IDs', () async {
      await db
          .update(db.teams)
          .write(const TeamsCompanion(installationIds: Value([])));
      final client = MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/repos/openci-org/openci/installation') {
          expect(request.method, 'GET');
          return http.Response(jsonEncode({'id': 998877}), HttpStatus.ok);
        }
        if (request.method == 'POST') {
          expect(
            request.url.path,
            '/app/installations/998877/access_tokens',
          );
          return http.Response(
            jsonEncode({'token': 'installation-token'}),
            HttpStatus.created,
          );
        }

        expect(request.method, 'GET');
        expect(request.url.queryParameters['ref'], 'commit-sha-123');
        expect(
          request.headers['authorization'],
          contains('installation-token'),
        );
        if (request.url.path.endsWith('/contents/openci')) {
          return http.Response(
            jsonEncode([
              {'type': 'file', 'name': 'ci.dart', 'path': 'openci/ci.dart'},
            ]),
            HttpStatus.ok,
          );
        }
        return http.Response(
          jsonEncode({
            'type': 'file',
            'content': base64Encode(utf8.encode('void main() {}')),
            'encoding': 'base64',
          }),
          HttpStatus.ok,
        );
      });
      addTearDown(client.close);
      final context = _requestContext(
        db: db,
        path:
            '/teams/team-123/repositories/openci/openci-files'
            '?ref=commit-sha-123&owner=openci-org&installationId=998877',
        environment: environment,
        client: client,
      );

      final response = await route.onRequest(
        context.context,
        'team-123',
        'openci',
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.json(), [
        {
          'name': 'ci.dart',
          'path': 'openci/ci.dart',
          'content': 'void main() {}',
        },
      ]);
      expect(requests.map((request) => request.url.path), [
        '/repos/openci-org/openci/installation',
        '/app/installations/998877/access_tokens',
        '/repos/openci-org/openci/contents/openci',
        '/repos/openci-org/openci/contents/openci/ci.dart',
      ]);
    });

    for (final uid in ['user-1', 'system-job-processor']) {
      test('allows team member $uid without an internal key', () async {
        await db.teamDao.addTeamMember('team-123', uid);
        final client = MockClient((request) async {
          if (request.url.path.endsWith('/installation')) {
            return http.Response(jsonEncode({'id': 998877}), HttpStatus.ok);
          }
          if (request.method == 'POST') {
            return http.Response(
              jsonEncode({'token': 'installation-token'}),
              HttpStatus.created,
            );
          }
          return http.Response('[]', HttpStatus.ok);
        });
        addTearDown(client.close);
        final context = _requestContext(
          db: db,
          path:
              '/teams/team-123/repositories/openci/openci-files'
              '?ref=commit-sha-123&owner=openci-org&installationId=998877',
          environment: environment,
          client: client,
          uid: uid,
          headers: {'Authorization': 'Bearer firebase-id-token'},
        );

        final response = await route.onRequest(
          context.context,
          'team-123',
          'openci',
        );

        expect(response.statusCode, HttpStatus.ok);
        expect(await response.json(), isEmpty);
      });
    }

    test('rejects a missing team before contacting GitHub', () async {
      await db.delete(db.teams).go();

      final response = await get();

      expect(response.statusCode, HttpStatus.notFound);
      expect(await response.json(), {
        'success': false,
        'error': 'Team not found',
      });
      expect(requests, isEmpty);
    });

    test('rejects legacy IDs without an active verified connection', () async {
      await db.delete(db.gitHubConnections).go();

      final response = await get();

      expect(response.statusCode, HttpStatus.badRequest);
      expect(await response.json(), {
        'success': false,
        'error': 'No active GitHub connection for this team',
      });
      expect(requests, isEmpty);
    });

    test(
      'rejects an invalid installation ID before contacting GitHub',
      () async {
        final response = await get(installationId: 'not-a-number');

        expect(response.statusCode, HttpStatus.badRequest);
        expect(await response.json(), {
          'success': false,
          'error': 'Invalid installationId',
        });
        expect(requests, isEmpty);
      },
    );

    test('requires owner', () async {
      final context = _requestContext(
        db: db,
        path:
            '/teams/team-123/repositories/openci/openci-files'
            '?ref=commit-sha-123&installationId=998877',
        environment: environment,
      );

      final response = await route.onRequest(
        context.context,
        'team-123',
        'openci',
      );

      expect(response.statusCode, HttpStatus.badRequest);
      expect(await response.json(), {
        'success': false,
        'error': 'owner is required',
      });
    });

    test('requires installation ID', () async {
      final context = _requestContext(
        db: db,
        path:
            '/teams/team-123/repositories/openci/openci-files'
            '?ref=commit-sha-123&owner=openci-org',
        environment: environment,
      );

      final response = await route.onRequest(
        context.context,
        'team-123',
        'openci',
      );

      expect(response.statusCode, HttpStatus.badRequest);
      expect(await response.json(), {
        'success': false,
        'error': 'installationId is required',
      });
    });

    test('rejects an installation ID that is not linked to the team', () async {
      final context = _requestContext(
        db: db,
        path:
            '/teams/team-123/repositories/openci/openci-files'
            '?ref=commit-sha-123&owner=openci-org&installationId=123456',
        environment: environment,
      );

      final response = await route.onRequest(
        context.context,
        'team-123',
        'openci',
      );

      expect(response.statusCode, HttpStatus.forbidden);
      expect(await response.json(), {
        'success': false,
        'error': 'Forbidden',
      });
    });

    test(
      'rejects another team connection despite matching legacy IDs',
      () async {
        final team = (await db.teamDao.getTeam('team-123'))!;
        await db.into(db.teams).insert(team.copyWith(id: 'other-team'));
        await db
            .into(db.gitHubConnections)
            .insert(
              connection.copyWith(
                id: 'other-team-connection',
                teamId: 'other-team',
                installationId: 111111,
              ),
            );

        final response = await get(installationId: '111111');

        expect(response.statusCode, HttpStatus.forbidden);
        expect(await response.json(), {'success': false, 'error': 'Forbidden'});
        expect(requests, isEmpty);
      },
    );

    test(
      'rejects a suspended target even with another active connection',
      () async {
        await db
            .update(db.gitHubConnections)
            .replace(
              connection.copyWith(status: GitHubConnectionStatus.suspended),
            );
        await db
            .into(db.gitHubConnections)
            .insert(
              connection.copyWith(
                id: 'other-connection',
                installationId: 111111,
              ),
            );

        final response = await get();

        expect(response.statusCode, HttpStatus.forbidden);
        expect(requests, isEmpty);
      },
    );

    test('rejects matching installation IDs for another host or App', () async {
      await db
          .update(db.gitHubConnections)
          .replace(
            connection.copyWith(installationId: 111111),
          );
      await db
          .into(db.gitHubConnections)
          .insert(
            connection.copyWith(
              id: 'other-host',
              githubApiBaseUrl: 'https://another.example/api/v3',
            ),
          );
      await db
          .into(db.gitHubConnections)
          .insert(
            connection.copyWith(
              id: 'other-app',
              githubAppId: 42,
            ),
          );

      final response = await get();

      expect(response.statusCode, HttpStatus.forbidden);
      expect(requests, isEmpty);
    });

    test('rejects a repository that belongs to another installation', () async {
      await db
          .into(db.gitHubConnections)
          .insert(
            connection.copyWith(
              id: 'other-connection',
              installationId: 111111,
            ),
          );

      final response = await get(
        respond: (_) =>
            http.Response(jsonEncode({'id': 111111}), HttpStatus.ok),
      );

      expect(response.statusCode, HttpStatus.forbidden);
      expect(await response.json(), {'success': false, 'error': 'Forbidden'});
      expect(requests.single.url.path, '/repos/openci-org/openci/installation');
    });

    test(
      'stops when GitHub rejects the repository installation lookup',
      () async {
        final response = await get(
          respond: (_) =>
              http.Response('Repository not accessible', HttpStatus.notFound),
        );

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(await response.json(), {
          'success': false,
          'error': 'Internal server error',
        });
        expect(
          requests.single.url.path,
          '/repos/openci-org/openci/installation',
        );
      },
    );

    test('stops when GitHub rejects token creation', () async {
      final response = await get(
        respond: (request) {
          if (request.url.path.endsWith('/installation')) {
            return http.Response(jsonEncode({'id': 998877}), HttpStatus.ok);
          }
          return http.Response('Installation suspended', HttpStatus.forbidden);
        },
      );

      expect(response.statusCode, HttpStatus.internalServerError);
      expect(await response.json(), {
        'success': false,
        'error': 'Internal server error',
      });
      expect(requests.map((request) => request.url.path), [
        '/repos/openci-org/openci/installation',
        '/app/installations/998877/access_tokens',
      ]);
    });

    test(
      'does not return an empty success or try another connection on access denial',
      () async {
        await db
            .into(db.gitHubConnections)
            .insert(
              connection.copyWith(
                id: 'other-connection',
                installationId: 111111,
              ),
            );

        final response = await get(
          respond: (request) {
            if (request.url.path.endsWith('/installation')) {
              return http.Response(jsonEncode({'id': 998877}), HttpStatus.ok);
            }
            if (request.method == 'POST') {
              return http.Response(
                jsonEncode({'token': 'installation-token'}),
                HttpStatus.created,
              );
            }
            return http.Response(
              jsonEncode({'message': 'Forbidden'}),
              HttpStatus.forbidden,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          },
        );

        expect(response.statusCode, HttpStatus.internalServerError);
        expect(await response.json(), {
          'success': false,
          'error': 'Internal server error',
        });
        expect(requests.map((request) => request.url.path), [
          '/repos/openci-org/openci/installation',
          '/app/installations/998877/access_tokens',
          '/repos/openci-org/openci/contents/openci',
        ]);
      },
    );

    test('uses the normalized operator URL for lookup, token and files', () async {
      environment['GITHUB_API_BASE_URL'] =
          ' https://github.example:8443/api/v3/// ';
      await db
          .update(db.gitHubConnections)
          .replace(
            connection.copyWith(
              githubApiBaseUrl: 'https://github.example:8443/api/v3',
            ),
          );

      final response = await get(
        respond: (request) {
          if (request.url.path.endsWith('/installation')) {
            return http.Response(jsonEncode({'id': 998877}), HttpStatus.ok);
          }
          if (request.method == 'POST') {
            return http.Response(
              jsonEncode({'token': 'installation-token'}),
              HttpStatus.created,
            );
          }
          return http.Response('[]', HttpStatus.ok);
        },
      );

      expect(response.statusCode, HttpStatus.ok);
      expect(await response.json(), isEmpty);
      expect(requests.map((request) => request.url.toString()), [
        'https://github.example:8443/api/v3/repos/openci-org/openci/installation',
        'https://github.example:8443/api/v3/app/installations/998877/access_tokens',
        'https://github.example:8443/api/v3/repos/openci-org/openci/contents/openci?ref=commit-sha-123',
      ]);
    });
  });

  testDatabaseFailures([
    DatabaseFailureEndpoint(
      '/teams/team-1/repositories/repo/openci-files',
      HttpMethod.get,
      (c) => route.onRequest(c, 'team-1', 'repo'),
      configure: (context) {
        context.provide<InternalApiKeyValidator>(
          const InternalApiKeyValidator(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          ),
        );
      },
    ),
  ]);
}

TestRequestContext _requestContext({
  required AppDatabase db,
  required String path,
  required Map<String, String> environment,
  http.Client? client,
  String? uid,
  Map<String, String> headers = const {
    'Authorization': 'Bearer test-internal-key',
  },
}) {
  final context =
      TestRequestContext(
          path: path,
          method: HttpMethod.get,
          headers: headers,
        )
        ..provide<AppDatabase>(db)
        ..provide<String?>(uid)
        ..provide<InternalApiKeyValidator>(
          const InternalApiKeyValidator(
            environment: {'INTERNAL_API_KEY': 'test-internal-key'},
          ),
        )
        ..provide<Map<String, String>>(environment);
  final githubClient =
      client ??
      MockClient(
        (_) async => fail('GitHub must not be contacted'),
      );
  if (client == null) addTearDown(githubClient.close);
  context.provide<http.Client>(githubClient);
  return context;
}
